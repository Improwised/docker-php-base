#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# copy default config files if they don't exist
if [[ ! -f /etc/nginx/sites-enabled/default.conf ]]; then
    cp /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
fi