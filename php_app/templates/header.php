<?php
$pageTitle = $pageTitle ?? (isset($errorTitle) ? $errorTitle . ' · Café discovery'
    : (is_array($cafe ?? null) ? $cafe['name'] . ' · Café discovery'
    : (($path ?? '') === 'about' ? 'About · Café discovery' : 'Explore cafés · Café discovery')));
$isCatalogue = ($path ?? '') === '' || ($path ?? '') === 'index.php';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= h($pageTitle) ?></title>
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
