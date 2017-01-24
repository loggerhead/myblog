#!/usr/bin/env bash

# POST ("application/json") on this URL will trigger update
export BLOG_UPDATE_URL=
# BUT also need correct webhook token
export BLOG_WEBHOOK_TOKEN=

# do NOT modify below environment variables
# the directory of HTTPS certificate
export CERT_DIR=/var/www/blog/cert
export NGX_LOG_DIR=/var/log/nginx
export NGX_RUN_DIR=/var/run/nginx
export NGX_CACHE_DIR=/var/cache/nginx
