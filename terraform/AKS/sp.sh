# https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-list
# az ad sp list --show-mine

FILE_TFVARS="terraform.tfvars"

if [ ! -f "$FILE_TFVARS" ]; then
    echo "El archivo $FILE_TFVARS no existe"
    exit 1
fi

# Por defecto usare un hash del path para crear el service principal
AZ_SP_NAME_HASH=$(echo -n "$(pwd)" | sha256sum | cut -d " " -f1)

TFVARS="$(cat terraform.tfvars)"
PATTERN="##### service principal"$'\n'.+$'\n'"#####"

if [[ $TFVARS =~ $PATTERN ]]; then
  echo "La cadena modificada elimando la sp"
  
  AZ_SP_ID="$(az ad sp list --display-name $AZ_SP_NAME_HASH --query "[].id" --out tsv)"

  az ad sp delete --id $AZ_SP_ID

  echo "${TFVARS//$BASH_REMATCH/}" > $FILE_TFVARS
  sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' $FILE_TFVARS

else
  echo "La cadena modificada agregando la sp"

  AZ_SUBSCRIPTION_ID="$(az account show --query "id" --out tsv)"

  AZ_SP_JSON="$(
      az ad sp create-for-rbac \
          --name $AZ_SP_NAME_HASH \
          --role="Contributor" \
          --scopes="/subscriptions/$AZ_SUBSCRIPTION_ID"
  )"

  APP_ID=$(echo $AZ_SP_JSON | jq ".appId")
  APP_PASSWORD=$(echo $AZ_SP_JSON | jq ".password")

  echo "" >> $FILE_TFVARS
  echo "##### service principal" >> $FILE_TFVARS
  echo "# $AZ_SP_NAME_HASH" >> $FILE_TFVARS
  echo "aks_app_id = $APP_ID" >> $FILE_TFVARS
  echo "aks_client_secret = $APP_PASSWORD" >> $FILE_TFVARS
  echo "#####" >> $FILE_TFVARS
fi



#cat $FILE_TFVARS