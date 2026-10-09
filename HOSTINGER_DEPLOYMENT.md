# Hostinger deployment for myfanverse.in

Updated: 2026-10-09. This runbook installs the PHP café catalogue at https://myfanverse.in/ on Hostinger Web/Cloud hosting. Preparing a release and passing local checks does not establish that the hosting account, domain, database or live site has been configured. No hosting changes follow from this document alone.

## 1. Confirm the hosting runtime and preserve the existing site

Use a Custom PHP/HTML website for `myfanverse.in`. Confirm ownership and access to that domain's DNS settings. If it already serves a website, download its files and a database export before replacing anything. Keep the previous release and private configuration available for rollback. Prefer testing the same package and layout on a temporary domain or staging subdomain with a separate database first.

Hostinger Web/Cloud hosting uses MariaDB, although hPanel may label its database menus “MySQL.” Open the website's database in phpMyAdmin and run:

```sql
SELECT VERSION();
```

This application's database target is MariaDB 10.11 or newer, InnoDB, and utf8mb4. Use the actual returned version when verifying compatibility; do not infer a version from the menu label. [Hostinger database documentation](https://www.hostinger.com/support/1583226-which-database-management-system-is-used-at-hostinger/)

In the website's PHP Configuration, select PHP 8.2 or a verified newer version when offered and ensure `PDO`/`pdo_mysql` are available. If the account offers a different PHP version, verify the release with that version before publishing. Turn `display_errors` off and keep error logging on. The catalogue needs no Composer install or Node/Python process. [Hostinger PHP configuration](https://www.hostinger.com/support/4667515-how-to-manage-php-extensions-and-options-in-hostinger/)

For CLI schema setup, confirm SSH is available in the hosting plan and use the connection command from hPanel. PHP used by SSH can differ from the website's selected PHP version: check `php -v` and `php -m`. Use the host-provided PHP 8.2 binary if `php` points to another runtime. [Hostinger SSH access](https://www.hostinger.com/support/1583645-how-to-enable-ssh-access-in-hostinger/)

## 2. Build the reviewed release locally

