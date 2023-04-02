source ./.env

kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml

kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

CERT_MANAGER=$(cat cert-manager.yml | sed "s/\$CLUSTER_ISSUER_EMAIL/${CLUSTER_ISSUER_EMAIL}/g")

echo "$CERT_MANAGER" | kubectl delete -f -

EXTERNAL_DNS=$(
    cat external-dns.yml \
    | sed "s/\$DOMAIN_FILTER/${GODADDY_DOMAIN}/g" \
    | sed "s/\$GODADDY_API_KEY/${GODADDY_API_KEY}/g" \
    | sed "s/\$GODADDY_API_SECRET/${GODADDY_API_SECRET}/g" \
    | sed "s/\$CLUSTER_ISSUER_EMAIL/${CLUSTER_ISSUER_EMAIL}/g")

echo "$EXTERNAL_DNS" | kubectl delete -f -