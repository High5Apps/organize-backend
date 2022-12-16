FROM nginx:1.22

RUN apt update \
  && apt install -y inotify-tools \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY docker/web/nginx.conf /etc/nginx/nginx.conf
COPY docker/web/docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh
COPY docker/web/nginx-auto-reloader.sh /usr/src/app/nginx-auto-reloader.sh

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
