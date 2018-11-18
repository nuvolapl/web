FROM php:7.2-fpm-alpine

# SYSTEM
RUN apk update && apk upgrade
RUN apk --no-cache add \
    shadow \
    zlib-dev

RUN addgroup -g 2432 -S nuvola
RUN usermod -a -G nuvola www-data

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/composer-setup.php

# PHP
RUN docker-php-ext-install \
    opcache \
    zip

ARG APP_ENV
ARG APP_DEBUG
ARG APP_SECRET

ENV APP_ENV=$APP_ENV
ENV APP_DEBUG=$APP_DEBUG
ENV APP_SECRET=$APP_SECRET

COPY ./.docker/services/web/conf.d/common.ini /usr/local/etc/php/conf.d/common.ini
COPY ./.docker/services/web/conf.d/${APP_ENV}.ini /usr/local/etc/php/conf.d/${APP_ENV}.ini

WORKDIR '/var/www'

COPY ./ ./

RUN chown -R www-data:nuvola \
    ./var \
    ./vendor \
    ./composer.lock \
    ./symfony.lock

RUN composer global require hirak/prestissimo
RUN composer install --no-interaction $(if [[ 'prod' == $APP_ENV ]]; then echo '--no-dev --optimize-autoloader'; fi;)
