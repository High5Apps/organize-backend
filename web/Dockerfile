FROM nginx:1.25.2

RUN apt update \
  && apt install -y inotify-tools \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh
COPY nginx-auto-reloader.sh /usr/src/app/nginx-auto-reloader.sh

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
