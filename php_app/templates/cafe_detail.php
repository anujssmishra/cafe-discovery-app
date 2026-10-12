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
      <div class="detail-title-row">
        <h1><?= h($cafe['name']) ?></h1>
        <?php if ($websiteAllowed): ?>
          <a class="header-website-btn" href="<?= h($website) ?>" target="_blank" rel="noopener noreferrer" title="Official website for <?= h($cafe['name']) ?>"><span aria-hidden="true">🌐 </span>Visit Website ↗</a>
        <?php endif; ?>
      </div>
      <?php if ($isDemo): ?><span class="badge">Fictional demo</span><?php endif; ?>
      <?php if (trim((string) ($cafe['summary'] ?? '')) !== '' && $cafe['summary'] !== 'More details are not recorded yet.'): ?>
        <p class="intro-copy"><?= h($cafe['summary']) ?></p>
      <?php endif; ?>
    </header>

    <?php
    $heroUrl = !empty($cafe['hero_image_url']) ? $cafe['hero_image_url'] : (!empty($cafe['photo_url']) ? $cafe['photo_url'] : '');
    ?>
    <?php if (!empty($heroUrl)): ?>
      <div class="detail-hero-banner">
        <img class="detail-hero-img" src="<?= h($heroUrl) ?>" alt="<?= h($cafe['name']) ?>" loading="eager" width="1200" height="360">
      </div>
    <?php endif; ?>

    <?php if ($isDemo): ?>
      <p class="notice">This is fictional development data. This café and its offerings do not represent a real business.</p>
    <?php endif; ?>

    <!-- Friends' Take Section (Placed at the top) -->
    <section class="panel friends-take-section" id="friends-take">
      <div class="section-header">
        <div class="section-title-group">
          <span class="section-icon" aria-hidden="true">👥</span>
          <h2>Friends' Take</h2>
        </div>
        <a class="private-badge" href="<?= h(app_url('/circles/')) ?>" style="text-decoration:none;" title="Manage your circle">Circle: <?= h($session['circle_name'] ?? 'Private Circle') ?> ⚙</a>
      </div>
      <p class="section-subtitle">Real experiences and notes from your circle. No commercial star ratings, sponsored reviews, or bot inflation.</p>

      <?php if (!empty($message)): ?>
        <div class="notice" style="background:#e8f5e9; border-color:#81c784; color:#1b5e20; margin-bottom:1.25rem;">
          <p style="margin:0; font-weight:650;">✓ <?= h($message) ?></p>
        </div>
      <?php endif; ?>

      <?php if (empty($friendReviews)): ?>
        <div class="friend-empty-box">
          <p class="empty-copy">No notes recorded from your circle for this café yet.</p>
          <p class="empty-hint">Visited this spot? Have a Google Maps review? <a href="<?= h(app_url('/circles/')) ?>">Auto-match your Google review</a> or post a quick note below.</p>
        </div>
      <?php else: ?>
        <div class="friend-reviews-list">
          <?php foreach ($friendReviews as $review): ?>
            <article class="friend-review-card">
              <header class="review-header">
                <div class="reviewer-meta">
                  <strong class="friend-name"><?= h($review['friend_name']) ?></strong>
                  <?php if (($review['source_type'] ?? '') === 'google_matched'): ?>
                    <span class="verified-friend-pill" style="color:#1a73e8; background:#e8f0fe; border-color:#d2e3fc;">✓ Google Match<?= !empty($review['google_rating']) ? ' · ⭐ ' . (int) $review['google_rating'] . '★' : '' ?></span>
                  <?php else: ?>
                    <span class="verified-friend-pill">✓ Circle</span>
                  <?php endif; ?>
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

      <!-- Inline Circle Note Submission Form -->
      <div class="inline-note-form-box">
        <h3 style="font-size:1.1rem; margin-bottom:0.3rem;"><span aria-hidden="true">✍️ </span>Add a Note to Your Circle</h3>
        <p class="muted" style="margin-bottom:1rem; font-size:0.85rem;">Post your recommendation or order tips directly to <strong><?= h($session['circle_name'] ?? 'Lucknow Coffee Circle') ?></strong>.</p>

        <form method="post" action="<?= h(app_url('/cafes/' . $cafe['id'] . '/note')) ?>" class="inline-review-form">
          <input type="hidden" name="cafe_id" value="<?= h($cafe['id']) ?>">
          <div class="inline-note-form-grid">
            <div class="form-field">
              <label for="note-friend-name">Your Name</label>
              <input id="note-friend-name" name="friend_name" type="text" maxlength="80" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : '') ?>" placeholder="e.g. Anuj" required>
            </div>
            <div class="form-field">
              <label for="note-visit-context">Visit Context / Time</label>
              <input id="note-visit-context" name="visit_context" type="text" maxlength="80" placeholder="e.g. Work Session, Sunday Brunch">
            </div>
          </div>

          <div class="inline-note-form-grid">
            <div class="form-field">
              <label for="note-must-try">Must-Order Food / Drink Pick</label>
              <input id="note-must-try" name="must_try" type="text" maxlength="120" placeholder="e.g. Cold Brew & Almond Croissant">
            </div>
            <div class="form-field">
              <label for="note-rating">Overall Vibe Score</label>
              <select id="note-rating" name="rating">
                <option value="5" selected>⭐⭐⭐⭐⭐ 5/5 - Outstanding</option>
                <option value="4">⭐⭐⭐⭐ 4/5 - Good Spot</option>
                <option value="3">⭐⭐⭐ 3/5 - Average</option>
              </select>
            </div>
          </div>

          <div class="form-field" style="margin-bottom: 1rem;">
            <label for="note-text">Recommendation Note / Experience</label>
            <textarea id="note-text" name="review_text" rows="3" maxlength="1000" placeholder="What makes this café worth visiting? Seating comfort, quiet corners, wifi speed, signature brews..." required style="width:100%; border:1px solid #9cae9e; border-radius:.45rem; padding:.7rem; font-family:inherit; font-size:16px;"></textarea>
          </div>

          <button type="submit" class="button" style="min-height:44px;"><span aria-hidden="true">💬 </span>Post Note to Circle</button>
        </form>
      </div>
    </section>

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
          <?php if ($websiteAllowed): ?>
            <div><dt>Official website</dt><dd class="address-container"><a class="address-link" href="<?= h($website) ?>" target="_blank" rel="noopener noreferrer"><?= h(preg_replace('#^https?://(www\.)?#', '', rtrim($website, '/'))) ?></a><a class="mini-btn website-btn" href="<?= h($website) ?>" target="_blank" rel="noopener noreferrer" title="Visit website"><span aria-hidden="true">🌐 </span>Visit ↗</a></dd></div>
          <?php endif; ?>
          <div><dt>Ownership</dt><dd><?= h(catalogue_ownership($cafe)) ?></dd></div>
        </dl>
        <?php if ($websiteAllowed): ?>
          <div class="detail-actions">
            <a class="button button-secondary" href="<?= h($website) ?>" target="_blank" rel="noopener noreferrer"><span aria-hidden="true">🌐 </span>Visit café website ↗</a>
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
          <!-- Mobile-Optimized List View (Shown on screens <= 600px) -->
          <div class="offerings-mobile-list" aria-label="Recorded offerings list">
            <?php foreach ($offerings as $offering): ?>
              <?php
              $offeringEvidence = catalogue_evidence($offering['source'] ?? null, $offering['checked_on'] ?? null, $isDemo);
              $drinkName = trim((string) ($offering['drink_type'] ?? '')) !== '' ? ucwords(str_replace('_', ' ', $offering['drink_type'])) : 'Unknown';
              $brewMethod = trim((string) ($offering['brewing_method'] ?? '')) !== '' ? $offering['brewing_method'] : 'Unknown';
              $rawCurrency = trim((string) ($offering['currency'] ?? ''));
              $currSymbol = ($rawCurrency === 'INR' || $rawCurrency === '') ? '₹' : $rawCurrency . ' ';
              $formattedPrice = ($offering['price'] ?? null) === null ? 'Unknown' : $currSymbol . number_format((float) $offering['price'], 0);
              ?>
              <div class="offering-mobile-card">
                <div class="offering-mobile-header">
                  <strong class="offering-mobile-name"><?= h($drinkName) ?></strong>
                  <span class="offering-mobile-price"><?= h($formattedPrice) ?></span>
                </div>
                <div class="offering-mobile-body">
                  <span class="offering-mobile-method">⚙ <?= h($brewMethod) ?></span>
                  <span class="offering-mobile-evidence">
                    <?php if ($offeringEvidence['complete']): ?>
                      📋 <?= h($offeringEvidence['source']) ?><?= $offeringEvidence['date'] !== '' ? ' (' . h($offeringEvidence['date']) . ')' : '' ?>
                    <?php else: ?>
                      📋 Evidence incomplete
                    <?php endif; ?>
                  </span>
                </div>
              </div>
            <?php endforeach; ?>
          </div>

          <!-- Desktop Table View (Shown on screens > 600px) -->
          <div class="table-scroll offerings-desktop-table" tabindex="0" role="region" aria-label="Recorded offerings table">
            <table>
              <caption class="sr-only">Drinks, brewing methods, prices and verification</caption>
              <thead><tr><th scope="col">Drink</th><th scope="col">Method</th><th scope="col">Price</th><th scope="col">Evidence</th></tr></thead>
              <tbody>
                <?php foreach ($offerings as $offering): ?>
                  <?php
                  $offeringEvidence = catalogue_evidence($offering['source'] ?? null, $offering['checked_on'] ?? null, $isDemo);
                  $drinkName = trim((string) ($offering['drink_type'] ?? '')) !== '' ? ucwords(str_replace('_', ' ', $offering['drink_type'])) : 'Unknown';
                  $rawCurrency = trim((string) ($offering['currency'] ?? ''));
                  $currSymbol = ($rawCurrency === 'INR' || $rawCurrency === '') ? '₹' : $rawCurrency . ' ';
                  $formattedPrice = ($offering['price'] ?? null) === null ? 'Unknown' : $currSymbol . number_format((float) $offering['price'], 2, '.', '');
                  ?>
                  <tr>
                    <th scope="row" class="drink-cell"><?= h($drinkName) ?></th>
                    <td class="method-cell"><?= h(trim((string) ($offering['brewing_method'] ?? '')) !== '' ? $offering['brewing_method'] : 'Unknown') ?></td>
                    <td class="price price-cell"><?= h($formattedPrice) ?></td>
                    <td class="evidence-cell"><?php if ($offeringEvidence['complete']): ?><?= h($offeringEvidence['source']) ?><br><span class="muted"><?= $offeringEvidence['current'] ? 'Checked ' : 'Historical check: ' ?><?= h($offeringEvidence['date']) ?></span><?php else: ?>Unknown<?php if ($offeringEvidence['source'] !== ''): ?><br><span class="muted">Recorded source: <?= h($offeringEvidence['source']) ?>; evidence incomplete</span><?php endif; ?><?php endif; ?></td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>
      </section>
    </div>
  </article>
</main>
<?php require __DIR__ . '/footer.php'; ?>
