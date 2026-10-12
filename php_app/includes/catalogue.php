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

function catalogue_extract_brand_name(string $fullName): string
{
    $clean = trim(preg_replace('/\s*\([^)]*\)\s*/', ' ', $fullName));
    return $clean !== '' ? $clean : $fullName;
}

function catalogue_group_cafes_by_brand(array $rawCafes): array
{
    $grouped = [];
    foreach ($rawCafes as $cafe) {
        $brandName = catalogue_extract_brand_name($cafe['name']);
        if (!isset($grouped[$brandName])) {
            $grouped[$brandName] = $cafe;
            $grouped[$brandName]['brand_name'] = $brandName;
            $grouped[$brandName]['branches'] = [];
            $grouped[$brandName]['branch_areas'] = [];
            $grouped[$brandName]['total_friend_reviews'] = 0;
        }

        $grouped[$brandName]['branches'][] = $cafe;
        $grouped[$brandName]['total_friend_reviews'] += (int) ($cafe['friend_review_count'] ?? 0);
        if (!empty($cafe['area_name']) && !in_array($cafe['area_name'], $grouped[$brandName]['branch_areas'], true)) {
            $grouped[$brandName]['branch_areas'][] = $cafe['area_name'];
        }
    }

    $result = [];
    foreach ($grouped as $brandItem) {
        $branchCount = count($brandItem['branches']);
        $brandItem['branch_count'] = $branchCount;
        $brandItem['friend_review_count'] = $brandItem['total_friend_reviews'];

        if ($branchCount > 1) {
            $brandItem['name'] = $brandItem['brand_name'];
            $brandItem['area_display'] = $branchCount . ' branches in Lucknow (' . implode(', ', array_slice($brandItem['branch_areas'], 0, 4)) . (count($brandItem['branch_areas']) > 4 ? '...' : '') . ')';
        } else {
            $brandItem['area_display'] = $brandItem['area_name'] . (!empty($brandItem['area_city']) ? ' · ' . $brandItem['area_city'] : '');
        }

        $result[] = $brandItem;
    }

    return $result;
}

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
        . $friendCountExpr . $from . ' ORDER BY c.name ASC, c.id ASC');
    $statement->execute($params);
    $rawCafes = $statement->fetchAll();

    $groupedCafes = catalogue_group_cafes_by_brand($rawCafes);
    $total = count($groupedCafes);
    $pageSize = 12;
    $pages = max(1, (int) ceil($total / $pageSize));
    $page = min(max(1, $filters['page']), $pages);

    $pageCafes = array_slice($groupedCafes, ($page - 1) * $pageSize, $pageSize);

    return [
        'cafes' => $pageCafes,
        'pagination' => ['page' => $page, 'pages' => $pages, 'total' => $total, 'page_size' => $pageSize],
    ];
}

function catalogue_get_branches_for_cafe(PDO $pdo, array $currentCafe, bool $demoMode): array
{
    $brandName = catalogue_extract_brand_name($currentCafe['name']);
    $sql = 'SELECT c.*, a.name AS area_name, a.city AS area_city
            FROM cafe c JOIN area a ON c.area_id = a.id
            WHERE c.is_active = 1 AND a.is_active = 1' . ($demoMode ? '' : ' AND c.is_demo = 0') . ' ORDER BY a.name, c.name';
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $all = $stmt->fetchAll();

    $branches = [];
    foreach ($all as $item) {
        if (catalogue_extract_brand_name($item['name']) === $brandName) {
            $branches[] = $item;
        }
    }
    return $branches;
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
