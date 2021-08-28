#!/bin/bash

echo "Building OpenRAVE Docker...";
docker build -f ./Dockerfile \
  -t openrave_docker --build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" --build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)" .;
