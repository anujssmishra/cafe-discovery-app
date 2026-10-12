<?php
declare(strict_types=1);

const VIBE_OPTIONS = [
    'work' => ['label' => 'Work & Study', 'search' => 'Work & Study'],
    'aesthetic' => ['label' => 'Aesthetic & Cozy', 'search' => 'Aesthetic & Cozy'],
    'garden' => ['label' => 'Garden & Outdoor', 'search' => 'Garden & Outdoor'],
    'quiet' => ['label' => 'Minimalist & Quiet', 'search' => 'Minimalist & Quiet'],
    'social' => ['label' => 'Lively & Social', 'search' => 'Lively & Social'],
    'date' => ['label' => 'Date Spot', 'search' => 'Date Spot'],
];

function catalogue_page(PDO $pdo, array $filters, bool $demoMode): array
{
    $where = 'c.is_active = 1 AND a.is_active = 1';
    $params = [];
    if (!$demoMode) {
        $where .= ' AND c.is_demo = 0';
    }
    if ($filters['q'] !== '') {
        $where .= " AND c.name LIKE :q ESCAPE '!'";
        $params[':q'] = '%' . strtr($filters['q'], ['!' => '!!', '%' => '!%', '_' => '!_']) . '%';
    }
    if ($filters['area'] !== '') {
        $where .= ' AND a.slug = :area';
        $params[':area'] = $filters['area'];
    }
    if (!empty($filters['vibe']) && isset(VIBE_OPTIONS[$filters['vibe']])) {
        $where .= " AND c.vibe_tags LIKE :vibe ESCAPE '!'";
        $params[':vibe'] = '%' . strtr(VIBE_OPTIONS[$filters['vibe']]['search'], ['!' => '!!', '%' => '!%', '_' => '!_']) . '%';
    }
    $from = ' FROM cafe c JOIN area a ON c.area_id = a.id WHERE ' . $where;
    $count = $pdo->prepare('SELECT COUNT(*)' . $from);
    $count->execute($params);
    $total = (int) $count->fetchColumn();
    $pageSize = 12;
    $pages = max(1, (int) ceil($total / $pageSize));
    $page = min(max(1, $filters['page']), $pages);

    // Defensive check: only subquery friend_review if table exists
    $friendCountExpr = '0 AS friend_review_count';
    try {
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'friend_review'");
        if ($tableCheck && $tableCheck->rowCount() > 0) {
            $friendCountExpr = '(SELECT COUNT(*) FROM friend_review fr WHERE fr.cafe_id = c.id AND fr.is_verified_friend = 1) AS friend_review_count';
        }
    } catch (Throwable) {
        $friendCountExpr = '0 AS friend_review_count';
    }

    $statement = $pdo->prepare('SELECT c.*, a.name AS area_name, a.city AS area_city, '
        . $friendCountExpr . $from . ' ORDER BY c.name ASC, c.id ASC LIMIT :limit OFFSET :offset');
    foreach ($params as $key => $value) {
        $statement->bindValue($key, $value, PDO::PARAM_STR);
    }
    $statement->bindValue(':limit', $pageSize, PDO::PARAM_INT);
    $statement->bindValue(':offset', ($page - 1) * $pageSize, PDO::PARAM_INT);
    $statement->execute();
    return [
        'cafes' => $statement->fetchAll(),
        'pagination' => ['page' => $page, 'pages' => $pages, 'total' => $total, 'page_size' => $pageSize],
    ];
}

function catalogue_all_cafes(PDO $pdo, array $filters, bool $demoMode): array
{
    $where = 'c.is_active = 1 AND a.is_active = 1';
    $params = [];
    if (!$demoMode) {
        $where .= ' AND c.is_demo = 0';
    }
    if ($filters['q'] !== '') {
        $where .= " AND c.name LIKE :q ESCAPE '!'";
        $params[':q'] = '%' . strtr($filters['q'], ['!' => '!!', '%' => '!%', '_' => '!_']) . '%';
    }
    if ($filters['area'] !== '') {
        $where .= ' AND a.slug = :area';
        $params[':area'] = $filters['area'];
    }
    if (!empty($filters['vibe']) && isset(VIBE_OPTIONS[$filters['vibe']])) {
        $where .= " AND c.vibe_tags LIKE :vibe ESCAPE '!'";
        $params[':vibe'] = '%' . strtr(VIBE_OPTIONS[$filters['vibe']]['search'], ['!' => '!!', '%' => '!%', '_' => '!_']) . '%';
    }

    $friendCountExpr = '0 AS friend_review_count';
    try {
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'friend_review'");
        if ($tableCheck && $tableCheck->rowCount() > 0) {
            $friendCountExpr = '(SELECT COUNT(*) FROM friend_review fr WHERE fr.cafe_id = c.id AND fr.is_verified_friend = 1) AS friend_review_count';
        }
    } catch (Throwable) {
        $friendCountExpr = '0 AS friend_review_count';
    }

    $statement = $pdo->prepare('SELECT c.id, c.name, c.latitude, c.longitude, c.address, c.price_band, c.photo_url, c.vibe_tags, c.food_highlights, c.summary, a.name AS area_name, a.city AS area_city, a.slug AS area_slug, '
        . $friendCountExpr . ' FROM cafe c JOIN area a ON c.area_id = a.id WHERE ' . $where . ' ORDER BY c.name ASC');
    $statement->execute($params);
    return $statement->fetchAll();
}

function catalogue_detail(PDO $pdo, string $id, bool $demoMode): array|false
{
    $statement = $pdo->prepare('SELECT c.*, a.name AS area_name, a.city AS area_city
        FROM cafe c JOIN area a ON c.area_id = a.id
        WHERE c.id = :id AND c.is_active = 1 AND a.is_active = 1'
        . ($demoMode ? '' : ' AND c.is_demo = 0'));
    $statement->execute([':id' => $id]);
    return $statement->fetch();
}

function catalogue_friend_reviews(PDO $pdo, string $id, ?string $circleId = null): array
{
    try {
        if ($circleId !== null && defined('DEFAULT_CIRCLE_ID') && $circleId !== DEFAULT_CIRCLE_ID) {
            $stmt = $pdo->prepare('SELECT * FROM friend_review 
                WHERE cafe_id = :id AND is_verified_friend = 1 
                  AND (circle_id = :circle_id OR circle_id = :default_id OR circle_id IS NULL)
                ORDER BY (circle_id = :active_id) DESC, visited_on DESC, created_at DESC');
            $stmt->execute([
                ':id' => $id,
                ':circle_id' => $circleId,
                ':default_id' => DEFAULT_CIRCLE_ID,
                ':active_id' => $circleId,
            ]);
        } else {
            $stmt = $pdo->prepare('SELECT * FROM friend_review 
                WHERE cafe_id = :id AND is_verified_friend = 1 
                ORDER BY visited_on DESC, created_at DESC');
            $stmt->execute([':id' => $id]);
        }
        return $stmt->fetchAll();
    } catch (Throwable) {
        return [];
    }
}
