#!/usr/bin/env bash

docker login
docker build -t programic/pipe-import-database:latest .
docker push programic/pipe-import-database:latest