#!/bin/bash

IMAGE_NAME="lafayettegabe/docker-postgres-walg"
VERSION="1.0.1"

echo "Building multi-architecture WAL-D image..."
echo "Platforms: linux/amd64, linux/arm64"

if ! docker buildx version >/dev/null 2>&1; then
    echo "ERROR: Docker Buildx is not available"
    echo "Please enable Docker Buildx or update Docker Desktop"
    exit 1
fi

BUILDER_NAME="multiarch-builder"
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "Creating multi-architecture builder..."
    docker buildx create --name "$BUILDER_NAME" --use
else
    echo "Using existing builder: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

echo "Building and pushing multi-architecture image..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "$IMAGE_NAME:$VERSION" \
    --tag "$IMAGE_NAME:latest" \
    --push \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Multi-architecture build completed successfully!"
    echo ""
    echo "Image: $IMAGE_NAME:$VERSION"
    echo "Platforms: linux/amd64, linux/arm64"
    echo ""
    echo "Verify with:"
    echo "docker buildx imagetools inspect $IMAGE_NAME:latest"
else
    echo "❌ Build failed"
    exit 1
fi
