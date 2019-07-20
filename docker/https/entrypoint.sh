#!/bin/sh

certbot certonly --standalone --text --non-interactive \
  --email support@rdoc.info --agree-tos \
  --domains 'rdoc.info,www.rdoc.info,rubydoc.info,www.rubydoc.info,rubydoc.org,www.rubydoc.org'
crond
nginx
