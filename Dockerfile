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
    php82 php82-bcmath php82-ctype php82-curl php82-dom php82-exif php82-fileinfo \
    php82-fpm php82-gd php82-gmp php82-iconv php82-intl php82-mbstring \
    php82-mysqlnd php82-mysqli php82-opcache php82-openssl php82-pcntl php82-pecl-apcu php82-pdo php82-pdo_mysql \
    php82-phar php82-posix php82-session php82-simplexml php82-sockets php82-sqlite3 php82-tidy \
    php82-tokenizer php82-xml php82-xmlreader php82-xmlwriter php82-zip php82-pecl-xdebug php82-pecl-redis php82-soap php82-sodium php82-pdo_sqlite php82-pdo_pgsql php82-pgsql \
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
    && php82 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php82 -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php82 composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php82 -r "unlink('composer-setup.php'); unlink('installer.sig');" \
    # Cleanup
    && apk del .build-deps

##################  INSTALLATION ENDS  ##################

##################  CONFIGURATION STARTS  ##################

ADD rootfs /

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/php82/php.ini /etc/php82/conf.d/php.ini && \
    ln -s /usr/bin/php82 /usr/bin/php && \
    chown -R nginx:nginx /var/www && \
    mkdir -p /var/www/storage/logs/ && \
    touch /var/www/storage/logs/laravel.log /var/log/nginx/error.log /var/log/php82/error.log

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

ENTRYPOINT ["dockerize", \
    "-template", "/etc/php82/php.ini:/etc/php82/php.ini", \
    "-template", "/etc/php82/php-fpm.conf:/etc/php82/php-fpm.conf", \
    "-template", "/etc/php82/php-fpm.d:/etc/php82/php-fpm.d", \
    "-stdout", "/var/www/storage/logs/laravel.log", \
    "-stdout", "/var/log/nginx/error.log", \
    "-stdout", "/var/log/php82/error.log", \
    "-poll"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
