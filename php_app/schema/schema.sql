CREATE TABLE IF NOT EXISTS `area` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(120) NOT NULL,
    `slug` VARCHAR(140) NOT NULL UNIQUE,
    `city` VARCHAR(120) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `display_order` INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cafe` (
    `id` CHAR(36) PRIMARY KEY,
    `name` VARCHAR(180) NOT NULL,
    `area_id` INT NOT NULL,
    `address` TEXT NOT NULL,
    `summary` TEXT,
    `latitude` DECIMAL(9,6) NULL,
    `longitude` DECIMAL(9,6) NULL,
    `website` VARCHAR(255),
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `is_demo` TINYINT(1) NOT NULL DEFAULT 0,
    `checked_on` DATE NULL,
    `source` TEXT,
    `brand_location_count` INT NULL,
    `brand_count_scope` VARCHAR(40) NOT NULL DEFAULT 'worldwide',
    `brand_count_source` TEXT,
    `brand_count_checked_on` DATE NULL,
    `independence_status` VARCHAR(32) NOT NULL DEFAULT 'unknown',
    `independence_source` TEXT,
    `independence_checked_on` DATE NULL,
    CONSTRAINT `fk_cafe_area` FOREIGN KEY (`area_id`) REFERENCES `area`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_cafe_coordinates` CHECK (
        (`latitude` IS NULL AND `longitude` IS NULL) OR 
        (`latitude` IS NOT NULL AND `longitude` IS NOT NULL)
    ),
    CONSTRAINT `chk_cafe_latitude` CHECK (`latitude` >= -90 AND `latitude` <= 90),
    CONSTRAINT `chk_cafe_longitude` CHECK (`longitude` >= -180 AND `longitude` <= 180),
    CONSTRAINT `chk_cafe_brand_count` CHECK (`brand_location_count` >= 1),
    CONSTRAINT `chk_cafe_independence_status` CHECK (`independence_status` IN ('unknown', 'verified_independent', 'verified_not_independent'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cafe_offering` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cafe_id` CHAR(36) NOT NULL,
    `drink_type` VARCHAR(20) NOT NULL,
    `brewing_method` VARCHAR(100) NOT NULL DEFAULT '',
    `price` DECIMAL(8,2) NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'INR',
    `checked_on` DATE NULL,
    `source` TEXT,
    CONSTRAINT `fk_offering_cafe` FOREIGN KEY (`cafe_id`) REFERENCES `cafe`(`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_offering_price` CHECK (`price` IS NULL OR `price` >= 0),
    CONSTRAINT `chk_offering_drink_type` CHECK (`drink_type` IN ('espresso', 'filter', 'milk', 'cold_brew', 'tea', 'matcha'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
