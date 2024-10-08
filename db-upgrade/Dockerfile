FROM postgres:17

COPY --from=postgres:15 /usr/lib/postgresql/15 /usr/lib/postgresql/15/
COPY --from=postgres:15 /usr/share/postgresql/15 /usr/share/postgresql/15/

ENV PGBINOLD /usr/lib/postgresql/15/bin
ENV PGBINNEW /usr/lib/postgresql/17/bin

ENV PGDATAOLD /var/lib/postgresql/15/data
ENV PGDATANEW /var/lib/postgresql/17/data

RUN set -eux; \
  mkdir -p "$PGDATAOLD" "$PGDATANEW"; \
  chown -R postgres:postgres /var/lib/postgresql

WORKDIR /var/lib/postgresql

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["pg_upgrade", "--link"]
