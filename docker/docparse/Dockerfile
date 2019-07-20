FROM ruby:2.6-alpine
RUN gem update --system --no-document
RUN gem install --no-document bundler yard
WORKDIR /build
ENTRYPOINT ["ruby"]
