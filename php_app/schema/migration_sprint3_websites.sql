-- =====================================================================
-- Sprint 3 Database Migration: Official Café Websites
-- Targets: MariaDB 10.11+ / MySQL 8.x (Hostinger Single Web Hosting)
-- Safe & Idempotent: Updates `website` for cafés with verified official sites
-- =====================================================================

-- 1. Roastery Coffee House
UPDATE `cafe` SET `website` = 'https://roasterycoffee.co.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000001';

-- 2. Overflow Coffee
UPDATE `cafe` SET `website` = 'https://overflowcoffee.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000002';

-- 3. The Hazelnut Factory (All 6 Lucknow Locations)
UPDATE `cafe` SET `website` = 'https://thehazelnutfactory.com/' WHERE `id` IN (
    'c1010001-0000-0000-0000-000000000003', -- Hazratganj
    'c1010001-0000-0000-0000-000000000020', -- Rohtas Summit, Gomti Nagar
    'c1010001-0000-0000-0000-000000000021', -- Phoenix Palassio, Sushant Golf City
    'c1010001-0000-0000-0000-000000000022', -- Nirala Nagar
    'c1010001-0000-0000-0000-000000000023', -- Manoj Pandey Chauraha, Gomti Nagar
    'c1010001-0000-0000-0000-000000000024'  -- Aliganj
);

-- 4. Chacoco Cafe (Chai Coffee Community)
UPDATE `cafe` SET `website` = 'https://chaicoffeecommunity.com/' WHERE `id` = 'c1010001-0000-0000-0000-000000000006';

-- 5. HoNS (House of No Sugar - Both Lucknow Locations)
UPDATE `cafe` SET `website` = 'https://www.cafehons.com/' WHERE `id` IN (
    'c1010001-0000-0000-0000-000000000008', -- Kisan Bazar, Gomti Nagar
    'c1010001-0000-0000-0000-000000000032'  -- Hazratganj
);

-- 6. Cappuccino Blast
UPDATE `cafe` SET `website` = 'https://www.cappuccinoblast.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000009';

-- 7. Mocha Cafe & Bar
UPDATE `cafe` SET `website` = 'https://mocha.co.in/' WHERE `id` = 'c1010001-0000-0000-0000-000000000010';

-- 8. Nothing Before Coffee (NBC - All 4 Lucknow Locations)
UPDATE `cafe` SET `website` = 'https://nothingbeforecoffee.com/' WHERE `id` IN (
    'c1010001-0000-0000-0000-000000000018', -- Experion, Gomti Nagar
    'c1010001-0000-0000-0000-000000000027', -- Vivek Khand, Gomti Nagar
    'c1010001-0000-0000-0000-000000000028', -- Indira Nagar
    'c1010001-0000-0000-0000-000000000029'  -- Aliganj
);

-- 9. Third Wave Coffee (Both Lucknow Locations)
UPDATE `cafe` SET `website` = 'https://thirdwavecoffee.in/' WHERE `id` IN (
    'c1010001-0000-0000-0000-000000000019', -- Gomti Nagar
    'c1010001-0000-0000-0000-000000000026'  -- Hazratganj
);
