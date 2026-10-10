<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require_once dirname(__DIR__) . '/includes/request.php';
$checks = 0;
function check(bool $ok, string $message): void
{
    global $checks;
    if (!$ok) { throw new RuntimeException($message); }
    $checks++;
}
set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});
try {
    $empty = catalogue_request([]);
    check($empty['q'] === '' && $empty['area'] === '' && $empty['page'] === 1 && $empty['errors'] === [], 'Default request');
    $valid = catalogue_request(['q' => ' café ', 'area' => 'sample-area', 'page' => '2']);
    check($valid['q'] === 'café' && $valid['area'] === 'sample-area' && $valid['page'] === 2 && $valid['errors'] === [], 'Valid Unicode request');
    foreach (['q', 'area', 'page'] as $key) {
        foreach ([[], ['unexpected'], new stdClass(), 2, null] as $value) {
            check(catalogue_request([$key => $value])['errors'] !== [], 'Reject nonscalar/nonstring ' . $key);
        }
        check(catalogue_request([$key => "\0invalid"])['errors'] !== [], 'Reject raw control ' . $key);
    }
    foreach (['-1', '1.2', '1e3', 'abc', '+1'] as $page) {
        check(catalogue_request(['page' => $page])['errors'] !== [], 'Reject page ' . $page);
    }
    check(catalogue_request(['page' => '0'])['page'] === 1, 'Zero clamps to first');
    $large = catalogue_request(['page' => str_repeat('9', 100)]);
    check($large['errors'] === [] && is_int($large['page']) && $large['page'] > 0, 'Huge page saturates');
    check(catalogue_request(['q' => str_repeat('é', 180)])['errors'] === [], '180 Unicode chars accepted');
    check(catalogue_request(['q' => str_repeat('é', 181)])['errors'] !== [], '181 Unicode chars rejected');
    check(catalogue_request(['q' => "\xff"])['errors'] !== [], 'Invalid UTF-8 rejected');
    foreach (['../x', 'Bad Area', '<script>', str_repeat('a', 141)] as $area) {
        check(catalogue_request(['area' => $area])['errors'] !== [], 'Reject malformed area');
    }
    check(valid_cafe_id('11111111-1111-4111-8111-111111111111'), 'Full UUID accepted');
    foreach (['', '11111111', '../secret', str_repeat('a', 36), '11111111-1111-4111-8111-111111111111extra'] as $id) {
        check(!valid_cafe_id($id), 'Malformed ID rejected');
    }
    fwrite(STDOUT, "Unit checks passed: {$checks}.\n");
} catch (Throwable $error) {
    fwrite(STDERR, 'FAIL: ' . $error->getMessage() . "\n");
    exit(1);
}
