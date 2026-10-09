<?php
declare(strict_types=1);

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
    $from = ' FROM cafe c JOIN area a ON c.area_id = a.id WHERE ' . $where;
    $count = $pdo->prepare('SELECT COUNT(*)' . $from);
    $count->execute($params);
    $total = (int) $count->fetchColumn();
    $pageSize = 12;
    $pages = max(1, (int) ceil($total / $pageSize));
    $page = min(max(1, $filters['page']), $pages);
    $statement = $pdo->prepare('SELECT c.*, a.name AS area_name, a.city AS area_city'
        . $from . ' ORDER BY c.name ASC, c.id ASC LIMIT :limit OFFSET :offset');
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

function catalogue_detail(PDO $pdo, string $id, bool $demoMode): array|false
{
    $statement = $pdo->prepare('SELECT c.*, a.name AS area_name, a.city AS area_city
        FROM cafe c JOIN area a ON c.area_id = a.id
        WHERE c.id = :id AND c.is_active = 1 AND a.is_active = 1'
        . ($demoMode ? '' : ' AND c.is_demo = 0'));
    $statement->execute([':id' => $id]);
    return $statement->fetch();
}
