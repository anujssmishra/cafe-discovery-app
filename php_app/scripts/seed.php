<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/seed.php';
$arguments = array_slice($argv, 1);
if ($arguments === ['--help']) {
    fwrite(STDOUT, "Usage: php php_app/scripts/seed.php --demo\nRequires APP_ENV=development or test and DEMO_MODE=true.\nInserts fictional fixtures without changing existing records.\n");
    exit(0);
}
if ($arguments !== ['--demo']) {
    fwrite(STDERR, "Usage: php php_app/scripts/seed.php --demo\n");
    exit(2);
}
try {
    $config = app_config();
    if (!in_array($config['app_env'], ['development', 'test'], true) || $config['demo_mode'] !== true) {
        throw new RuntimeException('Demo seeding requires APP_ENV=development or test and DEMO_MODE=true.');
    }
    $result = seed_demo(db_connect($config));
    fwrite(STDOUT, sprintf("Demo seed complete: %d areas, %d cafés and %d offerings inserted; %d existing cafés preserved.\n", $result['areas_inserted'], $result['cafes_inserted'], $result['offerings_inserted'], $result['cafes_existing']));
} catch (Throwable $error) {
    fwrite(STDERR, "Demo seed failed: " . $error->getMessage() . "\n");
    exit(1);
}
