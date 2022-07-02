FROM php:8.0-fpm-alpine

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

RUN apk upgrade --update && \
  apk --no-cache add icu-dev autoconf make g++ gcc ca-certificates wget curl

# for gd
RUN apk add --no-cache \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev

# for imap
RUN apk add imap-dev krb5-dev libressl-dev

# 使用するモジュール追加
RUN apk add --no-cache php8-bcmath php8-pecl-memcached unzip libzip-dev less
RUN docker-php-ext-install intl pdo_mysql opcache zip bcmath exif

RUN docker-php-ext-configure gd --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
    
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
