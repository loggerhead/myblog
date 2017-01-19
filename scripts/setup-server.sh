#!/usr/bin/env bash

if [ "$USER" != "root" ]; then
    echo "Need run with sudo!"
    exit 1
fi

set -o nounset
CNT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $CNT_DIR
source server-envs.sh

apt-get install -y logrotate
mkdir -p /etc/logrotate.d $CERT_DIR $NGX_LOG_DIR $NGX_RUN_DIR $NGX_CACHE_DIR
cp ../nginx.logrotate /etc/logrotate.d

set +o nounset
if [ "$1" == "hub" ]; then
    docker pull loggerhead/myblog
else
    docker pull daocloud.io/loggerhead/myblog
fi
