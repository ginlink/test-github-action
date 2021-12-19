#!/bin/sh
yarn

yarn build

docker build -t ginlink/test-rollback:$RELEASE_VERSION .

docker login --username $DOCKER_ACCESS_NAME -p $DOCKER_ACCESS_TOKEN

docker push ginlink/test-rollback:$RELEASE_VERSION
