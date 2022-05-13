# syntax=docker/dockerfile:1.2
FROM ghcr.io/roadrunner-server/roadrunner:2.9.4 AS roadrunner
FROM mlocati/php-extension-installer:latest AS extension-installer
FROM premoweb/chadburn:1.0.1 as cron
FROM --platform=linux/amd64 php:8.1-fpm-alpine as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr
COPY --from=extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=cron /usr/bin/chadburn /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"

RUN apk add --no-cache bash && \
    install-php-extensions \
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
