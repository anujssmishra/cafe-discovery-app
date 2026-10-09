<?php
declare(strict_types=1);

function catalogue_evidence(mixed $source, mixed $date, bool $demo = false): array
{
    $source = is_string($source) ? trim($source) : '';
    $date = is_string($date) ? trim($date) : '';
    $generic = ['', 'unknown', 'unverified', 'web research', 'menu', 'not recorded', 'n/a'];
    $documented = !$demo && !in_array(strtolower($source), $generic, true)
        && !str_contains(strtolower($source), 'synthetic') && !str_contains(strtolower($source), 'fictional');
    $checked = preg_match('/^\d{4}-\d{2}-\d{2}$/D', $date) ? DateTimeImmutable::createFromFormat('!Y-m-d', $date) : false;
    $validDate = $checked !== false && $checked->format('Y-m-d') === $date;
    $today = new DateTimeImmutable('today');
    $complete = $documented && $validDate && $checked <= $today;
    $current = $complete && $checked >= $today->modify('-30 days');
    return ['source' => $source, 'date' => $validDate ? $date : null, 'complete' => $complete, 'current' => $current];
}

function catalogue_ownership(array $cafe): string
{
    $evidence = catalogue_evidence($cafe['independence_source'] ?? null, $cafe['independence_checked_on'] ?? null, (bool) ($cafe['is_demo'] ?? false));
    $kind = match ($cafe['independence_status'] ?? 'unknown') {
        'verified_independent' => 'Independent',
        'verified_not_independent' => 'Not independent',
        default => null,
    };
    if ($kind === null || !$evidence['complete']) { return 'Unknown'; }
    return $evidence['current'] ? $kind . ' · checked ' . $evidence['date']
        : 'Historical record: ' . $kind . ' · ' . $evidence['date'];
}
