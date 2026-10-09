<?php
declare(strict_types=1);

function seed_demo_fixtures(): array
{
    $source = 'Synthetic development fixture; no real café or checked menu is represented.';
    $definitions = [
        ['b1833e2a-f772-50cc-8dfc-b08eb028fe04', 'Demo Paper Lantern Café', 'demo-paper-quarter', [['filter', 'Pour-over', 180], ['tea', '', 90]]],
        ['c7876dda-d0a2-58fb-9675-3bd6a21184bb', 'Demo Ink Cup Café', 'demo-paper-quarter', [['espresso', 'Espresso machine', 120], ['milk', '', 170]]],
        ['ddb9d09e-8e1e-5fdc-87d0-24de206a7da2', 'Demo Chapter Eight Café', 'demo-paper-quarter', [['milk', 'Espresso machine', 160], ['cold_brew', '', 190]]],
        ['1be94070-8833-5815-8876-f398ba078928', 'Demo Pencil Perch Café', 'demo-paper-quarter', [['tea', 'Steeped', 100], ['matcha', '', 220]]],
        ['aeabd403-b807-50c2-94a8-8ec8e16f6b70', 'Demo Cloud Kettle Café', 'demo-cloud-gardens', [['filter', 'Immersion', 150], ['espresso', '', 110]]],
        ['0e05e5ef-6158-5e80-a9e7-9f28dfae5f7c', 'Demo Rainbow Roast Café', 'demo-cloud-gardens', [['cold_brew', 'Cold steep', 200], ['milk', '', 180]]],
        ['7d3e7ccf-168c-5f30-a21f-8b914520c4b9', 'Demo Pocket Meadow Café', 'demo-cloud-gardens', [['matcha', 'Whisked', 240], ['tea', '', 120]]],
        ['2774ea7e-9968-5f29-b258-c62d4e5ed0ab', 'Demo Moon Saucer Café', 'demo-cloud-gardens', [['espresso', 'Espresso machine', 130], ['filter', '', 210]]],
    ];
    $cafes = [];
    foreach ($definitions as $index => [$id, $name, $slug, $offerings]) {
        $cafes[] = [
            'id' => $id, 'name' => $name, 'area_slug' => $slug,
            'address' => 'Fictional address ' . ($index + 1) . ', Fictional Demo City',
            'summary' => 'A fictional café for exploring the demonstration catalogue. It is not a real venue.',
            'checked_on' => null, 'source' => $source,
            'offerings' => array_map(static fn(array $item): array => [
                'drink_type' => $item[0], 'brewing_method' => $item[1], 'price' => $item[2],
                'currency' => 'INR', 'checked_on' => null, 'source' => $source,
            ], $offerings),
        ];
    }
    return [
        'areas' => [
            ['name' => 'Demo Paper Quarter', 'slug' => 'demo-paper-quarter', 'city' => 'Fictional Demo City', 'display_order' => 10],
            ['name' => 'Demo Cloud Gardens', 'slug' => 'demo-cloud-gardens', 'city' => 'Fictional Demo City', 'display_order' => 20],
        ],
        'cafes' => $cafes,
    ];
}

function seed_require_transactional_tables(PDO $pdo): void
{
    if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'mysql') {
        throw new RuntimeException('Demo seeding requires a PDO MySQL connection to MariaDB.');
    }
    $version = (string) $pdo->query('SELECT VERSION()')->fetchColumn();
    if (preg_match('/^(?:5\.5\.5-)?(\d+\.\d+\.\d+).*MariaDB/i', $version, $matches) !== 1
        || version_compare($matches[1], '10.11.0', '<')) {
        throw new RuntimeException('Demo seeding requires MariaDB 10.11 or newer.');
    }
    $checksEnabled = $pdo->query('SELECT @@SESSION.check_constraint_checks AS check_constraint_checks, @@SESSION.foreign_key_checks AS foreign_key_checks')->fetch(PDO::FETCH_ASSOC);
    if ((int) $checksEnabled['check_constraint_checks'] !== 1 || (int) $checksEnabled['foreign_key_checks'] !== 1) {
        throw new RuntimeException('Demo seeding requires session check_constraint_checks and foreign_key_checks to stay enabled.');
    }
    $engines = $pdo->query("SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('area', 'cafe', 'cafe_offering')")->fetchAll(PDO::FETCH_KEY_PAIR);
    foreach (['area', 'cafe', 'cafe_offering'] as $table) {
        if (!isset($engines[$table]) || strcasecmp((string) $engines[$table], 'InnoDB') !== 0) {
            throw new RuntimeException('Demo seeding requires all catalogue tables to exist and use InnoDB; run schema setup first.');
        }
    }
}

