#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# add environment variable into files
dockerize -template /etc/php82/php.ini:/etc/php82/php.ini -template /etc/php82/php-fpm.conf:/etc/php82/php-fpm.conf -template /etc/php82/php-fpm.d:/etc/php82/php-fpm.d