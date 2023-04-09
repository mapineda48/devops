sudo apt update && sudo apt upgrade -y


#################################### Update DUCK DNS ########################################
curl "https://www.duckdns.org/update?domains=mapineda48&token=$1"

DUCK_DNS_CRONTAB="@reboot curl 'https://www.duckdns.org/update?domains=mapineda48&token=$1' >/dev/null 2>&1"

# Obtener la lista de tareas actual y agregar la nueva tarea
crontab -l | { cat; echo $DUCK_DNS_CRONTAB; } > /tmp/crontab.tmp

# Cargar la nueva lista en cron
crontab /tmp/crontab.tmp

# Eliminar el archivo temporal
rm /tmp/crontab.tmp

#################################### Docker ########################################
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

sudo apt-get install -q -y ca-certificates curl gnupg

sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -q -y

sudo apt-get install -q -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# https://docs.docker.com/engine/install/linux-postinstall/
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# sudo apt-get install docker-compose-plugin
sudo apt-get install -q -y docker-compose-plugin

sudo apt autoremove -q -y

sudo reboot