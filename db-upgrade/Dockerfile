FROM postgres:15

COPY --from=postgres:14 /usr/lib/postgresql/14 /usr/lib/postgresql/14/
COPY --from=postgres:14 /usr/share/postgresql/14 /usr/share/postgresql/14/

ENV PGBINOLD /usr/lib/postgresql/14/bin
ENV PGBINNEW /usr/lib/postgresql/15/bin

ENV PGDATAOLD /var/lib/postgresql/14/data
ENV PGDATANEW /var/lib/postgresql/15/data

RUN mkdir -p "$PGDATAOLD" "$PGDATANEW" \
	&& chown -R postgres:postgres /var/lib/postgresql

WORKDIR /var/lib/postgresql

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["pg_upgrade", "--link"]
