<?php
declare(strict_types=1);

// Auto-detect base directory for flat (public_html/) or nested (php_app/public/) deployment
$baseDir = is_dir(__DIR__ . '/includes') ? __DIR__ : dirname(__DIR__);
$templateDir = is_dir($baseDir . '/templates')
    ? $baseDir . '/templates'
    : (is_dir($baseDir . '/includes/templates') ? $baseDir . '/includes/templates' : $baseDir . '/templates');

// Visitors receive one generic response, including when configuration or connection fails.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);
require_once $baseDir . '/includes/db.php';
require_once $baseDir . '/includes/web.php';
require_once $baseDir . '/includes/request.php';
require_once $baseDir . '/includes/catalogue.php';
require_once $baseDir . '/includes/circles.php';

$config = ['base_path' => ''];
$path = '';
ob_start();
try {
    $config = app_config();
    header('Content-Type: text/html; charset=UTF-8');
    header('X-Content-Type-Options: nosniff');
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (!in_array($method, ['GET', 'HEAD', 'POST'], true)) {
        header('Allow: GET, HEAD, POST');
        $statusCode = 405;
        $errorTitle = 'Method not allowed';
        $errorMessage = 'Use a link or the catalogue search form to browse this guide.';
        http_response_code($statusCode);
        require $templateDir . '/error.php';
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
            $vibeFilter = $filters['vibe'];
            $errors = $filters['errors'];
            $cafes = [];
            $areas = [];
            $vibes = VIBE_OPTIONS;
            $pagination = ['page' => 1, 'pages' => 1, 'total' => 0, 'page_size' => 12];
            if ($errors !== []) {
                http_response_code(400);
            } else {
                $pdo = db_connect($config);
                $session = circle_get_current_session($pdo);
                $result = catalogue_page($pdo, $filters, $config['demo_mode']);
                $cafes = $result['cafes'];
                $pagination = $result['pagination'];
                $areaSql = 'SELECT a.* FROM area a WHERE a.is_active = 1';
                if (!$config['demo_mode']) {
                    $areaSql .= ' AND EXISTS (SELECT 1 FROM cafe c WHERE c.area_id = a.id AND c.is_active = 1 AND c.is_demo = 0)';
                }
                $areas = $pdo->query($areaSql . ' ORDER BY a.display_order, a.name, a.slug')->fetchAll();
            }
            require $templateDir . '/catalogue.php';
        } elseif ($path === 'about') {
            require $templateDir . '/about.php';
        } elseif ($path === 'circles') {
            $pdo = db_connect($config);
            $session = circle_get_current_session($pdo);
            $matchName = trim((string) ($_GET['match_name'] ?? ''));
            $matchedReviews = $matchName !== '' ? circle_find_google_matches($pdo, $matchName) : [];
            $message = (string) ($_GET['msg'] ?? '');
            require $templateDir . '/circles.php';
        } elseif ($path === 'circles/create' && $method === 'POST') {
            $pdo = db_connect($config);
            $circleName = trim((string) ($_POST['circle_name'] ?? ''));
            $creatorName = trim((string) ($_POST['creator_name'] ?? ''));
            if ($circleName !== '' && $creatorName !== '') {
                $newCircle = circle_create($pdo, $circleName, $creatorName);
                header('Location: ' . app_url('/circles/', ['msg' => "Circle '{$newCircle['name']}' created! Share your invite link."]));
                exit;
            }
            header('Location: ' . app_url('/circles/'));
            exit;
        } elseif ($path === 'circles/join-code' && $method === 'POST') {
            $pdo = db_connect($config);
            $inviteCode = trim((string) ($_POST['invite_code'] ?? ''));
            $memberName = trim((string) ($_POST['member_name'] ?? ''));
            if ($inviteCode !== '' && $memberName !== '') {
                $joined = circle_join($pdo, $inviteCode, $memberName);
                if ($joined) {
                    header('Location: ' . app_url('/circles/', ['msg' => "Joined '{$joined['name']}'!"]));
                    exit;
                }
            }
            header('Location: ' . app_url('/circles/', ['msg' => 'Invalid invite code. Check and try again.']));
            exit;
        } elseif (preg_match('~^join/([^/]+)$~D', $path, $matches)) {
            $pdo = db_connect($config);
            $inviteCode = $matches[1];
            $stmt = $pdo->prepare('SELECT * FROM circle WHERE invite_code = :code LIMIT 1');
            $stmt->execute([':code' => $inviteCode]);
            $circle = $stmt->fetch();
            if ($circle) {
                // Auto-join as guest or redirect to circles page
                $session = circle_get_current_session($pdo);
                if (!$session['is_logged_in']) {
                    circle_join($pdo, $inviteCode, 'Circle Friend');
                }
                header('Location: ' . app_url('/circles/', ['msg' => "Welcome to {$circle['name']}!"]));
                exit;
            }
            header('Location: ' . app_url('/circles/', ['msg' => 'Circle invite link expired or not found.']));
            exit;
        } elseif ($path === 'circles/import' && $method === 'POST') {
            $pdo = db_connect($config);
            $session = circle_get_current_session($pdo);
            $memberName = trim((string) ($_POST['member_name'] ?? ($session['member_name'] !== 'Guest' ? $session['member_name'] : 'Circle Friend')));
            $reviewIds = array_map('intval', (array) ($_POST['review_ids'] ?? []));
            $count = circle_import_google_reviews($pdo, $session['circle_id'], $memberName, $reviewIds);
            header('Location: ' . app_url('/circles/', ['msg' => "Successfully imported {$count} Google " . ($count === 1 ? 'review' : 'reviews') . " into {$session['circle_name']}!"]));
            exit;
        } elseif (preg_match('~^cafes/([^/]+)$~D', $path, $matches) && valid_cafe_id($matches[1])) {
            $pdo = db_connect($config);
            $session = circle_get_current_session($pdo);
            $cafe = catalogue_detail($pdo, $matches[1], $config['demo_mode']);
            if ($cafe !== false) {
                $statement = $pdo->prepare('SELECT * FROM cafe_offering WHERE cafe_id = :id ORDER BY drink_type, brewing_method, id');
                $statement->execute([':id' => $cafe['id']]);
                $offerings = $statement->fetchAll();
                $friendReviews = catalogue_friend_reviews($pdo, $cafe['id'], $session['circle_id'] ?? null);
                require $templateDir . '/cafe_detail.php';
            } else {
                $statusCode = 404;
                $errorTitle = 'Café not found';
                $errorMessage = 'This café is unavailable. Browse the catalogue for active listings.';
                http_response_code($statusCode);
                require $templateDir . '/error.php';
            }
        } else {
            $statusCode = 404;
            $errorTitle = 'Page not found';
            $errorMessage = 'The requested page is unavailable. Browse the catalogue to continue.';
            http_response_code($statusCode);
            require $templateDir . '/error.php';
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
    require $templateDir . '/error.php';
}
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'HEAD') {
    ob_end_clean();
} else {
    ob_end_flush();
}
