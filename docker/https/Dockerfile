FROM alpine:3.10
RUN apk add -U nginx certbot certbot-nginx
COPY ./docker/https/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./docker/https/certbot-renew /etc/periodic/daily/certbot-renew
RUN chmod a+x /etc/periodic/daily/certbot-renew
RUN certbot certonly --standalone --text --non-interactive \
  --email support@rdoc.info --agree-tos \
  --domains 'rdoc.info,www.rdoc.info,rubydoc.info,www.rubydoc.info,rubydoc.org,www.rubydoc.org'
ENTRYPOINT []
EXPOSE 80 443
CMD sh -c "crond && nginx"
