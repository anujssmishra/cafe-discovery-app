<?php
declare(strict_types=1);

/**
 * Sync Google Maps Reviews for Lucknow Cafes via Cloud Scraper API (Outscraper).
 *
 * Usage:
 *   CLI: php php_app/scripts/sync_google_reviews.php [--api-key=KEY] [--limit=15] [--dry-run]
 *   Web (Cron): https://myfanverse.in/sync_google_reviews.php?secret=SECRET_KEY
 */

$baseDir = dirname(__DIR__);
require_once $baseDir . '/includes/db.php';
require_once $baseDir . '/includes/circles.php';

$config = app_config();
$pdo = db_connect($config);

// Ensure the schema is active
circle_ensure_schema($pdo);

// Parse arguments
$apiKey = $config['outscraper_api_key'] ?? '';
$limit = 15;
$dryRun = false;
$cafeIdFilter = null;

if (PHP_SAPI === 'cli') {
    foreach (array_slice($argv, 1) as $arg) {
        if (str_starts_with($arg, '--api-key=')) {
            $apiKey = substr($arg, strlen('--api-key='));
        } elseif (str_starts_with($arg, '--limit=')) {
            $limit = max(1, (int) substr($arg, strlen('--limit=')));
        } elseif (str_starts_with($arg, '--cafe-id=')) {
            $cafeIdFilter = substr($arg, strlen('--cafe-id='));
        } elseif ($arg === '--dry-run') {
            $dryRun = true;
        }
    }
} else {
    // Web invocation requires a secret or admin key
    $secret = $_GET['secret'] ?? '';
    $cronSecret = getenv('CRON_SECRET') ?: ($config['db_pass'] ? substr(md5($config['db_pass']), 0, 16) : 'sync-lucknow-cafes');
    if ($secret !== $cronSecret) {
        http_response_code(403);
        echo "Access denied. Invalid cron secret.\n";
        exit;
    }
    if (isset($_GET['limit'])) {
        $limit = max(1, (int) $_GET['limit']);
    }
}

if ($apiKey === '') {
    echo "Error: Outscraper API key is required.\n";
    echo "Provide it via --api-key=YOUR_KEY or set OUTSCRAPER_API_KEY in config/local.php\n";
    echo "Get a free API key at: https://outscraper.com/ (500 free reviews/month)\n";
    exit(1);
}

// Fetch active cafes
$sql = 'SELECT c.id, c.name, a.name AS area_name, c.address 
        FROM cafe c 
        JOIN area a ON c.area_id = a.id 
        WHERE c.is_active = 1';
$params = [];

if ($cafeIdFilter !== null) {
    $sql .= ' AND c.id = :cid';
    $params[':cid'] = $cafeIdFilter;
}

$sql .= ' ORDER BY a.name, c.name';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$cafes = $stmt->fetchAll();

echo "Starting Google Reviews sync for " . count($cafes) . " cafes (Limit: {$limit} reviews/cafe)...\n\n";

$insertStmt = $pdo->prepare('INSERT INTO cafe_google_review (
    cafe_id, author_name, rating, review_text, publish_date, 
    visit_context, must_try_item, food_quality_verdict, ambiance_rating
) VALUES (
    :cafe_id, :author_name, :rating, :review_text, :publish_date,
    :visit_context, :must_try_item, :food_quality_verdict, :ambiance_rating
)');

$checkStmt = $pdo->prepare('SELECT id FROM cafe_google_review 
    WHERE cafe_id = :cafe_id AND author_name = :author_name AND review_text = :review_text 
    LIMIT 1');

$totalInserted = 0;
$totalSkipped = 0;
$totalFetched = 0;

foreach ($cafes as $index => $cafe) {
    $step = $index + 1;
    $query = "{$cafe['name']}, {$cafe['area_name']}, Lucknow";
    echo "[{$step}/" . count($cafes) . "] {$cafe['name']} ({$cafe['area_name']})... ";

    $url = 'https://api.app.outscraper.com/maps/reviews-v3?' . http_build_query([
        'query' => $query,
        'reviewsLimit' => $limit,
        'async' => 'false',
        'language' => 'en',
    ]);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'X-API-KEY: ' . $apiKey,
        'Accept: application/json',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200 || !$response) {
        echo "FAILED (HTTP {$httpCode})\n";
        continue;
    }

    $json = json_decode((string) $response, true);
    if (!isset($json['data'][0])) {
        echo "No data returned.\n";
        continue;
    }

    $reviewsData = [];
    if (isset($json['data'][0]['reviews_data'])) {
        $reviewsData = $json['data'][0]['reviews_data'];
    } elseif (isset($json['data'][0][0]['reviews_data'])) {
        $reviewsData = $json['data'][0][0]['reviews_data'];
    }

    $cafeFetched = count($reviewsData);
    $cafeInserted = 0;
    $cafeSkipped = 0;

    foreach ($reviewsData as $rev) {
        $authorName = trim((string) ($rev['author_title'] ?? $rev['author_name'] ?? 'Google Reviewer'));
        $rating = max(1, min(5, (int) ($rev['review_rating'] ?? 5)));
        $text = trim((string) ($rev['review_text'] ?? ''));
        $publishDate = (string) ($rev['review_datetime_utc'] ?? ($rev['review_timestamp'] ? date('Y-m-d', (int) $rev['review_timestamp']) : 'Recently'));

        if ($text === '') {
            continue;
        }

        // Check if duplicate
        $checkStmt->execute([
            ':cafe_id' => $cafe['id'],
            ':author_name' => $authorName,
            ':review_text' => $text,
        ]);

        if ($checkStmt->fetch()) {
            $cafeSkipped++;
            continue;
        }

        if (!$dryRun) {
            $insertStmt->execute([
                ':cafe_id' => $cafe['id'],
                ':author_name' => $authorName,
                ':rating' => $rating,
                ':review_text' => $text,
                ':publish_date' => $publishDate,
                ':visit_context' => 'Google Maps Review',
                ':must_try_item' => null,
                ':food_quality_verdict' => $rating >= 4 ? 'Recommended on Google' : null,
                ':ambiance_rating' => 'chill_cozy',
            ]);
        }
        $cafeInserted++;
    }

    $totalFetched += $cafeFetched;
    $totalInserted += $cafeInserted;
    $totalSkipped += $cafeSkipped;

    echo "Fetched {$cafeFetched}, Inserted {$cafeInserted}, Skipped {$cafeSkipped}\n";
    
    // Polite delay between API queries
    usleep(250000); // 0.25s
}

echo "\n------------------------------------------------------------\n";
echo "Sync Complete!" . ($dryRun ? " [DRY RUN]" : "") . "\n";
echo "Total Fetched: {$totalFetched}\n";
echo "Total Inserted: {$totalInserted}\n";
echo "Total Skipped (Duplicates): {$totalSkipped}\n";
echo "------------------------------------------------------------\n";
