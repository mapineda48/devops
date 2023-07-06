# Reemplaza el texto de filtro aquí
FILTER_TEXT="external-dns"
DELIMITER="-"

# Obtiene la lista de registros de DNS
RECORDS=$(curl -s -X GET "https://api.godaddy.com/v1/domains/$DOMAIN/records" \
  -H "Authorization: sso-key $API_KEY:$SECRET_KEY" \
  -H "Content-Type: application/json")

echo "$RECORDS" | jq -c '.[]' | while read -r RECORD; do
  RECORD_TYPE=$(echo "$RECORD" | jq '.type' | tr -d '"')
  RECORD_NAME=$(echo "$RECORD" | jq '.name' | tr -d '"')

  if [ ! "$RECORD_TYPE" == "TXT" ] && [ ! "$RECORD_NAME" == *"$FILTER_TEXT"* ]; then
    continue;
  fi

  echo "Eliminando registro: Nombre=$RECORD_NAME Tipo=TXT"

  curl -s -X DELETE "https://api.godaddy.com/v1/domains/$DOMAIN/records/TXT/$RECORD_NAME" \
    -H "Authorization: sso-key $API_KEY:$SECRET_KEY" \
    -H "Content-Type: application/json"

  RECORD_NAME="$(echo $RECORD_NAME | sed "s/${FILTER_TEXT}//g")"

  #  echo $RECORD_NAME

  # Extrae la primera parte del string antes del delimitador
  TYPE="${RECORD_NAME%%$DELIMITER*}"

  # Extrae la segunda parte del string después del delimitador
  NAME="${RECORD_NAME#*$DELIMITER}"

  if [[ "$TYPE" == "$NAME" ]]; then
    continue;
  fi

  TYPE="$(echo $TYPE | tr '[:lower:]' '[:upper:]')"

  echo "Eliminando registro: Nombre=$NAME Tipo=$TYPE"

  curl -s -X DELETE "https://api.godaddy.com/v1/domains/$DOMAIN/records/$TYPE/$NAME" \
    -H "Authorization: sso-key $API_KEY:$SECRET_KEY" \
    -H "Content-Type: application/json"

done
