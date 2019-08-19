#!/usr/bin/env bash

#This script will build and push image for further testing.

echo "Building operatot image and pushing"

cd $TRAVIS_BUILD_DIR/
CURRENTDIR=$(pwd)
mkdir -p helm-charts/nuodb/
echo "Current dir : $CURRENTDIR"
echo "Build Tag  : $1"
cd ../
git clone https://github.com/nuodb/nuodb-ce-helm.git
cd nuodb-ce-helm/
git checkout $HELM_BRANCH
rm -fr .git/
cd $TRAVIS_BUILD_DIR/
cp -a ../nuodb-ce-helm/. $TRAVIS_BUILD_DIR/helm-charts/nuodb

docker version
echo "Docker login..."
docker login -u $BOT_U -p $BOT_P $DOCKER_SERVER


echo "Build NuoDB Operator..."
export NUODB_OP_IMAGE=$1
echo "Build image tag $NUODB_OP_IMAGE"
operator-sdk build $NUODB_OP_IMAGE
docker push $NUODB_OP_IMAGE
