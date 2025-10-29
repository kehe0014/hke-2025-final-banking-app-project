#!/bin/bash

if [[ "$GITHUB_EVENT_NAME" == "release" ]]; then
    echo "tag=$GITHUB_REF_NAME" >> $GITHUB_OUTPUT
else
    SHORT_SHA=$(echo $GITHUB_SHA | cut -c1-8)
    BRANCH=$(echo "$GITHUB_REF" | sed 's/refs\/heads\///' | sed 's/[^a-zA-Z0-9]/-/g')
    echo "tag=${BRANCH}-${SHORT_SHA}" >> $GITHUB_OUTPUT
fi

echo "Generated tag: $(cat $GITHUB_OUTPUT | grep tag | cut -d'=' -f2)"