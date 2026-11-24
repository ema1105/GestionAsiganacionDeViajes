#!/usr/bin/env bash
# =============================================================================
# GAV — Crea toda la infraestructura en Azure for Students desde Azure Cloud Shell
#
#   1. portal.azure.com -> icono >_ (Cloud Shell) -> Bash.
#      Si pregunta por almacenamiento, "No storage account required" sirve
#      (pero entonces DESCARGA la llave antes de cerrar la sesión).
#   2. Manage files -> Upload -> este archivo.
#   3. bash azure-crear-infraestructura.sh
#
# Crea en el grupo rg-gav: VNet con 2 subredes, NSG, IP pública estática,
# VM Ubuntu 24.04 (Docker + swap preinstalados) y MySQL Flexible Server privado.
# Se puede ejecutar otra vez: reutiliza lo que ya exista.
# =============================================================================
set -euo pipefail

LOCATION="${LOCATION:-eastus2}"            # debe estar en las regiones permitidas
RG="rg-gav"
VNET="vnet-gav";  SNET_VM="snet-vm";  SNET_DB="snet-mysql"
NSG="nsg-gav-vm"; PIP="pip-gav";      VM="vm-gav"
VM_SIZE="${VM_SIZE:-Standard_B2s}"          # alternativa con 4 GB: Standard_B2als_v2
VM_USER="azureuser"
DB_USER="gavadmin"; DB_NAME="gav"; MYSQL_VERSION="8.0.21"
TAGS="project=GAV"
KEY="$HOME/.ssh/gav-azure"

