-- =====================================================================
-- Sprint 4 Database Migration: Multi-Tenant Circles & Google Reviews Auto-Match
-- Targets: MariaDB 10.11+ / MySQL 8.x (Hostinger Single Web Hosting)
-- Safe & Idempotent: Uses IF NOT EXISTS clauses and ON DUPLICATE KEY UPDATE
-- =====================================================================

-- 1. Create `circle` Table (Any friend group can create their own circle)
CREATE TABLE IF NOT EXISTS circle (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    invite_code VARCHAR(32) NOT NULL UNIQUE,
    city VARCHAR(80) NOT NULL DEFAULT 'Lucknow',
    creator_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_circle_invite (invite_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Create `circle_member` Table
CREATE TABLE IF NOT EXISTS circle_member (
    id INT AUTO_INCREMENT PRIMARY KEY,
    circle_id CHAR(36) NOT NULL,
    member_name VARCHAR(120) NOT NULL,
    email VARCHAR(180) NULL,
    google_sub VARCHAR(64) NULL,
    auth_token VARCHAR(64) NOT NULL UNIQUE,
    role ENUM('creator', 'member') NOT NULL DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_member_circle FOREIGN KEY (circle_id) REFERENCES circle(id) ON DELETE CASCADE,
    INDEX idx_member_lookup (circle_id, auth_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Enhance `friend_review` with circle association & Google source tracking
ALTER TABLE friend_review
    ADD COLUMN IF NOT EXISTS circle_id CHAR(36) NULL AFTER id,
    ADD COLUMN IF NOT EXISTS source_type ENUM('direct', 'google_matched') NOT NULL DEFAULT 'direct' AFTER review_text,
    ADD COLUMN IF NOT EXISTS google_rating INT NULL AFTER source_type;

-- 4. Create `cafe_google_review` Table (Public Reviews Index for Matching)
CREATE TABLE IF NOT EXISTS cafe_google_review (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cafe_id CHAR(36) NOT NULL,
    author_name VARCHAR(150) NOT NULL,
    rating INT NOT NULL DEFAULT 5,
    review_text TEXT NOT NULL,
    publish_date VARCHAR(50) NULL,
    visit_context VARCHAR(120) NULL,
    must_try_item VARCHAR(255) NULL,
    food_quality_verdict VARCHAR(255) NULL,
    ambiance_rating VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cgr_cafe FOREIGN KEY (cafe_id) REFERENCES cafe(id) ON DELETE CASCADE,
    INDEX idx_cgr_author (author_name),
    INDEX idx_cgr_cafe (cafe_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Seed Pioneer Circle (Default community circle for Lucknow)
INSERT INTO `circle` (`id`, `name`, `invite_code`, `city`, `creator_name`) VALUES
('c0000001-0000-0000-0000-000000000001', 'Lucknow Coffee Circle', 'lucknow-circle', 'Lucknow', 'Anuj')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 6. Link existing initial reviews to the Pioneer Circle
UPDATE `friend_review` 
SET `circle_id` = 'c0000001-0000-0000-0000-000000000001'
WHERE `circle_id` IS NULL;

-- 7. Seed Public Google Reviews for Matching (Available to auto-match when friends connect)
INSERT INTO `cafe_google_review` 
    (`cafe_id`, `author_name`, `rating`, `review_text`, `publish_date`, `visit_context`, `must_try_item`, `food_quality_verdict`, `ambiance_rating`)
VALUES
-- Anuj Mishra reviews
(
    'c1010001-0000-0000-0000-000000000001', -- Roastery Gomti Nagar
    'Anuj Mishra',
    5,
    'The outdoor courtyard seating under the trees is unmatched in Lucknow. Super peaceful before 11 AM. Coffee is brewed consistently well, especially their cascara and specialty pour-overs.',
    '1 week ago',
    'Weekend Morning Brew Session',
    'Monsooned Malabar Cascara & Blueberry Cheesecake',
    'Top-tier breakfast menu and house cheesecakes',
    'chill_cozy'
),
(
    'c1010001-0000-0000-0000-000000000002', -- Overflow Coffee Palassio
    'Anuj Mishra',
    5,
    'Quiet, focused vibe. Excellent table height for laptop work with power sockets nearby. Best manual V60 pour-overs in the Sushant Golf City area.',
    '3 days ago',
    'Solo Deep Work & Reading',
    'Manual V60 Pour-Over & Warm Cinnamon Roll',
    'Great fresh sourdough toasts and pastries',
    'work_productive'
),
(
    'c1010001-0000-0000-0000-000000000026', -- Third Wave Coffee Hazratganj
    'Anuj Mishra',
    5,
    'Super quiet first-floor seating inside Le Press. Plug points at almost every table and very reliable Wi-Fi for working afternoons.',
    '2 weeks ago',
    'Remote Work Afternoon',
    'Classic Bagel with Cream Cheese & Orange Zest Mocha',
    'Solid pour-over options and warm bagels',
    'work_productive'
),
-- Priya Sharma reviews
(
    'c1010001-0000-0000-0000-000000000003', -- The Hazelnut Factory Hazratganj
    'Priya Sharma',
    5,
    'Unbelievable variety of fresh pastries and desserts. The French cruffins and hot coffee are delicious, perfect spot for dessert dates.',
    '2 weeks ago',
    'Evening Dessert Date',
    'Nutella Cruffin & Belgian Mocha',
    'Luxury desserts and artisanal bakes',
    'aesthetic_vibey'
),
-- Rohan Kapoor reviews
(
    'c1010001-0000-0000-0000-000000000004', -- The Fresh Factory Gomti Nagar
    'Rohan Kapoor',
    5,
    'Fresh healthy food and nutritious bowls done right. Super light salads, sourdough avocado toasts, and great cold brews.',
    '3 weeks ago',
    'Post-Workout Healthy Brunch',
    'Avocado Toast & Cold Brew Tonic',
    'Clean healthy menu with vegan choices',
    'work_productive'
),
-- Sneha Verma reviews
(
    'c1010001-0000-0000-0000-000000000005', -- The Cherry Tree Hazratganj
    'Sneha Verma',
    5,
    'Habibullah estate charm never gets old. Classic baked cheesecake and wood-fired thin crust pizza are must-orders.',
    '1 month ago',
    'Casual Weekend Hangout',
    'New York Baked Cheesecake & Farmhouse Pizza',
    'Reliable bakery classics and comfort food',
    'chill_cozy'
),
-- Kabir reviews
(
    'c1010001-0000-0000-0000-000000000025', -- The Cherry Tree Nirala Nagar
    'Kabir Singh',
    5,
    'Much more relaxed and less crowded than the Hazratganj outlet. Easy street parking in Nirala Nagar and great coffee.',
    '1 week ago',
    'Sunday Family Breakfast',
    'New York Baked Cheesecake & Farmhouse Pizza',
    'Comfort food done right, peaceful neighborhood vibe',
    'chill_cozy'
),
-- Aarav reviews
(
    'c1010001-0000-0000-0000-000000000020', -- THF Rohtas Summit
    'Aarav Gupta',
    5,
    'Great outdoor sitting at Summit. Always packed in the evenings with good energy. Service is fast despite the crowd.',
    '5 days ago',
    'Late Evening Hangout',
    'Nutella Cruffin & Iced Belgian Mocha',
    'Excellent fresh cruffins and desserts as always',
    'lively_chatty'
);
