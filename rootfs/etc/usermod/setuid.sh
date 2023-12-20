#!/usr/bin/env bash

echo "User Id $UID, Group id $GID"
usermod -u "$UID" nginx && groupmod -g "$GID" nginx
