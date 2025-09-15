#!/bin/bash
set -e

# Pull the Docker image from Docker Hub
echo
docker pull vishalpapan/python-flask-aws-ci-app:0840fbcf1ae4f8663b62d2f6f3920f68fc922a19
# Run the Docker image as a container
echo
docker run -d -p 5000:5000 vishalpapan/python-flask-aws-ci-app:0840fbcf1ae4f8663b62d2f6f3920f68fc922a19