<?php
// php_app/scripts/seed.php

require_once __DIR__ . '/../includes/db.php';

echo "Seeding database...\n";

// Helper to generate v4 UUID
function uuid4() {
    $data = random_bytes(16);
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

// 1. Seed Areas
$areas = [
    ['slug' => 'gomti-nagar', 'name' => 'Gomti Nagar', 'city' => 'Lucknow', 'display_order' => 10],
    ['slug' => 'sushant-golf-city', 'name' => 'Sushant Golf City', 'city' => 'Lucknow', 'display_order' => 20],
    ['slug' => 'hazratganj', 'name' => 'Hazratganj', 'city' => 'Lucknow', 'display_order' => 30],
    ['slug' => 'mall-avenue', 'name' => 'Mall Avenue', 'city' => 'Lucknow', 'display_order' => 40],
    ['slug' => 'badshahnagar', 'name' => 'Badshahnagar', 'city' => 'Lucknow', 'display_order' => 50],
    ['slug' => 'cantonment', 'name' => 'Cantonment', 'city' => 'Lucknow', 'display_order' => 60],
];

$areaIdMap = [];
$areaStmt = $pdo->prepare("INSERT INTO area (name, slug, city, display_order) VALUES (:name, :slug, :city, :display_order) ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)");
foreach ($areas as $area) {
    $areaStmt->execute([
        ':name' => $area['name'],
        ':slug' => $area['slug'],
        ':city' => $area['city'],
        ':display_order' => $area['display_order']
    ]);
    
    // Fetch the ID to use for the cafes
    $stmt = $pdo->prepare("SELECT id FROM area WHERE slug = :slug");
    $stmt->execute([':slug' => $area['slug']]);
    $areaIdMap[$area['slug']] = $stmt->fetchColumn();
}

// 2. Seed Cafes
$cafes = [
    ['name' => 'Roastery Coffee House', 'area' => 'gomti-nagar', 'address' => 'Plot No. 4, Ground Floor, Vibhuti Khand, Gomti Nagar', 'lat' => 26.8640, 'lon' => 80.9995, 'indep' => false, 'count' => 18, 'drink' => 'espresso', 'price' => 195],
    ['name' => 'Overflow Coffee', 'area' => 'sushant-golf-city', 'address' => 'G-14, Ground Floor, Phoenix Palassio Mall, Amar Shaheed Path, Sushant Golf City', 'lat' => 26.8090, 'lon' => 81.0062, 'indep' => true, 'count' => 1, 'drink' => 'filter', 'price' => 180],
    ['name' => 'The Hazelnut Factory', 'area' => 'hazratganj', 'address' => 'Raza Plaza, Near Sahu Cinema, Hazratganj', 'lat' => 26.8505, 'lon' => 80.9427, 'indep' => false, 'count' => 12, 'drink' => 'milk', 'price' => 220],
    ['name' => 'The Fresh Factory', 'area' => 'gomti-nagar', 'address' => 'Shop 31, First Floor, DLF MyPad, Vibhuti Khand, Gomti Nagar', 'lat' => 26.8643, 'lon' => 81.0001, 'indep' => true, 'count' => 1, 'drink' => 'cold_brew', 'price' => 200],
    ['name' => 'The Cherry Tree Bakery & Cafe', 'area' => 'hazratganj', 'address' => '11, Habibullah Estate, Hazratganj', 'lat' => 26.8520, 'lon' => 80.9445, 'indep' => false, 'count' => 4, 'drink' => 'espresso', 'price' => 180],
    ['name' => 'Chacoco Cafe', 'area' => 'gomti-nagar', 'address' => '4/14, Vishal Khand 4, Gomti Nagar', 'lat' => 26.8540, 'lon' => 80.9850, 'indep' => true, 'count' => 1, 'drink' => 'milk', 'price' => 150],
    ['name' => 'Let\'s Bake Stories', 'area' => 'mall-avenue', 'address' => 'Rudraksh Complex, 17/17A Havelock Road, Near Mall Avenue', 'lat' => 26.8373, 'lon' => 80.9472, 'indep' => true, 'count' => 1, 'drink' => 'espresso', 'price' => 180],
    ['name' => 'HoNS (House of No Sugar)', 'area' => 'gomti-nagar', 'address' => 'Shop A-9, Kisan Bazar, Vibhuti Khand, Gomti Nagar', 'lat' => 26.8530, 'lon' => 80.9985, 'indep' => false, 'count' => 3, 'drink' => 'filter', 'price' => 160],
    ['name' => 'Cappuccino Blast', 'area' => 'hazratganj', 'address' => '12 Mall Avenue Rd, The Mall Avenue, Hazratganj', 'lat' => 26.8376, 'lon' => 80.9469, 'indep' => true, 'count' => 1, 'drink' => 'espresso', 'price' => 150],
    ['name' => 'Mocha Cafe & Bar', 'area' => 'gomti-nagar', 'address' => 'CP-1, 2nd Floor, Anand Plaza, Viram Khand 1, Gomti Nagar', 'lat' => 26.8488, 'lon' => 80.9997, 'indep' => false, 'count' => 25, 'drink' => 'espresso', 'price' => 175],
    ['name' => 'Sidewalk Bakehouse & Cafe', 'area' => 'gomti-nagar', 'address' => '4/492, Vivek Khand 2, Near Patrakarpuram, Gomti Nagar', 'lat' => 26.8450, 'lon' => 81.0100, 'indep' => false, 'count' => 4, 'drink' => 'espresso', 'price' => 200],
    ['name' => 'Melting Point', 'area' => 'gomti-nagar', 'address' => 'Hotel Dayal Paradise, Vipul Khand 5, Gomti Nagar', 'lat' => 26.8458, 'lon' => 80.9998, 'indep' => false, 'count' => 3, 'drink' => 'milk', 'price' => 200],
    ['name' => 'Sassy Canteen', 'area' => 'badshahnagar', 'address' => 'Sapphire Building, Metro City Centre, Badshahnagar', 'lat' => 26.8700, 'lon' => 80.9600, 'indep' => true, 'count' => 1, 'drink' => 'espresso', 'price' => 180],
    ['name' => 'Chihiro', 'area' => 'cantonment', 'address' => '3, MG Marg, Sadar Bazaar, Cantonment', 'lat' => 26.8170, 'lon' => 80.9400, 'indep' => true, 'count' => 1, 'drink' => 'matcha', 'price' => 190],
    ['name' => 'Talllk', 'area' => 'gomti-nagar', 'address' => 'Shop 26, B-1, DLF MyPad, Vibhuti Khand, Gomti Nagar', 'lat' => 26.8639, 'lon' => 80.9999, 'indep' => true, 'count' => 1, 'drink' => 'espresso', 'price' => 160],
    ['name' => 'The Comma', 'area' => 'hazratganj', 'address' => 'Le Press, 29 Nawal Kishore Road, Hazratganj', 'lat' => 26.8530, 'lon' => 80.9450, 'indep' => true, 'count' => 1, 'drink' => 'cold_brew', 'price' => 200],
    ['name' => 'Criolo', 'area' => 'hazratganj', 'address' => 'Le Press, 29 Nawal Kishore Road, Hazratganj', 'lat' => 26.8530, 'lon' => 80.9450, 'indep' => false, 'count' => 5, 'drink' => 'espresso', 'price' => 150],
    ['name' => 'NBC (Nothing Before Coffee)', 'area' => 'gomti-nagar', 'address' => 'Shop 4, Experio at Experion Capital, Vibhuti Khand, Gomti Nagar', 'lat' => 26.8650, 'lon' => 81.0020, 'indep' => false, 'count' => 60, 'drink' => 'espresso', 'price' => 90],
    ['name' => 'TWC (The White Cafe)', 'area' => 'gomti-nagar', 'address' => 'Vivek Khand, Gomti Nagar', 'lat' => 26.8515, 'lon' => 80.9980, 'indep' => true, 'count' => 1, 'drink' => 'espresso', 'price' => 180],
];

$today = date('Y-m-d');
$cafeStmt = $pdo->prepare("
    INSERT INTO cafe (id, name, area_id, address, latitude, longitude, is_demo, independence_status, brand_location_count, source, checked_on, independence_source, independence_checked_on, brand_count_source, brand_count_checked_on)
    VALUES (:id, :name, :area_id, :address, :lat, :lon, 0, :status, :count, 'Web research', :checked, 'Web research', :checked, 'Web research', :checked)
");

$offeringStmt = $pdo->prepare("
    INSERT INTO cafe_offering (cafe_id, drink_type, price, currency, source, checked_on)
    VALUES (:cafe_id, :drink, :price, 'INR', 'Menu', :checked)
");

// Clear existing to avoid duplicates in a seed run (if you want fresh)
$pdo->exec("DELETE FROM cafe_offering");
$pdo->exec("DELETE FROM cafe");

$count = 0;
foreach ($cafes as $c) {
    $cafeId = uuid4();
    $status = $c['indep'] ? 'verified_independent' : 'verified_not_independent';
    $areaId = $areaIdMap[$c['area']];

    $cafeStmt->execute([
        ':id' => $cafeId,
        ':name' => $c['name'],
        ':area_id' => $areaId,
        ':address' => $c['address'],
        ':lat' => $c['lat'],
        ':lon' => $c['lon'],
        ':status' => $status,
        ':count' => $c['count'],
        ':checked' => $today
    ]);

    $offeringStmt->execute([
        ':cafe_id' => $cafeId,
        ':drink' => $c['drink'],
        ':price' => $c['price'],
        ':checked' => $today
    ]);
    
    $count++;
}

echo "Successfully seeded $count Lucknow cafes!\n";
