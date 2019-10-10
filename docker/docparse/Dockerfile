FROM ruby:2.6-alpine
RUN adduser -D app
RUN sed -E -i 's/^(docker:.+)/\1app/' /etc/group
RUN gem update --system --no-document
RUN gem install --no-document bundler yard
USER app
WORKDIR /build
ENTRYPOINT ["ruby"]
