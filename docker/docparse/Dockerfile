FROM ruby:4-alpine

ARG GIT_SHA
ENV GIT_SHA=$GIT_SHA

RUN apk add -U git

ADD ./generate.rb /rb/generate.rb
RUN chmod +x /rb/generate.rb

RUN adduser -D app
USER app
ENV GEM_HOME=/home/app/.gems
RUN gem update --system --no-document
RUN gem install --no-document bundler
RUN git clone --depth 1 --branch main https://github.com/lsegal/yard /home/app/yard
ENV RUBYOPT="-I/home/app/yard/lib"
RUN ruby -ryard -e "puts YARD::VERSION"
WORKDIR /build

ENTRYPOINT ["/rb/generate.rb"]
