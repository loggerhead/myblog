FROM jfloff/alpine-python:2.7
MAINTAINER loggerhead "lloggerhead@gmail.com"

ENV HOME /home/root
WORKDIR /home/root

RUN apk update && apk upgrade ;\
    apk add --no-cache bash git ;\
    apk add --update ca-certificates openssl ;\
    pip install flask supervisor ;\
    wget https://github.com/loggerhead/build_nginx/releases/download/latest/nginx.tar.gz ;\
    tar zxf nginx.tar.gz ;\
    mv nginx /usr/sbin/nginx ;\
    mkdir -p /var/www/blog/cert ;\
    rm nginx.tar.gz

ADD nginx-config /etc/nginx
ADD update-site /var/www/blog/myblog-update
COPY supervisord.conf /etc/supervisor/supervisord.conf
RUN git clone https://github.com/loggerhead/blog.loggerhead.me.git /var/www/blog/output

VOLUME ["/etc/nginx", "/var/www/blog/cert"]

CMD ["supervisord"]
