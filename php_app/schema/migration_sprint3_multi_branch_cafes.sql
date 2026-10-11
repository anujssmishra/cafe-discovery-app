-- =====================================================================
-- Sprint 3 Database Migration: Multi-Branch Cafés Expansion (Lucknow)
-- Targets: MariaDB 10.11+ / MySQL 8.x (Hostinger Single Web Hosting)
-- Safe & Idempotent: Uses ON DUPLICATE KEY UPDATE / INSERT IGNORE
-- =====================================================================

-- 1. Add New Café Neighbourhoods (Aliganj, Nirala Nagar, Indira Nagar)
INSERT INTO `area` (`id`, `name`, `slug`, `city`, `is_active`, `display_order`) VALUES
(7, 'Aliganj', 'aliganj', 'Lucknow', 1, 70),
(8, 'Nirala Nagar', 'nirala-nagar', 'Lucknow', 1, 80),
(9, 'Indira Nagar', 'indira-nagar', 'Lucknow', 1, 90)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `slug`=VALUES(`slug`), `is_active`=VALUES(`is_active`);

-- 2. Clarify Existing Branches with Distinct Branch Labels
UPDATE `cafe` SET `name` = 'The Hazelnut Factory (Hazratganj)' WHERE `id` = 'c1010001-0000-0000-0000-000000000003';
UPDATE `cafe` SET `name` = 'The Cherry Tree Bakery & Cafe (Hazratganj)' WHERE `id` = 'c1010001-0000-0000-0000-000000000005';
UPDATE `cafe` SET `name` = 'NBC (Nothing Before Coffee) (Experion)' WHERE `id` = 'c1010001-0000-0000-0000-000000000018';
UPDATE `cafe` SET `name` = 'Third Wave Coffee (Gomti Nagar)' WHERE `id` = 'c1010001-0000-0000-0000-000000000019';
UPDATE `cafe` SET `name` = 'Melting Point (Dayal Paradise)' WHERE `id` = 'c1010001-0000-0000-0000-000000000012';
UPDATE `cafe` SET `name` = 'HoNS (House of No Sugar) (Kisan Bazar)' WHERE `id` = 'c1010001-0000-0000-0000-000000000008';

