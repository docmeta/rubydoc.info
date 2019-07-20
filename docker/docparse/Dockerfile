FROM ruby:2.6-alpine

RUN gem update --system --no-document
RUN gem install --no-document bundler yard
COPY generate.rb /usr/share/yard/generate.rb

WORKDIR /build
ENTRYPOINT [ "ruby", "/usr/share/yard/generate.rb" ]
