<?php
declare(strict_types=1);

// Development router. Apache/Hostinger uses public/.htaccess.
$requestPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$requestPath = is_string($requestPath) ? rawurldecode($requestPath) : '/';
$basePath = rtrim((string) getenv('APP_BASE_PATH'), '/');
$validBase = $basePath === '' || preg_match('~^/(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+$~D', $basePath);
$withinBase = $validBase && ($basePath === '' || $requestPath === $basePath || str_starts_with($requestPath, $basePath . '/'));
$relativePath = $withinBase && $basePath !== '' ? substr($requestPath, strlen($basePath)) : $requestPath;
$relativePath = $relativePath === '' ? '/' : $relativePath;
$blocked = str_contains($requestPath, "\0") || str_contains($requestPath, '\\')
    || preg_match('~(?:^|/)\.~', $requestPath)
    || (preg_match('~\.php(?:/|$)~i', $relativePath) && $relativePath !== '/index.php');
if ($blocked) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=UTF-8');
    header('X-Content-Type-Options: nosniff');
    echo 'Page not found.';
    return true;
}
if ($withinBase && str_starts_with($relativePath, '/static/')) {
    $staticRoot = realpath(__DIR__ . '/static');
    $assetFile = realpath(__DIR__ . $relativePath);
    if ($staticRoot !== false && $assetFile !== false
        && str_starts_with($assetFile, $staticRoot . DIRECTORY_SEPARATOR)
        && is_file($assetFile) && strtolower(pathinfo($assetFile, PATHINFO_EXTENSION)) === 'css') {
        header('Content-Type: text/css; charset=UTF-8');
        header('X-Content-Type-Options: nosniff');
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'HEAD') { readfile($assetFile); }
        return true;
    }
    http_response_code(404);
    header('Content-Type: text/plain; charset=UTF-8');
    header('X-Content-Type-Options: nosniff');
    echo 'Asset not found.';
    return true;
}
require __DIR__ . '/index.php';
return true;
