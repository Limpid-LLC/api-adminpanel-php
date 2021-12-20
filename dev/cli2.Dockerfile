# syntax=docker/dockerfile:1.2

FROM --platform=linux/amd64 php:8.0-cli-alpine3.14 as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

# install composer, image page: <https://hub.docker.com/_/composer>
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"

RUN apk add gnu-libiconv=1.15-r3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

RUN set -x \
    # install permanent dependencies
    && apk add --no-cache \
        ca-certificates \
        tzdata \
    && cp /usr/share/zoneinfo/Europe/Kiev /etc/localtime && \
    echo "Europe/Kiev" > /etc/timezone && \
    date && \
    apk del --purge tzdata && \
    rm -rf \
      /tmp/* \
      /var/cache/apk/* \
      /var/lib/apt/lists/*

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
    mysqli \
    oauth \
    opcache \
    pcntl \
    pdo_dblib \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    psr \
    redis \
    soap \
    sockets \
    ssh2 \
    sysvmsg \
    sysvsem \
    sysvshm \
    tidy \
    vips \
    xsl \
    yaml \
    zip \
    zstd
    
RUN set -eux \
    # Enable ffi if it exists
    && if [ -f /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini ]; then \
        echo "ffi.enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini; \
    fi \
    # install supercronic (for laravel task scheduling), project page: <https://github.com/aptible/supercronic>
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64" \
         -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    # enable opcache for CLI and JIT, docs: <https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit> \
    # cant use 1233+ cuz of JIT bug with PDF generation
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1232\n" >> \
        ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini
