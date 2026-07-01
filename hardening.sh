#!/bin/bash

# Asegurar que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Por favor, ejecuta este script como root (usando sudo)."
  exit 1
fi

echo "[+] Iniciando fase de remediación y hardening..."

# 1. Actualización de paquetes de seguridad
echo "[+] Actualizando repositorios y aplicando parches de seguridad..."
apt update && apt upgrade -y

# 2. Endurecimiento del servicio SSH
SSH_CONFIG="/etc/ssh/sshd_config"
echo "[+] Configurando algoritmos MAC seguros en SSH..."
if [ -f "$SSH_CONFIG" ]; then
    # Remover configuraciones previas de MACs si existen para evitar duplicados
    sed -i '/^MACs/d' $SSH_CONFIG
    # Inyectar algoritmos robustos SHA-2
    echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com" >> $SSH_CONFIG
    # Reiniciar el servicio para aplicar cambios
    systemctl restart ssh
    echo "[+] Servicio SSH reconfigurado y reiniciado con éxito."
else
    echo "[-] Error: No se encontró el archivo $SSH_CONFIG"
fi

# 3. Mitigación de TCP Timestamps
SYSCTL_CONFIG="/etc/sysctl.conf"
echo "[+] Desactivando TCP Timestamps para ocultar el uptime..."
if ! grep -q "net.ipv4.tcp_timestamps" "$SYSCTL_CONFIG"; then
    echo "net.ipv4.tcp_timestamps = 0" >> "$SYSCTL_CONFIG"
else
    sed -i 's/^net.ipv4.tcp_timestamps.*/net.ipv4.tcp_timestamps = 0/' "$SYSCTL_CONFIG"
fi
# Aplicar cambios en caliente
sysctl -p

echo "[+] ¡Hardening completado!"
echo "[+] Se recomienda reiniciar el servidor para limpiar por completo el stack de red en memoria (sudo reboot)."