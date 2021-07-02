FROM alpine:3.14
LABEL MAINTAINER "Rakshit Menpara <rakshit@improwised.com>"

ENV composer_hash 48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

################## INSTALLATION STARTS ##################

# Install OS Dependencies
RUN set -ex \
  && apk add --no-cache --virtual .build-deps \
    gmp-dev tar \
  && apk add --no-cache --virtual .run-deps \
    curl \
    nodejs npm \
    # PHP and extensions
    php7 php7-apcu php7-bcmath php7-dom php7-ctype php7-curl php7-exif php7-fileinfo \
    php7-fpm php7-gd php7-gmp php7-iconv php7-intl php7-json php7-mbstring php7-mcrypt \
    php7-mysqlnd php7-mysqli php7-opcache php7-openssl php7-pcntl php7-pdo php7-pdo_mysql \
    php7-phar php7-posix php7-session php7-simplexml php7-sockets php7-sqlite3 php7-tidy \
    php7-tokenizer php7-xml php7-xmlwriter php7-zip php7-zlib php7-redis php7-soap \
    # Other dependencies
    mariadb-client sudo \
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
  && php7 -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer', 'composer-setup.php');" \
    && php7 -r "if (hash_file('SHA384', 'composer-setup.php') === '${composer_hash}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php7 composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php7 -r "unlink('composer-setup.php');" \
  # Cleanup
  && apk del .build-deps

##################  INSTALLATION ENDS  ##################

##################  CONFIGURATION STARTS  ##################

ADD rootfs /

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
    chown -R nginx:nginx /var/www && \
    mkdir -p /var/www/storage/logs/ && \
    touch /var/www/storage/logs/laravel.log /var/log/nginx/error.log /var/log/php7/error.log

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

ENTRYPOINT ["dockerize", \
    "-template", "/etc/php7/php.ini:/etc/php7/php.ini", \
    "-template", "/etc/php7/php-fpm.conf:/etc/php7/php-fpm.conf", \
    "-template", "/etc/php7/php-fpm.d:/etc/php7/php-fpm.d", \
    "-stdout", "/var/www/storage/logs/laravel.log", \
    "-stdout", "/var/log/nginx/error.log", \
    "-stdout", "/var/log/php7/error.log", \
    "-poll"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
