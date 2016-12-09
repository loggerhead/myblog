[![Travis Build Status](https://travis-ci.org/loggerhead/myblog.svg?branch=master)](https://travis-ci.org/loggerhead/myblog)
[![Docker image badge](https://images.microbadger.com/badges/image/loggerhead/myblog.svg)](https://microbadger.com/images/loggerhead/myblog)

#服务器
##下载配置
```bash
mkdir -p /var/www/blog/cert
git clone https://git.coding.net/loggerhead/myblog-nginx.git /etc/nginx
```

使用 `scp` 命令将证书放到服务器的 `/var/www/blog/cert`

##运行
```bash
docker run -d -p 80:80 -p 443:443 -p 54321:54321 -v /etc/nginx:/etc/nginx -v /var/www/blog/cert:/var/www/blog/cert loggerhead/myblog
```

会自动从 Docker Hub 拉取，如果速度不行，使用 https://daocloud.io

```bash
docker login daocloud.io
docker pull daocloud.io/loggerhead/myblog
```

##手动构建
```bash
docker build --rm -t loggerhead/myblog .
```

#客户端
```bash
ln -s scripts/blog.sh /usr/local/bin/blog.sh
```

