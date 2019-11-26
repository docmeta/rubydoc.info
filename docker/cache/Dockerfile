FROM alpine:3.10
RUN apk add --no-cache -U varnish ruby
COPY ./docker/cache/* /etc/varnish/
RUN echo 'fs.file-max = 700000' >> /etc/sysctl.conf
ARG BACKENDS=app
ENV VARNISH_BACKENDS=${BACKENDS}
ENTRYPOINT []
CMD sh -c 'ruby /etc/varnish/configure.rb && varnishd -F -a ":80,HTTP" -f "/etc/varnish/default.vcl" -p nuke_limit=1024'
