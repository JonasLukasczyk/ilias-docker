FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    zip \
    openjdk-17-jdk \
    maven \
    ffmpeg \
    ghostscript \
    imagemagick \
    nodejs \
    npm \
    apache2 \
    libapache2-mod-php \
    php \
    php-gd \
    php-xsl \
    php-imagick \
    php-curl \
    php-mysql \
    php-xmlrpc \
    php-soap \
    php-ldap \
    php-mbstring \
    php-zip \
    composer \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY configs/php.ini /etc/php/8.3/apache2/conf.d/99-ilias.ini
COPY configs/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN a2enmod rewrite headers expires \
    && mkdir -p /var/www/ilias /var/www/files/ilias /var/www/logs /var/www/config /var/www/.npm \
    && chown -R www-data:www-data /var/www

WORKDIR /var/www/ilias

RUN git clone --branch release_10 --depth 1 https://github.com/ILIAS-eLearning/ILIAS . \
    && npm clean-install --omit=dev --ignore-scripts \
    && composer install --no-dev --no-interaction --prefer-dist \
    && chown -R www-data:www-data /var/www/ilias

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=5 \
    CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
