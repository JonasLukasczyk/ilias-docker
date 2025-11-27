#!/bin/sh
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker build -t ilias .
docker run -it -d -p 80:80 ilias
