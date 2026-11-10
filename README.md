# ILIAS 10 Docker Compose

Production-oriented starting point for ILIAS 10 with separate application and MariaDB containers.

## First start

```sh
cp .env.example .env
nano .env

docker compose build
docker compose up -d
docker compose logs -f ilias
```

Open the URL configured as `ILIAS_HTTP_PATH`.

## Persistent data

The Compose project creates four named volumes:

- `mariadb_data`: MariaDB database files
- `ilias_data`: ILIAS external data directory (`/var/www/files/ilias`)
- `ilias_public_data`: ILIAS webroot data (`/var/www/ilias/public/data`)
- `ilias_logs`: ILIAS logs

Do not use `docker compose down -v` on a production installation unless you intentionally want to delete the persistent data.

## Useful commands

```sh
# Status
docker compose ps

# Logs
docker compose logs -f ilias
docker compose logs -f db

# Shell inside ILIAS container
docker compose exec ilias bash

# ILIAS setup status
docker compose exec --user www-data ilias php cli/setup.php status

# Stop/start
docker compose stop
docker compose start

# Rebuild after Dockerfile changes
docker compose build --pull ilias
docker compose up -d
```

## Backups

A complete backup must include the MariaDB database, `/var/www/files/ilias`, and `/var/www/ilias/public/data`.

Example database dump:

```sh
docker compose exec -T db mariadb-dump \
  -u"$ILIAS_DB_USER" -p"$ILIAS_DB_PASSWORD" \
  --lock-tables=false "$ILIAS_DB_NAME" > ilias-db.sql
```

Back up the Docker volumes as part of the VM/host backup strategy as well.
