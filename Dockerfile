FROM improwised/php-base:8.2-s6-fbc6b8a-1703073981

RUN apk update && apk add php82-pear php82-dev autoconf zlib-dev libc-dev g++ linux-headers make

RUN pecl82 install gRPC

RUN sudo sed -i '$ a extension=grpc.so' /etc/php82/php.ini

RUN apk add tzdata libatk-1.0 libc6-compat libexpat fontconfig libgcc glib pango libstdc++6 libx11 libxcomposite libxcursor libxdamage libxext libxfixes libxi libxrandr libxrender libxtst ca-certificates nss lsb-release-minimal xdg-utils wget alsa-lib alsa-lib-dev font-liberation gtk+3.0 glib cairo cairo-dev cairo-tools nspr libxcb libxi mesa-dev mesa-gbm dbus gnome gdk-pixbuf libx11 libxcb libxscrnsaver libayatana-appindicator cups cups-libs

COPY apply-env /etc/s6-overlay/s6-rc.d/apply-env

RUN chmod 755 /etc/s6-overlay/s6-rc.d/apply-env/run

RUN chmod 755 /etc/s6-overlay/s6-rc.d/apply-env/up

RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/apply-env
