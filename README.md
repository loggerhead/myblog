[![Travis Build Status](https://travis-ci.org/loggerhead/myblog.svg?branch=master)](https://travis-ci.org/loggerhead/myblog)
[![Docker image badge](https://images.microbadger.com/badges/image/loggerhead/myblog.svg)](https://microbadger.com/images/loggerhead/myblog)

# Server
## Setup

1. Put certificates to `/var/www/blog/cert`, including:

    ```
    loggerhead.me.bundle.pem
    loggerhead.me.key
    loggerhead.me.trusted.crt
    ```

2. `sudo scripts/setup-server.sh`

## Running

Setup environment variables in `scripts/server-envs.sh`

```bash
scripts/start-server.sh
```

# Client

```bash
pip install -r pelican-config/requirements.txt
ln -s scripts/blog.sh /usr/local/bin/blog.sh
```
