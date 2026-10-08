<?php
// php_app/templates/cafe_detail.php
$pageTitle = $cafe['name'] . ' | Café Discovery';
require __DIR__ . '/header.php';
?>

<div style="margin-bottom:1rem;">
  <a href="/" style="text-decoration:none; color:#0056b3;">← Back to Catalogue</a>
</div>

<div style="background:#fff; border:1px solid #ddd; padding:2rem; border-radius:4px;">
  <h1 style="margin-top:0;"><?= htmlspecialchars($cafe['name']) ?></h1>
  
  <p style="color:#555; font-size:1.1rem;">
    <?= htmlspecialchars($cafe['address']) ?> <br>
    <strong><?= htmlspecialchars($cafe['area_name']) ?></strong>, <?= htmlspecialchars($cafe['area_city']) ?>
  </p>

  <div style="margin: 1.5rem 0;">
    <?php if ($cafe['independence_status'] === 'verified_independent'): ?>
      <span class="badge badge-independent">Independent Ownership</span>
    <?php elseif ($cafe['independence_status'] === 'verified_not_independent'): ?>
      <span class="badge" style="background:#e3f2fd; color:#0d47a1;">Chain / Group</span>
    <?php endif; ?>
    
    <?php if ($cafe['is_demo']): ?>
      <span class="badge" style="background:#fff3cd; color:#856404;">Demo Data</span>
    <?php endif; ?>
  </div>

  <?php if (!empty($cafe['summary'])): ?>
    <div style="font-size:1.1rem; line-height:1.6; margin-bottom: 2rem;">
      <p><?= nl2br(htmlspecialchars($cafe['summary'])) ?></p>
    </div>
  <?php endif; ?>

  <hr style="border:0; border-top:1px solid #eee; margin: 2rem 0;">

  <h2>Menu Offerings</h2>
  <?php if (empty($offerings)): ?>
    <p>No verified menu data yet.</p>
  <?php else: ?>
    <table style="width:100%; text-align:left; border-collapse: collapse;">
      <thead>
        <tr style="border-bottom: 2px solid #ddd;">
          <th style="padding:0.5rem 0;">Drink Type</th>
          <th style="padding:0.5rem 0;">Method</th>
          <th style="padding:0.5rem 0;">Price</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($offerings as $offering): ?>
          <tr style="border-bottom: 1px solid #eee;">
            <td style="padding:0.5rem 0; text-transform: capitalize;"><?= htmlspecialchars(str_replace('_', ' ', $offering['drink_type'])) ?></td>
            <td style="padding:0.5rem 0;"><?= htmlspecialchars($offering['brewing_method'] ?: 'Standard') ?></td>
            <td style="padding:0.5rem 0;">
              <?php if ($offering['price']): ?>
                <?= htmlspecialchars($offering['currency']) ?> <?= htmlspecialchars($offering['price']) ?>
              <?php else: ?>
                <span style="color:#999;">Unknown</span>
              <?php endif; ?>
            </td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>

  <div style="margin-top: 3rem; padding:1rem; background:#f5f5f5; border-radius:4px; font-size:0.875rem; color:#666;">
    <strong>Verification Data:</strong><br>
    Checked on: <?= htmlspecialchars($cafe['checked_on'] ?? 'Unknown') ?><br>
    Source: <?= htmlspecialchars($cafe['source'] ?? 'Unknown') ?>
  </div>
</div>

<?php require __DIR__ . '/footer.php'; ?>
