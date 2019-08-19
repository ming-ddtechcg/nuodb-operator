#!/usr/bin/env bash

# jq, yq
echo "Installing jq and yq"
curl -Lo jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq
sudo mv jq /usr/local/bin/
curl -Lo yq https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64
chmod +x yq
sudo mv yq /usr/local/bin/
# operator-courier
echo "Installing operator-courier"
python3 -m pip install operator-courier

# SDK
echo "Installing operator-sdk"
SDK_VER="v0.6.0"
curl -Lo operator-sdk "https://github.com/operator-framework/operator-sdk/releases/download/${SDK_VER}/operator-sdk-${SDK_VER}-x86_64-linux-gnu"
chmod +x operator-sdk
sudo mv operator-sdk /usr/local/bin/

# Download kubectl, which is a requirement for using minikube.
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
# Download minikube.
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.2.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
mkdir -p $HOME/.kube $HOME/.minikube
touch $KUBECONFIG
chmod +x scripts/ci/test_operator.sh
chmod +x scripts/ci/verify_operator.sh
chmod +x scripts/ci/build_operator.sh
chmod +x scripts/ci/test_scorecard.sh


sudo minikube start --vm-driver=none --kubernetes-version=v1.15.0 --memory=8000 --cpus=4
sudo chown -R travis: /home/travis/.minikube/
kubectl cluster-info
# Verify kube-addon-manager.
# kube-addon-manager is responsible for managing other kubernetes components, such as kube-dns, dashboard, storage-provisioner..
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl -n kube-system get pods -lcomponent=kube-addon-manager -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1;echo "waiting for kube-addon-manager to be available"; kubectl get pods --all-namespaces; done
# Wait for kube-dns to be ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl -n kube-system get pods -lk8s-app=kube-dns -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1;echo "waiting for kube-dns to be available"; kubectl get pods --all-namespaces; done
#Install OLM on minikube
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.11.0/install.sh -o install.sh
chmod +x install.sh
./install.sh 0.11.0 

kubectl get nodes
