<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
$target = $argv[1] ?? dirname(__DIR__);
if (count($argv) > 2 || !is_dir($target)) {
    fwrite(STDERR, "Usage: php php_app/scripts/lint.php [directory]\n");
    exit(2);
}
$files = [];
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($target, FilesystemIterator::SKIP_DOTS)) as $file) {
    if ($file->isFile() && strtolower($file->getExtension()) === 'php') {
        $files[] = $file->getPathname();
    }
}
sort($files, SORT_STRING);
if ($files === []) {
    fwrite(STDERR, "No PHP files found.\n");
    exit(2);
}
$failures = 0;
foreach ($files as $file) {
    $process = proc_open([PHP_BINARY, '-l', $file], [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes);
    if (!is_resource($process)) {
        fwrite(STDERR, "Could not run PHP lint.\n");
        exit(2);
    }
    $output = stream_get_contents($pipes[1]) . stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    if (proc_close($process) !== 0) {
        $failures++;
        fwrite(STDERR, $output);
    }
}
if ($failures > 0) {
    fwrite(STDERR, "PHP lint failed in {$failures} file(s).\n");
    exit(1);
}
fwrite(STDOUT, 'PHP lint passed: ' . count($files) . " files.\n");
