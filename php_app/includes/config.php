<?php
declare(strict_types=1);

/** Read a private operator config, then overlay process environment. No dotenv loading. */
function app_config(): array
{
    $keys = ['APP_ENV', 'DEMO_MODE', 'APP_BASE_PATH', 'DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASS'];
    $explicit = getenv('APP_CONFIG_FILE');
    $file = $explicit === false ? dirname(__DIR__) . '/config/local.php' : $explicit;
    $absolute = DIRECTORY_SEPARATOR === '\\'
        ? preg_match('~^(?:[A-Za-z]:[\\\\/]|[\\\\/]{2}[^\\\\/]+[\\\\/])~', $file) === 1
        : str_starts_with($file, '/');
    if ($explicit !== false && !$absolute) {
        throw new RuntimeException('Private configuration must use an absolute path.');
    }
    $private = [];
    if ($explicit !== false || file_exists($file) || is_link($file)) {
        $resolved = realpath($file);
        if ($resolved === false || !is_file($resolved) || !is_readable($resolved)) {
            throw new RuntimeException('Private configuration is unavailable.');
        }
        $appRoot = dirname(__DIR__);
        // Shared-subdomain deployments keep cafe_app beside the apex public_html.
        // Protect that served ancestor too, including CLI configuration overrides.
        foreach ([$appRoot . '/public', $appRoot . '/public_html', dirname($appRoot) . '/public_html'] as $directory) {
            $public = realpath($directory);
            if ($public === false) { continue; }
            // A public alias to a private file is still web-accessible. Inspect
            // the supplied path's ancestors as well as its resolved target.
            for ($ancestor = dirname($file); ; $ancestor = dirname($ancestor)) {
                $canonical = realpath($ancestor);
                $same = $canonical !== false && (DIRECTORY_SEPARATOR === '\\'
                    ? strcasecmp($canonical, $public) === 0 : $canonical === $public);
                if ($same) { throw new RuntimeException('Private configuration must be outside the public directory.'); }
                if (dirname($ancestor) === $ancestor) { break; }
            }
            $prefix = $public . DIRECTORY_SEPARATOR;
            $inside = DIRECTORY_SEPARATOR === '\\'
                ? strncasecmp($resolved, $prefix, strlen($prefix)) === 0
                : strncmp($resolved, $prefix, strlen($prefix)) === 0;
            if ($inside) { throw new RuntimeException('Private configuration must be outside the public directory.'); }
        }
        // The file is trusted operator code, never a path accepted from a web request.
        $private = (static function (string $path): mixed { return require $path; })($resolved);
        if (!is_array($private)) { throw new RuntimeException('Invalid private configuration.'); }
        foreach ($private as $name => $value) {
            if (!in_array($name, $keys, true) || !is_string($value)) {
                throw new RuntimeException('Invalid private configuration.');
            }
        }
    }
    $env = static function (string $name, string $default = '') use ($private): string {
        $value = getenv($name);
        return $value === false ? ($private[$name] ?? $default) : $value;
    };
    $environment = $env('APP_ENV', 'production');
    if (!in_array($environment, ['development', 'test', 'production'], true)) {
        throw new RuntimeException('APP_ENV must be development, test or production.');
    }
    $demo = $env('DEMO_MODE', 'false');
    if (!in_array($demo, ['true', 'false'], true)) {
        throw new RuntimeException('DEMO_MODE must be true or false.');
    }
    if ($demo === 'true' && $environment === 'production') {
        throw new RuntimeException('Demo mode is restricted to development and test.');
    }
    $base = rtrim($env('APP_BASE_PATH'), '/');
    if ($base !== '' && !preg_match('~^/(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+$~D', $base)) {
        throw new RuntimeException('APP_BASE_PATH must be empty or a path such as /guide.');
    }
    $port = $env('DB_PORT', '3306');
    if (!ctype_digit($port) || (int) $port < 1 || (int) $port > 65535) {
        throw new RuntimeException('DB_PORT must be between 1 and 65535.');
    }
    $host = $env('DB_HOST', '127.0.0.1');
    $database = $env('DB_NAME', 'cafe_discovery');
    if (!preg_match('/^[A-Za-z0-9_.:-]+$/D', $host) || !preg_match('/^[A-Za-z0-9_]+$/D', $database)) {
        throw new RuntimeException('Invalid database host or name.');
    }
    $user = $env('DB_USER');
    if ($user === '') {
        throw new RuntimeException('DB_USER must be configured.');
    }
    return [
        'app_env' => $environment,
        'demo_mode' => $demo === 'true',
        'base_path' => $base,
        'db_host' => $host,
        'db_port' => (int) $port,
        'db_name' => $database,
        'db_user' => $user,
        'db_pass' => $env('DB_PASS'),
    ];
}
