# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    vim \
    git \
    curl \
    build-essential \
    python3 \
    python3-pip \
    zip unzip \
    openjdk-17-jdk \
    maven ffmpeg \
    ghostscript \
    nodejs npm \
    apache2 apache2-utils \
    libapache2-mod-php \
    php php-gd php-xsl php-imagick php-curl php-mysql php-xmlrpc php-soap php-ldap composer \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# php init
COPY ./configs/php.ini.fix /etc/php/8.3/apache2/
RUN cat /etc/php/8.3/apache2/php.ini.fix >> /etc/php/8.3/apache2/php.ini && rm /etc/php/8.3/apache2/php.ini.fix

# Create necessary directories and set permissions
RUN mkdir -p /var/www/ilias /var/www/files /var/www/logs /var/www/config /var/www/.npm && chown -R www-data:www-data /var/www

# Apache Configuration
COPY ./configs/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable Apache modules
RUN a2enmod rewrite

# Expose port 80 for HTTP traffic
EXPOSE 80

# Ilias
WORKDIR /var/www/ilias
COPY ./ILIAS /var/www/ilias/
RUN npm clean-install --omit=dev --ignore-scripts
RUN composer install --no-dev
COPY ./configs/ilias.json /var/www/config/

# Database
COPY ./configs/mariadb.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
RUN mkdir -p /run/mysqld && chown -R root:root /run/mysqld
COPY ./configs/mariadb.sql /etc/mysql/mariadb.sql

# Entry Point
COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
