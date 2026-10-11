-- =====================================================================
-- Sprint 3 Database Migration: Friend-Informed Discovery & Private Circles
-- Targets: MariaDB 10.11+ / MySQL 8.x (Hostinger Single Web Hosting)
-- Safe & Idempotent: Uses IF NOT EXISTS clauses to prevent duplicate execution errors
-- =====================================================================

-- 1. Add Vibe, Food Variety, and Price Band columns to `cafe`
ALTER TABLE cafe 
    ADD COLUMN IF NOT EXISTS vibe_tags VARCHAR(255) NULL AFTER website,
    ADD COLUMN IF NOT EXISTS food_highlights VARCHAR(255) NULL AFTER vibe_tags,
    ADD COLUMN IF NOT EXISTS price_band ENUM('budget', 'moderate', 'premium') NOT NULL DEFAULT 'moderate' AFTER food_highlights;

-- 2. Create `friend_review` table for private circle notes (zero public review spam)
CREATE TABLE IF NOT EXISTS friend_review (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cafe_id CHAR(36) NOT NULL,
    friend_name VARCHAR(100) NOT NULL,
    visit_context VARCHAR(120) NOT NULL,
    food_quality_verdict VARCHAR(255) NULL,
    food_variety_rating ENUM('limited', 'good', 'extensive') NULL,
    ambiance_rating ENUM('chill_cozy', 'aesthetic_vibey', 'work_productive', 'lively_chatty') NULL,
    must_try_item VARCHAR(255) NULL,
    review_text TEXT NOT NULL,
    is_verified_friend TINYINT(1) NOT NULL DEFAULT 1,
    visited_on DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_friend_review_cafe FOREIGN KEY (cafe_id) REFERENCES cafe(id) ON DELETE CASCADE,
    INDEX idx_friend_review_lookup (cafe_id, is_verified_friend, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. Enrich the 19 Lucknow Pilot Cafés with Verified Vibes & Food Highlights
-- =====================================================================

-- Overflow Coffee (Sushant Golf City)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Minimalist & Quiet',
    food_highlights = 'Artisan Sourdough, Cinnamon Rolls, Specialty Sandwiches',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000002';

-- Roastery Coffee House (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Garden & Outdoor, Date Spot, Lively & Social',
    food_highlights = 'All-Day Breakfast, Cheesecakes, Gourmet Burgers',
    price_band = 'premium'
WHERE id = 'c1010001-0000-0000-0000-000000000001';

-- The Hazelnut Factory (Hazratganj)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Lively & Social',
    food_highlights = 'Specialty Desserts, French Cruffins, Luxury Pastries',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000003';

-- The Fresh Factory (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Aesthetic & Cozy',
    food_highlights = 'Healthy Bowls, Avocado Toast, Vegan Options',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000004';

-- Let's Bake Stories (Mall Avenue)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Date Spot',
    food_highlights = 'Artisan Bakery, Fresh Sourdough, Custom Desserts',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000007';

-- Chacoco Cafe (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Minimalist & Quiet',
    food_highlights = 'Single-Origin Hot Chocolates, Artisan Truffles, Croissants',
    price_band = 'budget'
WHERE id = 'c1010001-0000-0000-0000-000000000006';

-- Cappuccino Blast (Hazratganj)
UPDATE cafe SET 
    vibe_tags = 'Garden & Outdoor, Lively & Social, Date Spot',
    food_highlights = 'Thin Crust Pizza, Italian Pasta, Multi-Cuisine Platters',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000009';

-- HoNS (House of No Sugar) (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Minimalist & Quiet',
    food_highlights = 'Sugar-Free Bakery, Keto Cheesecakes, Gluten-Free Snacks',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000008';

-- Chihiro (Cantonment)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Minimalist & Quiet',
    food_highlights = 'Japanese Mille Crepes, Matcha Cakes, Savory Sandwiches',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000014';

-- Talllk (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Minimalist & Quiet',
    food_highlights = 'Manual Brew Bar, Artisan Grilled Focaccia, Light Bites',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000015';

-- The Comma (Hazratganj)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Aesthetic & Cozy',
    food_highlights = 'Fresh Bagels, Artisanal Toast, Sourdough Bakes',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000016';

-- Criolo (Hazratganj)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Date Spot',
    food_highlights = 'Handcrafted Chocolaterie, Belgian Desserts, Fondue',
    price_band = 'budget'
WHERE id = 'c1010001-0000-0000-0000-000000000017';

-- Sassy Canteen (Badshahnagar)
UPDATE cafe SET 
    vibe_tags = 'Lively & Social, Aesthetic & Cozy',
    food_highlights = 'Fusion Comfort Food, Loaded Fries, Sliders',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000013';

-- Third Wave Coffee (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Work & Study, Lively & Social',
    food_highlights = 'Fresh Cookies, Savory Paninis, Banana Bread',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000019';

-- Nothing Before Coffee (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Quick Grab, Lively & Social',
    food_highlights = 'Warm Cookies, Brownies, Garlic Bread',
    price_band = 'budget'
WHERE id = 'c1010001-0000-0000-0000-000000000018';

-- The Cherry Tree Bakery & Cafe (Hazratganj)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Date Spot',
    food_highlights = 'Classic European Bakery, Cheesecakes, Thin Pizzas',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000005';

-- Mocha Cafe & Bar (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Lively & Social, Garden & Outdoor, Date Spot',
    food_highlights = 'Wood-Fired Pizza, Mezze Platters, Desserts',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000010';

-- Sidewalk Bakehouse & Cafe (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Minimalist & Quiet',
    food_highlights = 'French Almond Croissants, Fresh Sourdough, Baguettes',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000011';

-- Melting Point (Gomti Nagar)
UPDATE cafe SET 
    vibe_tags = 'Aesthetic & Cozy, Date Spot',
    food_highlights = 'Belgian Waffles, Chocolate Fondues, Gourmet Toasts',
    price_band = 'moderate'
WHERE id = 'c1010001-0000-0000-0000-000000000012';

-- =====================================================================
-- 4. Initial Seed for "Friends' Take" Private Circle Reviews
-- =====================================================================

INSERT INTO friend_review 
    (cafe_id, friend_name, visit_context, food_quality_verdict, food_variety_rating, ambiance_rating, must_try_item, review_text, is_verified_friend, visited_on)
VALUES
    (
        'c1010001-0000-0000-0000-000000000001',
        'Anuj',
        'Weekend Morning Brew Session',
        'Top-tier breakfast menu and house cheesecakes',
        'extensive',
        'chill_cozy',
        'Monsooned Malabar Cascara & Blueberry Cheesecake',
        'The outdoor courtyard seating under the trees is unmatched in Lucknow. Super peaceful before 11 AM. Coffee is brewed consistently well.',
        1,
        '2026-10-05'
    ),
    (
        'c1010001-0000-0000-0000-000000000002',
        'Anuj',
        'Solo Deep Work & Reading',
        'Great fresh sourdough toasts and pastries',
        'good',
        'work_productive',
        'Manual V60 Pour-Over & Warm Cinnamon Roll',
        'Quiet, focused vibe. Excellent table height for laptop work with power sockets nearby. Best pour-overs in the Sushant Golf City area.',
        1,
        '2026-10-07'
    ),
    (
        'c1010001-0000-0000-0000-000000000003',
        'Priya',
        'Evening Hangout with Friends',
        'Unbelievable variety of fresh pastries and desserts',
        'extensive',
        'aesthetic_vibey',
        'Nutella Cruffin & Spanish Iced Latte',
        'Extremely aesthetic interiors, perfect for photos. Can get a bit lively/loud on weekend evenings, but dessert quality is unbeatable.',
        1,
        '2026-10-08'
    ),
    (
        'c1010001-0000-0000-0000-000000000007',
        'Kabir',
        'Quiet Sunday Afternoon Date',
        'Artisan sourdough and bespoke cakes made fresh',
        'good',
        'aesthetic_vibey',
        'Tiramisu & Cortado',
        'Very cozy European bakery feel. The cortado had great balance with low acidity. Highly recommend the tiramisu.',
        1,
        '2026-10-09'
    );
