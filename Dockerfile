FROM ruby:3.1.0

WORKDIR /usr/src/app

COPY . .
RUN bundle install
