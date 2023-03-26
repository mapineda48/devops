# https://www.redhat.com/sysadmin/ca-certificates-cli

cat /etc/os-release

# Set the directory where the files are located
CA_TRUST_DIR="/etc/pki/ca-trust/extracted/pem/ca-trust"

# Set the name of the output file
TLS_CA_BUNDLE="../tls-ca-bundle.pem"

# Iterate through each file in the directory
for PEM_FILE in "$CA_TRUST_DIR"/*.pem
do
    #  Add a blank line after the file content
    echo "" >> "$TLS_CA_BUNDLE"
    
    # Add the file name as a comment in the output file
    echo "# $(basename $PEM_FILE)" >> "$TLS_CA_BUNDLE"
    
    # Add the file content to the output file
    cat "$PEM_FILE" >> "$TLS_CA_BUNDLE"
done