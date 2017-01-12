#!/bin/bash

WORKDIR=${BLOG_WORKDIR-$HOME/myblog}
EDITOR=${EDITOR-vim}

cd $WORKDIR

if [[ $1 == "upload" ]]; then
    make publish
    cd output/

    git add -A && git commit --amend -m 'update'
    git push -fu origin master
    curl $BLOG_UPDATE_URL
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
fi
