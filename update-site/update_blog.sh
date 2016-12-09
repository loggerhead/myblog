#!/bin/bash
function update_at {
    cd $1
    git fetch origin
    if [[ $? != 0 ]]; then
        echo "fetch failed"
        exit 1
    fi
    git reset --hard origin/master
    if [[ $? != 0 ]]; then
        echo "reset failed"
        exit 1
    fi
}

update_at /var/www/blog/output
update_at /etc/nginx
