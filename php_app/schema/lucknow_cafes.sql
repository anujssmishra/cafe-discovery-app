-- Lucknow Pilot Data Seed (All 32 Cafes across Lucknow Neighbourhoods)
-- Areas
INSERT INTO `area` (`id`, `name`, `slug`, `city`, `is_active`, `display_order`) VALUES
(1, 'Gomti Nagar', 'gomti-nagar', 'Lucknow', 1, 10),
(2, 'Sushant Golf City', 'sushant-golf-city', 'Lucknow', 1, 20),
(3, 'Hazratganj', 'hazratganj', 'Lucknow', 1, 30),
(4, 'Mall Avenue', 'mall-avenue', 'Lucknow', 1, 40),
(5, 'Badshahnagar', 'badshahnagar', 'Lucknow', 1, 50),
(6, 'Cantonment', 'cantonment', 'Lucknow', 1, 60),
(7, 'Aliganj', 'aliganj', 'Lucknow', 1, 70),
(8, 'Nirala Nagar', 'nirala-nagar', 'Lucknow', 1, 80),
(9, 'Indira Nagar', 'indira-nagar', 'Lucknow', 1, 90)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `slug`=VALUES(`slug`), `is_active`=VALUES(`is_active`);

-- Cafes (Single spots + all branches)
INSERT INTO `cafe` (`id`, `name`, `area_id`, `address`, `latitude`, `longitude`, `is_active`, `is_demo`, `checked_on`, `source`, `brand_location_count`, `brand_count_scope`, `brand_count_source`, `brand_count_checked_on`, `independence_status`, `independence_source`, `independence_checked_on`, `vibe_tags`, `food_highlights`, `price_band`) VALUES
('c1010001-0000-0000-0000-000000000001', 'Roastery Coffee House', 1, 'Plot No. 4, Ground Floor, Vibhuti Khand, Gomti Nagar', 26.8640, 80.9995, 1, 0, '2026-10-09', 'Web research', 18, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Garden & Outdoor, Date Spot, Lively & Social', 'All-Day Breakfast, Cheesecakes, Gourmet Burgers', 'premium'),
('c1010001-0000-0000-0000-000000000002', 'Overflow Coffee', 2, 'G-14, Ground Floor, Phoenix Palassio Mall, Amar Shaheed Path, Sushant Golf City', 26.8090, 81.0062, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Work & Study, Minimalist & Quiet', 'Artisan Sourdough, Cinnamon Rolls, Specialty Sandwiches', 'moderate'),
('c1010001-0000-0000-0000-000000000003', 'The Hazelnut Factory (Hazratganj)', 3, 'Raza Plaza, Near Sahu Cinema, Hazratganj', 26.8505, 80.9427, 1, 0, '2026-10-09', 'Web research', 12, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Lively & Social', 'Specialty Desserts, French Cruffins, Luxury Pastries', 'moderate'),
('c1010001-0000-0000-0000-000000000004', 'The Fresh Factory', 1, 'Shop 31, First Floor, DLF MyPad, Vibhuti Khand, Gomti Nagar', 26.8643, 81.0001, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Work & Study, Aesthetic & Cozy', 'Healthy Bowls, Avocado Toast, Vegan Options', 'moderate'),
('c1010001-0000-0000-0000-000000000005', 'The Cherry Tree Bakery & Cafe (Hazratganj)', 3, '11, Habibullah Estate, Hazratganj', 26.8520, 80.9445, 1, 0, '2026-10-09', 'Web research', 4, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Date Spot, Lively & Social', 'Artisan Bakery, Fresh Sourdough, Custom Desserts', 'moderate'),
('c1010001-0000-0000-0000-000000000006', 'Chacoco Cafe', 1, '4/14, Vishal Khand 4, Gomti Nagar', 26.8540, 80.9850, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Minimalist & Quiet', 'Single-Origin Hot Chocolates, Artisan Truffles, Croissants', 'budget'),
('c1010001-0000-0000-0000-000000000007', 'Let''s Bake Stories', 4, 'Rudraksh Complex, 17/17A Havelock Road, Near Mall Avenue', 26.8373, 80.9472, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Date Spot', 'Artisan Bakery, Fresh Sourdough, Custom Desserts', 'moderate'),
('c1010001-0000-0000-0000-000000000008', 'HoNS (House of No Sugar) (Kisan Bazar)', 1, 'Shop A-9, Kisan Bazar, Vibhuti Khand, Gomti Nagar', 26.8530, 80.9985, 1, 0, '2026-10-09', 'Web research', 3, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Work & Study, Minimalist & Quiet', 'Sugar-Free Bakery, Keto Cheesecakes, Gluten-Free Snacks', 'moderate'),
('c1010001-0000-0000-0000-000000000009', 'Cappuccino Blast', 3, '12 Mall Avenue Rd, The Mall Avenue, Hazratganj', 26.8376, 80.9469, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Garden & Outdoor, Lively & Social, Date Spot', 'Thin Crust Pizza, Italian Pasta, Multi-Cuisine Platters', 'moderate'),
('c1010001-0000-0000-0000-000000000010', 'Mocha Cafe & Bar', 1, 'CP-1, 2nd Floor, Anand Plaza, Viram Khand 1, Gomti Nagar', 26.8488, 80.9997, 1, 0, '2026-10-09', 'Web research', 25, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Lively & Social, Date Spot', 'Sizzlers, Loaded Nachos, Shakes, Finger Food', 'moderate'),
('c1010001-0000-0000-0000-000000000011', 'Sidewalk Bakehouse & Cafe', 1, '4/492, Vivek Khand 2, Near Patrakarpuram, Gomti Nagar', 26.8450, 81.0100, 1, 0, '2026-10-09', 'Web research', 4, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Minimalist & Quiet', 'Specialty Breads, Macarons, Custom Cold Brews', 'moderate'),
('c1010001-0000-0000-0000-000000000012', 'Melting Point (Dayal Paradise)', 1, 'Hotel Dayal Paradise, Vipul Khand 5, Gomti Nagar', 26.8458, 80.9998, 1, 0, '2026-10-09', 'Web research', 3, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Minimalist & Quiet, Aesthetic & Cozy', 'Signature Chocolates, Dry Cakes, Espresso', 'moderate'),
('c1010001-0000-0000-0000-000000000013', 'Sassy Canteen', 5, 'Sapphire Building, Metro City Centre, Badshahnagar', 26.8700, 80.9600, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Lively & Social, Aesthetic & Cozy', 'Fusion Comfort Food, Loaded Fries, Sliders', 'moderate'),
('c1010001-0000-0000-0000-000000000014', 'Chihiro', 6, '3, MG Marg, Sadar Bazaar, Cantonment', 26.8170, 80.9400, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Minimalist & Quiet', 'Japanese Mille Crepes, Matcha Cakes, Savory Sandwiches', 'moderate'),
('c1010001-0000-0000-0000-000000000015', 'Talllk', 1, 'Shop 26, B-1, DLF MyPad, Vibhuti Khand, Gomti Nagar', 26.8639, 80.9999, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Work & Study, Minimalist & Quiet', 'Specialty Pour-Overs, Sourdough Bakes, Quick Coffee', 'moderate'),
('c1010001-0000-0000-0000-000000000016', 'The Comma', 3, 'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09', 'Aesthetic & Cozy, Date Spot', 'Gourmet Sandwiches, Artisan Tea & Coffee Blends', 'moderate'),
('c1010001-0000-0000-0000-000000000017', 'Criolo', 3, 'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450, 1, 0, '2026-10-09', 'Web research', 5, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Work & Study, Aesthetic & Cozy', 'Artisan Coffee Roasts, Specialty Pastries', 'moderate'),
('c1010001-0000-0000-0000-000000000018', 'NBC (Nothing Before Coffee) (Experion)', 1, 'Shop 4, Experio at Experion Capital, Vibhuti Khand, Gomti Nagar', 26.8650, 81.0020, 1, 0, '2026-10-09', 'Web research', 60, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Work & Study, Lively & Social', 'Pocket Bites, Hot Brews, Frappes, Loaded Shakes', 'budget'),
('c1010001-0000-0000-0000-000000000019', 'Third Wave Coffee (Gomti Nagar)', 1, 'Vivek Khand, Gomti Nagar', 26.8515, 80.9980, 1, 0, '2026-10-09', 'Web research', 100, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09', 'Work & Study, Minimalist & Quiet', 'Bagels, Sourdough Toasts, Specialty Espresso', 'moderate'),
('c1010001-0000-0000-0000-000000000020', 'The Hazelnut Factory (Rohtas Summit)', 1, 'Ground Floor, Rohtas Summit, Vibhuti Khand, Gomti Nagar', 26.8625, 80.9990, 1, 0, '2026-10-11', 'Store locator', 12, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Lively & Social', 'Specialty Desserts, French Cruffins, Luxury Pastries, Savory Platters', 'moderate'),
('c1010001-0000-0000-0000-000000000021', 'The Hazelnut Factory (Phoenix Palassio)', 2, '1st Floor, Phoenix Palassio Mall, Amar Shaheed Path, Sushant Golf City', 26.8090, 81.0062, 1, 0, '2026-10-11', 'Store locator', 12, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Lively & Social', 'Specialty Desserts, French Cruffins, Artisanal Coffees, Macarons', 'moderate'),
('c1010001-0000-0000-0000-000000000022', 'The Hazelnut Factory (Nirala Nagar)', 8, 'B-192, Aliganj Main Rd, Opposite Ram Krishna Math, Nirala Nagar', 26.8780, 80.9420, 1, 0, '2026-10-11', 'Store locator', 12, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Date Spot', 'Specialty Desserts, French Cruffins, Gourmet Shakes, Tarts', 'moderate'),
('c1010001-0000-0000-0000-000000000023', 'The Hazelnut Factory (Manoj Pandey Chauraha)', 1, '2/140, Next to Gomti Nagar Police Station, Vijay Khand, Gomti Nagar', 26.8520, 80.9910, 1, 0, '2026-10-11', 'Store locator', 12, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Work & Study', 'Specialty Desserts, French Cruffins, Croissants, Breakfast Bakes', 'moderate'),
('c1010001-0000-0000-0000-000000000024', 'The Hazelnut Factory (Aliganj)', 7, 'Ram Ram Bank Chauraha, Sector B, Aliganj', 26.8910, 80.9440, 1, 0, '2026-10-11', 'Store locator', 12, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Lively & Social', 'Specialty Desserts, French Cruffins, Artisanal Bakery, Pastries', 'moderate'),
('c1010001-0000-0000-0000-000000000025', 'The Cherry Tree Bakery & Cafe (Nirala Nagar)', 8, 'B-11, Near 8 Number Chauraha, Nirala Nagar', 26.8770, 80.9410, 1, 0, '2026-10-11', 'Web research', 4, 'worldwide', 'Web research', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Minimalist & Quiet', 'Fresh Bakes, Cheesecakes, Thin Crust Pizza, Signature Shakes', 'moderate'),
('c1010001-0000-0000-0000-000000000026', 'Third Wave Coffee (Hazratganj)', 3, 'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450, 1, 0, '2026-10-11', 'Store locator', 100, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Work & Study, Minimalist & Quiet', 'Bagels, Sourdough Toasts, Croissants, Cookies, Specialty Espresso', 'moderate'),
('c1010001-0000-0000-0000-000000000027', 'NBC (Nothing Before Coffee) (Vivek Khand)', 1, '4/260, Vivek Khand 4, Gomti Nagar', 26.8510, 81.0020, 1, 0, '2026-10-11', 'Store locator', 60, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Work & Study, Lively & Social', 'Quick Bites, Loaded Nachos, Brownies, Frappes, Shaka Laka Shake', 'budget'),
('c1010001-0000-0000-0000-000000000028', 'NBC (Nothing Before Coffee) (Indira Nagar)', 9, 'Near Indira Nagar Metro Station, Indira Nagar', 26.8790, 80.9850, 1, 0, '2026-10-11', 'Store locator', 60, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Work & Study, Lively & Social', 'Pocket Pizzas, Brownies, Specialty Cold Brews, Iced Lattes', 'budget'),
('c1010001-0000-0000-0000-000000000029', 'NBC (Nothing Before Coffee) (Aliganj)', 7, 'Sector B, Kapoorthala Chauraha, Aliganj', 26.8870, 80.9450, 1, 0, '2026-10-11', 'Store locator', 60, 'worldwide', 'Store locator', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Lively & Social, Work & Study', 'Cookies, Pastries, Handcrafted Coffees, Affogato, Shakes', 'budget'),
('c1010001-0000-0000-0000-000000000030', 'Melting Point (Dayal Gateway)', 1, 'Kisan Bazar, Vibhuti Khand, Gomti Nagar', 26.8640, 80.9990, 1, 0, '2026-10-11', 'Web research', 3, 'worldwide', 'Web research', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Minimalist & Quiet', 'French Pastries, Custom Cakes, Continental Breakfast, Hot Brews', 'moderate'),
('c1010001-0000-0000-0000-000000000031', 'Melting Point (Sushant Golf City)', 2, 'IT/3, Dayal Bagh, Amar Shaheed Path, Sushant Golf City', 26.8050, 81.0100, 1, 0, '2026-10-11', 'Web research', 3, 'worldwide', 'Web research', '2026-10-11', 'Garden & Outdoor, Aesthetic & Cozy', 'Artisanal Pastries, Italian Pastas, Gourmet Coffee, High Tea', 'moderate'),
('c1010001-0000-0000-0000-000000000032', 'HoNS (House of No Sugar) (Hazratganj)', 3, 'Near Mayfair Cinema, Hazratganj', 26.8510, 80.9430, 1, 0, '2026-10-11', 'Web research', 3, 'worldwide', 'Web research', '2026-10-11', 'verified_not_independent', 'Web research', '2026-10-11', 'Aesthetic & Cozy, Minimalist & Quiet', 'Sugar-Free Bakery, Keto Cheesecakes, Gluten-Free Waffles, Healthy Smoothies', 'moderate')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `area_id`=VALUES(`area_id`), `address`=VALUES(`address`), `latitude`=VALUES(`latitude`), `longitude`=VALUES(`longitude`), `vibe_tags`=VALUES(`vibe_tags`), `food_highlights`=VALUES(`food_highlights`), `price_band`=VALUES(`price_band`), `independence_status`=VALUES(`independence_status`), `brand_location_count`=VALUES(`brand_location_count`);

-- Offerings
INSERT INTO `cafe_offering` (`id`, `cafe_id`, `drink_type`, `brewing_method`, `price`, `currency`, `checked_on`, `source`) VALUES
(1, 'c1010001-0000-0000-0000-000000000001', 'espresso', 'Espresso machine', 195.00, 'INR', '2026-10-09', 'Menu'),
(2, 'c1010001-0000-0000-0000-000000000002', 'filter', 'Filter coffee', 180.00, 'INR', '2026-10-09', 'Menu'),
(3, 'c1010001-0000-0000-0000-000000000003', 'milk', 'Milk coffee', 220.00, 'INR', '2026-10-09', 'Menu'),
(4, 'c1010001-0000-0000-0000-000000000004', 'cold_brew', 'Cold brew', 200.00, 'INR', '2026-10-09', 'Menu'),
(5, 'c1010001-0000-0000-0000-000000000005', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-09', 'Menu'),
(6, 'c1010001-0000-0000-0000-000000000006', 'milk', 'Milk coffee', 150.00, 'INR', '2026-10-09', 'Menu'),
(7, 'c1010001-0000-0000-0000-000000000007', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-09', 'Menu'),
(8, 'c1010001-0000-0000-0000-000000000008', 'filter', 'Filter coffee', 160.00, 'INR', '2026-10-09', 'Menu'),
(9, 'c1010001-0000-0000-0000-000000000009', 'espresso', 'Espresso machine', 150.00, 'INR', '2026-10-09', 'Menu'),
(10, 'c1010001-0000-0000-0000-000000000010', 'espresso', 'Espresso machine', 175.00, 'INR', '2026-10-09', 'Menu'),
(11, 'c1010001-0000-0000-0000-000000000011', 'espresso', 'Espresso machine', 200.00, 'INR', '2026-10-09', 'Menu'),
(12, 'c1010001-0000-0000-0000-000000000012', 'milk', 'Milk coffee', 200.00, 'INR', '2026-10-09', 'Menu'),
(13, 'c1010001-0000-0000-0000-000000000013', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-09', 'Menu'),
(14, 'c1010001-0000-0000-0000-000000000014', 'matcha', 'Matcha', 190.00, 'INR', '2026-10-09', 'Menu'),
(15, 'c1010001-0000-0000-0000-000000000015', 'espresso', 'Espresso machine', 160.00, 'INR', '2026-10-09', 'Menu'),
(16, 'c1010001-0000-0000-0000-000000000016', 'cold_brew', 'Cold brew', 200.00, 'INR', '2026-10-09', 'Menu'),
(17, 'c1010001-0000-0000-0000-000000000017', 'espresso', 'Espresso machine', 150.00, 'INR', '2026-10-09', 'Menu'),
(18, 'c1010001-0000-0000-0000-000000000018', 'espresso', 'Espresso machine', 90.00, 'INR', '2026-10-09', 'Menu'),
(19, 'c1010001-0000-0000-0000-000000000019', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-09', 'Menu'),
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

-- Verified Official Websites
UPDATE `cafe` SET `website` = 'https://roasterycoffee.co.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000001';
UPDATE `cafe` SET `website` = 'https://overflowcoffee.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000002';
UPDATE `cafe` SET `website` = 'https://thehazelnutfactory.com/' WHERE `id` IN ('c1010001-0000-0000-0000-000000000003', 'c1010001-0000-0000-0000-000000000020', 'c1010001-0000-0000-0000-000000000021', 'c1010001-0000-0000-0000-000000000022', 'c1010001-0000-0000-0000-000000000023', 'c1010001-0000-0000-0000-000000000024');
UPDATE `cafe` SET `website` = 'https://chaicoffeecommunity.com/' WHERE `id` = 'c1010001-0000-0000-0000-000000000006';
UPDATE `cafe` SET `website` = 'https://www.cafehons.com/' WHERE `id` IN ('c1010001-0000-0000-0000-000000000008', 'c1010001-0000-0000-0000-000000000032');
UPDATE `cafe` SET `website` = 'https://www.cappuccinoblast.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000009';
UPDATE `cafe` SET `website` = 'https://mocha.co.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000010';
UPDATE `cafe` SET `website` = 'https://nothingbeforecoffee.com/' WHERE `id` IN ('c1010001-0000-0000-0000-000000000018', 'c1010001-0000-0000-0000-000000000027', 'c1010001-0000-0000-0000-000000000028', 'c1010001-0000-0000-0000-000000000029');
UPDATE `cafe` SET `website` = 'https://thirdwavecoffee.in/' WHERE `id` IN ('c1010001-0000-0000-0000-000000000019', 'c1010001-0000-0000-0000-000000000026');

