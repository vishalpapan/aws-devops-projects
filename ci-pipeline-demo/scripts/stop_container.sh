#!/bin/bash

echo "Stopping existing Flask container..."

# Stop and remove existing container if running
if [ "$(docker ps -q -f name=flask-app)" ]; then
    echo "Stopping running container..."
    docker stop flask-app
fi

if [ "$(docker ps -aq -f name=flask-app)" ]; then
    echo "Removing existing container..."
    docker rm flask-app
fi

echo "Container cleanup completed."