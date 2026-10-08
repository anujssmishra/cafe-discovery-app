<?php
// php_app/public/index.php

require_once __DIR__ . '/../includes/db.php';

// Very basic router
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = trim($requestUri, '/');

if ($path === '' || $path === 'index.php') {
    // 1. Fetch search filters
    $searchQuery = $_GET['q'] ?? '';
    $areaFilter = $_GET['area'] ?? '';

    // 2. Build the SQL query
    $sql = "
        SELECT c.*, a.name AS area_name, a.city AS area_city 
        FROM cafe c
        JOIN area a ON c.area_id = a.id
        WHERE c.is_active = 1
    ";
    $params = [];

    if ($searchQuery !== '') {
        $sql .= " AND c.name LIKE :q";
        $params[':q'] = "%$searchQuery%";
    }
    if ($areaFilter !== '') {
        $sql .= " AND a.slug = :area";
        $params[':area'] = $areaFilter;
    }
    
    $sql .= " ORDER BY c.name ASC";

    // 3. Execute query
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $cafes = $stmt->fetchAll();

    // 4. Fetch all active areas for the filter chips
    $areaStmt = $pdo->query("SELECT * FROM area WHERE is_active = 1 ORDER BY display_order ASC");
    $areas = $areaStmt->fetchAll();

    // 5. Pass variables to the frontend view
    $viewFile = __DIR__ . '/../templates/catalogue.php';
    if (file_exists($viewFile)) {
        require $viewFile;
    } else {
        // Fallback for Backend API mode before Frontend Agent is done
        header('Content-Type: application/json');
        echo json_encode([
            'areas' => $areas,
            'cafes' => $cafes
        ]);
    }
} elseif (preg_match('/^cafes\/([a-f0-9\-]{36})$/', $path, $matches)) {
    // Cafe Detail Route
    $cafeId = $matches[1];
    
    $stmt = $pdo->prepare("
        SELECT c.*, a.name AS area_name, a.city AS area_city 
        FROM cafe c
        JOIN area a ON c.area_id = a.id
        WHERE c.id = :id AND c.is_active = 1
    ");
    $stmt->execute([':id' => $cafeId]);
    $cafe = $stmt->fetch();
    
    if (!$cafe) {
        http_response_code(404);
        echo "Cafe not found.";
        exit;
    }

    $offeringStmt = $pdo->prepare("SELECT * FROM cafe_offering WHERE cafe_id = :id ORDER BY drink_type, brewing_method");
    $offeringStmt->execute([':id' => $cafeId]);
    $offerings = $offeringStmt->fetchAll();

    $viewFile = __DIR__ . '/../templates/cafe_detail.php';
    if (file_exists($viewFile)) {
        require $viewFile;
    } else {
        // Fallback for Backend API mode
        header('Content-Type: application/json');
        echo json_encode([
            'cafe' => $cafe,
            'offerings' => $offerings
        ]);
    }
} else {
    http_response_code(404);
    echo "404 Not Found";
}
