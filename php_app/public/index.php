<?php
declare(strict_types=1);

// Visitors receive one generic response, including when configuration or connection fails.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/web.php';
require_once __DIR__ . '/../includes/request.php';
require_once __DIR__ . '/../includes/catalogue.php';

$config = ['base_path' => ''];
$path = '';
ob_start();
try {
    $config = app_config();
    header('Content-Type: text/html; charset=UTF-8');
    header('X-Content-Type-Options: nosniff');
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (!in_array($method, ['GET', 'HEAD'], true)) {
        header('Allow: GET, HEAD');
        $statusCode = 405;
        $errorTitle = 'Method not allowed';
        $errorMessage = 'Use a link or the catalogue search form to browse this guide.';
        http_response_code($statusCode);
        require __DIR__ . '/../templates/error.php';
    } else {
        $requestPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
        $base = $config['base_path'];
        $underBase = is_string($requestPath) && ($base === '' || $requestPath === $base
            || str_starts_with($requestPath, $base . '/'));
        $path = $underBase ? trim(substr($requestPath, strlen($base)), '/') : '__missing__';
        if ($path === '' || $path === 'index.php') {
            $filters = catalogue_request($_GET);
            $searchQuery = $filters['q'];
            $areaFilter = $filters['area'];
            $errors = $filters['errors'];
            $cafes = [];
            $areas = [];
            $pagination = ['page' => 1, 'pages' => 1, 'total' => 0, 'page_size' => 12];
            if ($errors !== []) {
                http_response_code(400);
            } else {
                $pdo = db_connect($config);
                $result = catalogue_page($pdo, $filters, $config['demo_mode']);
                $cafes = $result['cafes'];
                $pagination = $result['pagination'];
                $areaSql = 'SELECT a.* FROM area a WHERE a.is_active = 1';
                if (!$config['demo_mode']) {
                    $areaSql .= ' AND EXISTS (SELECT 1 FROM cafe c WHERE c.area_id = a.id AND c.is_active = 1 AND c.is_demo = 0)';
                }
                $areas = $pdo->query($areaSql . ' ORDER BY a.display_order, a.name, a.slug')->fetchAll();
            }
            require __DIR__ . '/../templates/catalogue.php';
        } elseif ($path === 'about') {
            require __DIR__ . '/../templates/about.php';
        } elseif (preg_match('~^cafes/([^/]+)$~D', $path, $matches) && valid_cafe_id($matches[1])) {
            $pdo = db_connect($config);
            $cafe = catalogue_detail($pdo, $matches[1], $config['demo_mode']);
            if ($cafe !== false) {
                $statement = $pdo->prepare('SELECT * FROM cafe_offering WHERE cafe_id = :id ORDER BY drink_type, brewing_method, id');
                $statement->execute([':id' => $cafe['id']]);
                $offerings = $statement->fetchAll();
                require __DIR__ . '/../templates/cafe_detail.php';
            } else {
                $statusCode = 404;
                $errorTitle = 'Café not found';
                $errorMessage = 'This café is unavailable. Browse the catalogue for active listings.';
                http_response_code($statusCode);
                require __DIR__ . '/../templates/error.php';
            }
        } else {
            $statusCode = 404;
            $errorTitle = 'Page not found';
            $errorMessage = 'The requested page is unavailable. Browse the catalogue to continue.';
            http_response_code($statusCode);
            require __DIR__ . '/../templates/error.php';
        }
    }
} catch (Throwable $exception) {
    ob_clean();
    // Log only diagnostic class/code, never database credentials, DSNs or submitted values.
    error_log('Catalogue request failed: ' . get_class($exception) . ' [' . $exception->getCode() . ']');
    http_response_code(503);
    header('Content-Type: text/html; charset=UTF-8');
    header('Retry-After: 60');
    $statusCode = 503;
    $errorTitle = 'Catalogue temporarily unavailable';
    $errorMessage = 'Please try again later.';
    require __DIR__ . '/../templates/error.php';
}
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'HEAD') {
    ob_end_clean();
} else {
    ob_end_flush();
}
