<?php
require_once __DIR__ . '/_evidence.php';
require __DIR__ . '/header.php';
$knownArea = $areaFilter === '';
foreach ($areas as $area) {
    if ((string) $area['slug'] === $areaFilter) { $knownArea = true; }
}
$pageQuery = array_filter(['q' => $searchQuery, 'area' => $areaFilter, 'vibe' => $vibeFilter], static fn($value) => $value !== '');
?>
<main id="main-content" class="page-shell" tabindex="-1">
  <section class="catalogue-intro">
    <p class="eyebrow">Find your next coffee stop</p>
    <h1>Explore cafés, one neighbourhood at a time.</h1>
    <p class="intro-copy">Search by name, neighbourhood, or vibe. Open a café to see food highlights, indicative prices, and recommendations from your circle.</p>
  </section>
  <form class="filter-form panel" method="get" action="<?= h(app_url('/')) ?>">
    <div class="form-field"><label for="search">Search by café name</label><input id="search" name="q" type="search" maxlength="180" value="<?= h($searchQuery) ?>" placeholder="Try a café name" aria-describedby="search-help"><small id="search-help">Part of a name works too.</small></div>
    <div class="form-field"><label for="area">Area</label><select id="area" name="area"><option value="">All areas</option><?php foreach ($areas as $area): ?><option value="<?= h($area['slug']) ?>"<?= $areaFilter === (string) $area['slug'] ? ' selected' : '' ?>><?= h($area['name']) ?><?= empty($area['city']) ? '' : ' · ' . h($area['city']) ?></option><?php endforeach; ?><?php if (!$knownArea): ?><option value="<?= h($areaFilter) ?>" selected>Unknown area filter</option><?php endif; ?></select></div>
    <div class="form-field"><label for="vibe">Vibe & mood</label><select id="vibe" name="vibe"><option value="">All vibes & moods</option><?php foreach ($vibes as $key => $opt): ?><option value="<?= h($key) ?>"<?= $vibeFilter === $key ? ' selected' : '' ?>><?= h($opt['label']) ?></option><?php endforeach; ?></select></div>
    <button type="submit" class="button">Find cafés</button>
    <a class="text-link" href="<?= h(app_url('/')) ?>">Clear filters</a>
  </form>
  <?php if ($errors): ?>
    <section class="notice validation-errors" aria-labelledby="validation-title"><h2 id="validation-title">Check your filters</h2><ul><?php foreach ($errors as $error): ?><li><?= h($error) ?></li><?php endforeach; ?></ul></section>
  <?php endif; ?>
  <?php if (!$errors): ?>
    <div class="results-heading"><h2><?= h($pagination['total']) ?> <?= (int) $pagination['total'] === 1 ? 'café' : 'cafés' ?> found</h2><?php if ((int) $pagination['total'] > 0): ?><p>Page <?= h($pagination['page']) ?> of <?= h($pagination['pages']) ?></p><?php endif; ?></div>
    <?php if (!$cafes): ?>
      <section class="panel empty-state"><h3>No cafés found</h3><p>Try a different name, area, or vibe, or clear the filters to browse the catalogue.</p><a class="button" href="<?= h(app_url('/')) ?>">Clear filters</a></section>
    <?php else: ?>
      <div class="cafe-grid">
        <?php foreach ($cafes as $item): ?>
          <?php
          $itemWebsite = (string) ($item['website'] ?? '');
          $itemWebsiteAllowed = !($item['is_demo'] ?? false) && filter_var($itemWebsite, FILTER_VALIDATE_URL)
              && in_array(strtolower((string) parse_url($itemWebsite, PHP_URL_SCHEME)), ['http', 'https'], true)
              && parse_url($itemWebsite, PHP_URL_USER) === null && parse_url($itemWebsite, PHP_URL_PASS) === null;
          ?>
          <article class="cafe-card panel">
            <div class="card-topline">
              <p class="eyebrow"><?= h($item['area_name']) ?><?= empty($item['area_city']) ? '' : ' · ' . h($item['area_city']) ?></p>
              <div class="card-pills">
                <?php if (!empty($item['friend_review_count']) && (int) $item['friend_review_count'] > 0): ?>
                  <span class="circle-pill" title="Reviewed by friends">👥 Circle pick</span>
                <?php endif; ?>
                <?php if (!empty($item['price_band'])): ?>
                  <span class="price-band-badge price-<?= h($item['price_band']) ?>" title="Spend tier: <?= h(ucfirst($item['price_band'])) ?>">
                    <?= $item['price_band'] === 'budget' ? '₹' : ($item['price_band'] === 'premium' ? '₹₹₹' : '₹₹') ?>
                  </span>
                <?php endif; ?>
                <?php if ($item['is_demo'] ?? false): ?><span class="badge">Demo</span><?php endif; ?>
              </div>
            </div>
            <div class="card-title-row">
              <h3><a href="<?= h(app_url('/cafes/' . $item['id'] . '/')) ?>"><?= h($item['name']) ?></a></h3>
              <?php if ($itemWebsiteAllowed): ?>
                <a class="card-website-btn" href="<?= h($itemWebsite) ?>" target="_blank" rel="noopener noreferrer" title="Official website: <?= h($item['name']) ?>"><span aria-hidden="true">🌐 </span>Website ↗</a>
              <?php endif; ?>
            </div>
            <?php if (trim((string) ($item['summary'] ?? '')) !== '' && $item['summary'] !== 'More details are not recorded yet.'): ?>
              <p class="card-summary"><?= h($item['summary']) ?></p>
            <?php endif; ?>
            <?php if (!empty($item['vibe_tags'])): ?>
              <div class="vibe-tags-container">
                <?php foreach (array_map('trim', explode(',', $item['vibe_tags'])) as $vTag): ?>
                  <span class="vibe-tag"><?= h($vTag) ?></span>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
            <?php if (!empty($item['food_highlights'])): ?>
              <p class="card-food-line"><span aria-hidden="true">🥐 </span><strong>Food:</strong> <?= h($item['food_highlights']) ?></p>
            <?php endif; ?>
            <?php if (!empty($item['friend_review_count']) && (int) $item['friend_review_count'] > 0): ?>
              <p class="friend-take-indicator"><span aria-hidden="true">👥 </span><strong>Friends' Take:</strong> <?= (int) $item['friend_review_count'] ?> <?= (int) $item['friend_review_count'] === 1 ? 'review' : 'reviews' ?> from your circle</p>
            <?php endif; ?>
            <?php
            $itemCoords = isset($item['latitude'], $item['longitude']) && is_numeric($item['latitude']) && is_numeric($item['longitude']);
            $itemMapUrl = $itemCoords
                ? 'https://www.google.com/maps/dir/?api=1&destination=' . rawurlencode($item['latitude'] . ',' . $item['longitude'])
                : 'https://www.google.com/maps/search/?api=1&query=' . rawurlencode($item['name'] . ', ' . ($item['address'] ?? '') . ', ' . ($item['area_name'] ?? ''));
            ?>
            <p class="address address-container"><?php if (trim((string) ($item['address'] ?? '')) !== ''): ?><a class="address-link" href="<?= h($itemMapUrl) ?>" target="_blank" rel="noopener noreferrer"><?= h($item['address']) ?></a><a class="mini-btn" href="<?= h($itemMapUrl) ?>" target="_blank" rel="noopener noreferrer" title="Open in Maps"><span aria-hidden="true">📍 </span>Maps ↗</a><?php else: ?>Address not recorded<?php endif; ?></p>
            <p class="evidence-line"><span>Ownership:</span> <?= h(catalogue_ownership($item)) ?></p>
            <a class="detail-link" href="<?= h(app_url('/cafes/' . $item['id'] . '/')) ?>">View details<span class="sr-only"> for <?= h($item['name']) ?></span><span aria-hidden="true"> →</span></a>
          </article>
        <?php endforeach; ?>
      </div>
      <?php if ((int) $pagination['pages'] > 1): ?>
        <nav class="pagination" aria-label="Catalogue pages">
          <?php if ((int) $pagination['page'] > 1): ?><a class="button button-secondary" rel="prev" href="<?= h(app_url('/', array_merge($pageQuery, ['page' => (int) $pagination['page'] - 1]))) ?>">Previous page</a><?php endif; ?>
          <span aria-current="page">Page <?= h($pagination['page']) ?> of <?= h($pagination['pages']) ?></span>
          <?php if ((int) $pagination['page'] < (int) $pagination['pages']): ?><a class="button button-secondary" rel="next" href="<?= h(app_url('/', array_merge($pageQuery, ['page' => (int) $pagination['page'] + 1]))) ?>">Next page</a><?php endif; ?>
        </nav>
      <?php endif; ?>
    <?php endif; ?>
  <?php endif; ?>
