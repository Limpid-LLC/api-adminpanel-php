# syntax=docker/dockerfile:1.2

FROM --platform=linux/amd64 php:8.0-fpm-alpine3.14 as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

# install composer, image page: <https://hub.docker.com/_/composer>
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"

RUN set -x \
    && apk add --no-cache \
        busybox \
        ca-certificates \
        fcgi \
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
    # enable opcache for CLI and JIT, docs: <https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit>
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> \
        ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    #php-fpm healthcheck https://github.com/renatomefi/php-fpm-healthcheck
    && curl -Lo /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck
