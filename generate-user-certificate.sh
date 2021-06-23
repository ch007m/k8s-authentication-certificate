#!/bin/bash
export USERNAME="snowdrop"
export NAMESPACE="demo"
export CA=CA.crt
export CLUSTER=kind-kind
export CLUSTER_SERVER=https://127.0.0.1:59817

#### Remove the generated files
rm snowdrop.*; rm snowdrop-kubeconfig; rm $CA

### Remove the CSR generated previously
kubectl delete csr $USERNAME

####
#### Generate private key
openssl genrsa -out $USERNAME.key 2048
#### Create CSR
openssl req -new -key $USERNAME.key -out $USERNAME.csr -subj "/CN=$USERNAME"

#### Send CSR to kube-apiserver for approval
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $USERNAME
spec:
  request: $(cat $USERNAME.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
#### Approve CSR
kubectl certificate approve $USERNAME
#### Download certificate
kubectl get csr $USERNAME -o jsonpath='{.status.certificate}' | base64 -d > $USERNAME.crt
####

### Get the CA certificate file
echo "### Get the Kind kubernetes CA certificate file"
docker exec -it kind-control-plane cat /etc/kubernetes/pki/ca.crt > $CA

#### Create the credential object and output the new kubeconfig file
echo "## Create the credential object and output the new kubeconfig file"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-credentials $USERNAME --client-certificate=$USERNAME.crt --client-key=$USERNAME.key --embed-certs"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-credentials $USERNAME --client-certificate=$USERNAME.crt --client-key=$USERNAME.key --embed-certs

#### Set the cluster info
echo "Set the cluster info"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-cluster $CLUSTER --server=$CLUSTER_SERVER --certificate-authority=$CA --embed-certs"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-cluster $CLUSTER --server=$CLUSTER_SERVER --certificate-authority=$CA --embed-certs

#### Set the context
echo "Set the context"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-context $USERNAME-$NAMESPACE-$CLUSTER --user=$USERNAME --cluster=$CLUSTER --namespace=$NAMESPACE"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-context $USERNAME-$NAMESPACE-$CLUSTER --user=$USERNAME --cluster=$CLUSTER --namespace=$NAMESPACE


