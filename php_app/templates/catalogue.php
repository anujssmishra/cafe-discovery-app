<?php
// php_app/templates/catalogue.php
$pageTitle = 'Explore Cafés | Café Discovery';
require __DIR__ . '/header.php';
?>

<div style="margin-bottom: 2rem;">
  <h1>Find your next pause</h1>
  <form method="GET" action="/" style="display:flex; gap:0.5rem; margin-bottom: 1rem;">
    <input type="text" name="q" placeholder="Search cafes by name..." value="<?= htmlspecialchars($_GET['q'] ?? '') ?>" style="padding: 0.5rem; flex: 1; border: 1px solid #ccc; border-radius: 4px;">
    
    <select name="area" style="padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px;">
      <option value="">All Areas</option>
      <?php foreach ($areas as $area): ?>
        <option value="<?= htmlspecialchars($area['slug']) ?>" <?= (($_GET['area'] ?? '') === $area['slug']) ? 'selected' : '' ?>>
          <?= htmlspecialchars($area['name']) ?>
        </option>
      <?php endforeach; ?>
    </select>
    
    <button type="submit" class="button button-primary">Search</button>
    <a href="/" class="button">Clear</a>
  </form>
</div>

<?php if (empty($cafes)): ?>
  <div style="text-align:center; padding: 3rem; background: #fff; border: 1px solid #ddd; border-radius: 4px;">
    <h3>No cafés found</h3>
    <p>Try another name or clear your filters.</p>
  </div>
<?php else: ?>
  <div class="grid">
    <?php foreach ($cafes as $cafe): ?>
      <div class="card">
        <h2 style="margin-top:0; font-size:1.25rem;">
          <a href="/cafes/<?= urlencode($cafe['id']) ?>" style="text-decoration:none; color:#111;">
            <?= htmlspecialchars($cafe['name']) ?>
          </a>
        </h2>
        <p style="color:#666; font-size:0.875rem; margin-bottom:0.5rem;">
          <?= htmlspecialchars($cafe['area_name']) ?>, <?= htmlspecialchars($cafe['area_city']) ?>
        </p>
        
        <div style="margin-bottom:1rem;">
          <?php if ($cafe['independence_status'] === 'verified_independent'): ?>
            <span class="badge badge-independent">Independent</span>
          <?php endif; ?>
        </div>
        
        <p style="font-size:0.875rem;"><?= htmlspecialchars(substr($cafe['summary'] ?? '', 0, 100)) ?>...</p>
        
        <a href="/cafes/<?= urlencode($cafe['id']) ?>" class="button" style="width:100%; text-align:center; box-sizing:border-box;">View Details</a>
      </div>
    <?php endforeach; ?>
  </div>
<?php endif; ?>

<?php require __DIR__ . '/footer.php'; ?>
