ARG NGINX_VERSION=1.26.2
ARG NGINX_MODULE_VTS_VERSION=v0.2.2

FROM nginx:${NGINX_VERSION}-alpine AS builder
ARG NGINX_MODULE_VTS_VERSION

RUN apk add --update --no-cache --virtual .build-deps \
  curl \
  gd-dev \
  geoip-dev \
  libc-dev \
  libxslt-dev \
  linux-headers \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  gcc \
  git \
  tar

RUN git clone https://github.com/vozlt/nginx-module-vts.git \
  --branch ${NGINX_MODULE_VTS_VERSION} \
  --depth=1

RUN curl -LO https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar -zxf nginx-${NGINX_VERSION}.tar.gz

WORKDIR /nginx-${NGINX_VERSION}

RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p')
RUN ./configure --with-compat $CONFARGS \
  --add-dynamic-module=../nginx-module-vts \
  && make modules
RUN cp objs/ngx_http_vhost_traffic_status_module.so \
  /usr/lib/nginx/modules/ngx_http_vhost_traffic_status_module.so

FROM nginx:${NGINX_VERSION}-alpine AS prod

COPY --from=builder \
  /usr/lib/nginx/modules/ngx_http_vhost_traffic_status_module.so \
  /etc/nginx/modules

RUN apk add --update --no-cache inotify-tools

WORKDIR /usr/src/app

COPY rails-proxy.conf /etc/nginx/rails-proxy.conf
COPY docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-auto-reloader.sh /usr/src/app/nginx-auto-reloader.sh
COPY server-locations.conf /etc/nginx/server-locations.conf
COPY store.conf /etc/nginx/store.conf
COPY public public
COPY vhost-traffic-status.conf /etc/nginx/vhost-traffic-status.conf

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]

FROM prod AS dev

COPY nginx.development.conf /etc/nginx/nginx.development.conf

FROM prod