/** Existing cafés and their whole offering sets remain untouched, including curator edits. */
function seed_demo(PDO $pdo): array
{
    if ($pdo->inTransaction()) {
        throw new RuntimeException('Demo seeding must own its transaction.');
    }
    seed_require_transactional_tables($pdo);
    $fixtures = seed_demo_fixtures();
    $result = ['areas_inserted' => 0, 'cafes_inserted' => 0, 'offerings_inserted' => 0, 'cafes_existing' => 0];
    $pdo->beginTransaction();
    try {
        $findArea = $pdo->prepare('SELECT id, name, city FROM area WHERE slug = ? FOR UPDATE');
        $insertArea = $pdo->prepare('INSERT INTO area (name, slug, city, is_active, display_order) VALUES (?, ?, ?, 1, ?)');
        $areaIds = [];
        foreach ($fixtures['areas'] as $area) {
            $findArea->execute([$area['slug']]);
            $existing = $findArea->fetch();
            if ($existing === false) {
                $insertArea->execute([$area['name'], $area['slug'], $area['city'], $area['display_order']]);
                $id = $pdo->lastInsertId();
                ++$result['areas_inserted'];
            } else {
                if ($existing['name'] !== $area['name'] || $existing['city'] !== $area['city']) {
                    throw new RuntimeException('Reserved demo area slug contains other data: ' . $area['slug']);
                }
                $id = $existing['id'];
            }
            $areaIds[$area['slug']] = (int) $id;
        }
        $findCafe = $pdo->prepare('SELECT id, is_demo FROM cafe WHERE id = ? FOR UPDATE');
        $insertCafe = $pdo->prepare('INSERT INTO cafe (id, name, area_id, address, summary, is_active, is_demo, checked_on, source, independence_status) VALUES (?, ?, ?, ?, ?, 1, 1, ?, ?, ?)');
        $insertOffering = $pdo->prepare('INSERT INTO cafe_offering (cafe_id, drink_type, brewing_method, price, currency, checked_on, source) VALUES (?, ?, ?, ?, ?, ?, ?)');
        foreach ($fixtures['cafes'] as $cafe) {
            $findCafe->execute([$cafe['id']]);
            $existing = $findCafe->fetch();
            if ($existing !== false) {
                if ((int) $existing['is_demo'] !== 1) {
                    throw new RuntimeException('Reserved demo UUID contains a non-demo café: ' . $cafe['id']);
                }
                ++$result['cafes_existing'];
                continue;
            }
            $insertCafe->execute([$cafe['id'], $cafe['name'], $areaIds[$cafe['area_slug']], $cafe['address'], $cafe['summary'], $cafe['checked_on'], $cafe['source'], 'unknown']);
            ++$result['cafes_inserted'];
            foreach ($cafe['offerings'] as $offering) {
                $insertOffering->execute([$cafe['id'], $offering['drink_type'], $offering['brewing_method'], $offering['price'], $offering['currency'], $offering['checked_on'], $offering['source']]);
                ++$result['offerings_inserted'];
            }
        }
        $pdo->commit();
        return $result;
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) { $pdo->rollBack(); }
        throw $error;
    }
}
