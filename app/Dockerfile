FROM ruby:3.2.2

RUN apt-get update && apt-get install -y \
  postgresql-client \
&& rm -rf /var/lib/apt/lists/*

RUN adduser organize
USER organize

WORKDIR /usr/src/app

COPY --chown=organize Gemfile Gemfile.lock ./
RUN bundle install

COPY --chown=organize . .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "rails server --binding=0.0.0.0" ]
