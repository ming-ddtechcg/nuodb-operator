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