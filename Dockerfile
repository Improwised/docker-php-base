FROM alpine:edge

ENV DOCKERIZE_VERSION v0.6.1
# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.5.0"
ARG S6_OVERLAY_ARCH="x86_64"
ENV UID=100 \
    GID=101 \
    FPM_LOG_LEVEL=warning

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

################## INSTALLATION STARTS ##################

# Install OS Dependencies
RUN set -ex \
  && apk add --no-cache --virtual .build-deps \
    autoconf automake build-base python3 gmp-dev \
    curl \
    tar \
    && apk add --no-cache --virtual .run-deps \
    nodejs npm libavif \
    && apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community add \
    # PHP and extensions
    php83 php83-bcmath php83-ctype php83-curl php83-dom php83-exif php83-fileinfo \
    php83-fpm php83-gd php83-gmp php83-iconv php83-intl php83-mbstring \
    php83-mysqlnd php83-mysqli php83-opcache php83-openssl php83-pcntl php83-pecl-apcu php83-pdo php83-pdo_mysql \
    php83-phar php83-posix php83-session php83-simplexml php83-sockets php83-sqlite3 php83-tidy \
    php83-tokenizer php83-xml php83-xmlreader php83-xmlwriter php83-zip php83-pecl-xdebug php83-pecl-redis php83-soap php83-sodium php83-pdo_sqlite php83-pdo_pgsql php83-pgsql \
    # Other dependencies
    mariadb-client sudo \
    # Miscellaneous packages
    bash ca-certificates dialog git libjpeg libpng-dev openssh-client vim wget shadow \
    # Nginx
    nginx \
    # Create directories
  && mkdir -p /etc/nginx \
    && mkdir -p /run/nginx \
    && mkdir -p /etc/nginx/sites-available \
    && mkdir -p /etc/nginx/sites-enabled \
    && rm -Rf /var/www/* \
    && rm -Rf /etc/nginx/nginx.conf \
  # Composer
  && wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig \
    && php83 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php83 -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php83 composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php83 -r "unlink('composer-setup.php'); unlink('installer.sig');" \
  # Cleanup
  && apk del .build-deps

##################  INSTALLATION ENDS  ##################

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# add s6 optional symlinks
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

##################  CONFIGURATION STARTS  ##################

ADD rootfs /

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/php83/php.ini /etc/php83/conf.d/php.ini && \
    rm -rf /usr/bin/php && \
    ln -s /usr/bin/php83 /usr/bin/php && \
    chown -R nginx:nginx /var/www && \
    chmod 755 /etc/s6-overlay/s6-rc.d/*/run && \
    chmod 755 /etc/s6-overlay/s6-rc.d/*/up && \
    mkdir -p /var/www/storage/logs/ && \
    touch /var/www/storage/logs/laravel.log /var/log/nginx/error.log /var/log/php83/error.log

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

ENTRYPOINT ["/init"]
