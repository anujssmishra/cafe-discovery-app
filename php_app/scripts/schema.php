<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/schema_helpers.php';
$arguments = array_slice($argv, 1);
if ($arguments === ['--help']) {
    fwrite(STDOUT, "Usage: php php_app/scripts/schema.php --apply\nRequires APP_ENV=development or test. MySQL 8.0.16+ only.\nDDL is nontransactional; back up existing databases before upgrading.\n");
    exit(0);
}
if ($arguments !== ['--apply']) {
    fwrite(STDERR, "Usage: php php_app/scripts/schema.php --apply\n");
    exit(2);
}
try {
    $config = app_config();
    if (!in_array($config['app_env'], ['development', 'test'], true)) {
        throw new RuntimeException('Schema setup requires APP_ENV=development or test.');
    }
    schema_apply(db_connect($config));
    fwrite(STDOUT, "Catalogue schema ready. Existing data retained; missing constraints and indexes added.\n");
} catch (Throwable $error) {
    fwrite(STDERR, "Schema setup failed: " . $error->getMessage() . "\nEarlier DDL may already have applied; inspect the database before retrying.\n");
    exit(1);
}
