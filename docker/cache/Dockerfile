FROM alpine:3.10
RUN apk add --no-cache -U varnish ruby
COPY ./docker/cache/* /etc/varnish/
RUN echo 'fs.file-max = 700000' >> /etc/sysctl.conf
RUN ln -s "lg_dirty_mult:8,lg_chunk:18" /etc/malloc.conf
ARG BACKENDS=app
ENV VARNISH_BACKENDS=${BACKENDS}
ENTRYPOINT [ "sh", "/etc/varnish/docker-entrypoint.sh" ]
