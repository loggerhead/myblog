[![Travis Build Status](https://travis-ci.org/loggerhead/myblog.svg?branch=master)](https://travis-ci.org/loggerhead/myblog)
[![Docker image badge](https://images.microbadger.com/badges/image/loggerhead/myblog.svg)](https://microbadger.com/images/loggerhead/myblog)

# Server
## Config HTTPS

```bash
CERT_HOME=/var/www/blog/cert
mkdir -p $CERT_HOME

# put your certificate to $CERT_HOME, including:
#
#     loggerhead.me.bundle.pem
#     loggerhead.me.key
#     loggerhead.me.trusted.crt
```

## Running
```bash
docker run -d -p 80:80 -p 443:443 -p 54321:54321 \
    -v /var/www/blog/cert:/var/www/blog/cert \
    loggerhead/myblog
```

For Chinese user, use https://daocloud.io instead.

```bash
docker login daocloud.io
docker pull daocloud.io/loggerhead/myblog
```

# Client

```bash
pip install -r pelican-config/requirements.txt
ln -s scripts/blog.sh /usr/local/bin/blog.sh
```
