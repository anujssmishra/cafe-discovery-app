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
    <h1>Explore cafés in your neighbourhood</h1>
    <p class="intro-copy">Search by name, neighbourhood, or vibe. Open a café to see food highlights, indicative prices, and recommendations from your circle.</p>
  </section>
  <form class="filter-form panel" method="get" action="<?= h(app_url('/')) ?>">
    <div class="form-field"><label for="search">Search by café name</label><input id="search" name="q" type="search" maxlength="180" value="<?= h($searchQuery) ?>" placeholder="Try a café name" aria-describedby="search-help"><small id="search-help">Part of a name works too.</small></div>
    <div class="form-field"><label for="area">Area</label><select id="area" name="area"><option value="">All areas</option><?php foreach ($areas as $area): ?><option value="<?= h($area['slug']) ?>"<?= $areaFilter === (string) $area['slug'] ? ' selected' : '' ?>><?= h($area['name']) ?><?= empty($area['city']) ? '' : ' · ' . h($area['city']) ?></option><?php endforeach; ?><?php if (!$knownArea): ?><option value="<?= h($areaFilter) ?>" selected>Unknown area filter</option><?php endif; ?></select></div>
    <div class="form-field"><label for="vibe">Vibe & mood</label><select id="vibe" name="vibe"><option value="">All vibes & moods</option><?php foreach ($vibes as $key => $opt): ?><option value="<?= h($key) ?>"<?= $vibeFilter === $key ? ' selected' : '' ?>><?= h($opt['label']) ?></option><?php endforeach; ?></select></div>
    <button type="submit" class="button">Find cafés</button>
    <a class="text-link" href="<?= h(app_url('/')) ?>">Clear filters</a>
  </form>

  <!-- "Find My Café Today" 3-Question Quick Matcher Widget -->
  <section class="panel matcher-panel" id="matcher">
    <div class="section-header">
      <div class="section-title-group">
        <span class="section-icon" aria-hidden="true">🎯</span>
        <h2>Find My Café Today</h2>
      </div>
      <span class="private-badge" style="color:#245339; background:#edf4eb; border-color:#cadbc6;">3-Question Quick Matcher</span>
    </div>
    <p class="section-subtitle" style="margin-bottom:0.85rem;">Not sure where to head? Answer 3 quick preferences for immediate, factual recommendations.</p>

    <form id="matcher-form" class="matcher-form-grid" onsubmit="runCafeMatcher(event)">
      <div class="form-field">
        <label for="match-vibe">1. Today's Purpose / Vibe</label>
        <select id="match-vibe" name="vibe">
          <option value="">Any Purpose / Vibe</option>
          <option value="work">💻 Work & Study (Quiet, Outlets)</option>
          <option value="aesthetic">✨ Aesthetic & Cozy (Interior & Vibe)</option>
          <option value="garden">🌿 Garden & Outdoor Seating</option>
          <option value="quiet">☕ Minimalist & Quiet Catchups</option>
          <option value="social">🗣️ Lively & Social Atmosphere</option>
          <option value="date">🕯️ Date Spot / Evening Vibe</option>
        </select>
      </div>

      <div class="form-field">
        <label for="match-area">2. Preferred Area</label>
        <select id="match-area" name="area">
          <option value="">Any Neighbourhood</option>
          <?php foreach ($areas as $a): ?>
            <option value="<?= h($a['slug']) ?>"><?= h($a['name']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="form-field">
        <label for="match-budget">3. Budget Tier</label>
        <select id="match-budget" name="budget">
          <option value="">Any Budget Tier</option>
          <option value="budget">₹ Budget (under ₹150)</option>
          <option value="moderate">₹₹ Moderate (₹150–₹300)</option>
          <option value="premium">₹₹₹ Premium (₹300+)</option>
        </select>
      </div>

      <div class="matcher-actions">
        <button type="submit" class="button" style="width:100%; min-height:46px;"><span aria-hidden="true">🎯 </span>Find Top 3 Matches</button>
      </div>
    </form>

    <div id="matcher-results" style="display:none; margin-top:1.25rem; border-top:1px solid var(--line); padding-top:1.25rem;">
      <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.5rem; margin-bottom:.85rem;">
        <h3 style="font-size:1.15rem; margin:0;"><span aria-hidden="true">✨ </span>Your Top 3 Matched Cafés</h3>
        <button type="button" class="mini-btn" onclick="document.getElementById('matcher-results').style.display='none';">Close Matches ✕</button>
      </div>
      <div id="matcher-cards-container" class="matcher-cards-grid"></div>
    </div>
  </section>

  <?php if ($errors): ?>
    <section class="notice validation-errors" aria-labelledby="validation-title"><h2 id="validation-title">Check your filters</h2><ul><?php foreach ($errors as $error): ?><li><?= h($error) ?></li><?php endforeach; ?></ul></section>
  <?php endif; ?>
  <?php if (!$errors): ?>
    <div class="view-switch-bar">
      <div class="results-heading" style="margin:0;">
        <h2><?= h($pagination['total']) ?> <?= (int) $pagination['total'] === 1 ? 'café' : 'cafés' ?> found</h2>
        <?php if ((int) $pagination['total'] > 0): ?><p>Page <?= h($pagination['page']) ?> of <?= h($pagination['pages']) ?></p><?php endif; ?>
      </div>
      <div class="view-switch-buttons" role="tablist" aria-label="Catalogue view modes">
        <button id="view-list-btn" class="view-btn active" type="button" role="tab" aria-selected="true" onclick="switchCatalogueView('list')">📋 List View</button>
        <button id="view-map-btn" class="view-btn" type="button" role="tab" aria-selected="false" onclick="switchCatalogueView('map')">🗺️ Map View</button>
      </div>
    </div>

    <?php if (!$cafes): ?>
      <section class="panel empty-state"><h3>No cafés found</h3><p>Try a different name, area, or vibe, or clear the filters to browse the catalogue.</p><a class="button" href="<?= h(app_url('/')) ?>">Clear filters</a></section>
    <?php else: ?>
      <!-- Catalogue List View -->
      <div id="catalogue-list-view">
        <div class="cafe-grid">
          <?php foreach ($cafes as $item): ?>
            <?php
            $itemWebsite = (string) ($item['website'] ?? '');
            $itemWebsiteAllowed = !($item['is_demo'] ?? false) && filter_var($itemWebsite, FILTER_VALIDATE_URL)
                && in_array(strtolower((string) parse_url($itemWebsite, PHP_URL_SCHEME)), ['http', 'https'], true)
                && parse_url($itemWebsite, PHP_URL_USER) === null && parse_url($itemWebsite, PHP_URL_PASS) === null;
            ?>
            <article class="cafe-card panel">
              <div class="card-header-wrapper">
                <div class="card-header-content">
                  <div class="card-topline">
                    <p class="eyebrow"><?= h($item['area_display'] ?? $item['area_name']) ?></p>
                    <div class="card-pills">
                      <?php if (!empty($item['branch_count']) && (int) $item['branch_count'] > 1): ?>
                        <span class="circle-pill" style="color:#0d47a1; background:#e3f2fd; border-color:#bbdefb;" title="Multiple locations available">📍 <?= (int) $item['branch_count'] ?> Branches</span>
                      <?php endif; ?>
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
                  </div>
                </div>
                <div class="card-thumb-container">
                  <a href="<?= h(app_url('/cafes/' . $item['id'] . '/')) ?>" tabindex="-1" aria-hidden="true">
                    <?php if (!empty($item['photo_url'])): ?>
                      <img class="card-thumb" src="<?= h($item['photo_url']) ?>" alt="<?= h($item['name']) ?>" loading="lazy" width="84" height="84">
                    <?php else: ?>
                      <div class="card-thumb-fallback" aria-hidden="true">☕</div>
                    <?php endif; ?>
                  </a>
                </div>
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
              <p class="address address-container"><?php if (trim((string) ($item['address'] ?? '')) !== ''): ?><a class="address-link" href="<?= h($itemMapUrl) ?>" target="_blank" rel="noopener noreferrer"><?= h($item['address']) ?></a><a class="mini-btn" href="<?= h($itemMapUrl) ?>" target="_blank" rel="noopener noreferrer" title="Open in Maps"><span aria-hidden="true">📍 </span>Maps ↗</a><?php else: ?>Address not recorded<?php endif; ?><?php if ($itemWebsiteAllowed): ?><a class="mini-btn website-btn" href="<?= h($itemWebsite) ?>" target="_blank" rel="noopener noreferrer" title="Official website: <?= h($item['name']) ?>"><span aria-hidden="true">🌐 </span>Website ↗</a><?php endif; ?></p>
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
      </div>

      <!-- Catalogue Map View -->
      <div id="catalogue-map-view" style="display:none;" role="tabpanel" aria-labelledby="view-map-btn">
        <div id="catalogue-map" class="map-container"></div>
      </div>
    <?php endif; ?>
  <?php endif; ?>

  <?php
  $allCafesData = [];
  foreach (($allCafes ?? []) as $ac) {
      $allCafesData[] = [
          'id' => $ac['id'],
          'name' => $ac['name'],
          'latitude' => $ac['latitude'] !== null ? (float) $ac['latitude'] : null,
          'longitude' => $ac['longitude'] !== null ? (float) $ac['longitude'] : null,
          'address' => $ac['address'] ?? '',
          'area_name' => $ac['area_name'] ?? '',
          'area_slug' => $ac['area_slug'] ?? '',
          'price_band' => $ac['price_band'] ?? 'moderate',
          'photo_url' => !empty($ac['photo_url']) ? $ac['photo_url'] : '',
          'vibe_tags' => $ac['vibe_tags'] ?? '',
          'food_highlights' => $ac['food_highlights'] ?? '',
          'summary' => $ac['summary'] ?? '',
          'friend_review_count' => (int) ($ac['friend_review_count'] ?? 0),
          'url' => app_url('/cafes/' . $ac['id'] . '/'),
      ];
  }
  ?>
  <script id="cafes-data" type="application/json">
    <?= json_encode($allCafesData, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP) ?>
  </script>
</main>
<script>
let leafletMapInstance = null;
let leafletMarkersLayer = null;

function switchCatalogueView(mode) {
  const listView = document.getElementById('catalogue-list-view');
  const mapView = document.getElementById('catalogue-map-view');
  const listBtn = document.getElementById('view-list-btn');
  const mapBtn = document.getElementById('view-map-btn');

  if (!listView || !mapView) return;

  if (mode === 'map') {
    listView.style.display = 'none';
    mapView.style.display = 'block';
    listBtn?.classList.remove('active');
    listBtn?.setAttribute('aria-selected', 'false');
    mapBtn?.classList.add('active');
    mapBtn?.setAttribute('aria-selected', 'true');
    localStorage.setItem('cafe_discovery_view', 'map');

    setTimeout(() => {
      initLeafletMap();
    }, 100);
  } else {
    mapView.style.display = 'none';
    listView.style.display = 'block';
    mapBtn?.classList.remove('active');
    mapBtn?.setAttribute('aria-selected', 'false');
    listBtn?.classList.add('active');
    listBtn?.setAttribute('aria-selected', 'true');
    localStorage.setItem('cafe_discovery_view', 'list');
  }
}

function initLeafletMap() {
  if (typeof L === 'undefined') return;

  const cafesDataEl = document.getElementById('cafes-data');
  if (!cafesDataEl) return;

  let cafes = [];
  try {
    cafes = JSON.parse(cafesDataEl.textContent);
  } catch (e) {
    return;
  }

  const validCafes = cafes.filter(c => c.latitude && c.longitude);

  if (!leafletMapInstance) {
    leafletMapInstance = L.map('catalogue-map').setView([26.8467, 80.9462], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(leafletMapInstance);
    leafletMarkersLayer = L.layerGroup().addTo(leafletMapInstance);
  } else {
    leafletMarkersLayer.clearLayers();
  }

  const coffeeIcon = L.divIcon({
    className: 'custom-coffee-pin-wrapper',
    html: '<div class="custom-coffee-pin">☕</div>',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18]
  });

  const bounds = [];

  validCafes.forEach(cafe => {
    const lat = cafe.latitude;
    const lng = cafe.longitude;
    bounds.push([lat, lng]);

    const priceBadge = cafe.price_band === 'budget' ? '₹ Budget' : (cafe.price_band === 'premium' ? '₹₹₹ Premium' : '₹₹ Moderate');
    const directionsUrl = `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`;

    const popupHtml = `
      <div class="map-popup">
        ${cafe.photo_url ? `<img src="${escapeHtml(cafe.photo_url)}" class="map-popup-img" alt="${escapeHtml(cafe.name)}" />` : ''}
        <div class="map-popup-content">
          <span class="map-popup-area">${escapeHtml(cafe.area_name)}</span>
          <h4 class="map-popup-title"><a href="${cafe.url}">${escapeHtml(cafe.name)}</a></h4>
          <div class="map-popup-meta">
            <span class="price-band-badge price-${cafe.price_band}">${priceBadge}</span>
            ${cafe.vibe_tags ? `<span class="vibe-tag">${escapeHtml(cafe.vibe_tags.split(',')[0])}</span>` : ''}
          </div>
          <a href="${directionsUrl}" target="_blank" rel="noopener noreferrer" class="mini-btn" style="margin-top:0.4rem; display:inline-flex;">📍 Directions ↗</a>
        </div>
      </div>
    `;

    L.marker([lat, lng], { icon: coffeeIcon })
      .bindPopup(popupHtml)
      .addTo(leafletMarkersLayer);
  });

  if (bounds.length > 0) {
    leafletMapInstance.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 });
  } else {
    leafletMapInstance.setView([26.8467, 80.9462], 12);
  }

  leafletMapInstance.invalidateSize();
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function runCafeMatcher(event) {
  event.preventDefault();
  const vibe = document.getElementById('match-vibe').value;
  const area = document.getElementById('match-area').value;
  const budget = document.getElementById('match-budget').value;

  const cafesDataEl = document.getElementById('cafes-data');
  if (!cafesDataEl) return;

  let cafes = [];
  try { cafes = JSON.parse(cafesDataEl.textContent); } catch (e) { return; }

  const vibeLabels = {
    work: 'Work & Study',
    aesthetic: 'Aesthetic & Cozy',
    garden: 'Garden & Outdoor',
    quiet: 'Minimalist & Quiet',
    social: 'Lively & Social',
    date: 'Date Spot'
  };

  const scored = cafes.map(c => {
    let score = 0;
    let reasons = [];

    if (vibe) {
      const vLabel = vibeLabels[vibe] || vibe;
      if (c.vibe_tags && c.vibe_tags.toLowerCase().includes(vibe)) {
        score += 45;
        reasons.push(`✓ Fits ${vLabel} vibe`);
      }
    } else {
      score += 10;
    }

    if (area) {
      if (c.area_slug === area) {
        score += 40;
        reasons.push(`✓ In ${c.area_name}`);
      }
    } else {
      score += 10;
    }

    if (budget) {
      if (c.price_band === budget) {
        score += 35;
        const bLabel = budget === 'budget' ? 'Budget' : (budget === 'premium' ? 'Premium' : 'Moderate');
        reasons.push(`✓ Fits ${bLabel} spend tier`);
      }
    } else {
      score += 10;
    }

    if (c.friend_review_count > 0) {
      score += 5;
      reasons.push(`👥 ${c.friend_review_count} friend note${c.friend_review_count > 1 ? 's' : ''}`);
    }

    return { cafe: c, score, reasons };
  });

  scored.sort((a, b) => b.score - a.score || a.cafe.name.localeCompare(b.cafe.name));
  const top3 = scored.slice(0, 3);

  const container = document.getElementById('matcher-cards-container');
  const resultsBox = document.getElementById('matcher-results');
  if (!container || !resultsBox) return;

  container.innerHTML = top3.map(item => {
    const c = item.cafe;
    const priceSymbol = c.price_band === 'budget' ? '₹' : (c.price_band === 'premium' ? '₹₹₹' : '₹₹');
    return `
      <div class="matcher-card">
        <div class="matcher-card-header">
          <h4 class="matcher-card-title"><a href="${c.url}">${escapeHtml(c.name)}</a></h4>
          <span class="price-band-badge price-${c.price_band}">${priceSymbol}</span>
        </div>
        <p class="eyebrow" style="margin:0;">${escapeHtml(c.area_name)}</p>
        <div class="match-reasons-list">
          ${item.reasons.map(r => `<span class="match-reason-tag">${escapeHtml(r)}</span>`).join('')}
        </div>
        ${c.food_highlights ? `<p class="card-food-line" style="margin:0;"><span aria-hidden="true">🥐 </span>${escapeHtml(c.food_highlights)}</p>` : ''}
        <a class="button button-secondary" href="${c.url}" style="margin-top:auto; min-height:38px; font-size:0.82rem; padding:0.4rem 0.6rem;">Explore Café →</a>
      </div>
    `;
  }).join('');

  resultsBox.style.display = 'block';
  resultsBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

document.addEventListener('DOMContentLoaded', () => {
  const searchInput = document.getElementById('search');
  const areaSelect = document.getElementById('area');
  const vibeSelect = document.getElementById('vibe');
  const form = document.querySelector('.filter-form');

  // Restore view mode preference
  const savedView = localStorage.getItem('cafe_discovery_view');
  if (savedView === 'map') {
    switchCatalogueView('map');
  }

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

          const oldNodes = currentMain.querySelectorAll('.view-switch-bar, #catalogue-list-view, #catalogue-map-view, .empty-state, .notice, #cafes-data');
          oldNodes.forEach(node => node.remove());

          const newNodes = newMain.querySelectorAll('.view-switch-bar, #catalogue-list-view, #catalogue-map-view, .empty-state, .notice, #cafes-data');
          let anchor = document.getElementById('matcher') || form;
          newNodes.forEach(node => {
            anchor.after(node);
            anchor = node;
          });

          window.history.replaceState({}, '', url.toString());
          searchInput.focus();
          searchInput.setSelectionRange(selStart, selEnd);

          if (localStorage.getItem('cafe_discovery_view') === 'map') {
            switchCatalogueView('map');
          }
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