</main>
<script>
document.addEventListener('DOMContentLoaded', () => {
  const searchInput = document.getElementById('search');
  const areaSelect = document.getElementById('area');
  const vibeSelect = document.getElementById('vibe');
  const form = document.querySelector('.filter-form');
  if (!searchInput || !form) return;

  let debounceTimer = null;

  function performLiveSearch() {
    const url = new URL(form.action || window.location.href);
    const formData = new FormData(form);
    const params = new URLSearchParams();
    for (const [key, val] of formData.entries()) {
      if (val.trim() !== '') params.set(key, val);
    }
    url.search = params.toString();

    fetch(url.toString())
      .then(res => res.text())
      .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const newMain = doc.querySelector('#main-content');
        const currentMain = document.querySelector('#main-content');
        if (newMain && currentMain) {
          const selStart = searchInput.selectionStart;
          const selEnd = searchInput.selectionEnd;

          const oldNodes = currentMain.querySelectorAll('.results-heading, .cafe-grid, .pagination, .empty-state, .notice');
          oldNodes.forEach(node => node.remove());

          const newNodes = newMain.querySelectorAll('.results-heading, .cafe-grid, .pagination, .empty-state, .notice');
          let anchor = form;
          newNodes.forEach(node => {
            anchor.after(node);
            anchor = node;
          });

          window.history.replaceState({}, '', url.toString());
          searchInput.focus();
          searchInput.setSelectionRange(selStart, selEnd);
        }
      })
      .catch(() => {});
  }

  searchInput.addEventListener('input', () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(performLiveSearch, 250);
  });

  areaSelect?.addEventListener('change', performLiveSearch);
  vibeSelect?.addEventListener('change', performLiveSearch);
});
</script>
<?php require __DIR__ . '/footer.php'; ?>
