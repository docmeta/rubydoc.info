#!/bin/sh

set -ex
ruby /etc/varnish/configure.rb

varnishd -F -a ":80,HTTP" -t 120 \
  -f "/etc/varnish/default.vcl" \
  -p nuke_limit=1024 -p max_retries=100 -p lru_interval=60 \
  -s "file,/var/lib/varnish/varnish_storage.bin,10G"
