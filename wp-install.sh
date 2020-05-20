#!/bin/bash

rm -r /tmp/*
clear

echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
echo "Please provide your email"
read -p "Type your email, then press [ENTER] : " EMAIL
touch file.txt
apt update -y
apt upgrade -y
echo "install nginx -y" >> file.txt
apt install nginx -y
echo "install python-software-properties -y" >> file.txt
apt install python-software-properties -y
echo "add-apt-repository ppa:ondrej/php -y" >> file.txt
add-apt-repository ppa:ondrej/php -y
echo "add-apt-repository universe -y" >> file.txt
add-apt-repository universe -y
echo "add-apt-repository ppa:certbot/certbot -y" >> file.txt
add-apt-repository ppa:certbot/certbot -y
echo "apt update -y" >> file.txt
apt update -y
echo "apt install ed certbot python3-certbot-nginx " >> file.txt
apt install ed certbot python3-certbot-nginx 
echo "apt install php7.4-fpm" >> file.txt
apt install php7.4-fpm
echo "" >> file.txt
apt install php7.4-xml
echo "apt install php7.4-xml" >> file.txt
apt install php7.4-mysql
echo "apt install php7.4-mysql" >> file.txt
apt install php7.4-dev
echo "apt install php7.4-dev" >> file.txt
apt install php-mbstring
echo "apt install php-mbstring" >> file.txt
apt install php-gettext
echo "apt install php-gettext" >> file.txt
apt install php-curl
echo "apt install php-curl" >> file.txt
apt install php7.4-gd
echo "apt install php7.4-gd" >> file.txt
apt install php7.4-cgi -y
echo "apt install php7.4-cgi -y" >> file.txt
phpenmod mbstring

echo "phpenmod mbstring" >> file.txt

perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/upload_max_filesize=2M/upload_max_filesize=100M/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/7.4/fpm/php.ini
perl -pi -e "s/post_max_size = 8M/post_max_size = 100M/g" /etc/php/7.4/fpm/php.ini

echo "perl" >> file.txt

cd /tmp
echo "1" >> file.txt
wget https://gist.githubusercontent.com/TaEduard/8361916fabd52e1d72b489efa3329e1c/raw/9cfe94a25f523ba4cacc6def7629888825f40ac5/nginx-wordpress
echo "2" >> file.txt
mv ./nginx-wordpress /etc/nginx/sites-available/$MY_DOMAIN
echo "3" >> file.txt
ln -s /etc/nginx/sites-available/$MY_DOMAIN /etc/nginx/sites-enabled/
echo "4" >> file.txt
perl -pi -e "s/example.com/$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
echo "5" >> file.txt
perl -pi -e "s/www.example.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/$MY_DOMAIN
echo "6" >> file.txt
perl -pi -e "s/#//g" /etc/nginx/sites-available/$MY_DOMAIN
echo "7" >> file.txt
apt install mariadb-client mariadb-server -y
echo "8" >> file.txt
apt install expect -y
echo "9" >> file.txt
certbot certonly -n -d $MY_DOMAIN --agree-tos -m $EMAIL --nginx

echo "certbot certonly -n -d $MY_DOMAIN --agree-tos -m $EMAIL --nginx" >> file.txt

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

echo "apt autoclean -y" >> file.txt

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

echo "service mysql restart" >> file.txt

SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/$MY_DOMAIN/wp-config.php


rm -r /tmp/*

read -p "Press [ENTER] to display your WordPress MySQL database details!"
echo "Database Name: $dbname"
echo "Username: $dbuser"
echo "Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"