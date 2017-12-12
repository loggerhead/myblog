#!/bin/bash

set -e

WORKDIR=${BLOG_WORKDIR}
EDITOR=${EDITOR-vim}

cd $WORKDIR

if [[ $1 == "upload" ]]; then
    make publish
    cd output/

    git add -A && git commit -m 'update'
    git push -u origin master
    FTP_CMD="mirror -R output htdocs; exit"
    lftp -e "$FTP_CMD" -u "$WWHOST_FTP_USER","$WWHOST_FTP_PASSWORD" "ftp://$WWHOST_IP"
    # curl http://www.loggerhead.me:54321/coding/push
elif [[ $1 == "stop" ]] || [[ $1 == "stopserver" ]]; then
    make stopserver
elif [[ $1 == "make" ]]; then
    make DEBUG=1 html
elif [[ $1 == "open" ]]; then
    open $WORKDIR
elif [[ $1 == "diff" ]]; then
    git diff --color
elif [[ $1 == "self" ]]; then
    $EDITOR $0
elif [[ $1 == "dir" ]]; then
    echo -n $WORKDIR
elif [[ $1 == "server" ]]; then
    make devserver
elif [[ -z $1 ]]; then
    make html
    make devserver
else
    echo "$0 [OPTIONS]"
    echo -e "\t          Make devserver"
    echo -e "\tupload    Update articles"
    echo -e "\tstop      Stop devserver"
    echo -e "\tmake      Make html"
    echo -e "\topen      Open blog directory"
    echo -e "\tdiff      Git diff my theme"
    echo -e "\tself      Edit this script by $EDITOR"
    echo -e "\tdir       Print work directory"
    echo -e "\tserver    Run debug server"
fi
