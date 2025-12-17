#!/bin/sh
docker run -d -p 80:80 --name ilias10-container ilias10-image
docker logs -f ilias10-container
