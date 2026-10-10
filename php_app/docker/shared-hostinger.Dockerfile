# Emulate an existing apex site with its cafes subdomain and private sibling app.
FROM php:8.2-cli AS package
RUN apt-get update && apt-get install -y --no-install-recommends libzip-dev \
    && docker-php-ext-install zip && rm -rf /var/lib/apt/lists/*
COPY . /app/php_app
RUN php /app/php_app/scripts/package.php --shared-subdomain --output=/tmp/release.zip \
    && php -r '$zip = new ZipArchive(); $zip->open("/tmp/release.zip"); $zip->extractTo("/release"); $zip->close();'

FROM php:8.2-apache
RUN docker-php-ext-install pdo_mysql && a2enmod rewrite
COPY --from=package /release /app/release
COPY docker/hostinger-local.php /app/release/cafe_app/config/local.php
COPY docker/shared-apex.html /app/release/public_html/index.html
COPY docker/shared-hostinger.conf /etc/apache2/sites-available/000-default.conf
