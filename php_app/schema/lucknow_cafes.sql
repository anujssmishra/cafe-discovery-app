-- Lucknow Pilot Data Seed
-- Areas
INSERT INTO `area` (`id`, `name`, `slug`, `city`, `is_active`, `display_order`) VALUES
(1, 'Gomti Nagar', 'gomti-nagar', 'Lucknow', 1, 10),
(2, 'Sushant Golf City', 'sushant-golf-city', 'Lucknow', 1, 20),
(3, 'Hazratganj', 'hazratganj', 'Lucknow', 1, 30),
(4, 'Mall Avenue', 'mall-avenue', 'Lucknow', 1, 40),
(5, 'Badshahnagar', 'badshahnagar', 'Lucknow', 1, 50),
(6, 'Cantonment', 'cantonment', 'Lucknow', 1, 60)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- Cafes
INSERT INTO `cafe` (`id`, `name`, `area_id`, `address`, `latitude`, `longitude`, `is_active`, `is_demo`, `checked_on`, `source`, `brand_location_count`, `brand_count_scope`, `brand_count_source`, `brand_count_checked_on`, `independence_status`, `independence_source`, `independence_checked_on`) VALUES
('c1010001-0000-0000-0000-000000000001', 'Roastery Coffee House', 1, 'Plot No. 4, Ground Floor, Vibhuti Khand, Gomti Nagar', 26.8640, 80.9995, 1, 0, '2026-10-09', 'Web research', 18, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000002', 'Overflow Coffee', 2, 'G-14, Ground Floor, Phoenix Palassio Mall, Amar Shaheed Path, Sushant Golf City', 26.8090, 81.0062, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000003', 'The Hazelnut Factory', 3, 'Raza Plaza, Near Sahu Cinema, Hazratganj', 26.8505, 80.9427, 1, 0, '2026-10-09', 'Web research', 12, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000004', 'The Fresh Factory', 1, 'Shop 31, First Floor, DLF MyPad, Vibhuti Khand, Gomti Nagar', 26.8643, 81.0001, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000005', 'The Cherry Tree Bakery & Cafe', 3, '11, Habibullah Estate, Hazratganj', 26.8520, 80.9445, 1, 0, '2026-10-09', 'Web research', 4, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000006', 'Chacoco Cafe', 1, '4/14, Vishal Khand 4, Gomti Nagar', 26.8540, 80.9850, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000007', 'Let''s Bake Stories', 4, 'Rudraksh Complex, 17/17A Havelock Road, Near Mall Avenue', 26.8373, 80.9472, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000008', 'HoNS (House of No Sugar)', 1, 'Shop A-9, Kisan Bazar, Vibhuti Khand, Gomti Nagar', 26.8530, 80.9985, 1, 0, '2026-10-09', 'Web research', 3, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000009', 'Cappuccino Blast', 3, '12 Mall Avenue Rd, The Mall Avenue, Hazratganj', 26.8376, 80.9469, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000010', 'Mocha Cafe & Bar', 1, 'CP-1, 2nd Floor, Anand Plaza, Viram Khand 1, Gomti Nagar', 26.8488, 80.9997, 1, 0, '2026-10-09', 'Web research', 25, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000011', 'Sidewalk Bakehouse & Cafe', 1, '4/492, Vivek Khand 2, Near Patrakarpuram, Gomti Nagar', 26.8450, 81.0100, 1, 0, '2026-10-09', 'Web research', 4, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000012', 'Melting Point', 1, 'Hotel Dayal Paradise, Vipul Khand 5, Gomti Nagar', 26.8458, 80.9998, 1, 0, '2026-10-09', 'Web research', 3, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000013', 'Sassy Canteen', 5, 'Sapphire Building, Metro City Centre, Badshahnagar', 26.8700, 80.9600, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000014', 'Chihiro', 6, '3, MG Marg, Sadar Bazaar, Cantonment', 26.8170, 80.9400, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000015', 'Talllk', 1, 'Shop 26, B-1, DLF MyPad, Vibhuti Khand, Gomti Nagar', 26.8639, 80.9999, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000016', 'The Comma', 3, 'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450, 1, 0, '2026-10-09', 'Web research', 1, 'worldwide', 'Web research', '2026-10-09', 'verified_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000017', 'Criolo', 3, 'Le Press, 29 Nawal Kishore Road, Hazratganj', 26.8530, 80.9450, 1, 0, '2026-10-09', 'Web research', 5, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000018', 'NBC (Nothing Before Coffee)', 1, 'Shop 4, Experio at Experion Capital, Vibhuti Khand, Gomti Nagar', 26.8650, 81.0020, 1, 0, '2026-10-09', 'Web research', 60, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09'),
('c1010001-0000-0000-0000-000000000019', 'Third Wave Coffee', 1, 'Vivek Khand, Gomti Nagar', 26.8515, 80.9980, 1, 0, '2026-10-09', 'Web research', 100, 'worldwide', 'Web research', '2026-10-09', 'verified_not_independent', 'Web research', '2026-10-09')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `independence_status`=VALUES(`independence_status`), `brand_location_count`=VALUES(`brand_location_count`);

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
(19, 'c1010001-0000-0000-0000-000000000019', 'espresso', 'Espresso machine', 180.00, 'INR', '2026-10-09', 'Menu')
ON DUPLICATE KEY UPDATE `price`=VALUES(`price`);
