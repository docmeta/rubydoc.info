ARG RUBY_VERSION=3.4.3
FROM ruby:$RUBY_VERSION-alpine AS build
LABEL Maintainer="Loren Segal <lsegal@soen.ca>"

RUN apk add --no-cache -U curl docker bash git build-base jemalloc postgresql-dev yaml-dev
RUN gem update --no-document --system

# Rails app lives here
WORKDIR /app

# Run and own only the runtime files as a non-root user for security
RUN adduser -D app
RUN sed -E -i 's/^(docker:.+)/\1app/' /etc/group
USER app

# Create GEM_HOME
RUN mkdir ~/.gems
ENV GEM_HOME=/home/app/.gems
RUN gem install bundler

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Install application gems
ADD --chown=app:app Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
ADD --chown=app:app . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Adjust binfiles to be executable on Linux
RUN chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN WITHOUT_JOBS=1 SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/rails", "server", "-p", "80", "-b", "0.0.0.0"]
