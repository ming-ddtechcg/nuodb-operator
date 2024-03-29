#!/usr/bin/env bash
OP_VER=0.0.5
OP_PATH=${TRAVIS_BUILD_DIR}/deploy/olm-catalog/nuodb-operator/${OP_VER}/
DEPLOY_DIR="${TRAVIS_BUILD_DIR}/deploy"
PKG_NAME=nuodb-operator
ABS_BUNDLE_PATH="${DEPLOY_DIR}/olm-catalog/${PKG_NAME}/${OP_VER}"
CR_DIR="${DEPLOY_DIR}/crds"
NAMESPACE=nuodb

echo "Create nuodb project..."
kubectl create namespace $NAMESPACE

CSV_FILE="$(find "$ABS_BUNDLE_PATH" -name "*${OP_VER}.clusterserviceversion.yaml" -print -quit)"
CSV_NAME="$(yq r "$CSV_FILE" "metadata.name")"
NAMESPACE=nuodb
CR_FILE=$DEPLOY_DIR/cr-test.yaml


dep_tmpl="spec.install.spec.deployments[0].spec.template.spec.containers[0].image"
yq w -i ${DEPLOY_DIR}/olm-catalog/nuodb-operator/0.0.5/nuodb.v0.0.5.clusterserviceversion.yaml "$dep_tmpl" "$NUODB_OP_IMAGE"

echo -e "\n\nRunning operator-sdk scorecard against "$CSV_NAME" with example "$(cat "$CR_FILE" | yq r - "kind")""
operator-sdk scorecard \
 --cr-manifest "$CR_FILE" \
 --crds-dir "$ABS_BUNDLE_PATH" \
 --csv-path "$CSV_FILE" \
 --namespace "$NAMESPACE" \
 --init-timeout 60 \
 --verbose

sleep 20
kubectl patch nuodb nuodb -p '{"metadata":{"finalizers":[]}}' --type=merge -n nuodb
kubectl patch crd/nuodbs.nuodb.com -p '{"metadata":{"finalizers":[]}}' --type=merge
