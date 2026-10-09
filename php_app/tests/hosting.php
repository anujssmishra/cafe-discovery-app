<?php
declare(strict_types=1);

// Requires the local hosting profile after integration.php populated its _test DB.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if ($argc !== 2 || !in_array($argv[1], ['http://hosting', 'http://127.0.0.1:8081'], true)) {
    fwrite(STDERR, "Usage: php php_app/tests/hosting.php http://hosting (local ZIP fixture only)\n");
    exit(2);
}
$base = $argv[1];
$checks = 0;
function hosting_check(bool $condition, string $label): void
{
    global $checks;
    if (!$condition) { throw new RuntimeException($label); }
    $checks++;
}
function hosting_response(string $path, string $method = 'GET'): array
{
    global $base;
    $body = file_get_contents($base . $path, false, stream_context_create(['http' => [
        'method' => $method, 'header' => "Host: myfanverse.in\r\n", 'ignore_errors' => true,
        'follow_location' => 0, 'timeout' => 10,
    ]]));
    if ($body === false) { throw new RuntimeException('No local hosting response.'); }
    preg_match('/^HTTP\/\S+\s+(\d+)/', $http_response_header[0] ?? '', $match);
    return [(int) ($match[1] ?? 0), $body, implode("\n", $http_response_header)];
}
try {
    [$status, $body] = hosting_response('/');
    hosting_check($status === 200 && str_contains($body, 'Browse cafés'), 'Catalogue from private production config');
    hosting_check(!str_contains($body, 'Demo mode:') && !str_contains($body, 'Paper Lantern'), 'Production excludes demo catalogue');
    [$status, $body] = hosting_response('/?q=QA%20Match&area=qa-active&page=2');
    hosting_check($status === 200 && str_contains($body, 'QA Match 12') && !str_contains($body, 'QA Match 00'), 'Combined filters and page two under Apache');
    hosting_check(str_contains($body, 'q=QA%20Match&amp;area=qa-active&amp;page=3'), 'Pagination preserves filters at domain root');
    [$status, $body] = hosting_response('/cafes/90000000-0000-4000-8000-000000000000/');
    hosting_check($status === 200 && str_contains($body, 'QA Match 00'), 'Full UUID detail through .htaccess');
    hosting_check(str_contains($body, 'href="/static/site.css"') && str_contains($body, 'href="/about/"'), 'Root links and assets');
    [$status, $body] = hosting_response('/about/');
    hosting_check($status === 200 && str_contains($body, 'About'), 'About route');
    [$status, $body] = hosting_response('/?q=does-not-exist');
    hosting_check($status === 200 && str_contains($body, 'No cafés found'), 'Empty catalogue response');
    foreach (['/?q[]=bad', '/?area[]=bad', '/?page[]=bad'] as $path) {
        [$status, $body] = hosting_response($path);
        hosting_check($status === 400 && !preg_match('/Warning:|Fatal error:|Notice:/i', $body), 'Malformed query safely rejected');
    }
    foreach (['/cafes/not-a-uuid/', '/cafes/90000000-0000-4000-8000-999999999999/',
        '/cafes/90000000-0000-4000-8000-000000000100/', '/cafes/90000000-0000-4000-8000-000000000101/',
        '/cafes/b1833e2a-f772-50cc-8dfc-b08eb028fe04/'] as $path) {
        [$status] = hosting_response($path);
        hosting_check($status === 404, 'Missing/inactive/hidden/demo detail returns 404');
    }
    foreach (['/config/local.php', '/config/local.example.php', '/includes/config.php', '/scripts/schema.php',
        '/schema/schema.sql', '/release.json', '/.env', '/.htaccess'] as $path) {
        [$status, $body] = hosting_response($path);
        hosting_check(in_array($status, [403, 404], true) && !str_contains($body, 'local-demo-only'), 'Private file unavailable over HTTP');
    }
    [$status, $body, $headers] = hosting_response('/static/site.css');
    hosting_check($status === 200 && str_contains(strtolower($headers), 'content-type: text/css'), 'CSS served as stylesheet');
    [$status, $body] = hosting_response('/cafes/90000000-0000-4000-8000-000000000000/', 'HEAD');
    hosting_check($status === 200 && $body === '', 'HEAD detail response');
    [$status] = hosting_response('/', 'POST');
    hosting_check($status === 405, 'POST rejected');
    fwrite(STDOUT, "Local Hostinger-layout Apache checks passed: {$checks}.\n");
} catch (Throwable $error) {
    fwrite(STDERR, 'FAIL after ' . $checks . ': ' . $error->getMessage() . "\n");
    exit(1);
}
