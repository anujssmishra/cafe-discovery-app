<?php
declare(strict_types=1);

// The existing apex and this subdomain share public_html. Keep runtime/config
// above that directory, rather than exposing them through the apex website.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
$bufferLevel = ob_get_level();
ob_start();
try {
    $entry = __DIR__ . '/../../cafe_app/public_html/index.php';
    if (!is_file($entry) || !is_readable($entry)) {
        throw new RuntimeException('Private application entry unavailable.');
    }
    require $entry;
    while (ob_get_level() > $bufferLevel) { ob_end_flush(); }
} catch (Throwable $error) {
    while (ob_get_level() > $bufferLevel) { ob_end_clean(); }
    error_log('Cafe bootstrap failed: ' . get_class($error));
    http_response_code(503);
    header('Content-Type: text/html; charset=UTF-8');
    echo '<!doctype html><html lang="en"><meta charset="utf-8"><title>Temporarily unavailable</title><h1>Temporarily unavailable</h1><p>Please try again later.</p></html>';
}
