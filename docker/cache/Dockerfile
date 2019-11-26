FROM alpine:3.10
RUN apk add --no-cache -U varnish ruby
COPY ./docker/cache/* /etc/varnish/
RUN echo 'fs.file-max = 700000' >> /etc/sysctl.conf
ARG BACKENDS=app
ENV VARNISH_BACKENDS=${BACKENDS}
ENTRYPOINT []
CMD sh -c 'ruby /etc/varnish/configure.rb && varnishd -F -a ":80,HTTP" -f "/etc/varnish/default.vcl" -p thread_pool_min=200 -p thread_pool_max=4000 -p thread_pool_add_delay=2 -p http_req_size=64000 -p cli_timeout=25 -p cli_buffer=36384 -p session_linger=100'
