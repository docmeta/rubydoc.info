FROM ruby:2.6-alpine
LABEL Maintainer="Loren Segal <lsegal@soen.ca>"

RUN apk add --no-cache -U docker git sqlite-dev build-base
RUN gem update --no-document --system

RUN touch /var/run/docker.sock
RUN chown root:docker /var/run/docker.sock

RUN adduser -D app
RUN sed -E -i 's/^(docker:.+)/\1app/' /etc/group
USER app

# Create GEM_HOME
RUN mkdir ~/.gems
ENV GEM_HOME=/home/app/.gems
RUN gem install bundler

# Bundle first to keep cache
ADD --chown=app:app ./Gemfile /app/Gemfile
ADD --chown=app:app ./Gemfile.lock /app/Gemfile.lock
WORKDIR /app
RUN bundle config set without 'test'
RUN bundle install

LABEL docmeta.rubydoc=true
ENV DOCKERIZED=1

# Rest of app
ADD --chown=app:app . /app

ENTRYPOINT [ "sh", "/app/docker/app/entrypoint.sh" ]
