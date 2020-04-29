#!/bin/bash
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
apt update -y
apt upgrade -y
apt install nginx -y
apt install python-software-properties -y
add-apt-repository ppa:ondrej/php -y
apt update -y
apt install php7.1-fpm php7.1-mysql php7.1-mcrypt php-mbstring php-gettext php-curl php7.1-gd php7.1-cgi -y
phpenmod mcrypt
phpenmod mbstring
perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini
perl -pi -e "s/;listen = /var/run/php5-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php/7.3/fpm/pool.d/www.conf
wget https://gist.githubusercontent.com/TaEduard/8361916fabd52e1d72b489efa3329e1c/raw/8b2fee3bae36d36eccb2aa3eb6c996cc224f971f/nginx-wordpress
mv ./nginx-wordpress /etc/nginx/sites-available/default
perl -pi -e "s/example.com/$MY_DOMAIN/g" /etc/nginx/sites-available/default
perl -pi -e "s/www.example.com/www.$MY_DOMAIN/g" /etc/nginx/sites-available/default
apt install mariadb-client mariadb-server -y
apt install expect -y

CURRENT_MYSQL_PASSWORD=''
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
dbname="wpdbse"
dbuser="wpuser"
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
echo "CREATE DATABASE $dbname;" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "FLUSH PRIVILEGES;" | mysql -u root -p$NEW_MYSQL_PASSWORD
apt purge expect -y
apt autoremove -y
apt autoclean -y
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
touch ./wordpress/.htaccess
chmod 660 ./wordpress/.htaccess
mkdir ./wordpress/wp-content/upgrade
cp -a ./wordpress/. /var/www/html
chown -R www-data /var/www/html
find /var/www/html -type d -exec chmod g+s {} \;
chmod g+w /var/www/html/wp-content
chmod -R g+w /var/www/html/wp-content/themes
chmod -R g+w /var/www/html/wp-content/plugins
perl -pi -e "s/database_name_here/$dbname/g" /var/www/html/wp-config.php
perl -pi -e "s/username_here/$dbuser/g" /var/www/html/wp-config.php
perl -pi -e "s/password_here/$userpass/g" /var/www/html/wp-config.php
service nginx restart
service php7.1-fpm restart
service mysql restart
echo "You are almost done. Replace the Secret Key in the wp-config.php with:"
echo
echo
curl -s https://api.wordpress.org/secret-key/1.1/salt/
echo
echo
echo "Use: nano /var/www/html/wp-config.php"
echo "... to edit the file!"
echo
echo "Then visit your website IP or Domain name to complete the WordPress Installation."
echo
read -p "Press [ENTER] to display your WordPress MySQL database details!"
echo "Database Name: $dbname"
echo "Username: $dbuser"
echo "Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"