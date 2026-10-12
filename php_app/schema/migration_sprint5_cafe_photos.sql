-- Sprint 5 Migration: Add photo_url and hero_image_url to cafe table
ALTER TABLE `cafe`
  ADD COLUMN IF NOT EXISTS `photo_url` VARCHAR(512) NULL AFTER `website`,
  ADD COLUMN IF NOT EXISTS `hero_image_url` VARCHAR(512) NULL AFTER `photo_url`;

-- Populate high-quality Unsplash specialty coffee images for Lucknow pilot cafes
UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000001'; -- Roastery Coffee House

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000002'; -- Overflow Coffee

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80'
WHERE `name` LIKE '%Hazelnut Factory%'; -- All Hazelnut Factory branches

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1525610553991-2bede1a236e2?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1525610553991-2bede1a236e2?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000004'; -- The Fresh Factory

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=1200&q=80'
WHERE `name` LIKE '%Cherry Tree%'; -- Cherry Tree Bakery & Cafe

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000006'; -- Chacoco Cafe

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000007'; -- Let's Bake Stories

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=1200&q=80'
WHERE `name` LIKE '%HoNS%'; -- House of No Sugar

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000009'; -- Cappuccino Blast

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1497636577773-f1231844b336?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1497636577773-f1231844b336?auto=format&fit=crop&w=1200&q=80'
WHERE `id` = 'c1010001-0000-0000-0000-000000000010'; -- Mocha Cafe & Bar

UPDATE `cafe` SET
  `photo_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=600&q=80',
  `hero_image_url` = 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=1200&q=80'
WHERE `photo_url` IS NULL OR `photo_url` = '';
