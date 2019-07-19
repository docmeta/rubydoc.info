FROM alpine:3.10
RUN apk add -U varnish
COPY ./docker/cache/default.vcl /etc/varnish/default.vcl
ENTRYPOINT []
CMD sh -c 'varnishd -F -a ":80,HTTP" -f "/etc/varnish/default.vcl"'
