<?php
declare(strict_types=1);

function h(mixed $value): string
{
    return htmlspecialchars((string) ($value ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** All paths passed here are application paths, never user-supplied destinations. */
function app_url(string $path = '/', array $query = []): string
{
    global $config;
    $url = ($config['base_path'] ?? '') . '/' . ltrim($path, '/');
    return $query === [] ? $url : $url . '?' . http_build_query($query, '', '&', PHP_QUERY_RFC3986);
}
