<?php
declare(strict_types=1);

/**
 * Circle & Google Reviews Match Engine
 */

const DEFAULT_CIRCLE_ID = 'c0000001-0000-0000-0000-000000000001';
const CIRCLE_COOKIE_NAME = 'cafe_circle_token';

function circle_generate_uuid(): string
{
    $data = random_bytes(16);
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40); // set version to 0100
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80); // set bits 6-7 to 10
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

function circle_generate_slug(string $name): string
{
    $slug = strtolower(trim(preg_replace('/[^A-Za-z0-9]+/', '-', $name), '-'));
    if ($slug === '') {
        $slug = 'circle';
    }
    return substr($slug, 0, 24) . '-' . substr(bin2hex(random_bytes(3)), 0, 5);
}

function circle_ensure_schema(PDO $pdo): void
{
    static $ensured = false;
    if ($ensured) {
        return;
    }
    $ensured = true;

    try {
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'circle'");
        if ($tableCheck && $tableCheck->rowCount() > 0) {
            return;
        }

        $migrationFile = __DIR__ . '/../schema/migration_sprint4_circles_and_google_match.sql';
        if (file_exists($migrationFile)) {
            $sql = file_get_contents($migrationFile);
            if ($sql) {
                // Split statements safely
                $statements = array_filter(array_map('trim', explode(';', $sql)));
                foreach ($statements as $stmtSql) {
                    if ($stmtSql !== '' && !str_starts_with($stmtSql, '--')) {
                        try {
                            $pdo->exec($stmtSql);
                        } catch (Throwable) {
                            // Continue with other statements
                        }
                    }
                }
            }
        }
    } catch (Throwable) {
        // Continue gracefully
    }
}

