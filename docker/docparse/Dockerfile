FROM ruby:3-alpine

ARG GIT_SHA
ENV GIT_SHA=$GIT_SHA

ADD ./generate.rb /rb/generate.rb
RUN chmod +x /rb/generate.rb

RUN adduser -D app
USER app
ENV GEM_HOME=/home/app/.gems
RUN gem update --system --no-document
RUN gem install --no-document bundler yard
WORKDIR /build

ENTRYPOINT ["/rb/generate.rb"]
