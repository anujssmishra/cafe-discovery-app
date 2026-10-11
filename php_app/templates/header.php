<?php
$pageTitle = $pageTitle ?? (isset($errorTitle) ? $errorTitle . ' · Café discovery'
    : (is_array($cafe ?? null) ? $cafe['name'] . ' · Café discovery'
    : (($path ?? '') === 'about' ? 'About · Café discovery' : 'Explore cafés in your neighbourhood · Café discovery')));
$isCatalogue = ($path ?? '') === '' || ($path ?? '') === 'index.php';

$pageDesc = isset($cafe) && is_array($cafe)
    ? (!empty(trim((string) ($cafe['summary'] ?? ''))) ? trim((string) $cafe['summary']) : "Explore {$cafe['name']} in {$cafe['area_name']}, Lucknow. Verified drink offerings, ownership status, and turn-by-turn directions.")
    : (($path ?? '') === 'about'
        ? 'About the independent Café Discovery guide — verification methodology, provenance, and editorial standards.'
        : 'Discover independent specialty cafés and third-wave coffee roasters in your neighbourhood across Lucknow.');

$protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') || (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'myfanverse.in';
$canonicalUrl = $protocol . '://' . $host . ($_SERVER['REQUEST_URI'] ?? '/');
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= h($pageTitle) ?></title>
  <meta name="description" content="<?= h($pageDesc) ?>">
  <meta name="theme-color" content="#245339">
  <link rel="canonical" href="<?= h($canonicalUrl) ?>">

  <!-- Open Graph / WhatsApp / Facebook -->
  <meta property="og:type" content="<?= isset($cafe) && is_array($cafe) ? 'restaurant' : 'website' ?>">
  <meta property="og:site_name" content="Café Discovery">
  <meta property="og:url" content="<?= h($canonicalUrl) ?>">
  <meta property="og:title" content="<?= h($pageTitle) ?>">
  <meta property="og:description" content="<?= h($pageDesc) ?>">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="<?= h($pageTitle) ?>">
  <meta name="twitter:description" content="<?= h($pageDesc) ?>">

  <link rel="stylesheet" href="<?= h(app_url('/static/site.css')) ?>">
</head>
<body>
<a class="skip-link" href="#main-content">Skip to content</a>
<header class="site-header">
  <div class="header-inner">
    <a class="brand" href="<?= h(app_url('/')) ?>">Café discovery<span>A good place to begin</span></a>
    <nav aria-label="Main navigation">
      <a href="<?= h(app_url('/')) ?>"<?= $isCatalogue ? ' aria-current="page"' : '' ?>>Browse cafés</a>
      <a href="<?= h(app_url('/about/')) ?>"<?= ($path ?? '') === 'about' ? ' aria-current="page"' : '' ?>>About</a>
    </nav>
  </div>
</header>
<?php if ($config['demo_mode'] ?? false): ?>
<div class="demo-banner"><div class="page-shell">Demo mode: fictional sample cafés are clearly labelled.</div></div>
<?php endif; ?>
