ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-cli
RUN apt-get update && apt-get install -y --no-install-recommends libzip-dev \
    && docker-php-ext-install pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app/php_app
