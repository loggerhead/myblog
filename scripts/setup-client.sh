#!/usr/bin/env bash

CNT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $CNT_DIR/..
source scripts/client-envs.sh

pip install -r pelican-config/requirements.txt
ln -s $BLOG_CONTENT_DIR $PWD/pelican-config/content
ln -s $PWD/scripts/blog.sh /usr/local/bin/blog.sh

echo "append following environment variables to ~/.profile"
echo "    export BLOG_WORKDIR=$PWD/pelican-config/"
