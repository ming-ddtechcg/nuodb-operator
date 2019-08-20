#!/bin/bash
PROJECT=nuodb
NODE=minikube
TESTDIR=$TRAVIS_BUILD_DIR
OPERATOR_NAMESPACE=nuodb

kubectl get nodes

kubectl label node ${NODE} nuodb.com/node-type=storage
kubectl label node ${NODE} nuodb.com/zone=nuodb --overwrite=true

cd ${TESTDIR}/deploy

export OPERATOR_NAMESPACE=nuodb
kubectl create secret docker-registry regcred --namespace=nuodb --docker-server=$DOCKER_SERVER --docker-username=$BOT_U --docker-password=$BOT_P --docker-email=""
kubectl create -f local-disk-class.yaml
kubectl create -f cluster_role_binding.yaml
kubectl create -n $OPERATOR_NAMESPACE -f operatorGroup.yaml
kubectl create -n $OPERATOR_NAMESPACE -f cluster_role.yaml
kubectl create -n $OPERATOR_NAMESPACE -f role.yaml
kubectl create -n $OPERATOR_NAMESPACE -f role_binding.yaml
kubectl create -n $OPERATOR_NAMESPACE -f service_account.yaml 
kubectl patch serviceaccount nuodb-operator -p '{"imagePullSecrets": [{"name": "regcred"}]}' -n $OPERATOR_NAMESPACE
kubectl create -f olm-catalog/nuodb-operator/0.0.5/nuodb.crd.yaml 
dep_tmpl="spec.install.spec.deployments[0].spec.template.spec.containers[0].image"
yq w -i olm-catalog/nuodb-operator/0.0.5/nuodb.v0.0.5.clusterserviceversion.yaml "$dep_tmpl" "$NUODB_OP_IMAGE"
kubectl create  -n $OPERATOR_NAMESPACE -f olm-catalog/nuodb-operator/0.0.5/nuodb.v0.0.5.clusterserviceversion.yaml


# Check deployment rollout status every 10 seconds (max 10 minutes) until complete.
ATTEMPTS=0
ROLLOUT_STATUS_CMD="kubectl rollout status deployment/nuodb-operator -n nuodb"
until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
  $ROLLOUT_STATUS_CMD
  ATTEMPTS=$((attempts + 1))
  kubectl get pods -n nuodb
  sleep 10
done


kubectl create configmap nuodb-lic-configmap --from-literal=nuodb.lic="" -n $OPERATOR_NAMESPACE


echo "Create the Custom Resource to deploy NuoDB..."
kubectl create -n $OPERATOR_NAMESPACE -f cr-test.yaml

echo "Sleeping for a while"
 sleep 20


echo "status of all pods"
kubectl get pods -n nuodb

echo "wait till admin is ready"
ATTEMPTS=0
ROLLOUT_STATUS_CMD="kubectl rollout status sts/admin -n nuodb"
until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
  $ROLLOUT_STATUS_CMD
  ATTEMPTS=$((attempts + 1))
  kubectl get pods -n nuodb
  sleep 10
done


echo "Sleeping for a while"
 sleep 20

kubectl get pods -n nuodb

kubectl exec -it admin-0 /bin/bash nuocmd show domain -n nuodb


