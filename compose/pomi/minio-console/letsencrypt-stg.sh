# https://letsencrypt.org/docs/staging-environment/

# Get the current script path
SCRIPT_PATH=$(realpath "$0")

# Get the directory that contains the script
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

echo "The current script directory is: $SCRIPT_DIR"

ROOT_CA=()

for URL in "${ROOT_CA[@]}"
do
    curl -L -o "$SCRIPT_DIR/ca-trust/$(basename $URL)" "$URL"
done