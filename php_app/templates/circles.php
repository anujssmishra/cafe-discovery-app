<?php
require __DIR__ . '/header.php';
$inviteUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . ($_SERVER['HTTP_HOST'] ?? 'myfanverse.in') . app_url('/join/' . ($session['invite_code'] ?? 'lucknow-circle') . '/');
$whatsappShareText = rawurlencode("Hey! Join our private café circle on Café Discovery so we can share honest coffee notes and favorite dishes in Lucknow: " . $inviteUrl);
$circleReviews = $circleReviews ?? [];
?>
<style>
/* Scoped high-finish styles for Circles UI */
.circles-page { max-width: 920px; margin: 0 auto; }
.circle-hero-card {
  background: linear-gradient(180deg, #fbfcf9 0%, #f4f7f2 100%);
  border: 1px solid #d8e2d4;
  border-radius: 0.85rem;
  padding: 1.6rem 1.8rem;
  margin-bottom: 2rem;
  box-shadow: 0 4px 16px rgba(36, 83, 57, 0.05);
}
.circle-hero-top { display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 1rem; margin-bottom: 0.8rem; }
.circle-badges { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
.circle-badge-pill {
  font-size: 0.72rem;
  font-weight: 750;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 0.2rem 0.6rem;
  border-radius: 2rem;
}
.badge-green { background: #e2ede0; color: #1e5a2e; border: 1px solid #c2dbbe; }
.badge-blue { background: #e8f0fe; color: #1967d2; border: 1px solid #d2e3fc; }
.circle-title { font-size: 1.85rem; margin: 0 0 0.4rem; color: var(--ink); line-height: 1.25; }
.circle-desc { color: var(--muted); font-size: 0.95rem; margin: 0 0 1.25rem; line-height: 1.5; max-width: 65ch; }
.circle-member-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 1rem;
  padding-top: 1.1rem;
  border-top: 1px solid #e1e9dd;
}
.member-status { display: flex; align-items: center; gap: 0.5rem; font-size: 0.92rem; color: var(--ink); }
.member-status strong { color: #1e5a2e; }
.invite-actions-group { display: flex; align-items: center; gap: 0.65rem; flex-wrap: wrap; }
.whatsapp-share-btn {
  background: #25d366;
  color: #fff !important;
  font-weight: 750;
  font-size: 0.88rem;
  padding: 0.55rem 1.1rem;
  border-radius: 2rem;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  text-decoration: none !important;
  box-shadow: 0 2px 6px rgba(37, 211, 102, 0.28);
  transition: transform 0.12s ease, background 0.12s ease;
}
.whatsapp-share-btn:hover { background: #1ebd5a; transform: translateY(-1px); }
.copy-pill-btn {
  background: #fff;
  border: 1px solid #ccd7c8;
  color: var(--ink);
  font-size: 0.85rem;
  font-weight: 650;
  padding: 0.55rem 0.95rem;
  border-radius: 2rem;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  transition: border-color 0.12s ease, background 0.12s ease;
}
.copy-pill-btn:hover { border-color: #9ab495; background: #f9fbf8; }

/* Google Sync Card */
.google-sync-card {
  background: #fff;
  border: 1px solid #d3e3fd;
  border-top: 4px solid #1a73e8;
  border-radius: 0.85rem;
  padding: 1.6rem 1.8rem;
  margin-bottom: 2rem;
  box-shadow: 0 4px 14px rgba(26, 115, 232, 0.05);
}
.google-sync-header { display: flex; align-items: center; gap: 0.65rem; margin-bottom: 0.35rem; }
.google-sync-title { font-size: 1.35rem; margin: 0; color: #1a73e8; font-weight: 750; }
.google-sync-desc { color: var(--muted); font-size: 0.92rem; margin: 0 0 1.25rem; line-height: 1.5; }
.google-search-row { display: flex; gap: 0.6rem; max-width: 580px; }
.google-search-input {
  flex: 1;
  padding: 0.65rem 0.95rem;
  border: 1.5px solid #d0d7de;
  border-radius: 0.55rem;
  font-size: 0.95rem;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.google-search-input:focus {
  outline: none;
  border-color: #1a73e8;
  box-shadow: 0 0 0 3px rgba(26, 115, 232, 0.15);
}
.google-search-btn {
  background: #1a73e8;
  color: #fff;
  border: none;
  padding: 0.65rem 1.2rem;
  border-radius: 0.55rem;
  font-weight: 700;
  font-size: 0.92rem;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  white-space: nowrap;
  transition: background 0.12s ease;
}
.google-search-btn:hover { background: #1558b0; }

/* Matched Results */
.matched-results-wrap {
  margin-top: 1.6rem;
  padding-top: 1.4rem;
  border-top: 1px solid #e8f0fe;
}
.matched-banner {
  background: #e8f0fe;
  color: #1558b0;
  padding: 0.75rem 1rem;
  border-radius: 0.55rem;
  font-weight: 700;
  font-size: 0.95rem;
  margin-bottom: 1.1rem;
}
.matched-cards-grid { display: flex; flex-direction: column; gap: 0.9rem; }
.matched-item-card {
  background: #fbfcfe;
  border: 1.5px solid #d2e3fc;
  border-radius: 0.65rem;
  padding: 1.1rem 1.25rem;
  transition: border-color 0.12s ease, background 0.12s ease;
}
.matched-item-card:hover { border-color: #1a73e8; background: #fff; }
.matched-label { display: flex; gap: 0.85rem; align-items: flex-start; cursor: pointer; }
.matched-checkbox { width: 1.25rem; height: 1.25rem; margin-top: 0.2rem; accent-color: #1a73e8; cursor: pointer; }
.matched-body { flex: 1; }
.matched-topline { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 0.4rem; }
.matched-cafe-title { font-size: 1.05rem; font-weight: 750; color: var(--ink); margin: 0; }
.matched-stars-pill {
  font-size: 0.8rem;
  font-weight: 750;
  color: #1558b0;
  background: #e8f0fe;
  padding: 0.2rem 0.55rem;
  border-radius: 0.35rem;
}
.matched-quote { font-style: italic; color: #2d3748; font-size: 0.9rem; margin: 0 0 0.5rem; line-height: 1.5; }
.matched-must-try {
  font-size: 0.82rem;
  font-weight: 750;
  color: #8c5a00;
  background: #fff8e8;
  border: 1px solid #fce2a6;
  padding: 0.2rem 0.55rem;
  border-radius: 0.35rem;
  display: inline-block;
}
.import-confirm-btn {
  background: #1b5e20;
  color: #fff;
  border: none;
  padding: 0.75rem 1.4rem;
  border-radius: 0.55rem;
  font-size: 0.95rem;
  font-weight: 750;
  cursor: pointer;
  margin-top: 1.2rem;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  transition: background 0.12s ease;
}
.import-confirm-btn:hover { background: #134617; }

/* Circle Notes Feed */
.circle-feed-section { margin-bottom: 2.2rem; }
.feed-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.feed-title { font-size: 1.35rem; margin: 0; color: var(--ink); }
.feed-count-pill { font-size: 0.8rem; font-weight: 700; color: var(--muted); background: #ebf0e7; padding: 0.2rem 0.6rem; border-radius: 1rem; }
.feed-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(290px, 1fr)); gap: 1.1rem; }
.feed-card {
  background: #fff;
  border: 1px solid #dde5da;
  border-left: 4px solid var(--green);
  border-radius: 0.65rem;
  padding: 1.2rem 1.3rem;
  box-shadow: 0 2px 8px rgba(36, 83, 57, 0.04);
}
.feed-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.45rem; }
.feed-cafe-link { font-weight: 750; font-size: 1.05rem; color: var(--green); text-decoration: none; }
.feed-cafe-link:hover { text-decoration: underline; }
.feed-reviewer-line { font-size: 0.83rem; color: var(--muted); margin-bottom: 0.65rem; display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap; }
.feed-text { font-size: 0.9rem; line-height: 1.55; color: var(--ink); margin: 0 0 0.65rem; }

/* Secondary Actions Grid */
.secondary-manage-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.3rem; margin-top: 2rem; }
.manage-subcard {
  background: #fafbf9;
  border: 1px solid #dfe5dc;
  border-radius: 0.75rem;
  padding: 1.4rem;
}
.manage-subcard h3 { font-size: 1.15rem; margin: 0 0 0.35rem; color: var(--ink); }
.manage-subcard p { font-size: 0.86rem; color: var(--muted); margin: 0 0 1rem; }
.form-input-clean {
  width: 100%;
  padding: 0.55rem 0.75rem;
  border: 1px solid #ccd7c8;
  border-radius: 0.45rem;
  font-size: 0.9rem;
  margin-bottom: 0.75rem;
  box-sizing: border-box;
}
.form-input-clean:focus { outline: none; border-color: var(--green); }

@media (max-width: 768px) {
  .circle-member-bar { flex-direction: column; align-items: flex-start; }
  .invite-actions-group { width: 100%; }
  .whatsapp-share-btn { width: 100%; justify-content: center; }
  .google-search-row { flex-direction: column; }
  .secondary-manage-grid { grid-template-columns: 1fr; }
}
</style>

<main id="main-content" class="page-shell circles-page" tabindex="-1">
  <a class="back-link" href="<?= h(app_url('/')) ?>"><span aria-hidden="true">← </span>Back to the catalogue</a>

  <?php if (!empty($message)): ?>
    <div class="notice" style="background:#e8f5e9; border-color:#a5d6a7; color:#1b5e20; margin-bottom:1.5rem; border-radius:.55rem; padding:.9rem 1.2rem;">
      <p style="margin:0; font-weight:750; font-size:.95rem;">✓ <?= h($message) ?></p>
    </div>
  <?php endif; ?>

  <!-- 1. Active Circle Hero Card -->
  <header class="circle-hero-card">
    <div class="circle-hero-top">
      <div class="circle-badges">
        <span class="circle-badge-pill badge-green">👥 Active Friend Circle</span>
        <span class="circle-badge-pill badge-blue">📍 Lucknow</span>
      </div>
    </div>
    
    <h1 class="circle-title"><?= h($session['circle_name']) ?></h1>
    <p class="circle-desc">A private discovery circle for you and your friends to share unfiltered coffee recommendations, quiet work spots, and favorite dishes across Lucknow without commercial rating noise or sponsored posts.</p>

    <div class="circle-member-bar">
      <div class="member-status">
        <span>Browsing as: <strong><?= h($session['member_name']) ?></strong></span>
      </div>
      
      <div class="invite-actions-group">
        <a class="whatsapp-share-btn" href="https://api.whatsapp.com/send?text=<?= $whatsappShareText ?>" target="_blank" rel="noopener noreferrer">
          <span aria-hidden="true">💬 </span>Invite Friends via WhatsApp
        </a>
        <button type="button" class="copy-pill-btn" onclick="navigator.clipboard.writeText('<?= h($inviteUrl) ?>'); this.textContent = '✓ Link Copied!'; setTimeout(() => this.textContent = '📋 Copy Link', 2500);" title="Copy circle invite link">
          <span aria-hidden="true">📋 </span>Copy Link
        </button>
      </div>
    </div>
  </header>

  <!-- 2. On-Demand Google Reviews Extraction Widget -->
  <section class="google-sync-card">
    <div class="google-sync-header">
      <span style="font-size:1.4rem; line-height:1;" aria-hidden="true">⭐</span>
      <h2 class="google-sync-title">On-Demand Google Reviews Extractor</h2>
    </div>
    <p class="google-sync-desc">Extract reviews you have posted on Google Maps and bring your Lucknow café recommendations into your circle in 1 tap. Enter your Google Maps Contributor Profile link or your Google display name below:</p>

    <form method="get" action="<?= h(app_url('/circles/')) ?>">
      <div style="display:flex; flex-direction:column; gap:.75rem; max-width:620px;">
        <div class="google-search-row">
          <input class="google-search-input" name="contrib_url" type="text" value="<?= h($_GET['contrib_url'] ?? '') ?>" placeholder="Google Contributor URL (e.g. google.com/maps/contrib/110382... or Contributor ID)">
        </div>
        <div class="google-search-row">
          <input class="google-search-input" name="match_name" type="text" value="<?= h($matchName ?: ($session['member_name'] !== 'Guest' ? $session['member_name'] : 'Anuj Mishra')) ?>" placeholder="Or enter your Google Maps display name (e.g. Anuj Mishra)">
          <button type="submit" class="google-search-btn">
            <span aria-hidden="true">⚡ </span>Extract My Reviews
          </button>
        </div>
      </div>
      <div style="font-size:.82rem; color:var(--muted); margin-top:.5rem;">
        💡 <em>How to get your profile link:</em> Open Google Maps → tap your profile icon → Your profile → Share profile link.
      </div>
    </form>

    <?php if (!empty($matchedReviews)): ?>
      <div class="matched-results-wrap">
        <div class="matched-banner">
          🎉 Found <?= count($matchedReviews) ?> Google <?= count($matchedReviews) === 1 ? 'Review' : 'Reviews' ?> for Lucknow cafés! Select the ones you want to import into <?= h($session['circle_name']) ?>:
        </div>

        <form method="post" action="<?= h(app_url('/circles/import/')) ?>">
          <input type="hidden" name="member_name" value="<?= h($matchName ?: $session['member_name']) ?>">
          <div class="matched-cards-grid">
            <?php foreach ($matchedReviews as $rev): ?>
              <article class="matched-item-card">
                <label class="matched-label">
                  <input type="checkbox" class="matched-checkbox" name="review_ids[]" value="<?= (int) $rev['id'] ?>" checked>
                  <div class="matched-body">
                    <div class="matched-topline">
                      <h3 class="matched-cafe-title"><?= h($rev['cafe_name']) ?><?= !empty($rev['area_name']) ? ' · <span style="font-weight:normal; color:var(--muted); font-size:.9rem;">' . h($rev['area_name']) . '</span>' : '' ?></h3>
                      <span class="matched-stars-pill">⭐ <?= (int) $rev['rating'] ?>/5 on Google</span>
                    </div>
                    <p class="matched-quote">"<?= h($rev['review_text']) ?>"</p>
                    <?php if (!empty($rev['must_try_item'])): ?>
                      <span class="matched-must-try">⭐ Must-Order: <?= h($rev['must_try_item']) ?></span>
                    <?php endif; ?>
                  </div>
                </label>
              </article>
            <?php endforeach; ?>
          </div>

          <button type="submit" class="import-confirm-btn">
            <span aria-hidden="true">📥 </span>Import Selected to <?= h($session['circle_name']) ?>
          </button>
        </form>
      </div>
    <?php elseif ($matchName !== '' || !empty($_GET['contrib_url'])): ?>
      <div class="matched-results-wrap">
        <div style="background:#fef7e0; color:#8c5a00; border:1px solid #f9e2a8; padding:1rem 1.2rem; border-radius:.6rem;">
          <strong style="display:block; margin-bottom:.25rem;">No reviews extracted yet for this profile.</strong>
          <span style="font-size:.9rem;">Ensure your Google Maps contributor profile or display name matches your public Google reviews. You can also share a café note directly below!</span>
        </div>
      </div>
    <?php endif; ?>
  </section>

  <!-- 2b. Direct Circle Café Recommendation Form -->
  <section class="panel" style="background:#fff; border:1px solid #d8e2d4; border-radius:.85rem; padding:1.4rem 1.6rem; margin-bottom:2rem; box-shadow:0 3px 12px rgba(36,83,57,0.04);">
    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.5rem; margin-bottom:.8rem;">
      <h2 style="font-size:1.25rem; margin:0; color:var(--ink); font-weight:750;">✍️ Share a Café Note Directly</h2>
      <span style="font-size:.82rem; color:var(--muted);">Post a personal recommendation to <?= h($session['circle_name']) ?></span>
    </div>
    <form method="post" action="<?= h(app_url('/circles/add-note/')) ?>">
      <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap:.8rem; margin-bottom:.8rem;">
        <div>
          <label style="display:block; font-size:.82rem; font-weight:700; color:var(--ink); margin-bottom:.3rem;">Select Lucknow Café *</label>
          <select name="cafe_id" class="form-input-clean" required style="width:100%;">
            <option value="">-- Choose a Café --</option>
            <?php if (!empty($cafesList)): ?>
              <?php foreach ($cafesList as $c): ?>
                <option value="<?= h($c['id']) ?>"><?= h($c['name']) ?></option>
              <?php endforeach; ?>
            <?php endif; ?>
          </select>
        </div>
        <div>
          <label style="display:block; font-size:.82rem; font-weight:700; color:var(--ink); margin-bottom:.3rem;">Your Display Name *</label>
          <input name="friend_name" type="text" class="form-input-clean" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : 'Anuj Mishra') ?>" required style="width:100%;">
        </div>
        <div>
          <label style="display:block; font-size:.82rem; font-weight:700; color:var(--ink); margin-bottom:.3rem;">Rating (1 - 5 Stars) *</label>
          <select name="rating" class="form-input-clean" style="width:100%;">
            <option value="5" selected>⭐⭐⭐⭐⭐ 5 - Exceptional</option>
            <option value="4">⭐⭐⭐⭐ 4 - Very Good</option>
            <option value="3">⭐⭐⭐ 3 - Decent / Average</option>
            <option value="2">⭐⭐ 2 - Below Expectations</option>
            <option value="1">⭐ 1 - Not Recommended</option>
          </select>
        </div>
        <div>
          <label style="display:block; font-size:.82rem; font-weight:700; color:var(--ink); margin-bottom:.3rem;">Must-Try Item / Drink</label>
          <input name="must_try" type="text" class="form-input-clean" placeholder="e.g. V60 Pour-over, Classic Bagel" style="width:100%;">
        </div>
      </div>
      <div style="margin-bottom:.8rem;">
        <label style="display:block; font-size:.82rem; font-weight:700; color:var(--ink); margin-bottom:.3rem;">Your Honest Review / Notes *</label>
        <textarea name="review_text" rows="3" class="form-input-clean" placeholder="How is the coffee, seating for laptop work, noise level, or service?" required style="width:100%; resize:vertical;"></textarea>
      </div>
      <button type="submit" class="button" style="font-weight:700; padding:.6rem 1.4rem;">
        <span aria-hidden="true">💬 </span>Post Note to <?= h($session['circle_name']) ?>
      </button>
    </form>
  </section>

  <!-- 3. Notes & Recommendations in this Circle -->
  <section class="circle-feed-section">
    <div class="feed-header">
      <h2 class="feed-title">Notes from this Circle</h2>
      <span class="feed-count-pill"><?= count($circleReviews) ?> <?= count($circleReviews) === 1 ? 'note' : 'notes' ?></span>
    </div>

    <?php if (empty($circleReviews)): ?>
      <div class="panel" style="text-align:center; padding:2rem 1.5rem; background:#fafbf9; border:1px dashed #cfd9cb; border-radius:.75rem;">
        <span style="font-size:2rem; display:block; margin-bottom:.5rem;" aria-hidden="true">☕</span>
        <h3 style="font-size:1.15rem; margin:0 0 .3rem; color:var(--ink);">No recommendations recorded yet</h3>
        <p style="color:var(--muted); font-size:.9rem; margin:0 0 1rem; max-width:48ch; margin-inline:auto;">
          Be the first to share notes with your circle! Match your Google Reviews above or invite your friends.
        </p>
      </div>
    <?php else: ?>
      <div class="feed-grid">
        <?php foreach ($circleReviews as $r): ?>
          <article class="feed-card">
            <div class="feed-card-header">
              <a class="feed-cafe-link" href="<?= h(app_url('/cafes/' . $r['cafe_id'] . '/')) ?>"><?= h($r['cafe_name']) ?></a>
            </div>
            <div class="feed-reviewer-line">
              <strong><?= h($r['friend_name']) ?></strong>
              <?php if (($r['source_type'] ?? '') === 'google_matched'): ?>
                <span class="circle-badge-pill badge-blue" style="font-size:.65rem; padding:.1rem .45rem;">✓ Google Match<?= !empty($r['google_rating']) ? ' · ⭐' . (int) $r['google_rating'] . '★' : '' ?></span>
              <?php else: ?>
                <span class="circle-badge-pill badge-green" style="font-size:.65rem; padding:.1rem .45rem;">✓ Circle</span>
              <?php endif; ?>
              <?php if (!empty($r['visited_on'])): ?>
                <span>· <?= h($r['visited_on']) ?></span>
              <?php endif; ?>
            </div>
            <p class="feed-text">"<?= h($r['review_text']) ?>"</p>
            <?php if (!empty($r['must_try_item'])): ?>
              <span class="matched-must-try" style="font-size:.78rem; padding:.15rem .45rem;">⭐ Must-Try: <?= h($r['must_try_item']) ?></span>
            <?php endif; ?>
          </article>
        <?php endforeach; ?>
      </div>
    <?php endif; ?>
  </section>

  <!-- 4. Secondary Actions: Create or Join Different Circle -->
  <section class="panel" style="margin-top:2.5rem; background:#fbfcf9; border-radius:.85rem;">
    <h2 style="font-size:1.25rem; margin:0 0 .35rem;">Manage or Switch Circle</h2>
    <p style="color:var(--muted); font-size:.88rem; margin:0 0 1.25rem;">Need a separate circle for work, college, or family? Create a new one or join with an invite code.</p>

    <div class="secondary-manage-grid">
      <!-- Create Circle -->
      <div class="manage-subcard">
        <h3>Start a New Circle</h3>
        <p>Create a dedicated space for a different friend group.</p>
        <form method="post" action="<?= h(app_url('/circles/create/')) ?>">
          <input class="form-input-clean" name="circle_name" type="text" placeholder="e.g. Hazratganj Coffee Club" required>
          <input class="form-input-clean" name="creator_name" type="text" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : '') ?>" placeholder="Your Name" required>
          <button type="submit" class="button" style="width:100%; justify-content:center;">Create Circle</button>
        </form>
      </div>

      <!-- Join with Code -->
      <div class="manage-subcard">
        <h3>Join Another Circle</h3>
        <p>Enter an invite code provided by a friend.</p>
        <form method="post" action="<?= h(app_url('/circles/join-code/')) ?>">
          <input class="form-input-clean" name="invite_code" type="text" placeholder="e.g. lucknow-circle" required>
          <input class="form-input-clean" name="member_name" type="text" value="<?= h($session['member_name'] !== 'Guest' ? $session['member_name'] : '') ?>" placeholder="Your Name" required>
          <button type="submit" class="button button-secondary" style="width:100%; justify-content:center;">Join Circle</button>
        </form>
      </div>
    </div>
  </section>
</main>
<?php require __DIR__ . '/footer.php'; ?>
