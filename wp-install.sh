#!/bin/bash
set -xv

rm -r /tmp/*
clear

echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN

echo "Please provide your Email for the domain name"
read -p "Type your Email for the domain name, then press [ENTER] : " EMAIL

apt update -y
apt upgrade -y
apt install nginx -y
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
add-apt-repository universe -y
apt update -y
apt install ed
apt install php7.4-fpm php7.4-xml php7.4-mysql php7.4-dev php7.4-mbstring php7.4-common php-common php-curl php7.4-gd php7.4-cgi -y
phpenmod mbstring

perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/upload_max_filesize=2M/upload_max_filesize=100M/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/post_max_size = 8M/post_max_size = 100M/g" /etc/php/7.4/fpm/php.ini

cd /tmp
wget https://gist.githubusercontent.com/TaEduard/8361916fabd52e1d72b489efa3329e1c/raw/9cfe94a25f523ba4cacc6def7629888825f40ac5/nginx-wordpress
mv ./nginx-wordpress /etc/nginx/sites-available/$MY_DOMAIN
ln -s /etc/nginx/sites-available/$MY_DOMAIN /etc/nginx/sites-enabled/
perl -pi -e "s/example.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
perl -pi -e "s/www.example.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
apt install mariadb-client mariadb-server -y
apt install expect -y

CURRENT_MYSQL_PASSWORD=''


MYSQL_DOMAIN=$(echo $MY_DOMAIN| sed 's/\.//g')
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "${SECURE_MYSQL}"
# Create WordPress MySQL database
dbname="wpdbse_${MYSQL_DOMAIN}"
dbuser="wpuser_${MYSQL_DOMAIN}"
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
echo "CREATE DATABASE $dbname;" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "FLUSH PRIVILEGES;" | mysql -u root -p$NEW_MYSQL_PASSWORD
apt purge expect -y
apt autoremove -y
apt autoclean -y


cd /tmp
wget https://wordpress.org/latest.tar.gz
mkdir /var/www/$MY_DOMAIN
tar xzvf latest.tar.gz
cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
cp -a ./wordpress/. /var/www/$MY_DOMAIN
chown -R www-data /var/www/$MY_DOMAIN
find /var/www/$MY_DOMAIN -type d -exec chmod g+s {} \;
chmod g+w /var/www/$MY_DOMAIN/wp-content
chmod -R g+w /var/www/$MY_DOMAIN/wp-content/themes
chmod -R g+w /var/www/$MY_DOMAIN/wp-content/plugins
perl -pi -e "s/database_name_here/$dbname/g" /var/www/$MY_DOMAIN/wp-config.php
perl -pi -e "s/username_here/$dbuser/g" /var/www/$MY_DOMAIN/wp-config.php
perl -pi -e "s/password_here/$userpass/g" /var/www/$MY_DOMAIN/wp-config.php
service nginx restart
service php7.4-fpm restart
service mysql restart

SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/$MY_DOMAIN/wp-config.php

apt update -y
apt install certbot python3-certbot-nginx -y
apt update -y
certbot certonly -n -d $MY_DOMAIN --agree-tos -m $EMAIL --nginx
perl -pi -e "s/#//g" /etc/nginx/sites-available/$MY_DOMAIN
service nginx restart

rm -r /tmp/*

read -p "Press [ENTER] to display your WordPress MySQL database details!"
echo "Database Name: $dbname"
echo "Username: $dbuser"
echo "Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"