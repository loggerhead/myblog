#!/bin/bash

# names of latest versions of each package
NGINX_VERSION=1.11.1
NPS_VERSION=1.11.33.2
VERSION_PCRE=pcre-8.38
VERSION_NGINX=nginx-$NGINX_VERSION
VERSION_LIBRESSL=libressl-2.4.0
VERSION_PAGESPEED=release-${NPS_VERSION}-beta
PAGESPEED_DIRNAME=ngx_pagespeed-${VERSION_PAGESPEED}

# URLs to the source directories
SOURCE_PCRE=http://ftp.csx.cam.ac.uk/pub/software/programming/pcre
SOURCE_NGINX=http://nginx.org/download
SOURCE_LIBRESSL=http://ftp.openbsd.org/pub/OpenBSD/LibreSSL
SOURCE_PAGESPEED=https://github.com/pagespeed/ngx_pagespeed/archive

# set where LibreSSL and nginx will be built
DOWNLOAD_LIST=packages_list.txt
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BPATH=$DIR/build
STATICLIBSSL=$BPATH/$VERSION_LIBRESSL

# clean out previous compile result
find $BPATH -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
mkdir -p $BPATH
cd $BPATH
echo "Download sources"
echo -n > $DOWNLOAD_LIST
echo $SOURCE_PCRE/$VERSION_PCRE.tar.gz           >> $DOWNLOAD_LIST
echo $SOURCE_NGINX/$VERSION_NGINX.tar.gz         >> $DOWNLOAD_LIST
echo $SOURCE_LIBRESSL/$VERSION_LIBRESSL.tar.gz   >> $DOWNLOAD_LIST
echo $SOURCE_PAGESPEED/$VERSION_PAGESPEED.tar.gz >> $DOWNLOAD_LIST
aria2c -c -j20 -Z -i $DOWNLOAD_LIST
echo "Extract Packages"
tar xzf $VERSION_PCRE.tar.gz
tar xzf $VERSION_NGINX.tar.gz
tar xzf $VERSION_LIBRESSL.tar.gz

tar xzf $PAGESPEED_DIRNAME.tar.gz
cd $PAGESPEED_DIRNAME
aria2c -c https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar xzf ${NPS_VERSION}.tar.gz
cd $BPATH/../

# build static LibreSSL
echo "Configure & Build LibreSSL"
cd $STATICLIBSSL
./configure LDFLAGS=-lrt --prefix=${STATICLIBSSL}/.openssl/ \
&& make install-strip

# build nginx, with various modules included/excluded
echo "Configure & Build Nginx"
cd $BPATH/$VERSION_NGINX
NGINX_LOG_DIR=/var/log/nginx
NGINX_CACHE_DIR=/var/cache/nginx
mkdir -p $NGINX_LOG_DIR $NGINX_CACHE_DIR

./configure --with-openssl=$STATICLIBSSL \
            --with-ld-opt="-lrt"  \
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=$NGINX_LOG_DIR/error.log \
            --http-log-path=$NGINX_LOG_DIR/access.log \
            --pid-path=/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=$NGINX_CACHE_DIR/fastcgi_temp \
            --http-uwsgi-temp-path=$NGINX_CACHE_DIR/uwsgi_temp \
            --http-scgi-temp-path=$NGINX_CACHE_DIR/scgi_temp \
            --with-ipv6 \
            --without-mail_pop3_module \
            --without-mail_smtp_module \
            --without-mail_imap_module \
            --with-http_v2_module \
            --with-http_ssl_module \
            --with-http_gzip_static_module \
            --with-http_stub_status_module \
            --with-http_image_filter_module \
            --with-http_stub_status_module \
            --with-http_realip_module \
            --with-http_auth_request_module \
            --with-http_addition_module \
            --with-http_geoip_module \
            --with-http_gzip_static_module \
            --with-file-aio \
            --with-pcre-jit \
            --with-pcre=$BPATH/$VERSION_PCRE \
            --add-module=$BPATH/$PAGESPEED_DIRNAME

touch $STATICLIBSSL/.openssl/include/openssl/ssl.h
echo "Create Nginx one-click deb file at $BPATH/$VERSION_NGINX/nginx-libressl_$NGINX_VERSION-*.deb"
make \
&& checkinstall --pkgname="nginx-libressl" \
                --pkgversion="$NGINX_VERSION" \
                --provides="nginx" \
                --requires="libc6, libpcre3, zlib1g" \
                --strip=yes \
                --stripso=yes \
                --backup=yes -y \
                --install=yes

dpkg -i nginx-libressl_$NGINX_VERSION-*.deb
echo "All done."
echo "This build has not edited your existing /etc/nginx directory."
echo "NOTICE: if you failed because 'cc: Internal error: Killed', remove the '-j' option behind 'make' command."
