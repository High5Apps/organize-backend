FROM ruby:3.3.5 AS prod

RUN apt-get update && apt-get install -y \
  postgresql-client \
&& rm -rf /var/lib/apt/lists/*

RUN adduser organize
USER organize

WORKDIR /usr/src/app

COPY --chown=organize Gemfile Gemfile.lock ./
RUN bundle config set --local without development test && bundle install

COPY --chown=organize . .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "rails server --binding=0.0.0.0" ]

FROM prod AS dev

RUN bundle config unset --local without && bundle install

FROM prod
