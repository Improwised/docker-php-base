FROM alpine:3.21

ENV DOCKERIZE_VERSION=v0.8.0
# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.5.0"
# set TARTGETARCH and S6_ARCH to map the s6-overlay arch naming conventions with the docker (TARGETARCH)
ARG TARGETARCH
ARG S6_ARCH

ENV UID=100 \
  GID=101 \
  FPM_LOG_LEVEL=warning
# Get architecture specific dockerize package
RUN set -eux \
  && DOCKERIZE_URL="" \
  && if [ "${TARGETARCH}" = "arm64" ]; then \
  DOCKERIZE_URL="https://github.com/jwilder/dockerize/releases/download/v0.8.0/dockerize-darwin-arm64-v0.8.0.tar.gz"; \
  elif [ "${TARGETARCH}" = "amd64" ]; then \
  DOCKERIZE_URL="https://github.com/jwilder/dockerize/releases/download/v0.8.0/dockerize-alpine-linux-amd64-v0.8.0.tar.gz"; \
  else \
  echo "Unsupported architecture: ${TARGETARCH}"; \
  exit 1; \
  fi \
  && wget -O dockerize.tar.gz "${DOCKERIZE_URL}" \
  && tar -C /usr/local/bin -xzvf dockerize.tar.gz  \
  && rm dockerize.tar.gz

################## INSTALLATION STARTS ##################

# Install OS Dependencies
RUN set -ex \
  && apk add --no-cache --virtual .build-deps \
  autoconf automake build-base python3 gmp-dev \
  curl \
  tar \
  xz \
  && apk add --no-cache --virtual .run-deps \
  nodejs npm \
  # PHP and extensions
  php84 php84-bcmath php84-ctype php84-curl php84-dom php84-exif php84-fileinfo \
  php84-fpm php84-gd php84-gmp php84-iconv php84-intl php84-mbstring \
  php84-mysqlnd php84-mysqli php84-opcache php84-openssl php84-pcntl php84-pecl-apcu php84-pdo php84-pdo_mysql \
  php84-phar php84-posix php84-session php84-simplexml php84-sockets php84-sqlite3 php84-tidy \
  php84-tokenizer php84-xml php84-xmlreader php84-xmlwriter php84-zip php84-pecl-xdebug php84-pecl-redis php84-soap php84-sodium php84-pdo_sqlite php84-pdo_pgsql php84-pgsql \
  # Other dependencies
  mariadb-client sudo shadow \
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
  && php84 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php84 -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php84 composer-setup.php --install-dir=/usr/bin --filename=composer \
  && php84 -r "unlink('composer-setup.php'); unlink('installer.sig');" \
  # Cleanup
  && apk del .build-deps

##################  INSTALLATION ENDS  ##################

# add s6 overlay based on architecture
RUN set -eux \
  && S6_ARCH="" \
  && if [ "${TARGETARCH}" = "amd64" ]; then S6_ARCH="x86_64"; \
  elif [ "${TARGETARCH}" = "arm64" ]; then S6_ARCH="aarch64"; fi\
  && if [ -z "${S6_ARCH}" ]; then { echo "Error: Not able to determine arch"; exit 1; }; fi \
  && echo "Installing s6-overlay for ${S6_ARCH}" \
  && wget "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
  && wget "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
  && tar -C / -Jxpf s6-overlay-noarch.tar.xz \
  && tar -C / -Jxpf s6-overlay-${S6_ARCH}.tar.xz 

# add s6 optional symlinks
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz


##################  CONFIGURATION STARTS  ##################

ADD rootfs /

RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
  ln -s /etc/php84/php.ini /etc/php84/conf.d/php.ini && \
  ln -s /usr/bin/php84 /usr/bin/php && \
  chown -R nginx:nginx /var/www && \
  chmod 755 /etc/s6-overlay/s6-rc.d/*/run && \
  chmod 755 /etc/s6-overlay/s6-rc.d/*/up && \
  mkdir -p /var/www/storage/logs/ && \
  touch /var/www/storage/logs/laravel.log /var/log/nginx/error.log /var/log/php84/error.log

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

ENTRYPOINT ["/init"]
