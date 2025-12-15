#!/bin/sh
docker stop $(docker ps -q -l)
docker rm $(docker ps -q -l)
