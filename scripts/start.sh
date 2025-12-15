#!/bin/sh
docker run -d -p 80:80 ilias10
docker logs -f $(docker ps -q -l)
