#!/usr/bin/env bash

docker login
docker build --platform linux/amd64 -t programic/pipe-import-database:latest .
docker push programic/pipe-import-database:latest