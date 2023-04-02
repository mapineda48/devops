# Personal Manifiest Testings

- Ingress-Ngnix
- Cert Manager
- External DNS

Create un .env file en this folder with follow vars:
```sh
CLUSTER_ISSUER_EMAIL="foo@bar.com"

GODADDY_API_KEY="my-api-key"

GODADDY_API_SECRET="my-api-secret"

GODADDY_DOMAIN="foo.com"
```

Next step is this command
```sh
bash ./apply.sh
```