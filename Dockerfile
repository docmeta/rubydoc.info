FROM ruby:2.3
MAINTAINER Loren Segal <lsegal@soen.ca>

# Bundle first to keep cache
ADD ./Gemfile /app/Gemfile
ADD ./Gemfile.lock /app/Gemfile.lock
ADD ./.bundle /app/.bundle
WORKDIR /app
RUN bundle --without test

# Rest of app
ADD . /app

EXPOSE 8080
LABEL docmeta.rubydoc=true
ENV DOCKERIZED=1

CMD bundle exec rake server:start
