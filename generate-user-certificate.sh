#!/bin/bash
export USERNAME="snowdrop"
export NAMESPACE="demo"
export CA=/etc/kubernetes/pki/ca.crt
export CLUSTER=kind-kind
export CLUSTER_SERVER=https://127.0.0.1:59817

####
#### Remove the generated files
rm snowdrop.*; rm snowdrop-kubeconfig

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

### Create the namespace $NAMESPACE
kubectl create ns $NAMESPACE
### Assign a role to the user
### Assign the role to the user
cat <<EOF | kubectl apply --namespace=$NAMESPACE -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: developer-admin
subjects:
- kind: User
  name: $USERNAME
  apiGroup: rbac.authorization.k8s.io
  namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
EOF

#### Create the credential object and output the new kubeconfig file
echo "## Create the credential object and output the new kubeconfig file"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-credentials $USERNAME --client-certificate=$USERNAME.crt --client-key=$USERNAME.key --embed-certs"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-credentials $USERNAME --client-certificate=$USERNAME.crt --client-key=$USERNAME.key --embed-certs

#### Set the cluster info
echo "Set the cluster info"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-cluster $CLUSTER --server=$CLUSTER_SERVER --certificate-authority=$CA --embed-certs"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-cluster $CLUSTER --server=$CLUSTER_SERVER --certificate-authority=$CA --embed-certs
# ERROR: error: could not stat certificate-authority file /etc/kubernetes/pki/ca.crt: stat /etc/kubernetes/pki/ca.crt: no such file or directory

#### Set the context
echo "Set the context"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config set-context $USERNAME-$NAMESPACE-$CLUSTER --user=$USERNAME --cluster=$CLUSTER --namespace=$NAMESPACE"
kubectl --kubeconfig=$USERNAME-kubeconfig config set-context $USERNAME-$NAMESPACE-$CLUSTER --user=$USERNAME --cluster=$CLUSTER --namespace=$NAMESPACE

#### Use the context
echo "Use the context"
echo "kubectl --kubeconfig=$USERNAME-kubeconfig config use-context $USERNAME-$NAMESPACE-$CLUSTER"
kubectl --kubeconfig=$USERNAME-kubeconfig config use-context $USERNAME-$NAMESPACE-$CLUSTER
