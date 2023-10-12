FROM postgres:16

COPY --from=postgres:15 /usr/lib/postgresql/15 /usr/lib/postgresql/15/
COPY --from=postgres:15 /usr/share/postgresql/15 /usr/share/postgresql/15/

ENV PGBINOLD /usr/lib/postgresql/15/bin
ENV PGBINNEW /usr/lib/postgresql/16/bin

ENV PGDATAOLD /var/lib/postgresql/15/data
ENV PGDATANEW /var/lib/postgresql/16/data

RUN mkdir -p "$PGDATAOLD" "$PGDATANEW" \
	&& chown -R postgres:postgres /var/lib/postgresql

WORKDIR /var/lib/postgresql

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["pg_upgrade", "--link"]
