<?php
declare(strict_types=1);

/** DDL implicitly commits in MariaDB; this is an additive, non-atomic setup. */
function schema_apply(PDO $pdo): void
{
    if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'mysql' || $pdo->inTransaction()) {
        throw new RuntimeException('Schema setup requires a PDO MySQL connection to MariaDB outside a transaction.');
    }
    $version = (string) $pdo->query('SELECT VERSION()')->fetchColumn();
    if (preg_match('/^(?:5\.5\.5-)?(\d+\.\d+\.\d+).*MariaDB/i', $version, $matches) !== 1
        || version_compare($matches[1], '10.11.0', '<')) {
        throw new RuntimeException('Schema setup requires MariaDB 10.11 or newer.');
    }
    $checksEnabled = $pdo->query('SELECT @@SESSION.check_constraint_checks AS check_constraint_checks, @@SESSION.foreign_key_checks AS foreign_key_checks')->fetch(PDO::FETCH_ASSOC);
    if ((int) $checksEnabled['check_constraint_checks'] !== 1 || (int) $checksEnabled['foreign_key_checks'] !== 1) {
        throw new RuntimeException('Schema setup requires session check_constraint_checks and foreign_key_checks to stay enabled.');
    }
    $sql = file_get_contents(__DIR__ . '/../schema/schema.sql');
    if ($sql === false) { throw new RuntimeException('Cannot read the schema file.'); }
    $sql = (string) preg_replace('/^\s*--.*$/m', '', $sql);
    foreach (explode(';', $sql) as $statement) {
        if (trim($statement) !== '') { $pdo->exec($statement); }
    }
    $engines = $pdo->query("SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('area', 'cafe', 'cafe_offering')")->fetchAll(PDO::FETCH_KEY_PAIR);
    $required = [
        'area' => ['id', 'name', 'slug', 'city', 'is_active', 'display_order'],
        'cafe' => ['id', 'name', 'area_id', 'address', 'summary', 'latitude', 'longitude', 'website', 'photo_url', 'hero_image_url', 'is_active', 'is_demo', 'checked_on', 'source', 'brand_location_count', 'brand_count_scope', 'brand_count_source', 'brand_count_checked_on', 'independence_status', 'independence_source', 'independence_checked_on'],
        'cafe_offering' => ['id', 'cafe_id', 'drink_type', 'brewing_method', 'price', 'currency', 'checked_on', 'source'],
    ];
    $columns = $pdo->prepare('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?');
    foreach ($required as $table => $expected) {
        if (!isset($engines[$table]) || strcasecmp((string) $engines[$table], 'InnoDB') !== 0) {
            throw new RuntimeException("Schema setup requires InnoDB for {$table}; back up and review its engine conversion manually.");
        }
        $columns->execute([$table]);
        if (array_diff($expected, $columns->fetchAll(PDO::FETCH_COLUMN)) !== []) {
            throw new RuntimeException("Existing {$table} columns differ from the reviewed PHP schema; manual migration is required.");
        }
    }
    $checks = [
        'area' => ['chk_area_active' => 'is_active IN (0, 1)'],
        'cafe' => [
            'chk_cafe_active' => 'is_active IN (0, 1)',
            'chk_cafe_demo' => 'is_demo IN (0, 1)',
            'chk_cafe_uuid' => "id REGEXP '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'",
            'chk_cafe_coordinate_pair' => '(latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL)',
            'chk_cafe_latitude' => 'latitude IS NULL OR latitude BETWEEN -90 AND 90',
            'chk_cafe_longitude' => 'longitude IS NULL OR longitude BETWEEN -180 AND 180',
            'chk_cafe_brand_count' => 'brand_location_count IS NULL OR brand_location_count >= 1',
            'chk_cafe_independence' => "independence_status IN ('unknown', 'verified_independent', 'verified_not_independent')",
        ],
        'cafe_offering' => [
            'chk_offering_price' => 'price IS NULL OR price >= 0',
            'chk_offering_drink' => "drink_type IN ('espresso', 'filter', 'milk', 'cold_brew', 'tea', 'matcha')",
            'chk_offering_currency' => "currency REGEXP '^[A-Za-z]{3}$'",
        ],
    ];
    $findCheck = $pdo->prepare('SELECT COUNT(*) FROM information_schema.CHECK_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=? AND CONSTRAINT_NAME=?');
    foreach ($checks as $table => $constraints) {
        foreach ($constraints as $name => $expression) {
            $findCheck->execute([$table, $name]);
            if ((int) $findCheck->fetchColumn() === 0) {
                $pdo->exec("ALTER TABLE {$table} ADD CONSTRAINT {$name} CHECK ({$expression})");
            }
        }
    }
    $indexes = [
        'area' => ['idx_area_public' => '(is_active, display_order, name, id)'],
        'cafe' => ['idx_cafe_public' => '(is_active, name, id)', 'idx_cafe_area_public' => '(area_id, is_active, name, id)'],
        'cafe_offering' => ['idx_offering_cafe' => '(cafe_id, drink_type, brewing_method, id)'],
    ];
    $findIndex = $pdo->prepare('SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=? AND INDEX_NAME=?');
    foreach ($indexes as $table => $definitions) {
        foreach ($definitions as $name => $definition) {
            $findIndex->execute([$table, $name]);
            if ((int) $findIndex->fetchColumn() === 0) {
                $pdo->exec("ALTER TABLE {$table} ADD INDEX {$name} {$definition}");
            }
        }
    }
    $findForeignKey = $pdo->prepare("SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE k JOIN information_schema.REFERENTIAL_CONSTRAINTS r ON r.CONSTRAINT_SCHEMA=k.CONSTRAINT_SCHEMA AND r.TABLE_NAME=k.TABLE_NAME AND r.CONSTRAINT_NAME=k.CONSTRAINT_NAME WHERE k.CONSTRAINT_SCHEMA=DATABASE() AND k.TABLE_NAME=? AND k.COLUMN_NAME=? AND k.REFERENCED_TABLE_NAME=? AND k.REFERENCED_COLUMN_NAME='id' AND r.DELETE_RULE=?");
    foreach ([['cafe', 'area_id', 'area', 'RESTRICT', 'fk_cafe_area'], ['cafe_offering', 'cafe_id', 'cafe', 'CASCADE', 'fk_offering_cafe']] as [$table, $column, $target, $delete, $name]) {
        $findForeignKey->execute([$table, $column, $target, $delete]);
        if ((int) $findForeignKey->fetchColumn() === 0) {
            $pdo->exec("ALTER TABLE {$table} ADD CONSTRAINT {$name} FOREIGN KEY ({$column}) REFERENCES {$target}(id) ON DELETE {$delete}");
        }
    }
}
