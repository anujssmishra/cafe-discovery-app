<?php
declare(strict_types=1);

/** Read process environment only; .env files are deliberately not loaded. */
function app_config(): array
{
    $env = static function (string $name, string $default = ''): string {
        $value = getenv($name);
        return $value === false ? $default : $value;
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
