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
4. Append following environments to `.profile`, `.zshrc` or `.bashrc`:

    ```bash
    export BLOG_UPDATE_URL="/coding/push"
    export BLOG_WEBHOOK_TOKEN="YOUR_SECRET_IN_WEBHOOK"
    ```

## Running

Setup environment variables in `scripts/server-envs.sh`

```bash
scripts/start-server.sh
```

# Client

```bash
scripts/setup-client.sh
```
