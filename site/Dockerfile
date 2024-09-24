FROM ruby:3.2.2 AS prod-base

RUN adduser organize
USER organize

WORKDIR /usr/src/app

ENV RAILS_ENV="production" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITHOUT="development"

COPY --chown=organize Gemfile Gemfile.lock ./
RUN bundle install && bundle exec bootsnap precompile --gemfile

COPY --chown=organize . .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "rails server --binding=0.0.0.0" ]

FROM prod-base AS dev

ENV RAILS_ENV="development" \
  BUNDLE_DEPLOYMENT="0" \
  BUNDLE_WITHOUT=""

RUN bundle install

FROM prod-base AS prod

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
