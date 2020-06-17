FROM alpine:3.10
RUN apk add --no-cache -U varnish ruby docker
COPY ./docker/cache/*.vcl /etc/varnish/
RUN echo 'fs.file-max = 700000' >> /etc/sysctl.conf
RUN ln -s "lg_dirty_mult:8,lg_chunk:18" /etc/malloc.conf
CMD varnishd -F -a ":80,HTTP" -t 120 \
  -f "/etc/varnish/default.vcl" \
  -p nuke_limit=1024 -p max_retries=100 -p lru_interval=60 \
  -s "file,/var/lib/varnish/varnish_storage.bin,10G"