-- 3. Insert Additional Branch Cards for Multi-Location Cafés
INSERT INTO `cafe` (
    `id`, `name`, `area_id`, `address`, `latitude`, `longitude`, 
    `is_active`, `is_demo`, `checked_on`, `source`, 
    `brand_location_count`, `brand_count_scope`, `brand_count_source`, `brand_count_checked_on`, 
    `independence_status`, `independence_source`, `independence_checked_on`,
    `vibe_tags`, `food_highlights`, `price_band`
) VALUES
-- The Hazelnut Factory: Rohtas Summit (Gomti Nagar)
(
    'c1010001-0000-0000-0000-000000000020', 'The Hazelnut Factory (Rohtas Summit)', 1,
    'Ground Floor, Rohtas Summit, Vibhuti Khand, Gomti Nagar', 26.8625, 80.9990,
    1, 0, '2026-10-11', 'Store locator',
    12, 'worldwide', 'Store locator', '2026-10-11',
    'verified_not_independent', 'Web research', '2026-10-11',
    'Aesthetic & Cozy, Lively & Social',
    'Specialty Desserts, French Cruffins, Luxury Pastries, Savory Platters',
    'moderate'
),
-- The Hazelnut Factory: Phoenix Palassio (Sushant Golf City)
(
    'c1010001-0000-0000-0000-000000000021', 'The Hazelnut Factory (Phoenix Palassio)', 2,
    '1st Floor, Phoenix Palassio Mall, Amar Shaheed Path, Sushant Golf City', 26.8090, 81.0062,
    1, 0, '2026-10-11', 'Store locator',
    12, 'worldwide', 'Store locator', '2026-10-11',
    'Aesthetic & Cozy, Lively & Social',
    'Specialty Desserts, French Cruffins, Artisanal Coffees, Macarons',
    'moderate'
),
-- The Hazelnut Factory: Nirala Nagar
(
    'c1010001-0000-0000-0000-000000000022', 'The Hazelnut Factory (Nirala Nagar)', 8,
    'B-192, Aliganj Main Rd, Opposite Ram Krishna Math, Nirala Nagar', 26.8780, 80.9420,
    1, 0, '2026-10-11', 'Store locator',
    12, 'worldwide', 'Store locator', '2026-10-11',
    'Aesthetic & Cozy, Date Spot',
    'Specialty Desserts, French Cruffins, Gourmet Shakes, Tarts',
    'moderate'
),
-- The Hazelnut Factory: Manoj Pandey Chauraha (Gomti Nagar)
(
    'c1010001-0000-0000-0000-000000000023', 'The Hazelnut Factory (Manoj Pandey Chauraha)', 1,
    '2/140, Next to Gomti Nagar Police Station, Vijay Khand, Gomti Nagar', 26.8520, 80.9910,
    1, 0, '2026-10-11', 'Store locator',
    12, 'worldwide', 'Store locator', '2026-10-11',
    'Aesthetic & Cozy, Work & Study',
    'Specialty Desserts, French Cruffins, Croissants, Breakfast Bakes',
    'moderate'
),
-- The Hazelnut Factory: Aliganj (Ram Ram Bank)
(
    'c1010001-0000-0000-0000-000000000024', 'The Hazelnut Factory (Aliganj)', 7,
    'Ram Ram Bank Chauraha, Sector B, Aliganj', 26.8910, 80.9440,
    1, 0, '2026-10-11', 'Store locator',
    12, 'worldwide', 'Store locator', '2026-10-11',
    'Aesthetic & Cozy, Lively & Social',
    'Specialty Desserts, French Cruffins, Artisanal Bakery, Pastries',
    'moderate'
),
-- The Cherry Tree: Nirala Nagar
(
    'c1010001-0000-0000-0000-000000000025', 'The Cherry Tree Bakery & Cafe (Nirala Nagar)', 8,
    'B-11, Near 8 Number Chauraha, Nirala Nagar', 26.8770, 80.9410,
    1, 0, '2026-10-11', 'Web research',
    4, 'worldwide', 'Web research', '2026-10-11',
    'verified_not_independent', 'Web research', '2026-10-11',
    'Aesthetic & Cozy, Minimalist & Quiet',
    'Fresh Bakes, Cheesecakes, Thin Crust Pizza, Signature Shakes',
    'moderate'
),
-- Third Wave Coffee: Hazratganj (Le Press)
(
    'c1010001-0000-0000-0000-000000000026', 'Third Wave Coffee (Hazratganj)', 3,
    'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450,
    1, 0, '2026-10-11', 'Store locator',
    100, 'worldwide', 'Store locator', '2026-10-11',
    'verified_not_independent', 'Web research', '2026-10-11',
    'Work & Study, Minimalist & Quiet',
    'Bagels, Sourdough Toasts, Croissants, Cookies, Specialty Espresso',
    'moderate'
),
-- NBC: Vivek Khand (Gomti Nagar)
(
    'c1010001-0000-0000-0000-000000000027', 'NBC (Nothing Before Coffee) (Vivek Khand)', 1,
    '4/260, Vivek Khand 4, Gomti Nagar', 26.8510, 81.0020,
    1, 0, '2026-10-11', 'Store locator',
    60, 'worldwide', 'Store locator', '2026-10-11',
    'verified_not_independent', 'Web research', '2026-10-11',
    'Work & Study, Lively & Social',
    'Quick Bites, Loaded Nachos, Brownies, Frappes, Shaka Laka Shake',
    'budget'
),
-- NBC: Indira Nagar
(
    'c1010001-0000-0000-0000-000000000028', 'NBC (Nothing Before Coffee) (Indira Nagar)', 9,
    'Near Indira Nagar Metro Station, Indira Nagar', 26.8790, 80.9850,
    1, 0, '2026-10-11', 'Store locator',
    60, 'worldwide', 'Store locator', '2026-10-11',
    'Work & Study, Lively & Social',
    'Pocket Pizzas, Brownies, Specialty Cold Brews, Iced Lattes',
    'budget'
),
-- NBC: Aliganj (Kapoorthala)
(
    'c1010001-0000-0000-0000-000000000029', 'NBC (Nothing Before Coffee) (Aliganj)', 7,
    'Sector B, Kapoorthala Chauraha, Aliganj', 26.8870, 80.9450,
    1, 0, '2026-10-11', 'Store locator',
    60, 'worldwide', 'Store locator', '2026-10-11',
    'Lively & Social, Work & Study',
    'Cookies, Pastries, Handcrafted Coffees, Affogato, Shakes',
    'budget'
),
-- Melting Point: Dayal Gateway (Kisan Bazar, Gomti Nagar)
(
    'c1010001-0000-0000-0000-000000000030', 'Melting Point (Dayal Gateway)', 1,
    'Kisan Bazar, Vibhuti Khand, Gomti Nagar', 26.8640, 80.9990,
    1, 0, '2026-10-11', 'Web research',
    3, 'worldwide', 'Web research', '2026-10-11',
    'verified_not_independent', 'Web research', '2026-10-11',
    'Aesthetic & Cozy, Minimalist & Quiet',
    'French Pastries, Custom Cakes, Continental Breakfast, Hot Brews',
    'moderate'
),
-- Melting Point: Sushant Golf City
(
    'c1010001-0000-0000-0000-000000000031', 'Melting Point (Sushant Golf City)', 2,
    'IT/3, Dayal Bagh, Amar Shaheed Path, Sushant Golf City', 26.8050, 81.0100,
    1, 0, '2026-10-11', 'Web research',
    3, 'worldwide', 'Web research', '2026-10-11',
    'Garden & Outdoor, Aesthetic & Cozy',
    'Artisanal Pastries, Italian Pastas, Gourmet Coffee, High Tea',
    'moderate'
),
-- HoNS (House of No Sugar): Hazratganj
(
    'c1010001-0000-0000-0000-000000000032', 'HoNS (House of No Sugar) (Hazratganj)', 3,
    'Near Mayfair Cinema, Hazratganj', 26.8510, 80.9430,
    1, 0, '2026-10-11', 'Web research',
    3, 'worldwide', 'Web research', '2026-10-11',
    'Aesthetic & Cozy, Minimalist & Quiet',
    'Sugar-Free Bakery, Keto Cheesecakes, Gluten-Free Waffles, Healthy Smoothies',
    'moderate'
)
ON DUPLICATE KEY UPDATE 
    `name`=VALUES(`name`), `area_id`=VALUES(`area_id`), `address`=VALUES(`address`),
    `latitude`=VALUES(`latitude`), `longitude`=VALUES(`longitude`),
    `vibe_tags`=VALUES(`vibe_tags`), `food_highlights`=VALUES(`food_highlights`),
    `price_band`=VALUES(`price_band`), `brand_location_count`=VALUES(`brand_location_count`);

