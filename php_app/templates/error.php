<?php require __DIR__ . '/header.php'; ?>
<main id="main-content" class="page-shell" tabindex="-1">
  <section class="panel empty-state">
    <p class="eyebrow"><?= h($statusCode ?? 500) ?></p>
    <h1><?= h($errorTitle ?? 'Something went wrong') ?></h1>
    <p><?= h($errorMessage ?? 'Please try again later.') ?></p>
    <a class="button" href="<?= h(app_url('/')) ?>">Back to the catalogue</a>
  </section>
</main>
<?php require __DIR__ . '/footer.php'; ?>
