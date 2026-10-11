<?php
require __DIR__ . '/header.php';
$inviteUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . ($_SERVER['HTTP_HOST'] ?? 'myfanverse.in') . app_url('/join/' . ($session['invite_code'] ?? 'lucknow-circle') . '/');
$whatsappShareText = rawurlencode("Hey! Join our private café circle on Café Discovery so we can share honest coffee notes and favorite dishes in Lucknow: " . $inviteUrl);
?>
<main id="main-content" class="page-shell" tabindex="-1">
  <a class="back-link" href="<?= h(app_url('/')) ?>"><span aria-hidden="true">← </span>Back to the catalogue</a>

  <header class="detail-heading">
    <p class="eyebrow">Private Discovery Circles</p>
    <h1><?= h($session['circle_name']) ?></h1>
    <p class="intro-copy">A private space for your friend circle to share genuine recommendations, must-try dishes, and quiet work spots. No sponsored posts or bot reviews.</p>
  </header>

  <?php if (!empty($message)): ?>
    <div class="notice" style="background:#e8f5e9; border-color:#a5d6a7; color:#1b5e20;">
      <p style="margin:0; font-weight:700;">✓ <?= h($message) ?></p>
    </div>
  <?php endif; ?>

  <div class="circles-grid">
    <!-- Card 1: Active Circle & Invite Friends -->
    <section class="panel circle-invite-panel">
      <div class="section-title-group">
        <span class="section-icon" aria-hidden="true">👥</span>
        <h2>Active Circle</h2>
      </div>
      <p class="muted">You are currently browsing as <strong><?= h($session['member_name']) ?></strong> in <strong><?= h($session['circle_name']) ?></strong>.</p>
      
      <div class="invite-share-box">
        <label for="invite-url-input">Invite Friends via Link</label>
        <div class="invite-input-row">
          <input id="invite-url-input" type="text" readonly value="<?= h($inviteUrl) ?>" onclick="this.select()">
          <button type="button" class="button" onclick="navigator.clipboard.writeText('<?= h($inviteUrl) ?>'); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy', 2000);">Copy</button>
        </div>
        <div style="margin-top:.85rem;">
          <a class="button button-whatsapp" href="https://api.whatsapp.com/send?text=<?= $whatsappShareText ?>" target="_blank" rel="noopener noreferrer">
            <span aria-hidden="true">💬 </span>Share to WhatsApp Group
          </a>
        </div>
      </div>
    </section>

    <!-- Card 2: Google Reviews Auto-Match -->
    <section class="panel google-match-panel" style="border-top: 4px solid #1a73e8;">
      <div class="section-title-group">
        <span class="section-icon" aria-hidden="true">🔍</span>
        <h2>Auto-Match from Google Reviews</h2>
      </div>
      <p class="muted">Written reviews on Google Maps before? Enter your name on Google Maps to automatically discover and import your reviews to this circle in 1 tap.</p>

      <form method="get" action="<?= h(app_url('/circles/')) ?>" class="match-form">
        <div class="form-field">
          <label for="google-author-name">Your Name on Google Maps</label>
          <input id="google-author-name" name="match_name" type="text" value="<?= h($matchName ?: ($session['member_name'] !== 'Guest' ? $session['member_name'] : 'Anuj Mishra')) ?>" placeholder="e.g. Anuj Mishra" required>
        </div>
        <button type="submit" class="button" style="background:#1a73e8; border-color:#1a73e8;">
          <span aria-hidden="true">🔍 </span>Auto-Find My Google Reviews
        </button>
      </form>

      <?php if (!empty($matchedReviews)): ?>
        <div class="matched-results-box" style="margin-top:1.5rem;">
          <h3 style="font-size:1.1rem; color:#1a73e8; margin-bottom:.6rem;">🎉 Found <?= count($matchedReviews) ?> Google <?= count($matchedReviews) === 1 ? 'Review' : 'Reviews' ?>!</h3>
          <p class="muted" style="font-size:.85rem; margin-bottom:1rem;">Select the reviews below to import them into <strong><?= h($session['circle_name']) ?></strong>:</p>

          <form method="post" action="<?= h(app_url('/circles/import/')) ?>">
            <input type="hidden" name="member_name" value="<?= h($matchName ?: $session['member_name']) ?>">
            <div class="match-list">
              <?php foreach ($matchedReviews as $rev): ?>
                <div class="match-card">
                  <label class="match-card-label">
                    <input type="checkbox" name="review_ids[]" value="<?= (int) $rev['id'] ?>" checked>
                    <div class="match-card-info">
                      <div class="match-card-header">
                        <strong><?= h($rev['cafe_name']) ?></strong>
                        <span class="match-rating">⭐ <?= (int) $rev['rating'] ?>/5 on Google</span>
                      </div>
                      <p class="match-text">"<?= h($rev['review_text']) ?>"</p>
                      <?php if (!empty($rev['must_try_item'])): ?>
                        <span class="match-dish">⭐ Must-Order: <?= h($rev['must_try_item']) ?></span>
                      <?php endif; ?>
                    </div>
                  </label>
                </div>
              <?php endforeach; ?>
            </div>
            <div style="margin-top:1rem;">
              <button type="submit" class="button" style="background:#1b5e20; border-color:#1b5e20;">
                <span aria-hidden="true">📥 </span>Import Selected to My Circle
              </button>
            </div>
          </form>
        </div>
      <?php elseif ($matchName !== ''): ?>
        <div class="friend-empty-box" style="margin-top:1.25rem;">
          <p class="empty-copy">No public reviews indexed for "<?= h($matchName) ?>" yet.</p>
          <p class="empty-hint">Try searching with your exact Google Maps display name (e.g. "Anuj Mishra", "Priya Sharma").</p>
        </div>
      <?php endif; ?>
    </section>

    <!-- Card 3: Create a New Circle -->
    <section class="panel">
      <h2>Start a New Circle</h2>
      <p class="muted">Want a separate circle for college friends, coworkers, or family? Create one below:</p>
      <form method="post" action="<?= h(app_url('/circles/create/')) ?>">
        <div class="form-field" style="margin-bottom:.8rem;">
          <label for="circle-name-input">Circle Name</label>
          <input id="circle-name-input" name="circle_name" type="text" placeholder="e.g. Hazratganj Coffee Club" required>
        </div>
        <div class="form-field" style="margin-bottom:1rem;">
          <label for="creator-name-input">Your Name</label>
          <input id="creator-name-input" name="creator_name" type="text" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : '') ?>" placeholder="Your name" required>
        </div>
        <button type="submit" class="button">Create Circle</button>
      </form>
    </section>

    <!-- Card 4: Join Another Circle -->
    <section class="panel">
      <h2>Join with Invite Code</h2>
      <p class="muted">Got an invite code from a friend? Enter it here to join their circle:</p>
      <form method="post" action="<?= h(app_url('/circles/join-code/')) ?>">
        <div class="form-field" style="margin-bottom:.8rem;">
          <label for="join-code-input">Invite Code</label>
          <input id="join-code-input" name="invite_code" type="text" placeholder="e.g. lucknow-circle" required>
        </div>
        <div class="form-field" style="margin-bottom:1rem;">
          <label for="join-name-input">Your Name</label>
          <input id="join-name-input" name="member_name" type="text" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : '') ?>" placeholder="Your name" required>
        </div>
        <button type="submit" class="button button-secondary">Join Circle</button>
      </form>
    </section>
  </div>
</main>
<?php require __DIR__ . '/footer.php'; ?>
