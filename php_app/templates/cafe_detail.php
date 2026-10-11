<?php
require_once __DIR__ . '/_evidence.php';
require __DIR__ . '/header.php';
$isDemo = (bool) ($cafe['is_demo'] ?? false);
$verification = catalogue_evidence($cafe['source'] ?? null, $cafe['checked_on'] ?? null, $isDemo);
$ownershipEvidence = catalogue_evidence($cafe['independence_source'] ?? null, $cafe['independence_checked_on'] ?? null, $isDemo);
$brandEvidence = catalogue_evidence($cafe['brand_count_source'] ?? null, $cafe['brand_count_checked_on'] ?? null, $isDemo);
$website = (string) ($cafe['website'] ?? '');
$websiteAllowed = !$isDemo && filter_var($website, FILTER_VALIDATE_URL)
    && in_array(strtolower((string) parse_url($website, PHP_URL_SCHEME)), ['http', 'https'], true)
    && parse_url($website, PHP_URL_USER) === null && parse_url($website, PHP_URL_PASS) === null;
$hasCoordinates = isset($cafe['latitude'], $cafe['longitude'])
    && is_numeric($cafe['latitude']) && is_numeric($cafe['longitude']);
$directionsUrl = $hasCoordinates
    ? 'https://www.google.com/maps/dir/?api=1&destination=' . rawurlencode($cafe['latitude'] . ',' . $cafe['longitude'])
    : 'https://www.google.com/maps/search/?api=1&query=' . rawurlencode($cafe['name'] . ', ' . ($cafe['address'] ?? '') . ', ' . ($cafe['area_name'] ?? ''));
