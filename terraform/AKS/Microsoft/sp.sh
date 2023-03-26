# https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-list

# Por defecto usare un hash del path para crear el service principal
AZ_SP_NAME_HASH=$(echo -n "$(pwd)" | sha256sum | cut -d " " -f1)
SP_TFVARS="terraform.tfvars"

echo "service principal name $AZ_SP_NAME_HASH"

if [ -f $SP_TFVARS ]; then
    echo "exists service principal"

    AZ_SP_ID="$(az ad sp list --display-name $AZ_SP_NAME_HASH --query "[].id" --out tsv)"

    az ad sp delete --id $AZ_SP_ID

    rm $SP_TFVARS
else
    echo "create service principal"

    AZ_SUBSCRIPTION_ID="$(az account show --query "id" --out tsv)"

    AZ_SP_JSON="$(
        az ad sp create-for-rbac \
            --name $AZ_SP_NAME_HASH \
            --role="Contributor" \
            --scopes="/subscriptions/$AZ_SUBSCRIPTION_ID"
    )"

    echo "# service principal display name $AZ_SP_NAME_HASH" > $SP_TFVARS

    echo "aks_service_principal_app_id = $(echo $AZ_SP_JSON | jq ".appId")" >> $SP_TFVARS

    echo "aks_service_principal_client_secret = $(echo $AZ_SP_JSON | jq ".password")" >> $SP_TFVARS

fi