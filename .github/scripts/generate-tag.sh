#!/bin/bash

set -e

echo "🔍 Generating image tag..."

if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
    TAG="$GITHUB_REF_NAME"
    echo "Release tag: $TAG"
else
    SHORT_SHA=$(echo "$GITHUB_SHA" | cut -c1-8)
    BRANCH=$(echo "$GITHUB_REF" | sed 's/refs\/heads\///' | sed 's/[^a-zA-Z0-9]/-/g')
    TAG="${BRANCH}-${SHORT_SHA}"
    echo "Branch tag: $TAG"
fi

echo "tag=$TAG" >> "$GITHUB_OUTPUT"
echo "✅ Generated tag: $TAG"