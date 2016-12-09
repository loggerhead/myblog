#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    SOURCE="$DIR/$TARGET"
  fi
done
SELF_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


JS_DIR=$SELF_DIR/js


# download_and_checksum(url, name)
download_and_checksum() {
    FILENAME=$2.js
    rm $JS_DIR/$2.*.js
    wget $1 -O $JS_DIR/$FILENAME
    # CHECKSUM=$( shasum -a 1 $JS_DIR/$FILENAME | head -c 7 )
    # cp $JS_DIR/$FILENAME $JS_DIR/$2.$CHECKSUM.js
}

download_and_checksum https://www.google-analytics.com/analytics.js ga
date +"%Y-%m-%d %H:%M:%S" > $SELF_DIR/update_js.log
