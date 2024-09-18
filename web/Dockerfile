FROM nginx:1.25.2 as prod

RUN apt update \
  && apt install -y inotify-tools \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY rails-proxy.conf /etc/nginx/rails-proxy.conf
COPY docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-auto-reloader.sh /usr/src/app/nginx-auto-reloader.sh
COPY store.conf /etc/nginx/store.conf

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]

FROM prod AS dev

COPY nginx.development.conf /etc/nginx/nginx.development.conf

FROM prod
