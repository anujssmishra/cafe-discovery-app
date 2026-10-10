<?php
declare(strict_types=1);

// Copy to local.php beside this file, outside public_html. Never commit local.php.
// Use the exact database host/name/user from Hostinger hPanel.
return [
    'APP_ENV' => 'production',
    'DEMO_MODE' => 'false',
    'APP_BASE_PATH' => '', // cafes.myfanverse.in domain root
    'DB_HOST' => 'localhost',
    'DB_PORT' => '3306',
    'DB_NAME' => 'replace_with_hpanel_database',
    'DB_USER' => 'replace_with_hpanel_user',
    'DB_PASS' => 'replace-with-private-database-password',
];
