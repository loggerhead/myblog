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
3. Setup `Secret` in GitHub webhook or `token` in Coding webhook.

## Running

Setup environment variables in `scripts/server-envs.sh`

```bash
scripts/start-server.sh
```

# Client

```bash
scripts/setup-client.sh
```
