# Getting Started

Updated: 2026-10-09. These instructions run the existing PHP catalogue. Use PHP 8.2 with PDO/pdo_mysql and MySQL 8.0.16 or newer (enforced CHECK constraints), InnoDB and utf8mb4. No Composer packages, Python environment, Django commands or PHPUnit installation are required for this increment.

## Select the checkout

```sh
git clone https://github.com/anujssmishra/cafe-discovery-app.git
cd cafe-discovery-app
git status --short --branch
git fetch origin main
```

Use `main` for the reviewed PHP implementation. The fixes were prepared on `fix/php-catalogue-review` from `ba97a0a`; inspect the actual available branch/head, preserve local work and never reset to a historical hash. Read [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) and [AGENTS.md](AGENTS.md).

## Recommended isolated local setup

Install/use an existing Docker Engine or Docker Desktop and start its Linux engine. Run from the repository root:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
```

The same commands work in PowerShell. Open [http://127.0.0.1:8000/](http://127.0.0.1:8000/), search `Paper`, combine with `demo-paper-quarter`, clear the filters, try a missing name and open a detail and the about page.

Compose creates `cafe_discovery` and a separate `cafe_discovery_test` database. The test runner resets only the latter. MySQL is not published on a host port, and the web port binds only to localhost. Committed Docker passwords are local-only examples, never production credentials. Docker copies source at build time so it also works on drive providers that cannot be bind-mounted. After PHP/template/CSS edits, rerun `docker compose -f php_app/compose.yaml build app test` and recreate app with `docker compose -f php_app/compose.yaml up -d app`. Storage persists in the `mysql-data` volume. Use `docker compose -f php_app/compose.yaml down` to stop without deleting it. The test database initialization script runs only when that MySQL volume is first initialized.

## Native PHP/MySQL setup

Create an empty local database and a database-scoped local user using your normal MySQL administration tool. Do not reuse production access. PHP reads process environment; copying `.env.example` to `.env` does not load it.

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

These commands are local development only. Repeat environment settings in a new terminal. `APP_ENV` accepts `development`, `test`, or `production` and defaults to `production`; `DEMO_MODE` accepts only `true`/`false`, defaults to false, and is rejected in production when true. Set `APP_BASE_PATH=/guide` only when installing under that path. The schema command and seed are CLI-only and guarded; the seed additionally requires `--demo`.

The seed inserts missing fictional fixtures and refuses reserved identifier collisions. It does not refresh dates, restore edited fields, reactivate rows, delete unrelated data or recreate URLs. Synthetic dates are null and ownership/count evidence is unknown. Existing real records from the old seed stay untouched; their generic “Web research”/“Menu” provenance needs a human audit before use as checked information.

The schema file creates new tables; `CREATE TABLE IF NOT EXISTS` does not retrofit constraints onto old tables. Follow the additive upgrade instructions in `php_app/schema/` for an existing PHP database after reviewing old records/custom schema and taking an appropriate local backup. Never drop tables to resolve a migration error.

## Run checks

Docker:

```sh
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test
```

The last command is `php php_app/tests/integration.php --allow-reset` in an isolated test container. It requires `APP_ENV=test`, an approved local MySQL host, and a database name ending `_test`. It drops/recreates catalogue tables only in that test database. It starts temporary local PHP HTTP servers and cleans them up. Do not point it at a database containing work you want to keep.

Native testing requires a separate disposable local database/user, then set `APP_ENV=test`, `DEMO_MODE=true`, `DB_NAME=cafe_discovery_test` and the corresponding DB variables:

```sh
php php_app/scripts/lint.php
php php_app/tests/unit.php
php php_app/tests/integration.php --allow-reset
```

Lint returns nonzero for any invalid PHP file. CI uses PHP 8.2/pdo_mysql and a fresh MySQL 8 service for these checks. A workflow is configuration; [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records checks actually run.

## Routing and Hostinger preparation

Only `php_app/public/` is the web document root. Keep `includes/`, `templates/`, `schema/` and `scripts/` outside the served directory. Do not upload the whole repository into a public document root. PHP's built-in server must receive `router.php` as shown above; it does not read `.htaccess`.

The public `.htaccess` routes non-file requests to `index.php`; static CSS stays a real file. Relative rewrites plus `APP_BASE_PATH` support a root or subdirectory installation. Hostinger uses LiteSpeed with [.htaccess support](https://www.hostinger.com/tutorials/create-default-wordpress-htaccess-file/). Configure PHP 8.2/pdo_mysql and private DB environment values deliberately. The application does not auto-load dotenv files, and arbitrary shared-host environment configuration must be checked on that host. If copying public files to a different physical location, preserve their relative sibling layout or adapt the include paths as a reviewed packaging change.

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
