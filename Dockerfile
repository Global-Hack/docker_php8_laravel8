FROM php:8.0.13-fpm-alpine

COPY ./www/exec /work/exec
RUN chmod 777 /work/exec
RUN find /work/exec -type d -print0 | xargs -0 chmod 755
RUN chown -R www-data:www-data /work/exec
COPY ./www/laravel /work/www
# COPY ./www /work/www
COPY ./infra/docker/php/php-fpm.d/zzz-www.conf /usr/local/etc/php-fpm.d/zzz-www.conf
COPY ./infra/docker/php/php.ini /usr/local/etc/php/php.ini

# timezone environment
ENV TZ=Asia/Tokyo
# locale
ENV LANG=ja_JP.UTF-8
# JSTに変更
RUN apk add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN apk add --no-cache mysql-client msmtp perl wget procps shadow libzip libpng libjpeg-turbo libwebp freetype icu

RUN apk add --no-cache --virtual build-essentials \
    icu-dev icu-libs zlib-dev g++ make automake autoconf libzip-dev \
    libpng-dev libwebp-dev libjpeg-turbo-dev freetype-dev && \
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install intl && \
    docker-php-ext-install opcache && \
    docker-php-ext-install exif && \
    docker-php-ext-install zip && \
    apk del build-essentials && rm -rf /usr/src/php*

# for imap
RUN apk add imap-dev krb5-dev libressl-dev

# 使用するモジュール追加
RUN apk add --no-cache php8-bcmath php8-pecl-memcached unzip less
RUN docker-php-ext-install intl pdo_mysql opcache zip bcmath exif
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd
    
# for imap
RUN PHP_OPENSSL=yes \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-enable imap

# for libreoffice
RUN mkdir -p /usr/share/man/man1
RUN apk add --no-cache libreoffice

# for composer
ENV COMPOSER_VERSION 1.8.0

RUN curl -L -O https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar && \
    chmod +x composer.phar && mv composer.phar /usr/local/bin/composer

WORKDIR /work/www
