<?php
declare(strict_types=1);

// Read-only, public-field allowlist. Never export circle notes or personal histories.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (in_array('--help', $argv, true)) {
    fwrite(STDOUT, "Usage: php php_app/scripts/export_catalogue.php > public-catalogue.json\nExports public café data, including explicit inactive flags, for Food RecSys synchronization.\n");
    exit(0);
}
require_once __DIR__ . '/../includes/db.php';

try {
    $db = db_connect();
    $cafes = $db->query('SELECT c.id, c.name, a.city, a.name AS area, c.address,
        c.latitude, c.longitude, c.price_band, c.photo_url, c.hero_image_url,
        c.website, c.vibe_tags, c.food_highlights, c.checked_on,
        (c.is_active AND a.is_active) AS is_active
        FROM cafe c JOIN area a ON a.id = c.area_id ORDER BY c.id')->fetchAll();
    $offerings = $db->query('SELECT cafe_id, drink_type, brewing_method, price,
        currency, checked_on, source FROM cafe_offering ORDER BY id')->fetchAll();
    $byCafe = [];
    foreach ($offerings as $offering) {
        $id = $offering['cafe_id'];
        unset($offering['cafe_id']);
        $offering['price'] = $offering['price'] === null ? null : (float)$offering['price'];
        $byCafe[$id][] = $offering;
    }
    foreach ($cafes as &$cafe) {
        $cafe['latitude'] = $cafe['latitude'] === null ? null : (float)$cafe['latitude'];
        $cafe['longitude'] = $cafe['longitude'] === null ? null : (float)$cafe['longitude'];
        $cafe['is_active'] = (bool)$cafe['is_active'];
        $cafe['source'] = 'cafe_app';
        foreach (['vibe_tags', 'food_highlights'] as $key) {
            $cafe[$key] = array_values(array_filter(array_map('trim', explode(',', $cafe[$key] ?? ''))));
        }
        $cafe['offerings'] = $byCafe[$cafe['id']] ?? [];
    }
    unset($cafe);
    fwrite(STDOUT, json_encode(['schema_version' => 1, 'restaurants' => $cafes],
        JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR) . "\n");
} catch (Throwable $error) {
    fwrite(STDERR, "Public catalogue export failed. Check database configuration and schema migrations.\n");
    exit(1);
}
