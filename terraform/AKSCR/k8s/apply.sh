# Get the current script path
SCRIPT_PATH=$(realpath "$0")

# Get the directory that contains the script
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

cd $SCRIPT_DIR

# Enviroment variables
source ./.env

##################################### Kubectl ##########################################
# Warning this will ereaser current config
cd ..
echo "$(terraform output kube_config)" | sed '1d;$d' > ~/.kube/config
cd k8s

################################## Ingress Ngnix #######################################

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml

################################## Cert Manager #######################################

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

CERT_MANAGER=$(cat cert-manager.yml | sed "s/\$CLUSTER_ISSUER_EMAIL/${CLUSTER_ISSUER_EMAIL}/g")

while true; do
  echo "$CERT_MANAGER" | kubectl apply -f -
  
  if [[ $? -eq 0 ]]; then
    break
  fi

  echo "Error al aplicar el manifiesto cert manager, reintentando en 6 segundos..."
  sleep 6
done

################################## External DNS #######################################

EXTERNAL_DNS=$(
    cat external-dns.yml \
    | sed "s/\$DOMAIN_FILTER/${GODADDY_DOMAIN}/g" \
    | sed "s/\$GODADDY_API_KEY/${GODADDY_API_KEY}/g" \
    | sed "s/\$GODADDY_API_SECRET/${GODADDY_API_SECRET}/g" \
    | sed "s/\$CLUSTER_ISSUER_EMAIL/${CLUSTER_ISSUER_EMAIL}/g")

echo "$EXTERNAL_DNS" | kubectl apply -f -