function circle_get_current_session(PDO $pdo): array
{
    circle_ensure_schema($pdo);
    $token = $_COOKIE[CIRCLE_COOKIE_NAME] ?? null;
    if ($token && is_string($token) && strlen($token) >= 16) {
        try {
            $stmt = $pdo->prepare('SELECT m.*, c.name AS circle_name, c.invite_code, c.city 
                FROM circle_member m 
                JOIN circle c ON m.circle_id = c.id 
                WHERE m.auth_token = :token LIMIT 1');
            $stmt->execute([':token' => $token]);
            $member = $stmt->fetch();
            if ($member) {
                return [
                    'is_logged_in' => true,
                    'member' => $member,
                    'circle_id' => $member['circle_id'],
                    'circle_name' => $member['circle_name'],
                    'invite_code' => $member['invite_code'],
                    'member_name' => $member['member_name'],
                ];
            }
        } catch (Throwable) {
            // Table might not exist yet during migration
        }
    }

    return [
        'is_logged_in' => false,
        'member' => null,
        'circle_id' => DEFAULT_CIRCLE_ID,
        'circle_name' => 'Lucknow Coffee Circle',
        'invite_code' => 'lucknow-circle',
        'member_name' => 'Guest',
    ];
}

function circle_create(PDO $pdo, string $circleName, string $creatorName, ?string $email = null): ?array
{
    circle_ensure_schema($pdo);
    try {
        $circleId = circle_generate_uuid();
        $inviteCode = circle_generate_slug($circleName);
        $authToken = bin2hex(random_bytes(32));

        $stmt = $pdo->prepare('INSERT INTO circle (id, name, invite_code, city, creator_name) VALUES (:id, :name, :code, :city, :creator)');
        $stmt->execute([
            ':id' => $circleId,
            ':name' => trim($circleName),
            ':code' => $inviteCode,
            ':city' => 'Lucknow',
            ':creator' => trim($creatorName),
        ]);

        $memberStmt = $pdo->prepare('INSERT INTO circle_member (circle_id, member_name, email, auth_token, role) VALUES (:cid, :name, :email, :token, :role)');
        $memberStmt->execute([
            ':cid' => $circleId,
            ':name' => trim($creatorName),
            ':email' => $email ? trim($email) : null,
            ':token' => $authToken,
            ':role' => 'creator',
        ]);

        // Set cookie for 1 year
        setcookie(CIRCLE_COOKIE_NAME, $authToken, [
            'expires' => time() + 31536000,
            'path' => '/',
            'httponly' => true,
            'samesite' => 'Lax',
        ]);

        return [
            'circle_id' => $circleId,
            'name' => trim($circleName),
            'invite_code' => $inviteCode,
            'creator_name' => trim($creatorName),
            'auth_token' => $authToken,
        ];
    } catch (Throwable $e) {
        error_log('Failed to create circle: ' . $e->getMessage());
        return null;
    }
}

function circle_join(PDO $pdo, string $inviteCode, string $memberName, ?string $email = null): ?array
{
    circle_ensure_schema($pdo);
    try {
        $stmt = $pdo->prepare('SELECT * FROM circle WHERE invite_code = :code LIMIT 1');
        $stmt->execute([':code' => trim($inviteCode)]);
        $circle = $stmt->fetch();
        if (!$circle) {
            return null;
        }

        $authToken = bin2hex(random_bytes(32));
        $memberStmt = $pdo->prepare('INSERT INTO circle_member (circle_id, member_name, email, auth_token, role) VALUES (:cid, :name, :email, :token, :role)');
        $memberStmt->execute([
            ':cid' => $circle['id'],
            ':name' => trim($memberName),
            ':email' => $email ? trim($email) : null,
            ':token' => $authToken,
            ':role' => 'member',
        ]);

        setcookie(CIRCLE_COOKIE_NAME, $authToken, [
            'expires' => time() + 31536000,
            'path' => '/',
            'httponly' => true,
            'samesite' => 'Lax',
        ]);

        return [
            'circle_id' => $circle['id'],
            'name' => $circle['name'],
            'invite_code' => $circle['invite_code'],
            'member_name' => trim($memberName),
        ];
    } catch (Throwable $e) {
        error_log('Failed to join circle: ' . $e->getMessage());
        return null;
    }
}

function circle_find_google_matches(PDO $pdo, string $name): array
{
    $cleanName = trim($name);
    if ($cleanName === '') {
        return [];
    }

    try {
        // Search by full name or first name match (e.g. "Anuj" matches "Anuj Mishra")
        $tokens = explode(' ', $cleanName);
        $firstName = $tokens[0] ?? $cleanName;

        $stmt = $pdo->prepare('SELECT gr.*, c.name AS cafe_name, a.name AS area_name 
            FROM cafe_google_review gr
            JOIN cafe c ON gr.cafe_id = c.id
            JOIN area a ON c.area_id = a.id
            WHERE LOWER(gr.author_name) = LOWER(:fullName)
               OR LOWER(gr.author_name) LIKE LOWER(:firstNameLike)
            ORDER BY gr.publish_date DESC, gr.id ASC');

        $stmt->execute([
            ':fullName' => $cleanName,
            ':firstNameLike' => $firstName . '%',
        ]);

        return $stmt->fetchAll();
    } catch (Throwable) {
        return [];
    }
}

function circle_import_google_reviews(PDO $pdo, string $circleId, string $memberName, array $reviewIds): int
{
    if (empty($reviewIds)) {
        return 0;
    }

    $imported = 0;
    $placeholders = implode(',', array_fill(0, count($reviewIds), '?'));
    $stmt = $pdo->prepare("SELECT * FROM cafe_google_review WHERE id IN ($placeholders)");
    $stmt->execute($reviewIds);
    $reviews = $stmt->fetchAll();

    $insertStmt = $pdo->prepare('INSERT INTO friend_review (
        circle_id, cafe_id, friend_name, visit_context,
        food_quality_verdict, food_variety_rating, ambiance_rating,
        must_try_item, review_text, source_type, google_rating,
        is_verified_friend, visited_on
    ) VALUES (
        :circle_id, :cafe_id, :friend_name, :visit_context,
        :food_quality, :food_variety, :ambiance,
        :must_try, :notes, :source_type, :rating,
        1, CURRENT_DATE()
    )');

    foreach ($reviews as $rev) {
        // Prevent duplicate import of the exact same review in this circle
        $dupCheck = $pdo->prepare('SELECT 1 FROM friend_review WHERE circle_id = :cid AND cafe_id = :cafe_id AND friend_name = :name AND review_text = :text LIMIT 1');
        $dupCheck->execute([
            ':cid' => $circleId,
            ':cafe_id' => $rev['cafe_id'],
            ':name' => $memberName,
            ':text' => $rev['review_text'],
        ]);

        if (!$dupCheck->fetch()) {
            $insertStmt->execute([
                ':circle_id' => $circleId,
                ':cafe_id' => $rev['cafe_id'],
                ':friend_name' => $memberName,
                ':visit_context' => $rev['visit_context'] ?: 'Google Maps Review',
                ':food_quality' => $rev['food_quality_verdict'] ?: 'Recommended on Google',
                ':food_variety' => 'good',
                ':ambiance' => $rev['ambiance_rating'] ?: 'chill_cozy',
                ':must_try' => $rev['must_try_item'] ?: 'Featured Specialty Brew',
                ':notes' => $rev['review_text'],
                ':source_type' => 'google_matched',
                ':rating' => (int) $rev['rating'],
            ]);
            $imported++;
        }
    }

    return $imported;
}

function circle_get_reviews(PDO $pdo, string $circleId): array
{
    try {
        $stmt = $pdo->prepare('SELECT fr.*, c.name AS cafe_name, a.name AS area_name 
            FROM friend_review fr
            JOIN cafe c ON fr.cafe_id = c.id
            JOIN area a ON c.area_id = a.id
            WHERE fr.is_verified_friend = 1 
              AND (fr.circle_id = :cid OR (:is_default = 1 AND (fr.circle_id = :default_id OR fr.circle_id IS NULL)))
            ORDER BY fr.visited_on DESC, fr.created_at DESC LIMIT 12');
        $isDefault = ($circleId === DEFAULT_CIRCLE_ID) ? 1 : 0;
        $stmt->execute([
            ':cid' => $circleId,
            ':is_default' => $isDefault,
            ':default_id' => DEFAULT_CIRCLE_ID,
        ]);
        return $stmt->fetchAll();
    } catch (Throwable) {
        return [];
    }
}

function circle_extract_user_reviews(PDO $pdo, string $identifier, array $config): array
{
    circle_ensure_schema($pdo);
    $raw = trim($identifier);
    if ($raw === '') {
        return [];
    }

    $contributorId = null;
    if (preg_match('~maps/contrib/([0-9]+)~', $raw, $m)) {
        $contributorId = $m[1];
    } elseif (ctype_digit($raw) && strlen($raw) >= 12) {
        $contributorId = $raw;
    }

    $authorName = $raw;
    $apiKeySerp = $config['serpapi_key'] ?? '';
    $apiKeyOutscraper = $config['outscraper_api_key'] ?? '';

    // 1. Live extraction via SerpApi Google Maps Contributor Reviews engine
    if ($contributorId !== null && $apiKeySerp !== '') {
        try {
            $url = 'https://serpapi.com/search.json?' . http_build_query([
                'engine' => 'google_maps_contributor_reviews',
                'contributor_id' => $contributorId,
                'api_key' => $apiKeySerp,
            ]);

            $ctx = stream_context_create(['http' => ['timeout' => 12]]);
            $res = @file_get_contents($url, false, $ctx);
            if ($res) {
                $data = json_decode($res, true);
                $userName = $data['contributor']['name'] ?? 'Google Contributor';
                $authorName = $userName;
                $reviewsList = $data['reviews'] ?? [];

                $cafes = $pdo->query('SELECT id, name FROM cafe WHERE is_active = 1')->fetchAll();
                $insertStmt = $pdo->prepare('INSERT INTO cafe_google_review (
                    cafe_id, author_name, rating, review_text, publish_date, 
                    visit_context, must_try_item, food_quality_verdict, ambiance_rating
                ) VALUES (
                    :cafe_id, :author_name, :rating, :review_text, :publish_date,
                    :visit_context, :must_try_item, :food_quality_verdict, :ambiance_rating
                )');
                $checkStmt = $pdo->prepare('SELECT id FROM cafe_google_review 
                    WHERE cafe_id = :cafe_id AND author_name = :author_name AND review_text = :text LIMIT 1');

                foreach ($reviewsList as $item) {
                    $placeTitle = trim((string) ($item['title'] ?? ''));
                    $reviewSnippet = trim((string) ($item['snippet'] ?? $item['text'] ?? ''));
                    $ratingVal = max(1, min(5, (int) ($item['rating'] ?? 5)));
                    $dateVal = (string) ($item['date'] ?? 'Recently');

                    if ($placeTitle === '' || $reviewSnippet === '') {
                        continue;
                    }

                    $matchedCafeId = null;
                    foreach ($cafes as $c) {
                        $cName = mb_strtolower(trim($c['name']));
                        $pTitle = mb_strtolower($placeTitle);
                        if (str_contains($pTitle, $cName) || str_contains($cName, $pTitle)) {
                            $matchedCafeId = $c['id'];
                            break;
                        }
                    }

                    if ($matchedCafeId) {
                        $checkStmt->execute([
                            ':cafe_id' => $matchedCafeId,
                            ':author_name' => $userName,
                            ':text' => $reviewSnippet,
                        ]);
                        if (!$checkStmt->fetch()) {
                            $insertStmt->execute([
                                ':cafe_id' => $matchedCafeId,
                                ':author_name' => $userName,
                                ':rating' => $ratingVal,
                                ':review_text' => $reviewSnippet,
                                ':publish_date' => $dateVal,
                                ':visit_context' => 'Google Maps Review',
                                ':must_try_item' => 'Signature Specialty Brew',
                                ':food_quality_verdict' => 'Recommended on Google Maps',
                                ':ambiance_rating' => 'chill_cozy',
                            ]);
                        }
                    }
                }
            }
        } catch (Throwable $e) {
            error_log('SerpApi extraction error: ' . $e->getMessage());
        }
    } elseif ($apiKeyOutscraper !== '' && $contributorId !== null) {
        // 2. Live extraction via Outscraper User Profile Reviews
        try {
            $url = 'https://api.app.outscraper.com/maps/reviews-v3?' . http_build_query([
                'query' => "https://www.google.com/maps/contrib/{$contributorId}/reviews",
                'reviewsLimit' => 30,
                'async' => 'false',
            ]);
            $ctx = stream_context_create([
                'http' => [
                    'header' => "X-API-KEY: {$apiKeyOutscraper}\r\n",
                    'timeout' => 15,
                ],
            ]);
            $res = @file_get_contents($url, false, $ctx);
            if ($res) {
                $json = json_decode($res, true);
                $reviewsData = $json['data'][0]['reviews_data'] ?? [];
                $cafes = $pdo->query('SELECT id, name FROM cafe WHERE is_active = 1')->fetchAll();
                $insertStmt = $pdo->prepare('INSERT INTO cafe_google_review (
                    cafe_id, author_name, rating, review_text, publish_date, 
                    visit_context, must_try_item, food_quality_verdict, ambiance_rating
                ) VALUES (
                    :cafe_id, :author_name, :rating, :review_text, :publish_date,
                    :visit_context, :must_try_item, :food_quality_verdict, :ambiance_rating
                )');
                $checkStmt = $pdo->prepare('SELECT id FROM cafe_google_review 
                    WHERE cafe_id = :cafe_id AND author_name = :author_name AND review_text = :text LIMIT 1');

                foreach ($reviewsData as $rev) {
                    $uName = trim((string) ($rev['author_title'] ?? 'Google Contributor'));
                    $authorName = $uName;
                    $text = trim((string) ($rev['review_text'] ?? ''));
                    $ratingVal = max(1, min(5, (int) ($rev['review_rating'] ?? 5)));
                    $placeName = trim((string) ($rev['place_name'] ?? $rev['title'] ?? ''));

                    $matchedCafeId = null;
                    foreach ($cafes as $c) {
                        if ($placeName !== '' && (str_contains(mb_strtolower($placeName), mb_strtolower($c['name'])) || str_contains(mb_strtolower($c['name']), mb_strtolower($placeName)))) {
                            $matchedCafeId = $c['id'];
                            break;
                        }
                    }

                    if ($matchedCafeId && $text !== '') {
                        $checkStmt->execute([':cafe_id' => $matchedCafeId, ':author_name' => $uName, ':text' => $text]);
                        if (!$checkStmt->fetch()) {
                            $insertStmt->execute([
                                ':cafe_id' => $matchedCafeId,
                                ':author_name' => $uName,
                                ':rating' => $ratingVal,
                                ':review_text' => $text,
                                ':publish_date' => $rev['review_datetime_utc'] ?? 'Recently',
                                ':visit_context' => 'Google Maps Review',
                                ':must_try_item' => 'Specialty Coffee',
                                ':food_quality_verdict' => 'Recommended on Google',
                                ':ambiance_rating' => 'chill_cozy',
                            ]);
                        }
                    }
                }
            }
        } catch (Throwable $e) {
            error_log('Outscraper extraction error: ' . $e->getMessage());
        }
    }

    // 3. Return matching reviews found for this user in the catalogue
    return circle_find_google_matches($pdo, $authorName);
}

function circle_add_direct_review(
    PDO $pdo,
    string $circleId,
    string $cafeId,
    string $friendName,
    string $reviewText,
    int $rating = 5,
    string $mustTry = '',
    string $context = ''
): bool {
    circle_ensure_schema($pdo);
    $cleanText = trim($reviewText);
    $cleanName = trim($friendName);
    if ($cleanText === '' || $cleanName === '') {
        return false;
    }

    try {
        $stmt = $pdo->prepare('INSERT INTO friend_review (
            circle_id, cafe_id, friend_name, visit_context,
            food_quality_verdict, food_variety_rating, ambiance_rating,
            must_try_item, review_text, source_type, google_rating,
            is_verified_friend, visited_on
        ) VALUES (
            :circle_id, :cafe_id, :friend_name, :visit_context,
            :food_quality, :food_variety, :ambiance,
            :must_try, :notes, :source_type, :rating,
            1, CURRENT_DATE()
        )');

        return $stmt->execute([
            ':circle_id' => $circleId,
            ':cafe_id' => $cafeId,
            ':friend_name' => $cleanName,
            ':visit_context' => trim($context) !== '' ? trim($context) : 'Direct Circle Note',
            ':food_quality' => 'Recommended by friend',
            ':food_variety' => 'good',
            ':ambiance' => 'chill_cozy',
            ':must_try' => trim($mustTry) !== '' ? trim($mustTry) : 'House Specialty',
            ':notes' => $cleanText,
            ':source_type' => 'direct',
            ':rating' => max(1, min(5, $rating)),
        ]);
    } catch (Throwable $e) {
        error_log('Failed to add direct circle review: ' . $e->getMessage());
        return false;
    }
}


