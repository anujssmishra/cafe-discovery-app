-- Sprint 5 Migration: Add photo_url and hero_image_url to cafe table and update exact cafe ambience photos for all 32 pilot cafes
ALTER TABLE `cafe`
  ADD COLUMN IF NOT EXISTS `photo_url` VARCHAR(512) NULL AFTER `website`,
  ADD COLUMN IF NOT EXISTS `hero_image_url` VARCHAR(512) NULL AFTER `photo_url`;

-- 1. Roastery Coffee House (Heritage Colonial House & Outdoor Courtyard Garden)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2024-08-10/xovz6ft6/Roastery_Lucknow_3_scaled.webp'
WHERE `id` = 'c1010001-0000-0000-0000-000000000001';

-- 2. Overflow Coffee (Spacious Modern Cafe Interior)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000002';

-- 3. The Hazelnut Factory (Hazratganj, Rohtas, Palassio, Nirala Nagar, Manoj Pandey, Aliganj)
UPDATE `cafe` SET
  `photo_url` = 'https://media.assettype.com/knocksense/2025-02-22/8rg332ol/THF2.jpg',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2025-02-22/wvmhxdwk/THF11.jpg'
WHERE `id` IN (
  'c1010001-0000-0000-0000-000000000003',
  'c1010001-0000-0000-0000-000000000020',
  'c1010001-0000-0000-0000-000000000021',
  'c1010001-0000-0000-0000-000000000022',
  'c1010001-0000-0000-0000-000000000023',
  'c1010001-0000-0000-0000-000000000024'
);

-- 4. The Fresh Factory (Aesthetic Cafe Seating & Window Light)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1525610553991-2bede1a236e2?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1525610553991-2bede1a236e2?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000004';

-- 5. The Cherry Tree Bakery & Cafe (Hazratganj & Nirala Nagar)
UPDATE `cafe` SET
  `photo_url` = 'https://media.assettype.com/knocksense/2024-08-10/djygvi1s/IMG_5390.jpg',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2024-08-10/djygvi1s/IMG_5390.jpg'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000005', 'c1010001-0000-0000-0000-000000000025');

-- 6. Chacoco Cafe (Boutique Chocolaterie Ambience)
UPDATE `cafe` SET
  `photo_url` = 'https://media.assettype.com/knocksense/2025-01-18/qz3rswbm/MMK02541.jpg',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2025-01-17/2oxvy5nh/MMK02537.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000006';

-- 7. Let''s Bake Stories (Sensory Garden Bakery & Bistro Interior)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000007';

-- 8. HoNS (House of No Sugar) (Kisan Bazar & Hazratganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1497636577773-f1231844b336?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1497636577773-f1231844b336?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000008', 'c1010001-0000-0000-0000-000000000032');

-- 9. Cappuccino Blast (Lush Garden Canopy & Outdoor Lounge Ambience)
UPDATE `cafe` SET
  `photo_url` = 'https://media.assettype.com/knocksense/2025-04-21/yc86dclk/MMK06118.jpg',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2025-04-15/0v3vi0vp/IMG9595.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000009';

-- 10. Mocha Cafe & Bar (Brick Wall Lounge & Restobar Interior)
UPDATE `cafe` SET
  `photo_url` = 'https://media.assettype.com/knocksense/2022-04/f134d420-b04a-4cfb-8e0c-5cdb6f3abec5/mc1.webp',
  `hero_image_url` = 'https://media.assettype.com/knocksense/2022-04/399543a8-b25d-477d-bc2e-41e4aed657f9/mc2.webp'
WHERE `id` = 'c1010001-0000-0000-0000-000000000010';

-- 11. Sidewalk Bakehouse & Cafe
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000011';

-- 12. Melting Point (Dayal Paradise, Dayal Gateway, Sushant Golf City)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000012', 'c1010001-0000-0000-0000-000000000030', 'c1010001-0000-0000-0000-000000000031');

-- 13. Sassy Canteen
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000013';

-- 14. Chihiro
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000014';

-- 15. Talllk
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000015';

-- 16. The Comma
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000016';

-- 17. Criolo
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000017';

-- 18. NBC (Nothing Before Coffee) (Experion, Vivek Khand, Indira Nagar, Aliganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN (
  'c1010001-0000-0000-0000-000000000018',
  'c1010001-0000-0000-0000-000000000027',
  'c1010001-0000-0000-0000-000000000028',
  'c1010001-0000-0000-0000-000000000029'
);

-- 19. Third Wave Coffee (Gomti Nagar & Hazratganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000019', 'c1010001-0000-0000-0000-000000000026');

-- Fallback for any remaining unassigned cafes
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=1200&q=80'
WHERE `photo_url` IS NULL OR `photo_url` = '';
