#source ./.env

################################## Kubectl config #######################################
# Configurar kubectl para que use el archivo kubeconfig
export KUBECONFIG="$(mktemp /tmp/XXXXXXXXXXXXXX)"

echo "$KUBECONFIG_CONTENTS" | sed '1d;$d' > $KUBECONFIG


################################## Ingress Ngnix #######################################
# https://kubernetes.github.io/ingress-nginx/deploy/#azure

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml


##################################### Cert Manager ######################################
# https://cert-manager.io/docs/installation/kubectl/

CERT_MANAGER_YML="https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml"

if [ -n "${CLUSTER_ISSUER_CERT}" ] && kubectl apply -f "$CERT_MANAGER_YML"; then

  # https://cert-manager.io/docs/configuration/acme/
  CLUSTER_ISSUER=$(envsubst < cluster-issuer.yml)

  while true; do
    echo "$CLUSTER_ISSUER" | kubectl apply -f -
    
    if [[ $? -eq 0 ]]; then
      break
    fi

    echo "Error al aplicar el manifiesto cert manager, reintentando en 6 segundos..."
    sleep 6
  done

else
    echo "Error al aplicar Cert-manager"
fi


##################################### External DNS ######################################
if [ -n "${GODADDY_API_KEY}" ] && [ -n "${GODADDY_API_SECRET}" ] && [ -n "${GODADDY_DOMAIN}" ]; then

  # Inicializar la variable que contendrá el contenido de todos los archivos
  EXTERNAL_DNS=""

  # Iterar sobre todos los archivos del directorio actual y concatenar su contenido
  for FILE in external-dns/*.yml; do
    if [ -f "$FILE" ]; then
      # Concatenar el contenido del archivo con un separador
      EXTERNAL_DNS="$EXTERNAL_DNS$(cat "$FILE")\n\n---\n"
    fi
  done

  echo -e "${EXTERNAL_DNS%---}" | envsubst | kubectl apply -f - 
fi


################################## Kubectl config #######################################
rm "$KUBECONFIG"


####################################### ACR ############################################
az acr login -n "$ACR_LOGIN"