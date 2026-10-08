<?php
// php_app/templates/header.php
$pageTitle = $pageTitle ?? 'Café Discovery';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="A developing café discovery guide. Explore café details, drink offerings and the evidence behind each listing.">
  <title><?= htmlspecialchars($pageTitle) ?></title>
  <link rel="stylesheet" href="/static/site.css">
  <style>
    /* Basic reset & styles inherited from Django's site.css */
    body { font-family: sans-serif; line-height: 1.5; margin: 0; padding: 0; background: #f9f9f9; color: #333; }
    .shell { max-width: 1200px; margin: 0 auto; padding: 0 1rem; }
    .site-header { background: #fff; padding: 1rem 0; border-bottom: 1px solid #ddd; display: flex; align-items: center; justify-content: space-between; }
    .site-header .brand { text-decoration: none; color: #111; font-weight: bold; font-size: 1.25rem; }
    .site-header .brand-subtitle { display: block; font-size: 0.875rem; font-weight: normal; color: #555; }
    .main-nav a { margin-left: 1rem; text-decoration: none; color: #0056b3; }
    .main-nav a[aria-current="page"] { font-weight: bold; color: #111; text-decoration: underline; }
    .site-footer { margin-top: 3rem; padding: 2rem 0; border-top: 1px solid #ddd; font-size: 0.875rem; color: #666; display: flex; justify-content: space-between; }
    .button { display: inline-block; padding: 0.5rem 1rem; text-decoration: none; background: #eee; color: #333; border: 1px solid #ccc; border-radius: 4px; }
    .button-primary { background: #0056b3; color: #fff; border-color: #004494; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1rem; }
    .card { background: #fff; border: 1px solid #ddd; padding: 1rem; border-radius: 4px; }
    .badge { display: inline-block; padding: 0.2rem 0.5rem; font-size: 0.75rem; font-weight: bold; border-radius: 3px; background: #eee; }
    .badge-independent { background: #e8f5e9; color: #1b5e20; }
  </style>
  <?= $extraHead ?? '' ?>
</head>
<body>
  <a class="skip-link" href="#main-content" style="position: absolute; left: -9999px;">Skip to content</a>
  <header class="site-header shell">
      <a class="brand" href="/">
        <span>Café Discovery<span class="brand-subtitle">A place for your next pause</span></span>
      </a>
      <nav class="main-nav" aria-label="Main navigation">
        <a href="/" <?= ($path === '' || $path === 'index.php') ? 'aria-current="page"' : '' ?>>Explore cafés</a>
        <a href="#">About the guide</a>
      </nav>
  </header>
  
  <div class="build-notice"><div class="shell" style="background:#e3f2fd; padding:0.5rem; margin-top:1rem; font-size:0.875rem;">Early catalogue build – Information may be incomplete. Check the source and dates on each listing.</div></div>
  
  <main id="main-content" tabindex="-1" class="shell" style="margin-top: 2rem;">
