FROM ruby:3.1.0

RUN apt-get update && apt-get install -y \
  postgresql-client \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT [ "./docker-entrypoint.sh" ]
CMD [ "rails server --binding=0.0.0.0" ]
