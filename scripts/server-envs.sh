#!/usr/bin/env bash

# any HTTP GET or POST on this URL will trigger update
export BLOG_UPDATE_URL="/coding/push"

# do NOT modify below environment variables
# the directory of HTTPS certificate
export CERT_DIR=/var/www/blog/cert
export NGX_LOG_DIR=/var/log/nginx
export NGX_RUN_DIR=/var/run/nginx
export NGX_CACHE_DIR=/var/cache/nginx
