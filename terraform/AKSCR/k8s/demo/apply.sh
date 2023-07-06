export APP_NAME="www"
export DOMAIN="mapineda48.xyz"
export DEPLOY_IMAGE="nginx:latest"

kubectl kustomize . | envsubst | kubectl apply -f - 

echo "Aplicación '${APP_NAME}' desplegada en el dominio '${DOMAIN}' utilizando la imagen '${DEPLOY_IMAGE}'"