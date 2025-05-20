FROM certbot/certbot:arm64v8-v4.0.0

WORKDIR /usr/src/app

COPY docker-entrypoint.sh /usr/src/app/docker-entrypoint.sh

ENTRYPOINT [ "./docker-entrypoint.sh" ]