$priceBandLabels = [
    'budget' => '₹ Budget (typically under ₹150 per person)',
    'moderate' => '₹₹ Moderate (typically ₹150–₹300 per person)',
    'premium' => '₹₹₹ Premium (typically ₹300+ per person)',
];
?>
<main id="main-content" class="page-shell" tabindex="-1">
  <a class="back-link" href="<?= h(app_url('/')) ?>"><span aria-hidden="true">← </span>Back to the catalogue</a>
  <article>
    <header class="detail-heading">
      <p class="eyebrow"><?= h($cafe['area_name']) ?><?= empty($cafe['area_city']) ? '' : ' · ' . h($cafe['area_city']) ?></p>
      <h1><?= h($cafe['name']) ?></h1>
      <?php if ($isDemo): ?><span class="badge">Fictional demo</span><?php endif; ?>
      <p class="intro-copy"><?= h(trim((string) ($cafe['summary'] ?? '')) !== '' ? $cafe['summary'] : 'More details are not recorded yet.') ?></p>
    </header>

    <?php if ($isDemo): ?>
      <p class="notice">This is fictional development data. This café and its offerings do not represent a real business.</p>
    <?php endif; ?>

    <!-- Ambiance, Vibes, Food & Price Bar -->
    <div class="detail-atmosphere-bar panel">
      <?php if (!empty($cafe['price_band'])): ?>
        <div class="atmosphere-item">
          <span class="atmosphere-label">Spend Tier</span>
          <span class="price-band-badge price-<?= h($cafe['price_band']) ?>">
            <?= h($priceBandLabels[$cafe['price_band']] ?? ucfirst($cafe['price_band'])) ?>
          </span>
        </div>
      <?php endif; ?>
      <?php if (!empty($cafe['vibe_tags'])): ?>
        <div class="atmosphere-item">
          <span class="atmosphere-label">Vibe & Ambiance</span>
          <div class="vibe-tags-container">
            <?php foreach (array_map('trim', explode(',', $cafe['vibe_tags'])) as $vTag): ?>
              <span class="vibe-tag"><?= h($vTag) ?></span>
            <?php endforeach; ?>
          </div>
        </div>
      <?php endif; ?>
      <?php if (!empty($cafe['food_highlights'])): ?>
        <div class="atmosphere-item">
          <span class="atmosphere-label">Food & Bakery</span>
          <span class="food-highlight-text"><span aria-hidden="true">🥐 </span><?= h($cafe['food_highlights']) ?></span>
        </div>
      <?php endif; ?>
    </div>

    <div class="detail-grid">
      <!-- Left Column: Details & Verification -->
      <section class="panel">
        <h2>Café details</h2>
        <dl class="details-list">
          <div><dt>Address</dt><dd class="address-container"><?php if (trim((string) ($cafe['address'] ?? '')) !== ''): ?><a class="address-link" href="<?= h($directionsUrl) ?>" target="_blank" rel="noopener noreferrer"><?= h($cafe['address']) ?></a><a class="mini-btn" href="<?= h($directionsUrl) ?>" target="_blank" rel="noopener noreferrer" title="Open in Maps"><span aria-hidden="true">📍 </span>Open in Maps ↗</a><?php else: ?>Unknown<?php endif; ?></dd></div>
          <?php if ($hasCoordinates): ?><div><dt>Location coordinates</dt><dd class="muted"><?= h($cafe['latitude']) ?>, <?= h($cafe['longitude']) ?></dd></div><?php endif; ?>
          <div><dt>Ownership</dt><dd><?= h(catalogue_ownership($cafe)) ?></dd></div>
          <div><dt>Ownership source</dt><dd><?= h($ownershipEvidence['source'] !== '' ? $ownershipEvidence['source'] : 'Unknown') ?><?php if (!$ownershipEvidence['complete']): ?> <span class="muted">(no documented verification)</span><?php endif; ?></dd></div>
          <div><dt>Brand location count</dt><dd><?php $brandCount = $cafe['brand_location_count'] ?? null; ?><?= $brandCount !== null && ctype_digit((string) $brandCount) && $brandEvidence['complete'] ? h($brandCount) . ' · recorded ' . h($brandEvidence['date']) : 'Unknown' ?></dd></div>
          <div><dt>Catalogue source</dt><dd><?= h($verification['source'] !== '' ? $verification['source'] : 'Unknown') ?></dd></div>
          <div><dt>Verification</dt><dd><?php if ($verification['complete']): ?><?= $verification['current'] ? 'Checked ' : 'Historical check: ' ?><?= h($verification['date']) ?><?php else: ?>Unknown — no documented verification<?php endif; ?></dd></div>
          <?php if ($verification['date'] !== null && !$verification['complete']): ?><div><dt>Recorded check date</dt><dd><?= h($verification['date']) ?> <span class="muted">(evidence incomplete)</span></dd></div><?php endif; ?>
        </dl>
        <?php if ($websiteAllowed): ?>
          <div class="detail-actions">
            <a class="button button-secondary" href="<?= h($website) ?>" target="_blank" rel="noopener noreferrer">Café website</a>
          </div>
        <?php endif; ?>
      </section>

      <!-- Right Column: Drink Offerings -->
      <section class="panel offerings-panel">
        <h2>Recorded offerings</h2>
        <p class="muted">Prices and availability can change. Unknown prices are shown explicitly.</p>
        <?php if (!$offerings): ?>
          <p class="empty-copy">No offerings have been recorded yet.</p>
        <?php else: ?>
          <div class="table-scroll" tabindex="0" role="region" aria-label="Recorded offerings table">
            <table>
              <caption class="sr-only">Drinks, brewing methods, prices and verification</caption>
              <thead><tr><th scope="col">Drink</th><th scope="col">Method</th><th scope="col">Price</th><th scope="col">Evidence</th></tr></thead>
              <tbody>
                <?php foreach ($offerings as $offering): ?>
                  <?php $offeringEvidence = catalogue_evidence($offering['source'] ?? null, $offering['checked_on'] ?? null, $isDemo); ?>
                  <tr>
                    <th scope="row"><?= h(trim((string) ($offering['drink_type'] ?? '')) !== '' ? str_replace('_', ' ', $offering['drink_type']) : 'Unknown') ?></th>
                    <td><?= h(trim((string) ($offering['brewing_method'] ?? '')) !== '' ? $offering['brewing_method'] : 'Unknown') ?></td>
                    <td class="price"><?php if (($offering['price'] ?? null) === null): ?>Unknown<?php else: ?><?= h(trim((string) ($offering['currency'] ?? '')) !== '' ? $offering['currency'] : 'Currency unknown') ?> <?= h(number_format((float) $offering['price'], 2, '.', '')) ?><?php endif; ?></td>
                    <td><?php if ($offeringEvidence['complete']): ?><?= h($offeringEvidence['source']) ?><br><span class="muted"><?= $offeringEvidence['current'] ? 'Checked ' : 'Historical check: ' ?><?= h($offeringEvidence['date']) ?></span><?php else: ?>Unknown<?php if ($offeringEvidence['source'] !== ''): ?><br><span class="muted">Recorded source: <?= h($offeringEvidence['source']) ?>; evidence incomplete</span><?php endif; ?><?php endif; ?></td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>
      </section>
    </div>

    <!-- Friends' Take Section -->
    <section class="panel friends-take-section">
      <div class="section-header">
        <div class="section-title-group">
          <span class="section-icon" aria-hidden="true">👥</span>
          <h2>Friends' Take</h2>
        </div>
        <span class="private-badge">Private Circle Notes</span>
      </div>
      <p class="section-subtitle">Real experiences and notes from your circle. No commercial star ratings, sponsored reviews, or bot inflation.</p>

      <?php if (empty($friendReviews)): ?>
        <p class="empty-copy">No notes recorded from your circle for this café yet.</p>
      <?php else: ?>
        <div class="friend-reviews-list">
          <?php foreach ($friendReviews as $review): ?>
            <article class="friend-review-card">
              <header class="review-header">
                <div class="reviewer-meta">
                  <strong class="friend-name"><?= h($review['friend_name']) ?></strong>
                  <span class="verified-friend-pill">✓ Circle</span>
                  <?php if (!empty($review['visit_context'])): ?>
                    <span class="visit-context">· <?= h($review['visit_context']) ?></span>
                  <?php endif; ?>
                </div>
                <?php if (!empty($review['visited_on'])): ?>
                  <time class="visited-date" datetime="<?= h($review['visited_on']) ?>"><?= date('M Y', strtotime($review['visited_on'])) ?></time>
                <?php endif; ?>
              </header>

              <?php if (!empty($review['must_try_item'])): ?>
                <div class="must-try-box">
                  <span class="must-try-label">⭐ Must-Order:</span>
                  <strong class="must-try-val"><?= h($review['must_try_item']) ?></strong>
                </div>
              <?php endif; ?>

              <div class="review-verdicts">
                <?php if (!empty($review['food_quality_verdict'])): ?>
                  <div class="verdict-item">
                    <span class="verdict-label">🥐 Food Quality:</span>
                    <span><?= h($review['food_quality_verdict']) ?></span>
                    <?php if (!empty($review['food_variety_rating'])): ?>
                      <span class="variety-pill"><?= h(ucfirst($review['food_variety_rating'])) ?> variety</span>
                    <?php endif; ?>
                  </div>
                <?php endif; ?>
                <?php if (!empty($review['ambiance_rating'])): ?>
                  <div class="verdict-item">
                    <span class="verdict-label">✨ Vibe:</span>
                    <span><?= h(ucwords(str_replace('_', ' ', $review['ambiance_rating']))) ?></span>
                  </div>
                <?php endif; ?>
              </div>

              <div class="review-content">
                <p><?= nl2br(h($review['review_text'])) ?></p>
              </div>
            </article>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </section>
  </article>
</main>
<?php require __DIR__ . '/footer.php'; ?>
