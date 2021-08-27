#!/bin/bash

echo "Building OpenRAVE Docker...";
docker build -f ./Dockerfile \
  -t openrave_docker .;
