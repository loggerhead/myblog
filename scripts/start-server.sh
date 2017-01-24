#!/usr/bin/env bash

set -o nounset
CNT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $CNT_DIR
source server-envs.sh

set +o nounset
if [ "$1" == "hub" ]; then
    IMAGE_NAME="loggerhead/myblog"
else
    IMAGE_NAME="daocloud.io/loggerhead/myblog"
fi
set -o nounset

docker run -d -p 80:80 -p 443:443 -p 54321:54321 \
    -e BLOG_UPDATE_URL=$BLOG_UPDATE_URL          \
    -e BLOG_WEBHOOK_TOKEN=$BLOG_WEBHOOK_TOKEN    \
    -v /etc/nginx:/etc/nginx                     \
    -v $CERT_DIR:$CERT_DIR                       \
    -v $NGX_LOG_DIR:$NGX_LOG_DIR                 \
    -v $NGX_RUN_DIR:$NGX_RUN_DIR                 \
    -v $NGX_CACHE_DIR:$NGX_CACHE_DIR             \
    $IMAGE_NAME
