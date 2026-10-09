<?php
declare(strict_types=1);

// Build an explicit runtime allowlist; never recursively copy the repository.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if ($argc !== 2 || !str_starts_with($argv[1], '--output=')) {
    fwrite(STDERR, "Usage: php php_app/scripts/package.php --output=<absolute ZIP path>\n");
    exit(2);
}
try {
    $output = substr($argv[1], strlen('--output='));
    $absolute = DIRECTORY_SEPARATOR === '\\'
        ? preg_match('~^(?:[A-Za-z]:[\\\\/]|[\\\\/]{2}[^\\\\/]+[\\\\/])~', $output) === 1
        : str_starts_with($output, '/');
    if (!$absolute || !str_ends_with(strtolower($output), '.zip')) {
        throw new RuntimeException('Output must be an absolute ZIP path.');
    }
    $parent = realpath(dirname($output));
    if ($parent === false || !is_dir($parent) || !is_writable($parent) || file_exists($output) || is_link($output)) {
        throw new RuntimeException('Use a writable existing directory and a new output filename.');
    }
    $root = realpath(dirname(__DIR__));
    if ($root === false) { throw new RuntimeException('Cannot resolve the release source.'); }
    foreach (['public', 'public_html'] as $directory) {
        $public = realpath($root . '/' . $directory);
        if ($public === false) { continue; }
        for ($ancestor = dirname($output); ; $ancestor = dirname($ancestor)) {
            $canonical = realpath($ancestor);
            $same = $canonical !== false && (DIRECTORY_SEPARATOR === '\\'
                ? strcasecmp($canonical, $public) === 0 : $canonical === $public);
            if ($same) { throw new RuntimeException('Release output must be outside the public directory.'); }
            if (dirname($ancestor) === $ancestor) { break; }
        }
        $prefix = $public . DIRECTORY_SEPARATOR;
        $within = DIRECTORY_SEPARATOR === '\\'
            ? strncasecmp($parent . DIRECTORY_SEPARATOR, $prefix, strlen($prefix)) === 0
            : strncmp($parent . DIRECTORY_SEPARATOR, $prefix, strlen($prefix)) === 0;
        if ($within) { throw new RuntimeException('Release output must be outside the public directory.'); }
    }
    if (!class_exists(ZipArchive::class)) { throw new RuntimeException('Packaging requires the PHP zip extension.'); }
    $files = [
        'public/index.php' => 'public_html/index.php',
        'public/.htaccess' => 'public_html/.htaccess',
        'public/static/site.css' => 'public_html/static/site.css',
        'config/local.example.php' => 'config/local.example.php',
        'schema/schema.sql' => 'schema/schema.sql',
        'schema/README.md' => 'schema/README.md',
        'scripts/schema.php' => 'scripts/schema.php',
        'scripts/schema_helpers.php' => 'scripts/schema_helpers.php',
    ];
    foreach (['config.php', 'db.php', 'request.php', 'catalogue.php', 'web.php'] as $file) {
        $files['includes/' . $file] = 'includes/' . $file;
    }
    foreach (['header.php', 'footer.php', 'catalogue.php', 'cafe_detail.php', 'about.php', 'error.php', '_evidence.php'] as $file) {
        $files['templates/' . $file] = 'templates/' . $file;
    }
    $contents = [];
    $hashes = [];
    foreach ($files as $source => $destination) {
        $path = $root . '/' . $source;
        $resolved = realpath($path);
        $expected = str_replace(['/', '\\'], DIRECTORY_SEPARATOR, $path);
        $matches = $resolved !== false && (DIRECTORY_SEPARATOR === '\\'
            ? strcasecmp($resolved, $expected) === 0 : $resolved === $expected);
        if (!$matches || is_link($path) || !is_file($path) || !is_readable($path)) {
            throw new RuntimeException('A required release file is unavailable.');
        }
        $data = file_get_contents($path);
        if ($data === false) { throw new RuntimeException('Cannot read a required release file.'); }
        $contents[$destination] = $data;
        $hashes[$destination] = hash('sha256', $data);
    }
    $contents['release.json'] = json_encode([
        'format' => 1,
        'domain' => 'myfanverse.in',
        'php_minimum' => '8.2',
        'database' => 'MariaDB 10.11+',
        'built_at_utc' => gmdate('c'),
        'files_sha256' => $hashes,
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR) . "\n";
    // Write privately to a temporary file; publish only a fully closed archive.
    $temporary = tempnam($parent, '.cafe-release-');
    if ($temporary === false) { throw new RuntimeException('Cannot create the release archive.'); }
    try {
        $zip = new ZipArchive();
        if ($zip->open($temporary, ZipArchive::OVERWRITE) !== true) { throw new RuntimeException('Cannot open the release archive.'); }
        foreach ($contents as $path => $data) {
            if (!$zip->addFromString($path, $data)) { throw new RuntimeException('Cannot add a release file.'); }
        }
        if (!$zip->close()) { throw new RuntimeException('Cannot finalize the release archive.'); }
        if (!rename($temporary, $output)) { throw new RuntimeException('Cannot save the release archive.'); }
    } finally {
        if (is_file($temporary)) { unlink($temporary); }
    }
    fwrite(STDOUT, "Hostinger release created: {$output}\n");
} catch (Throwable $error) {
    fwrite(STDERR, 'Release refused: ' . $error->getMessage() . "\n");
    exit(1);
}
