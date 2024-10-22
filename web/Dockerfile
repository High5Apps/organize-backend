FROM nginx:1.26.2-alpine AS prod

RUN apk add --update --no-cache inotify-tools

WORKDIR /usr/src/app

COPY rails-proxy.conf /etc/nginx/rails-proxy.conf
COPY docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-auto-reloader.sh /usr/src/app/nginx-auto-reloader.sh
COPY server-locations.conf /etc/nginx/server-locations.conf
COPY store.conf /etc/nginx/store.conf
COPY public public

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]

FROM prod AS dev

COPY nginx.development.conf /etc/nginx/nginx.development.conf

FROM prod
