# syntax=docker/dockerfile:1.2

FROM --platform=linux/amd64 php:8.0-cli as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

# install composer, image page: <https://hub.docker.com/_/composer>
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"

RUN install-php-extensions \
    bcmath \
    decimal \
    exif \
    gd \
    gettext \
    gmp \
    igbinary \
    imagick \
    intl \
    mcrypt \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    psr \
    redis \
    ssh2 \
    tidy \
    vips \
    xsl \
    yaml \
    zip \
    zstd
    
RUN set -eux \
    # install supercronic (for laravel task scheduling), project page: <https://github.com/aptible/supercronic>
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64" \
         -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \

