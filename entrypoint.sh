#!/bin/sh
set -eu

required_vars="ILIAS_DB_HOST ILIAS_DB_NAME ILIAS_DB_USER ILIAS_DB_PASSWORD ILIAS_HTTP_PATH ILIAS_CONTACT_EMAIL"
for var in $required_vars; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
        echo "ERROR: required environment variable $var is not set" >&2
        exit 1
    fi
done

ILIAS_DB_PORT="${ILIAS_DB_PORT:-3306}"
ILIAS_CLIENT_ID="${ILIAS_CLIENT_ID:-myilias}"
ILIAS_SERVER_TIMEZONE="${ILIAS_SERVER_TIMEZONE:-Europe/Berlin}"
ILIAS_CONTACT_FIRSTNAME="${ILIAS_CONTACT_FIRSTNAME:-ILIAS}"
ILIAS_CONTACT_LASTNAME="${ILIAS_CONTACT_LASTNAME:-Admin}"

export ILIAS_DB_PORT ILIAS_CLIENT_ID ILIAS_SERVER_TIMEZONE \
       ILIAS_CONTACT_FIRSTNAME ILIAS_CONTACT_LASTNAME

mkdir -p /var/www/files/ilias /var/www/logs /var/www/config /var/www/ilias/public/data
chown -R www-data:www-data /var/www/files /var/www/logs /var/www/config /var/www/ilias/public/data

php -r '
$config = [
    "common" => [
        "client_id" => getenv("ILIAS_CLIENT_ID"),
        "server_timezone" => getenv("ILIAS_SERVER_TIMEZONE"),
    ],
    "database" => [
        "type" => "innodb",
        "host" => getenv("ILIAS_DB_HOST"),
        "port" => (int) getenv("ILIAS_DB_PORT"),
        "user" => getenv("ILIAS_DB_USER"),
        "password" => getenv("ILIAS_DB_PASSWORD"),
        "database" => getenv("ILIAS_DB_NAME"),
        "create_database" => false,
    ],
    "filesystem" => [
        "data_dir" => "/var/www/files/ilias",
    ],
    "logging" => [
        "enable" => true,
        "path_to_logfile" => "/var/www/logs/ilias.log",
        "errorlog_dir" => "/var/www/logs/",
    ],
    "http" => [
        "path" => getenv("ILIAS_HTTP_PATH"),
    ],
    "systemfolder" => [
        "contact" => [
            "firstname" => getenv("ILIAS_CONTACT_FIRSTNAME"),
            "lastname" => getenv("ILIAS_CONTACT_LASTNAME"),
            "email" => getenv("ILIAS_CONTACT_EMAIL"),
        ],
    ],
    "utilities" => [
        "path_to_convert" => "/usr/bin/convert",
        "path_to_zip" => "/usr/bin/zip",
        "path_to_unzip" => "/usr/bin/unzip",
    ],
    "mediaobject" => [
        "path_to_ffmpeg" => "/usr/bin/ffmpeg",
    ],
    "preview" => [
        "path_to_ghostscript" => "/usr/bin/gs",
    ],
];
file_put_contents("/var/www/config/ilias.json", json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);
'
chown www-data:www-data /var/www/config/ilias.json
chmod 600 /var/www/config/ilias.json

echo "Waiting for MariaDB at ${ILIAS_DB_HOST}:${ILIAS_DB_PORT}..."
until mariadb-admin ping \
    --host="$ILIAS_DB_HOST" \
    --port="$ILIAS_DB_PORT" \
    --user="$ILIAS_DB_USER" \
    --password="$ILIAS_DB_PASSWORD" \
    --silent; do
    sleep 2
done

# The client table is a reliable indicator that this ILIAS database has already
# been installed. This avoids re-running the install command on every restart.
TABLE_COUNT="$(mariadb \
    --host="$ILIAS_DB_HOST" \
    --port="$ILIAS_DB_PORT" \
    --user="$ILIAS_DB_USER" \
    --password="$ILIAS_DB_PASSWORD" \
    --batch --skip-column-names \
    "$ILIAS_DB_NAME" \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${ILIAS_DB_NAME}' AND table_name='client_data';")"

cd /var/www/ilias
if [ "$TABLE_COUNT" = "0" ]; then
    echo "No existing ILIAS installation found. Running initial setup..."
    su -s /bin/sh -c 'php cli/setup.php install /var/www/config/ilias.json -y' www-data
else
    echo "Existing ILIAS installation detected. Skipping install."
fi

exec apache2ctl -D FOREGROUND
