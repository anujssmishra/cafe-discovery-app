<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/schema_helpers.php';
$arguments = array_slice($argv, 1);
$usage = "Usage (local): php php_app/scripts/schema.php --apply\nUsage (production): php php_app/scripts/schema.php --apply --production --database=<exact configured DB_NAME>\nMariaDB 10.11+ only. Back up existing data before applying nontransactional DDL.\n";
if ($arguments === ['--help']) {
    fwrite(STDOUT, $usage . "Local setup requires APP_ENV=development or test.\nProduction setup requires APP_ENV=production, DEMO_MODE=false and an exact database acknowledgement.\nDemo seeding is never allowed in production.\n");
    exit(0);
}
$apply = false;
$production = false;
$database = null;
$validArguments = true;
foreach ($arguments as $argument) {
    if ($argument === '--apply' && !$apply) {
        $apply = true;
    } elseif ($argument === '--production' && !$production) {
        $production = true;
    } elseif (str_starts_with($argument, '--database=') && $database === null && substr($argument, 11) !== '') {
        $database = substr($argument, 11);
    } else {
        $validArguments = false;
    }
}
if (!$validArguments || !$apply || ($production && $database === null) || (!$production && $database !== null)) {
    fwrite(STDERR, $usage);
    exit(2);
}
try {
    $config = app_config();
    if ($production) {
        if ($config['app_env'] !== 'production' || $config['demo_mode'] !== false) {
            throw new RuntimeException('Production schema setup requires APP_ENV=production and DEMO_MODE=false.');
        }
        if (!hash_equals((string) $config['db_name'], (string) $database)) {
            throw new RuntimeException('Production schema setup requires --database to match the configured DB_NAME exactly.');
        }
    } elseif (!in_array($config['app_env'], ['development', 'test'], true)) {
        throw new RuntimeException('Production schema setup requires --apply --production --database=<exact configured DB_NAME>.');
    }
    $pdo = db_connect($config);
    if ($production && (string) $pdo->query('SELECT DATABASE()')->fetchColumn() !== $database) {
        throw new RuntimeException('The connected database does not match the production acknowledgement.');
    }
    schema_apply($pdo);
    fwrite(STDOUT, "Catalogue schema ready. Existing data retained; missing constraints and indexes added.\n");
} catch (Throwable $error) {
    fwrite(STDERR, "Schema setup failed: " . $error->getMessage() . "\nEarlier DDL may already have applied; inspect the database before retrying.\n");
    exit(1);
}
