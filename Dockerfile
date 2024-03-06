FROM alpine:3.18

ENV DOCKERIZE_VERSION v0.6.1
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
    nodejs npm \
    # PHP and extensions
    php81 php81-bcmath php81-ctype php81-curl php81-dom php81-exif php81-fileinfo \
    php81-fpm php81-gd php81-gmp php81-iconv php81-intl php81-mbstring \
    php81-mysqlnd php81-mysqli php81-opcache php81-openssl php81-pcntl php81-pecl-apcu php81-pdo php81-pdo_mysql \
    php81-phar php81-posix php81-session php81-simplexml php81-sockets php81-sqlite3 php81-tidy \
    php81-tokenizer php81-xml php81-xmlreader php81-xmlwriter php81-zip php81-pecl-xdebug php81-pecl-redis php81-soap php81-sodium php81-pdo_sqlite php81-pdo_pgsql php81-pgsql \
    # Other dependencies
    mariadb-client sudo shadow \
    # Miscellaneous packages
    bash ca-certificates dialog git libjpeg libpng-dev openssh-client supervisor vim wget \
    # Nginx
    nginx \
    # Create directories
    && mkdir -p /etc/nginx \
    && mkdir -p /run/nginx \
    && mkdir -p /etc/nginx/sites-available \
    && mkdir -p /etc/nginx/sites-enabled \
    && mkdir -p /var/log/supervisor \
    && rm -Rf /var/www/* \
    && rm -Rf /etc/nginx/nginx.conf \
    # Composer
    && wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig \
    && php81 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php81 -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php81 composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php81 -r "unlink('composer-setup.php'); unlink('installer.sig');" \
    # Cleanup
    && apk del .build-deps

##################  INSTALLATION ENDS  ##################

##################  CONFIGURATION STARTS  ##################

ADD rootfs /

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/php81/php.ini /etc/php81/conf.d/php.ini && \
    chown -R nginx:nginx /var/www && \
    mkdir -p /var/www/storage/logs/ && \
    touch /var/www/storage/logs/laravel.log /var/log/nginx/error.log /var/log/php81/error.log

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

ENTRYPOINT ["dockerize", \
    "-template", "/etc/php81/php.ini:/etc/php81/php.ini", \
    "-template", "/etc/php81/php-fpm.conf:/etc/php81/php-fpm.conf", \
    "-template", "/etc/php81/php-fpm.d:/etc/php81/php-fpm.d", \
    "-stdout", "/var/www/storage/logs/laravel.log", \
    "-stdout", "/var/log/nginx/error.log", \
    "-stdout", "/var/log/php81/error.log", \
    "-poll"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
