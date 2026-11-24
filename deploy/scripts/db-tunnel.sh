#!/usr/bin/env bash
# Se ejecuta en el PORTÁTIL (Git Bash / WSL). Túnel SSH hacia el MySQL privado de Azure
# a través de la VM. Mientras esté abierto: Workbench / Power BI / mysqldump -> 127.0.0.1:3307
#
#   bash deploy/scripts/db-tunnel.sh gav-azure-key <IP_VM> mysql-gav-xxxx.mysql.database.azure.com
set -euo pipefail
KEY="${1:?Ruta de la llave privada (gav-azure-key)}"
VM_IP="${2:?IP pública de la VM}"
DB_HOST="${3:?Host de MySQL}"
LOCAL_PORT="${4:-3307}"
echo ">> Túnel en 127.0.0.1:${LOCAL_PORT} -> ${DB_HOST}:3306 (Ctrl+C para cerrar)"
ssh -i "$KEY" -N -L "${LOCAL_PORT}:${DB_HOST}:3306" "${SSH_USER:-azureuser}@${VM_IP}"
