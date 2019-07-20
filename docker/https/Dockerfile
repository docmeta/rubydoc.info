FROM alpine:3.10
RUN apk add -U dcron nginx certbot certbot-nginx
COPY ./docker/https/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./docker/https/certbot-renew /etc/periodic/daily/certbot-renew
COPY ./docker/https/entrypoint.sh /entrypoint.sh
RUN chmod a+x /etc/periodic/daily/certbot-renew
RUN chmod a+x /entrypoint.sh
EXPOSE 80 443
ENTRYPOINT [ "/entrypoint.sh" ]
