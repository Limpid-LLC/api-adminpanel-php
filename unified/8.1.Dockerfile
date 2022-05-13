# syntax=docker/dockerfile:1.2

FROM --platform=linux/amd64 php:8.1-fpm-alpine as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"

RUN install-php-extensions \
    @composer \
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
    redis \
    soap \
    ssh2 \
    tidy \
    vips \
    xsl \
    yaml \
    zip \
    zstd \
    xdebug
