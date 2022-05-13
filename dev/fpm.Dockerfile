# syntax=docker/dockerfile:1.2

FROM --platform=linux/amd64 php:8.0-fpm-alpine3.14 as runtime

LABEL org.opencontainers.image.source=https://github.com/Limpid-LLC/api-adminpanel-php

# install composer, image page: <https://hub.docker.com/_/composer>
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_HOME="/tmp/composer"
ENV PHP_EXT_MPDECIMAL_VERSION 2.5.1
ENV PHP_EXT_REDIS_VERSION 5.3.4

RUN apk add gnu-libiconv=1.15-r3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

RUN set -x \
    # install permanent dependencies
    && apk add --no-cache \
        busybox \
        ca-certificates \
        fcgi \
        freetds \
        freetype \
        gettext \
        gmp \
        icu-libs \
        imagemagick \
        libffi \
        libgmpxx \
        libintl \
        libjpeg-turbo \
        libmcrypt \
        libpng \
        libpq \
        libssh2 \
        libstdc++ \
        libtool \
        libxpm \
        libxslt \
        libzip \
        make \
        tidyhtml \
        tzdata \
        vips \
        yaml \
    && cp /usr/share/zoneinfo/Europe/Kiev /etc/localtime && \
    echo "Europe/Kiev" > /etc/timezone && \
    date && \
    apk del --purge tzdata && \
    rm -rf \
      /tmp/* \
      /var/cache/apk/* \
      /var/lib/apt/lists/*
    # install build-time dependencies
RUN set -eux \
    && apk add --no-cache --virtual .build-deps \
        g++ \
        autoconf \
        cmake \
        curl-dev \
        freetds-dev \
        freetype-dev \
        gcc \
        gettext-dev \
        git \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        libc-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libssh2-dev \
        libwebp-dev \
        libxml2-dev \
        libxpm-dev \
        libxslt-dev \
        libzip-dev \
        openssl-dev \
        pcre-dev \
        pkgconf \
        postgresql-dev \
        tidyhtml-dev \
        vips-dev \
        yaml-dev \
        zlib-dev \
    # Enable ffi if it exists
    && set -eux \
    && if [ -f /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini ]; then \
        echo "ffi.enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini; \
    fi \
    # Install extensions
    && docker-php-ext-install -j$(nproc) \
    gettext \
    gmp \
    bcmath \
    exif \
    intl \
    mysqli \
    opcache \
    pdo_dblib \
    pdo_pgsql \
    pcntl \
    pgsql \
    soap \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    tidy \
    xsl \
    # Pecl install extensions
    && pecl install \
    oauth \
    ssh2-1.3.1 \
    yaml \
    vips \
    igbinary \
    mcrypt \
    && docker-php-ext-enable igbinary \
    # Redis
    && yes | pecl install redis \
    && docker-php-ext-enable redis \
    # Configure extensions
    # gd
    && ln -s /usr/lib/x86_64-linux-gnu/libXpm.* /usr/lib/ \
    && docker-php-ext-configure gd \
        --enable-gd \
        --with-webp \
        --with-jpeg \
        --with-xpm \
        --with-freetype \
        --enable-gd-jis-conv \
    && docker-php-ext-install -j$(nproc) gd \
    # Install pdo_mysql
    && docker-php-ext-configure pdo_mysql --with-zlib-dir=/usr \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    # Install zip
    && docker-php-ext-configure zip --with-zip \
    && docker-php-ext-install -j$(nproc) zip \
    # Install imagick
    # Note: Build from source until the pecl release is ready for PHP 8
    && git clone --depth=1 https://github.com/Imagick/imagick \
    && cd imagick \
    && phpize && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd ../ \
    && rm -rf imagick \
    # Install php-decimal
    && curl https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${PHP_EXT_MPDECIMAL_VERSION}.tar.gz \
    | tar -zxC /tmp/ && cd /tmp/mpdecimal-${PHP_EXT_MPDECIMAL_VERSION} \
    && ./configure && make -j$(nproc) CFLAGS=-DNDEBUG && make -j$(nproc) check && make -j$(nproc) install \
    && pecl install decimal \
    && rm -rf /tmp/mpdecimal-${PHP_EXT_MPDECIMAL_VERSION} \
    # Enable extensions
    && docker-php-ext-enable \
    oauth \
    ssh2 \
    yaml \
    mcrypt \
    gd \
    pdo_mysql \
    zip \
    imagick \
    decimal \
    vips \
    # make clean up
    && docker-php-source delete \
    && apk del .build-deps \
    # enable opcache for CLI and JIT, docs: <https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit> \
    # cant use 1233+ cuz of JIT bug with PDF generation
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1232\n" >> \
        ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    #php-fpm healthcheck https://github.com/renatomefi/php-fpm-healthcheck
    && curl -Lo /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck
