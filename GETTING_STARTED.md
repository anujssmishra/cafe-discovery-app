# Getting Started

Updated: 2026-10-09. These instructions run the existing PHP catalogue. Use PHP 8.2+ with PDO/pdo_mysql and MariaDB 10.11+, InnoDB and utf8mb4. No Composer packages, Python environment, Django commands or PHPUnit installation are required for this increment.

## Select the checkout

```sh
git clone https://github.com/anujssmishra/cafe-discovery-app.git
cd cafe-discovery-app
git status --short --branch
git fetch origin main
```

Use `main` for the reviewed PHP/MariaDB implementation, published at implementation checkpoint `1db5344`. The work originated on `codex/hostinger-mariadb` from `5c25b1d`. Inspect actual branch/head, preserve local work and never reset to a historical hash. Read [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) and [AGENTS.md](AGENTS.md).

## Recommended isolated local setup

Install/use an existing Docker Engine or Docker Desktop and start its Linux engine. Run from the repository root:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
```

The same commands work in PowerShell. Open [http://127.0.0.1:8000/](http://127.0.0.1:8000/), search `Paper`, combine with `demo-paper-quarter`, clear the filters, try a missing name and open a detail and the about page.

Compose creates `cafe_discovery` and a separate `cafe_discovery_test` database. The test runner resets only the latter. MariaDB is not published on a host port, and the web port binds only to localhost. Committed Docker passwords are local-only examples, never production credentials. Docker copies source at build time so it also works on drive providers that cannot be bind-mounted. After PHP/template/CSS edits, rerun `docker compose -f php_app/compose.yaml build app test` and recreate app with `docker compose -f php_app/compose.yaml up -d app`. Storage persists in the new `cafe-catalogue-mariadb-local_mariadb-data` volume, separate from historical MySQL data. Stop old cafe-catalogue-local PHP/Apache containers if they occupy ports 8000/8080. Preserve the old MySQL volume; never mount its data directory into MariaDB. Transfer valuable data by a reviewed logical export/import into a separate database and verify rows before switching. Use `docker compose -f php_app/compose.yaml down` to stop without deleting it. The test database initialization script runs only when that MariaDB volume is first initialized.

## Native PHP/MariaDB setup

Create an empty local database and a database-scoped local user using your normal MariaDB administration tool. Do not reuse production access. PHP reads process environment or private config/local.php; copying .env.example to .env does not load it. PDO uses the mysql driver/DSN for MariaDB too.

On macOS/Linux, configure your shell (replace the user/password with your own local values):

```sh
export APP_ENV=development
export DEMO_MODE=true
export APP_BASE_PATH=
export DB_HOST=127.0.0.1
export DB_PORT=3306
export DB_NAME=cafe_discovery
export DB_USER=your_local_user
export DB_PASS=your_local_password
php -v
php -m
php php_app/scripts/schema.php --apply
php php_app/scripts/seed.php --demo
php -S 127.0.0.1:8000 -t php_app/public php_app/public/router.php
```

PowerShell equivalent:

```powershell
$env:APP_ENV = "development"
$env:DEMO_MODE = "true"
$env:APP_BASE_PATH = ""
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_NAME = "cafe_discovery"
$env:DB_USER = "your_local_user"
$env:DB_PASS = "your_local_password"
php -v
php -m
php php_app/scripts/schema.php --apply
php php_app/scripts/seed.php --demo
php -S 127.0.0.1:8000 -t php_app/public php_app/public/router.php
```

These commands are local only. Repeat environment settings in a new terminal. Alternatively copy php_app/config/local.example.php to ignored php_app/config/local.php, fill its values and select development/demo settings locally. The file returns allowed uppercase string keys. Environment overrides every value, including empty values. APP_CONFIG_FILE optionally selects an absolute private PHP file outside public/public_html; invalid explicit config fails closed. APP_ENV defaults production; DEMO_MODE defaults false and cannot be true in production. APP_BASE_PATH is empty for myfanverse.in or /guide for that subdirectory. Schema and seed are CLI-only; production schema requires separate explicit database confirmation. Seed requires development/test demo mode and --demo.

The seed inserts missing fictional fixtures and refuses reserved identifier collisions. It does not refresh dates, restore edited fields, reactivate rows, delete unrelated data or recreate URLs. Synthetic dates are null and ownership/count evidence is unknown. Existing real records from the old seed stay untouched; their generic “Web research”/“Menu” provenance needs a human audit before use as checked information.

The schema file creates new tables; `CREATE TABLE IF NOT EXISTS` does not retrofit constraints onto old tables. Follow the additive upgrade instructions in `php_app/schema/` for an existing PHP database after reviewing old records/custom schema and taking an appropriate local backup. Never drop tables to resolve a migration error.

## Run checks

Docker:

```sh
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/config.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/package.php
docker compose -f php_app/compose.yaml run --rm test
```

The last command is `php php_app/tests/integration.php --allow-reset` in an isolated test container. It requires `APP_ENV=test`, an approved local MariaDB host, and a database name ending `_test`. It drops/recreates catalogue tables only in that test database. It starts temporary local PHP HTTP servers and cleans them up. Do not point it at a database containing work you want to keep.

Native testing requires a separate disposable local database/user, then set `APP_ENV=test`, `DEMO_MODE=true`, `DB_NAME=cafe_discovery_test` and the corresponding DB variables:

```sh
php php_app/scripts/lint.php
php php_app/tests/unit.php
php php_app/tests/config.php
php php_app/tests/package.php
php php_app/tests/integration.php --allow-reset
```

Lint returns nonzero for any invalid PHP file. CI configures PHP 8.2/8.3 and MariaDB 10.11/11.4 with pdo_mysql/zip for these checks. A workflow is configuration; [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records checks actually run.

## Routing and Hostinger preparation

Only `php_app/public/` is the web document root. Keep `includes/`, `templates/`, `schema/` and `scripts/` outside the served directory. Do not upload the whole repository into a public document root. PHP's built-in server must receive `router.php` as shown above; it does not read `.htaccess`.

The public .htaccess routes non-file requests to index.php; static CSS remains a real file. Relative rewrites and APP_BASE_PATH support root/subdirectory installs. The packager creates public_html with private sibling folders, preserving include paths. Follow [HOSTINGER_DEPLOYMENT.md](HOSTINGER_DEPLOYMENT.md) for myfanverse.in: verify actual PHP/MariaDB versions, use private config/local.php, apply the reviewed schema, upload the correct layout, and configure actual hPanel DNS/SSL values. CLI environment need not reach website PHP. Packaging needs the PHP zip extension; serving does not.

Production settings are `APP_ENV=production` and `DEMO_MODE=false`, with HTTPS, private credentials, protected logs, backups/restore and checked real data. This review does not deploy or validate Hostinger. Seeds are forbidden against production. PHP visitors receive generic errors; server logs identify exception class/code without showing credentials.

## Troubleshooting

| Symptom | Action |
|---|---|
| Missing PDO driver | Enable pdo_mysql in the selected PHP runtime |
| Generic 503 | Check private server logs, DB connection, schema and environment; keep display_errors disabled |
| Empty list | Check active café and area flags, filters, and demo mode |
| Detail 404 | Use the full UUID route; inactive areas/cafés and hidden demo records are unavailable |
| Missing CSS or broken links | Serve public only; check router/.htaccess and APP_BASE_PATH |
| Seed refused | Use local development/test, DEMO_MODE=true and --demo; investigate collisions |
| Docker engine unavailable | Start Docker's Linux engine, then rerun the commands |
| Native integration refused | Use the isolated local _test database and explicit --allow-reset |

## Local rehearsal of the Hostinger ZIP layout

After the disposable integration suite has populated local QA fixtures:

```sh
docker compose -f php_app/compose.yaml --profile hosting up -d --build hosting
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/hosting.php http://hosting
```

Open http://127.0.0.1:8081/. This Apache fixture serves the extracted ZIP with private-file production/demo-off configuration and no APP/DB environment. It uses the disposable _test database; QA records are never deployed. This checks layout/routing, not Hostinger/DNS/SSL. Stop it with docker compose -f php_app/compose.yaml --profile hosting down (preserves the volume).