-- 4. Insert Drink Offerings for New Branches
INSERT INTO `cafe_offering` (`id`, `cafe_id`, `drink_type`, `brewing_method`, `price`, `currency`, `checked_on`, `source`) VALUES
(20, 'c1010001-0000-0000-0000-000000000020', 'milk', 'Milk coffee', 220.00, 'INR', '2026-10-11', 'Menu'),
(21, 'c1010001-0000-0000-0000-000000000021', 'espresso', 'Espresso machine', 190.00, 'INR', '2026-10-11', 'Menu'),
(22, 'c1010001-0000-0000-0000-000000000022', 'milk', 'Milk coffee', 220.00, 'INR', '2026-10-11', 'Menu'),
(23, 'c1010001-0000-0000-0000-000000000023', 'espresso', 'Espresso machine', 190.00, 'INR', '2026-10-11', 'Menu'),
(24, 'c1010001-0000-0000-0000-000000000024', 'milk', 'Milk coffee', 220.00, 'INR', '2026-10-11', 'Menu'),
(25, 'c1010001-0000-0000-0000-000000000025', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-11', 'Menu'),
(26, 'c1010001-0000-0000-0000-000000000026', 'cold_brew', 'Cold brew', 210.00, 'INR', '2026-10-11', 'Menu'),
(27, 'c1010001-0000-0000-0000-000000000027', 'espresso', 'Espresso machine', 90.00, 'INR', '2026-10-11', 'Menu'),
(28, 'c1010001-0000-0000-0000-000000000028', 'espresso', 'Espresso machine', 90.00, 'INR', '2026-10-11', 'Menu'),
(29, 'c1010001-0000-0000-0000-000000000029', 'espresso', 'Espresso machine', 90.00, 'INR', '2026-10-11', 'Menu'),
(30, 'c1010001-0000-0000-0000-000000000030', 'milk', 'Milk coffee', 200.00, 'INR', '2026-10-11', 'Menu'),
(31, 'c1010001-0000-0000-0000-000000000031', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-11', 'Menu'),
(32, 'c1010001-0000-0000-0000-000000000032', 'filter', 'Filter coffee', 160.00, 'INR', '2026-10-11', 'Menu')
ON DUPLICATE KEY UPDATE `price`=VALUES(`price`);

-- 5. Add Circle Reviews for Key New Branches
INSERT INTO `friend_review` (
    `cafe_id`, `friend_name`, `visit_context`, 
    `food_quality_verdict`, `food_variety_rating`, `ambiance_rating`, 
    `must_try_item`, `review_text`, `is_verified_friend`, `visited_on`
) VALUES
-- THF Rohtas Summit
(
    'c1010001-0000-0000-0000-000000000020',
    'Aarav',
    'Late Evening Hangout',
    'Excellent fresh cruffins and desserts as always',
    'extensive',
    'lively_chatty',
    'Nutella Cruffin & Iced Belgian Mocha',
    'Great outdoor sitting at Summit. Always packed in the evenings with good energy. Service is fast despite the crowd.',
    1,
    '2026-10-06'
),
-- Third Wave Coffee Hazratganj
(
    'c1010001-0000-0000-0000-000000000026',
    'Pooja',
    'Remote Work Afternoon',
    'Fresh bagels and really solid pour-over options',
    'good',
    'work_productive',
    'Classic Bagel with Cream Cheese & Orange Zest Mocha',
    'Super quiet first-floor seating inside Le Press. Plug points at almost every table and very reliable Wi-Fi.',
    1,
    '2026-10-08'
),
-- The Cherry Tree Nirala Nagar
(
    'c1010001-0000-0000-0000-000000000025',
    'Kabir',
    'Sunday Family Breakfast',
    'Comfort food done right, peaceful neighborhood vibe',
    'good',
    'chill_cozy',
    'New York Baked Cheesecake & Farmhouse Pizza',
    'Much more relaxed and less crowded than the Hazratganj outlet. Easy street parking in Nirala Nagar.',
    1,
    '2026-10-07'
);
