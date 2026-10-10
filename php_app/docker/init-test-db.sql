-- Isolated local integration database; never apply to an existing/production server.
CREATE DATABASE IF NOT EXISTS cafe_discovery_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON cafe_discovery_test.* TO 'cafe'@'%';
