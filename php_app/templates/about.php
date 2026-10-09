<?php require __DIR__ . '/header.php'; ?>
<main id="main-content" class="page-shell" tabindex="-1">
  <article class="prose panel">
    <p class="eyebrow">About the catalogue</p><h1>A place to start your café search</h1>
    <p>Explore cafés by name or area, then view their recorded details and offerings. The catalogue is a work in progress: opening hours, prices and ownership can change.</p>
    <h2>What the information means</h2>
    <p>Unknown information is shown as unknown. A recorded source or an earlier check does not guarantee that a café's details are current. Contact the café before making a special trip.</p>
    <?php if ($config['demo_mode'] ?? false): ?>
      <p class="notice">Demo mode includes clearly labelled fictional cafés and sample offerings for development. They are not recommendations or real businesses.</p>
    <?php endif; ?>
    <h2>What is available</h2>
    <p>You can browse, search, filter by area and open café details without an account, location access or JavaScript. Accounts, ratings, matching and maps are future work.</p>
    <a class="button" href="<?= h(app_url('/')) ?>">Browse cafés</a>
  </article>
</main>
<?php require __DIR__ . '/footer.php'; ?>
