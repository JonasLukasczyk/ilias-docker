#!/bin/sh
docker exec -it $(docker ps -q -l) bash
