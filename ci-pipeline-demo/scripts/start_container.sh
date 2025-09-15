#!/bin/bash

echo "Starting Flask application container..."

# Pull the latest image from Docker Hub
# Replace 'your-dockerhub-username' with actual username
DOCKER_USERNAME="your-dockerhub-username"
IMAGE_NAME="python-flask-aws-ci-app"

echo "Pulling latest image from Docker Hub..."
docker pull $DOCKER_USERNAME/$IMAGE_NAME:latest

echo "Starting new container..."
docker run -d \
  --name flask-app \
  -p 80:5000 \
  --restart unless-stopped \
  $DOCKER_USERNAME/$IMAGE_NAME:latest

echo "Container started successfully!"
echo "Application should be available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"