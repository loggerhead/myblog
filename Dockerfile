FROM ubuntu:16.04
MAINTAINER loggerhead "i@loggerhead.me"

ENV HOME /home/root
WORKDIR /home/root

RUN apt-get -y -qq update ;\
    apt-get -y -qq install build-essential checkinstall \
        libgd2-xpm-dev libgeoip-dev libxslt-dev zlib1g-dev \
        git aria2 python-pip python-dev ;\
    apt-get clean && rm -r /var/lib/apt/lists/* ;\
    pip install flask supervisor ;\
    mkdir -p /var/www/blog/cert
RUN git clone https://github.com/loggerhead/blog.loggerhead.me.git /var/www/blog/output
ADD nginx-config /etc/nginx
ADD update-site /var/www/blog/myblog-update

ADD scripts/build_nginx.sh /home/root/build_nginx.sh
RUN ["/bin/bash", "/home/root/build_nginx.sh"]
RUN rm -rf /home/root/build

COPY supervisord.conf /etc/supervisor/supervisord.conf

VOLUME ["/etc/nginx", "/var/www/blog/cert"]

CMD ["supervisord"]
