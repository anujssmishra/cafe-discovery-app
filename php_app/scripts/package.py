#!/usr/bin/env python3
"""Build an explicit runtime allowlist package for Hostinger deployment.

Mirrors php_app/scripts/package.php without requiring the PHP CLI.
"""

from datetime import datetime, timezone
import hashlib
import json
import os
import sys
import zipfile

FILES_MAP = {
    'public/index.php': 'public_html/index.php',
    'public/.htaccess': 'public_html/.htaccess',
    'public/static/site.css': 'public_html/static/site.css',
    'config/local.example.php': 'config/local.example.php',
    'schema/schema.sql': 'schema/schema.sql',
    'schema/README.md': 'schema/README.md',
    'schema/lucknow_cafes.sql': 'schema/lucknow_cafes.sql',
    'schema/migration_sprint3_vibes_and_friends.sql': 'schema/migration_sprint3_vibes_and_friends.sql',
    'schema/migration_sprint3_websites.sql': 'schema/migration_sprint3_websites.sql',
    'schema/migration_sprint3_multi_branch_cafes.sql': 'schema/migration_sprint3_multi_branch_cafes.sql',
    'schema/migration_sprint4_circles_and_google_match.sql': 'schema/migration_sprint4_circles_and_google_match.sql',
    'schema/migration_sprint5_cafe_photos.sql': 'schema/migration_sprint5_cafe_photos.sql',
    'scripts/schema.php': 'scripts/schema.php',
    'scripts/schema_helpers.php': 'scripts/schema_helpers.php',
    'scripts/sync_google_reviews.php': 'scripts/sync_google_reviews.php',
    'includes/config.php': 'includes/config.php',
    'includes/db.php': 'includes/db.php',
    'includes/request.php': 'includes/request.php',
    'includes/catalogue.php': 'includes/catalogue.php',
    'includes/web.php': 'includes/web.php',
    'includes/circles.php': 'includes/circles.php',
    'templates/header.php': 'templates/header.php',
    'templates/footer.php': 'templates/footer.php',
    'templates/catalogue.php': 'templates/catalogue.php',
    'templates/cafe_detail.php': 'templates/cafe_detail.php',
    'templates/about.php': 'templates/about.php',
    'templates/error.php': 'templates/error.php',
    'templates/_evidence.php': 'templates/_evidence.php',
    'templates/circles.php': 'templates/circles.php',
}


def build_package(output_path: str, flat_public_html: bool = False) -> None:
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    contents = {}
    hashes = {}

    for src_rel, dst_rel in FILES_MAP.items():
        src_path = os.path.join(root, src_rel)
        if not os.path.isfile(src_path):
            raise FileNotFoundError(f"Missing required release file: {src_rel}")

        with open(src_path, 'rb') as f:
            data = f.read()

        target_rel = dst_rel
        if flat_public_html:
            # If deploying directly inside public_html/, flatten public_html/ prefix
            if target_rel.startswith('public_html/'):
                target_rel = target_rel[len('public_html/'):]

        contents[target_rel] = data
        hashes[target_rel] = hashlib.sha256(data).hexdigest()

    manifest = {
        'format': 1,
        'domain': 'myfanverse.in',
        'php_minimum': '8.2',
        'database': 'MariaDB 10.11+',
        'built_at_utc': datetime.now(timezone.utc).isoformat(),
        'layout': 'flat-public_html' if flat_public_html else 'standard-hostinger',
        'files_sha256': hashes,
    }
    manifest_bytes = (json.dumps(manifest, indent=2) + "\n").encode('utf-8')
    contents['release.json'] = manifest_bytes

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    temp_output = output_path + '.tmp'
    try:
        with zipfile.ZipFile(temp_output, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
            for entry_name, entry_bytes in sorted(contents.items()):
                zf.writestr(entry_name, entry_bytes)
        if os.path.exists(output_path):
            os.remove(output_path)
        os.rename(temp_output, output_path)
        print(f"Hostinger release created: {output_path} ({len(contents)} files)")
    finally:
        if os.path.exists(temp_output):
            os.remove(temp_output)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 package.py --output=<zip_path> [--flat]")
        sys.exit(2)

    output = None
    flat = False
    for arg in sys.argv[1:]:
        if arg.startswith('--output='):
            output = arg.split('=', 1)[1]
        elif arg == '--flat':
            flat = True
        else:
            print(f"Unknown argument: {arg}")
            sys.exit(2)

    if not output:
        print("Missing required --output argument.")
        sys.exit(2)

    build_package(output, flat_public_html=flat)


if __name__ == '__main__':
    main()