From the repository root, complete the checks in [GETTING_STARTED.md](GETTING_STARTED.md), then run with PHP 8.2+ and the Zip extension. CI is configured for PHP 8.2/8.3 and MariaDB 10.11/11.4; [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records actual results. Choose a new ZIP filename in an existing writable directory outside the public web root; the packager refuses to overwrite an existing file:

```sh
php php_app/scripts/package.php --output=/absolute/path/myfanverse-hostinger.zip
```

PowerShell example using an absolute output path inside the checkout:

```powershell
$releasePath = Join-Path (Get-Location) 'myfanverse-hostinger.zip'
php php_app/scripts/package.php "--output=$releasePath"
```

If PHP/Zip is unavailable on your computer, use the running local Docker app after rebuilding it as described in GETTING_STARTED:

```sh
docker compose -f php_app/compose.yaml exec -T app php php_app/scripts/package.php --output=/tmp/hostinger-myfanverse.in.zip
docker compose -f php_app/compose.yaml cp app:/tmp/hostinger-myfanverse.in.zip ./hostinger-myfanverse.in.zip
```

The first command creates the archive inside the running container; the second copies it onto your computer. A `run --rm` container would discard the archive on exit. If the ZIP already exists inside the container, use a new filename in both commands. The manifest includes SHA-256 hashes for the packaged payload files.

Inspect the ZIP before upload. It contains only the allowlisted runtime, schema setup files, safe configuration example and a release manifest. It excludes private `config/local.php`, seeds, test fixtures, database exports, `.env`, Git history and `legacy_django/`. The manifest records the intended domain `myfanverse.in`; it does not change DNS or bind requests to that domain.

Do not upload the whole repository. Keep the ZIP and all backups outside the served directory.

## 3. Upload with the correct public/private layout

Find the website's actual document root in hPanel. For a usual domain-root installation, arrange the files as follows. The account's parent directories may differ; preserve these relative sibling paths.

```text
domains/myfanverse.in/
├── public_html/
│   ├── index.php
│   ├── .htaccess
│   └── static/
│       └── site.css
├── includes/
├── templates/
├── config/
│   ├── local.example.php
│   └── local.php           # create privately on the host
├── scripts/
│   ├── schema.php
│   └── schema_helpers.php
├── schema/
│   ├── schema.sql
│   └── README.md
└── release.json
```

Only `public_html/` is served by the website. `includes/`, `templates/`, `config/`, `scripts/` and `schema/` must be siblings outside it. Extract the ZIP in a private staging folder first, then upload its contents into this layout using hPanel File Manager or SFTP where available. Enable hidden-file display so `public_html/.htaccess` is included.

If hPanel File Manager opens directly inside `public_html/`, do not extract the whole ZIP there: it would nest another `public_html/` and expose private directories. Use the account-level directory view or transfer the folders separately. Do not relax the web root to serve the parent folder.

The relative include paths and `.htaccess` are already supplied. The Hostinger website uses its normal PHP server; do not start PHP's development server, upload `router.php`, or install Docker on shared hosting.

## 4. Create the database and private configuration

In hPanel's database management page, create a database and its user for this website. Copy the full assigned names, including any account prefix. Use the database hostname shown by Hostinger, normally `localhost`, and port `3306`.

Copy the safe example to `config/local.php` on the host and replace the placeholders privately:

```php
<?php
declare(strict_types=1);

return [
    'APP_ENV' => 'production',
    'DEMO_MODE' => 'false',
    'APP_BASE_PATH' => '',
    'DB_HOST' => 'localhost',
    'DB_PORT' => '3306',
    'DB_NAME' => 'your_full_hpanel_database_name',
    'DB_USER' => 'your_full_hpanel_database_user',
    'DB_PASS' => 'your_private_database_password',
];
```

Every value is a string. Leave `APP_BASE_PATH` empty for https://myfanverse.in/; the hostname is not a base path. PHP automatically reads this private sibling file. Process environment variables take precedence when explicitly set, so remove unintended overrides when diagnosing configuration. Copying an `.env` file does not configure this application. If the host supplies `APP_CONFIG_FILE`, it must be an absolute path to a readable private PHP configuration file outside the public web root; otherwise the default `config/local.php` is used. Keep this variable unset for the layout above.

Use the owner-only file permissions supported by the account while ensuring PHP can read the file. Never put credentials in `public_html/`, Git, the release ZIP, an issue, a screenshot or this document. Future uploads must preserve the existing `config/local.php`; the packager omits it.

## 5. Apply the schema deliberately

Back up any database containing valuable records. The schema command creates missing catalogue tables and adds reviewed constraints/indexes while preserving records; DDL is not transactional, and an error can leave earlier statements applied. Read the packaged `schema/README.md` before upgrading an existing or customized schema. Use a separate staging copy for rehearsal.

Connect with the SSH command supplied by hPanel. Change to the directory containing `public_html/`, `config/` and `scripts/`, then run:

```sh
php -v
php -m
php scripts/schema.php --apply --production --database=your_full_hpanel_database_name
```

The `--database` value must exactly match the configured production database name. The production flag and explicit database confirmation are required; keep `APP_ENV=production` and `DEMO_MODE=false`. Never temporarily enable development or demo mode to bypass a safeguard.

After success, use phpMyAdmin to verify the database:

```sql
SELECT VERSION();

SELECT @@SESSION.check_constraint_checks, @@SESSION.foreign_key_checks;

SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('area', 'cafe', 'cafe_offering');

SHOW CREATE TABLE area;
SHOW CREATE TABLE cafe;
SHOW CREATE TABLE cafe_offering;
```

Confirm both session check settings return 1, all three tables are InnoDB, and the documented foreign keys and CHECK constraints are present. Never disable either setting to bypass a failure. If the command fails, retain its private diagnostic, inspect the schema and data, and resolve the cause before retrying. Never drop existing tables to make it pass.

If the hosting plan lacks SSH, phpMyAdmin can import the packaged `schema/schema.sql` into a **new empty database** after checking the supported MariaDB version and confirming both session constraint-check settings above are 1. Verify the resulting tables as above. This is an initial installation path: `CREATE TABLE IF NOT EXISTS` does not upgrade existing tables. An existing database needs the reviewed additive upgrade through an available CLI/staging workflow; do not expose `schema.php` through the website.

Production seeds are forbidden and are excluded from the ZIP. A fresh production database shows an informative empty catalogue until reviewed real records are imported. There is no PHP catalogue admin in this release. Import only owned/permitted café data with accurate sources and historical verification dates, preserve UUID URLs, and represent missing evidence as unknown. A local synthetic fixture is not a production verification source.

## 6. Connect myfanverse.in and enable HTTPS

Add or connect `myfanverse.in` to this specific Hostinger website. Use the website's **Check guide** / domain connection flow to obtain its actual DNS values. If the domain is already correctly connected, retain the existing records.

Choose either the current DNS provider's A-record method or move nameserver management to Hostinger. Copy the exact IP addresses or nameservers displayed for this account; this repository cannot supply them. Remove only conflicting website A/AAAA records as directed by that guide. Configure `www.myfanverse.in` through the same guide if you want that alias.

Preserve email MX, SPF, DKIM and DMARC records. A nameserver change moves the authoritative zone and can affect email, so copy the existing records before making that change and restore the appropriate mail records in the new zone. Keeping the existing DNS provider and changing website records avoids moving the whole zone. Confirm the connection in hPanel and check propagation before cutover. [Hostinger domain connection guide](https://www.hostinger.com/support/1863967-how-to-point-a-domain-to-hostinger/)

Install/activate the SSL certificate for `myfanverse.in` and the `www` alias if used, then verify Force HTTPS is enabled in the website's SSL settings. Check that HTTP redirects to HTTPS without a loop. Hostinger enables forced HTTPS by default after certificate installation on Web/Cloud plans, but confirm the actual account setting. [Hostinger HTTPS configuration](https://www.hostinger.com/support/1583201-how-to-enable-or-disable-https-for-your-website-at-hostinger/)

Use https://myfanverse.in/ as the intended primary URL. If using `www`, configure the host's domain redirect to the primary URL and test it independently. The application uses relative links, so root catalogue/detail/assets work on the selected domain without hardcoded server IPs.

## 7. Verify staging, then the live release

Record the package/revision, actual PHP/MariaDB versions and observed results. Local integration checks cover the database and routes; these host checks confirm the real web server, configuration and TLS.

| Check | Expected result |
|---|---|
| `https://myfanverse.in/` | 200, escaped catalogue or informative empty state; no demo banner |
| `/about/` | 200 with the café guide explanation |
| `/static/site.css` | 200 CSS; page styles load |
| `/?q%5B%5D=bad`, `/?page=-2` | 400 with a clear validation message and no PHP warnings |
| `/cafes/not-a-uuid/` and an absent full UUID | 404, no internal exception details |
| Known active café/area, when reviewed data exists | Detail 200; filters/pagination preserve q and area; inactive records unavailable |
| `/.env`, `/config/local.php`, `/includes/config.php`, `/scripts/schema.php` | No private file or executable setup endpoint is accessible |
| Narrow phone viewport and keyboard navigation | No page overflow; visible focus, labelled filters, usable pagination and table scrolling |
| HTTP, HTTPS and optional www alias | Valid certificate and intended redirect to the primary HTTPS URL |

Do not create a database failure deliberately on the live site to test generic errors; use staging for failure cases. Check the private hosting error log if a request returns 503 and keep credentials/internal traces out of visitor responses.

After staging passes, retain backups, upload the reviewed release to the live layout, preserve its private configuration, apply any necessary rehearsed schema change, then repeat the smoke checks. Avoid replacing files midway through active requests when the host offers a maintenance/staging cutover.

## Optional local rehearsal of the ZIP layout

The `hosting` Compose profile builds and extracts the actual allowlisted ZIP, serves `public_html/` with Apache, and loads a private PHP configuration file without APP/DB environment variables. Its production-mode reader points only to the local disposable `cafe_discovery_test` database and uses committed local example credentials. It does not contact Hostinger or change DNS.

After running the integration suite to create its guarded test fixtures, start the rehearsal from the repository root:

```sh
docker compose -f php_app/compose.yaml run --rm test
docker compose -f php_app/compose.yaml --profile hosting up -d --build hosting
```

The first command resets only the disposable local `_test` database; do not use it with valuable data or live configuration. Open http://127.0.0.1:8081/ and test the table above using the local origin instead of `myfanverse.in`. Demo rows remain hidden in this profile; the suite's unrelated QA records can exercise positive details and filtering. These are synthetic local test records, not production content. The rehearsal checks packaging, Apache routing and private configuration; hosted LiteSpeed, DNS and TLS still require real staging checks.

## 8. Updates and rollback

For each update, package a tested checkout, back up files and database, preserve `config/local.php`, and rehearse schema changes on a copy. Keep the ZIP, exports and logs private.

If a file/configuration release fails, restore the previous compatible runtime files and private configuration. For a schema failure, inspect which DDL completed; do not assume reverting PHP undoes database changes. Restore the reviewed database backup when necessary, accounting for any newer records before replacing it. Record the restored release and repeat the smoke checks.

Actual Hostinger account access, DNS values, PHP selection, database version, production data, TLS and deployment remain host-specific verification. [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records local evidence and outstanding acceptance checks.