ok()   { printf '\033[32m✔ %s\033[0m\n' "$*"; }
info() { printf '\033[36m» %s\033[0m\n' "$*"; }
existe() { "$@" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# 0. Datos
# -----------------------------------------------------------------------------
echo; echo "=== GAV: infraestructura en Azure ==="; echo
az account show --query "{suscripcion:name, estado:state}" -o table
echo
read -rp "Región permitida para tu suscripción [${LOCATION}]: " R; LOCATION="${R:-$LOCATION}"
echo "Tu IP pública: ábrela en TU navegador (no aquí) en https://checkip.amazonaws.com"
read -rp "IP pública para permitir SSH: " MY_IP
[[ "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "IP no válida."; exit 1; }

EXISTING_DB=$(az mysql flexible-server list -g "$RG" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -z "$EXISTING_DB" ]; then
  echo "Contraseña para MySQL: 8-128 caracteres con mayúscula, minúscula y número; sin / @ \" ni espacios."
  read -rsp "Contraseña DB: " DB_PASSWORD; echo
  read -rsp "Repetir: " DB_PASSWORD2; echo
  [ "$DB_PASSWORD" = "$DB_PASSWORD2" ] || { echo "No coinciden."; exit 1; }
  MYSQL_SERVER="mysql-gav-$(openssl rand -hex 3)"
else
  MYSQL_SERVER="$EXISTING_DB"
fi

# -----------------------------------------------------------------------------
# 1. Proveedores (suscripciones nuevas los traen sin registrar)
# -----------------------------------------------------------------------------
info "Registrando proveedores (puede tardar unos minutos la primera vez)"
for ns in Microsoft.Compute Microsoft.Network Microsoft.DBforMySQL; do
  az provider register --namespace "$ns" --wait >/dev/null
done
ok "Proveedores listos"

# -----------------------------------------------------------------------------
# 2. Grupo de recursos y red
# -----------------------------------------------------------------------------
az group create -n "$RG" -l "$LOCATION" --tags "$TAGS" -o none
ok "Grupo ${RG} (${LOCATION})"

if ! existe az network vnet show -g "$RG" -n "$VNET"; then
  az network vnet create -g "$RG" -n "$VNET" -l "$LOCATION" --address-prefixes 10.10.0.0/16 \
    --subnet-name "$SNET_VM" --subnet-prefixes 10.10.1.0/24 --tags "$TAGS" -o none
fi
if ! existe az network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$SNET_DB"; then
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n "$SNET_DB" \
    --address-prefixes 10.10.2.0/24 --delegations Microsoft.DBforMySQL/flexibleServers -o none
fi
ok "Red ${VNET}: ${SNET_VM} 10.10.1.0/24, ${SNET_DB} 10.10.2.0/24 (delegada a MySQL)"

# -----------------------------------------------------------------------------
# 3. NSG (firewall de la subred de la VM)
# -----------------------------------------------------------------------------
if ! existe az network nsg show -g "$RG" -n "$NSG"; then
  az network nsg create -g "$RG" -n "$NSG" -l "$LOCATION" --tags "$TAGS" -o none
fi
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-SSH-Equipo --priority 100 \
  --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes "${MY_IP}/32" --destination-port-ranges 22 -o none
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-HTTP --priority 110 \
  --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --destination-port-ranges 80 -o none
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-HTTPS --priority 120 \
  --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --destination-port-ranges 443 -o none
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-HTTP3 --priority 130 \
  --direction Inbound --access Allow --protocol Udp \
  --source-address-prefixes Internet --destination-port-ranges 443 -o none
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n "$SNET_VM" --network-security-group "$NSG" -o none
ok "NSG ${NSG}: SSH solo desde ${MY_IP}; 80/443 abiertos"

# -----------------------------------------------------------------------------
# 4. IP pública estática
# -----------------------------------------------------------------------------
if ! existe az network public-ip show -g "$RG" -n "$PIP"; then
  az network public-ip create -g "$RG" -n "$PIP" -l "$LOCATION" --sku Standard \
    --allocation-method Static --version IPv4 --tags "$TAGS" -o none
fi
VM_IP=$(az network public-ip show -g "$RG" -n "$PIP" --query ipAddress -o tsv)
ok "IP pública ${VM_IP}"

# -----------------------------------------------------------------------------
# 5. MySQL Flexible Server privado (se lanza sin esperar; tarda ~10 min)
# -----------------------------------------------------------------------------
if [ -z "$EXISTING_DB" ]; then
  info "Creando MySQL ${MYSQL_SERVER} en segundo plano"
  az mysql flexible-server create -g "$RG" -n "$MYSQL_SERVER" -l "$LOCATION" \
    --tier Burstable --sku-name Standard_B1ms --version "$MYSQL_VERSION" \
    --storage-size 32 --storage-auto-grow Disabled \
    --high-availability Disabled \
    --admin-user "$DB_USER" --admin-password "$DB_PASSWORD" \
    --database-name "$DB_NAME" \
    --vnet "$VNET" --subnet "$SNET_DB" \
    --tags "$TAGS" --yes -o none &
  DB_PID=$!
else
  ok "MySQL ${MYSQL_SERVER} ya existe"
  DB_PID=""
fi

# -----------------------------------------------------------------------------
# 6. Llave SSH y VM con Docker preinstalado
# -----------------------------------------------------------------------------
if [ ! -f "$KEY" ]; then
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "gav-azure" >/dev/null
fi
cp "$KEY" "$HOME/gav-azure-key"   # copia fácil de descargar

cat > /tmp/gav-cloud-init.sh <<'CLOUDINIT'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose-v2 git mysql-client htop
systemctl enable --now docker
usermod -aG docker azureuser
timedatectl set-timezone America/Bogota
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
echo 'vm.swappiness=10' > /etc/sysctl.d/99-gav.conf && sysctl --system
touch /home/azureuser/GAV_SERVIDOR_LISTO
CLOUDINIT

if ! existe az vm show -g "$RG" -n "$VM"; then
  info "Creando VM ${VM} (${VM_SIZE})"
  az vm create -g "$RG" -n "$VM" -l "$LOCATION" \
    --image Ubuntu2404 --size "$VM_SIZE" \
    --admin-username "$VM_USER" --ssh-key-values "${KEY}.pub" \
    --vnet-name "$VNET" --subnet "$SNET_VM" --nsg "" \
    --public-ip-address "$PIP" \
    --storage-sku StandardSSD_LRS --os-disk-size-gb 32 \
    --custom-data /tmp/gav-cloud-init.sh \
    --tags "$TAGS" -o none
fi
ok "VM ${VM} creada"

# -----------------------------------------------------------------------------
# 7. Esperar MySQL y ajustar parámetros
# -----------------------------------------------------------------------------
if [ -n "$DB_PID" ]; then
  info "Esperando MySQL (10-15 min; no cierres Cloud Shell)..."
  wait "$DB_PID"
fi
az mysql flexible-server parameter set -g "$RG" -s "$MYSQL_SERVER" \
  -n log_bin_trust_function_creators --value ON -o none
DB_HOST=$(az mysql flexible-server show -g "$RG" -n "$MYSQL_SERVER" --query fullyQualifiedDomainName -o tsv)
ok "MySQL listo: ${DB_HOST}"

# -----------------------------------------------------------------------------
# 8. Resumen
# -----------------------------------------------------------------------------
cat > "$HOME/gav-resumen-azure.txt" <<EOF
===== GAV — Infraestructura en Azure (${LOCATION}) =====
IP pública de la VM (DuckDNS y SSH) : ${VM_IP}
SSH                                 : ssh -i gav-azure-key ${VM_USER}@${VM_IP}
VM                                  : ${VM} (${VM_SIZE})
MySQL (DB_HOST)                     : ${DB_HOST}
DB_NAME / DB_USER                   : ${DB_NAME} / ${DB_USER}
SSH permitido desde                 : ${MY_IP}/32

Líneas para el .env (la contraseña es la que escribiste):
DB_HOST=${DB_HOST}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
EOF

echo; cat "$HOME/gav-resumen-azure.txt"; echo
echo "SIGUIENTE:"
echo " 1) Manage files -> Download -> ${HOME}/gav-azure-key        (llave privada SSH: guárdala)"
echo " 2) Manage files -> Download -> ${HOME}/gav-resumen-azure.txt"
echo " 3) En duckdns.org pon la IP ${VM_IP} en los dos subdominios."
echo " 4) En ~5 min la VM termina de instalar Docker (aparece ~/GAV_SERVIDOR_LISTO)."
