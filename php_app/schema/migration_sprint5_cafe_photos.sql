-- Sprint 5 Migration: Add photo_url and hero_image_url to cafe table and update exact photos for all 32 pilot cafes
ALTER TABLE `cafe`
  ADD COLUMN IF NOT EXISTS `photo_url` VARCHAR(512) NULL AFTER `website`,
  ADD COLUMN IF NOT EXISTS `hero_image_url` VARCHAR(512) NULL AFTER `photo_url`;

-- 1. Roastery Coffee House
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/4wj8xe4j/img_7065_1_819x1024.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2024-08-10/xovz6ft6/Roastery_Lucknow_3_scaled.webp'
WHERE `id` = 'c1010001-0000-0000-0000-000000000001';

-- 2. Overflow Coffee
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000002';

-- 3. The Hazelnut Factory (Hazratganj, Rohtas, Palassio, Nirala Nagar, Manoj Pandey)
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/lxm0alnj/img_7089_1_808x1024.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2026-03-25/g7cj4rus/SaveClip_App_495491455_18157743802361780_4074009342884877174_n.jpg'
WHERE `id` IN (
  'c1010001-0000-0000-0000-000000000003',
  'c1010001-0000-0000-0000-000000000020',
  'c1010001-0000-0000-0000-000000000021',
  'c1010001-0000-0000-0000-000000000022',
  'c1010001-0000-0000-0000-000000000023'
);

-- 4. The Hazelnut Factory (Aliganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2025-02-22/8rg332ol/THF2.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-02-22/wvmhxdwk/THF11.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000024';

-- 5. The Fresh Factory
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2024-11-08/c2twdfqe/Snapinsta_app_275261277_2821123361361582_3149258783180486357_n_1080.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-06-25/ujan11yo/iced-matcha-latte-hero.webp'
WHERE `id` = 'c1010001-0000-0000-0000-000000000004';

-- 6. The Cherry Tree Bakery & Cafe (Hazratganj & Nirala Nagar)
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2024-08-10/djygvi1s/IMG_5390.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2024-08-10/djygvi1s/IMG_5390.jpg'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000005', 'c1010001-0000-0000-0000-000000000025');

-- 7. Chacoco Cafe
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2025-01-18/qz3rswbm/MMK02541.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-01-17/2oxvy5nh/MMK02537.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000006';

-- 8. Let''s Bake Stories
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/fcg3uvb2/img_7087_766x1024.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2024-11-08/eqt0zab4/Snapinsta_app_419821511_345302981647242_8463049603502196515_n_1080.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000007';

-- 9. HoNS (House of No Sugar) (Kisan Bazar & Hazratganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2025-06-25/012pdtxi/Iced_Matcha_Green_Tea_Latte_pic_1.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-06-25/012pdtxi/Iced_Matcha_Green_Tea_Latte_pic_1.jpg'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000008', 'c1010001-0000-0000-0000-000000000032');

-- 10. Cappuccino Blast
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2025-12-24/k2q8e73h/IMG5850.jpeg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-04-15/0v3vi0vp/IMG9595.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000009';

-- 11. Mocha Cafe & Bar
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2022-04/f134d420-b04a-4cfb-8e0c-5cdb6f3abec5/mc1.webp',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2022-04/399543a8-b25d-477d-bc2e-41e4aed657f9/mc2.webp'
WHERE `id` = 'c1010001-0000-0000-0000-000000000010';

-- 12. Sidewalk Bakehouse & Cafe
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/bzgebzlp/img_7096_300x300.png',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2024-08-13/5dca1ksi/knocksense_2024_07_bdab3560_87e2_4136_ab61_f22bf4bdfacc_6M2_8031.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000011';

-- 13. Melting Point (Dayal Paradise, Dayal Gateway, Sushant Golf City)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000012', 'c1010001-0000-0000-0000-000000000030', 'c1010001-0000-0000-0000-000000000031');

-- 14. Sassy Canteen
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2025-06-25/qgkq6zkl/SaveClip.App503028707180738339319105261547134658951896926n.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2025-06-25/qgkq6zkl/SaveClip.App503028707180738339319105261547134658951896926n.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000013';

-- 15. Chihiro
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/w9f5cx26/img_7098_808x1024.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2026-09-28/w9f5cx26/img_7098_808x1024.jpg'
WHERE `id` = 'c1010001-0000-0000-0000-000000000014';

-- 16. Talllk
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-09-28/ajdr2fsu/e8468069_cf7b_4d23_a0c6_0c3ec7f0078e_1.jpg',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2026-03-25/yxn368zv/e66d3079505800b9d692b5e7606a1640.avif'
WHERE `id` = 'c1010001-0000-0000-0000-000000000015';

-- 17. The Comma
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000016';

-- 18. Criolo
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000017';

-- 19. NBC (Nothing Before Coffee) (Experion, Vivek Khand, Indira Nagar, Aliganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.assettype.com/knocksense/2026-03-25/ri3xvcqx/unnamed.webp',
  `hero_image_url` = 'https://images.assettype.com/knocksense/2024-09-30/4jk7lone/2023_12_17.jpg'
WHERE `id` IN (
  'c1010001-0000-0000-0000-000000000018',
  'c1010001-0000-0000-0000-000000000027',
  'c1010001-0000-0000-0000-000000000028',
  'c1010001-0000-0000-0000-000000000029'
);

-- 20. Third Wave Coffee (Gomti Nagar & Hazratganj)
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80'
WHERE `id` IN ('c1010001-0000-0000-0000-000000000019', 'c1010001-0000-0000-0000-000000000026');

-- Fallback for any remaining unassigned cafes
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=1200&q=80'
WHERE `photo_url` IS NULL OR `photo_url` = '';
