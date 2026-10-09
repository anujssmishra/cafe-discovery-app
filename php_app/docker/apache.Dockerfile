FROM php:8.2-apache
RUN docker-php-ext-install pdo_mysql && a2enmod rewrite
COPY . /app/php_app
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf
