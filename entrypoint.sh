#!/bin/sh

# Ensure MariaDB is initialized if it's not already done
echo "Initializing MariaDB database..."
mysqld --user=root &
sleep 5  # Wait for MariaDB to start up
echo "Running database initialization script..."
mysql < /etc/mysql/mariadb.sql

# Start Apache in the foreground
echo "Starting Apache server..."
apache2ctl start

# echo "Starting Ilias..."
cd /var/www/ilias
php cli/setup.php install /var/www/config/ilias.json -y

chown -R www-data:www-data /var/www

# wait
tail -f /dev/null
