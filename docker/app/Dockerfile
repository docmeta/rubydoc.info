FROM ruby:2.6
LABEL Maintainer="Loren Segal <lsegal@soen.ca>"

RUN apt-get update && apt-get install -y cron
RUN curl -fsSL https://get.docker.com | sh
RUN echo 'gem: "--no-document"' > /root/.gemrc
RUN gem update --system

RUN useradd -ms /bin/bash app
RUN usermod -a -G docker app
USER app

# Create GEM_HOME
RUN mkdir ~/.gems
ENV GEM_HOME=/home/app/.gems
RUN gem install bundler

# Bundle first to keep cache
ADD --chown=app:app ./Gemfile /app/Gemfile
ADD --chown=app:app ./Gemfile.lock /app/Gemfile.lock
WORKDIR /app
RUN bundle --without test --path vendor/bundle

LABEL docmeta.rubydoc=true
ENV DOCKERIZED=1
ENV DOCKER_HOST=tcp://dind:2375

# Rest of app
ADD --chown=app:app . /app

# Install cron scripts
RUN crontab ./docker/app/crontab

# Command as root but don't worry, we switch back to app!
USER root
ENTRYPOINT [ "sh", "/app/docker/app/entrypoint.sh" ]
