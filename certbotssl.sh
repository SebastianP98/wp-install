#!/bin/bash
set -xv

apt update -y
apt install certbot python3-certbot-nginx -y
#curl -o- https://raw.githubusercontent.com/vinyll/certbot-install/master/install.sh | bash
apt update -y
#certbot certonly -n -d $MY_DOMAIN --agree-tos -m $EMAIL --nginx
certbot certonly -n  -d $MY_DOMAIN -m $EMAIL --agree-tos --webroot -w /var/www/html 
#certbot certonly --email $EMAIL --agree-tos --webroot -w /var/www/$MY_DOMAIN -d $MY_DOMAIN
perl -pi -e "s/#//g" /etc/nginx/sites-available/$MY_DOMAIN
service nginx restart