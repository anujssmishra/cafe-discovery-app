<?php
declare(strict_types=1);

/** Reject compound query values before trimming, SQL binding or rendering. */
function catalogue_request(array $query): array
{
    $errors = [];
    $values = ['q' => '', 'area' => '', 'vibe' => '', 'page' => '1'];
    foreach ($values as $key => $default) {
        if (!array_key_exists($key, $query)) {
            continue;
        }
        if (!is_string($query[$key])) {
            $errors[] = ucfirst($key) . ' must be a single text value.';
            continue;
        }
        if (preg_match('/[\x00-\x1F\x7F]/', $query[$key])) {
            $errors[] = ucfirst($key) . ' must not contain control characters.';
            continue;
        }
        $values[$key] = trim($query[$key]);
    }
    if (strlen($values['q']) > 720 || !preg_match('//u', $values['q'])
        || preg_match('/[\x00-\x1F\x7F]/', $values['q'])) {
        $errors[] = 'Search must contain valid text of at most 180 characters.';
        $values['q'] = '';
    } elseif (preg_match_all('/./us', $values['q']) > 180) {
        $errors[] = 'Search must contain at most 180 characters.';
        $values['q'] = '';
    }
    if ($values['area'] !== '' && !preg_match('/^[a-z0-9]+(?:-[a-z0-9]+)*$/D', $values['area'])) {
        $errors[] = 'Choose a valid area.';
        $values['area'] = '';
    } elseif (strlen($values['area']) > 140) {
        $errors[] = 'Choose a valid area.';
        $values['area'] = '';
    }
    if ($values['vibe'] !== '' && !preg_match('/^[a-z0-9-]+$/D', $values['vibe'])) {
        $errors[] = 'Choose a valid vibe.';
        $values['vibe'] = '';
    } elseif (strlen($values['vibe']) > 50) {
        $errors[] = 'Choose a valid vibe.';
        $values['vibe'] = '';
    }
    if ($values['page'] === '' || !ctype_digit($values['page'])) {
        $errors[] = 'Page must be a positive whole number.';
        $values['page'] = '1';
    }
    // Saturate before conversion to avoid integer overflow from arbitrarily large inputs.
    $digits = ltrim($values['page'], '0');
    $page = strlen($digits) > 9 ? 1000000000 : max(1, (int) $digits);
    return ['q' => $values['q'], 'area' => $values['area'], 'vibe' => $values['vibe'], 'page' => $page, 'errors' => $errors];
}

function valid_cafe_id(string $id): bool
{
    return preg_match('/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/iD', $id) === 1;
}
