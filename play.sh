#!/bin/bash

export USERNAME="snowdrop"
export NAMESPACE="demo"
export CLUSTER=kind-kind

kubectl config use-context kind-kind

### Delete previously created resources
kubectl delete rolebinding $USERNAME -n $NAMESPACE
kubectl delete ns $NAMESPACE

### Create the namespace $NAMESPACE
kubectl create ns $NAMESPACE

### Assign the role ADMIN to the $USERNAME
cat <<EOF | kubectl apply --namespace=$NAMESPACE -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME-admin
  namespace: $NAMESPACE
subjects:
- kind: User
  name: $USERNAME
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
EOF

### Create a pod
echo "Create a pod under $NAMESPACE"
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-name
spec:
  containers:
  - name: nginx
    image: nginx:latest
    command: ['sh', '-c', 'echo "Hello, Kubernetes!" && sleep 3600']
EOF

#### Use the context
echo "Use the $USERNAME context"
kubectl --kubeconfig=$USERNAME-kubeconfig config use-context $USERNAME-$NAMESPACE-$CLUSTER

#sleep 20s
#### Get a pod
echo "1. Get the nginx pod created the namespace $NAMESPACE"
kubectl --kubeconfig=$USERNAME-kubeconfig get pods -n $NAMESPACE
echo "################ Next ###############"
echo ""

### Should see a rolebinding
echo "2. See if we have a RoleBinding assigned to the user snowdrop and having the role ADMIN"
kubectl --kubeconfig=$USERNAME-kubeconfig -n $NAMESPACE get rolebinding
echo "################ Next ###############"
echo ""

#### Should get YES as we see pods within the namespace $NAMESPACE
echo "3. Should get YES as we see pods within the namespace $NAMESPACE"
kubectl auth can-i get pods --as $USERNAME --namespace $NAMESPACE
echo "################ Next ###############"
echo ""

#### Should get NO as we cannot see the pods under the namespace kube-system
echo "4. Should get NO as we cannot see the pods under the namespace kube-system"
kubectl auth can-i get po --as $USERNAME --namespace kube-system
echo "################ Next ###############"
echo ""