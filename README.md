## How to authenticate a user and use a different role

[Blog post](https://neonmirrors.net/post/2019-10/authentication-and-authorization-in-k8s/)
[Kubernetes CSR doc](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)

### Steps

- Create a private key and Certificate request
```bash
openssl genrsa -out snowdrop.key 2048
openssl req -new -key snowdrop.key -out snowdrop.csr -subj "/CN=Snowdrop"
```
- Ask Kubernetes to approve the following CSR and generate a self-signed certificate
```bash
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: snowdrop
spec:
    groups:
    - system:authenticated
    request: $(cat snowdrop.csr | base64 | tr -d '\n')
    signerName: kubernetes.io/kube-apiserver-client
    usages:
    - digital signature
    - key encipherment
    - client auth
EOF
```
- Approve it and get the certificate
```bash
kubectl certificate approve snowdrop
kubectl get csr snowdrop -o jsonpath='{.status.certificate}' | base64 -d > snowdrop.crt
```

