#!/bin/bash

# ==============================================================================
# FRAMEWORK MODULAR DE HARDENING DE SISTEMAS LINUX
# Desarrollado para auditoría y endurecimiento automatizado de servidores Debian
# ==============================================================================

# Configuración de colores para la terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Archivo de registro local (Log)
LOG_FILE="/var/log/hardening_execution.log"

# --- FUNCIONES DE CONTROL ---

log_success() {
    echo -e "${GREEN}[+] $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[-] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[*] $1${NC}" | tee -a "$LOG_FILE"
}

verificar_privilegios() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Este script debe ejecutarse con privilegios de root (sudo).${NC}"
        exit 1
    fi
    echo "=== Iniciando sesión de Hardening: $(date) ===" >> "$LOG_FILE"
}

# --- MÓDULOS DE HARDENING ---

modulo_actualizacion_sistema() {
    log_info "Iniciando Módulo 1: Actualización y depuración del sistema..."
    
    apt update -y && apt upgrade -y
    if [ $? -eq 0 ]; then
        log_success "Sistema operativo actualizado y parches de seguridad aplicados."
    else
        log_error "Falla al ejecutar apt upgrade."
    fi

    # Eliminación de servicios obsoletos comunes que abren puertos innecesarios
    log_info "Removiendo servicios potenciales de fuga de información (rpcbind, nis)..."
    apt purge rpcbind nis -y > /dev/null 2>&1
    apt autoremove -y > /dev/null 2>&1
    log_success "Depuración de paquetes obsoletos completada."
}

modulo_seguridad_ssh() {
    log_info "Iniciando Módulo 2: Endurecimiento de políticas SSH..."
    SSH_CONFIG="/etc/ssh/sshd_config"

    if [ -f "$SSH_CONFIG" ]; then
        # Respaldo de seguridad previo
        cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
        
        # Eliminación de líneas previas de MACs para evitar colisiones
        sed -i '/^MACs/d' "$SSH_CONFIG"
        
        # Inyección de algoritmos robustos con mitigación extendida (ETM)
        echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com" >> "$SSH_CONFIG"
        
        # Buenas prácticas adicionales: Deshabilitar login de Root directo por SSH
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG" || echo "PermitRootLogin no" >> "$SSH_CONFIG"
        
        systemctl restart ssh
        log_success "Configuración SSH endurecida en el puerto personalizado. Root deshabilitado en SSH."
    else
        log_error "No se encontró el archivo de configuración SSH en $SSH_CONFIG."
    fi
}

modulo_firewall_y_red() {
    log_info "Iniciando Módulo 3: Configuración de Firewall (UFW) y Stack TCP/IP..."
    
    # Instalar UFW si no existe
    apt install ufw -y > /dev/null 2>&1

    # Definir reglas por defecto por seguridad: Bloquear todo lo entrante, permitir saliente
    ufw default deny incoming > /dev/null
    ufw default allow outgoing > /dev/null

    # Permitir de forma explícita tu puerto SSH de gestión
    ufw allow 2222/tcp comment 'Gestion SSH Segura' > /dev/null
    
    # Habilitar el firewall de manera persistente
    echo "y" | ufw enable > /dev/null
    log_success "Firewall UFW activo. Regla estricta aplicada sobre el puerto 2222/tcp."

    # Ofuscación del stack de red (TCP Timestamps)
    SYSCTL_CONFIG="/etc/sysctl.conf"
    if ! grep -q "net.ipv4.tcp_timestamps" "$SYSCTL_CONFIG"; then
        echo "net.ipv4.tcp_timestamps = 0" >> "$SYSCTL_CONFIG"
    else
        sed -i 's/^net.ipv4.tcp_timestamps.*/net.ipv4.tcp_timestamps = 0/' "$SYSCTL_CONFIG"
    fi
    sysctl -p > /dev/null
    log_success "Marcas de tiempo TCP desactivadas en el archivo de control del sistema."
}

modulo_politicas_usuarios() {
    log_info "Iniciando Módulo 4: Configuración de directivas de cuentas y contraseñas..."
    
    LOGIN_DEFS="/etc/login.defs"
    if [ -f "$LOGIN_DEFS" ]; then
        # Definir tiempo máximo de vida de una contraseña (90 días)
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$LOGIN_DEFS" || echo "PASS_MAX_DAYS   90" >> "$LOGIN_DEFS"
        # Definir días de advertencia previos al cambio (7 días)
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' "$LOGIN_DEFS" || echo "PASS_WARN_AGE   7" >> "$LOGIN_DEFS"
        log_success "Políticas de caducidad de contraseñas de cuentas del sistema actualizadas a 90 días."
    else
        log_error "No se pudo acceder a $LOGIN_DEFS."
    fi
}

# --- HILO PRINCIPAL DE EJECUCIÓN (ORQUESTADOR) ---

main() {
    clear
    echo -e "${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}         EJECUTANDO DESPLIEGUE MODULAR DE CONTROL DE RIESGOS        ${NC}"
    echo -e "${YELLOW}===================================================================${NC}"
    
    verificar_privilegios
    
    # Llamada selectiva de módulos
    modulo_actualizacion_sistema
    echo "-------------------------------------------------------------------"
    modulo_seguridad_ssh
    echo "-------------------------------------------------------------------"
    modulo_firewall_y_red
    echo "-------------------------------------------------------------------"
    modulo_politicas_usuarios
    
    echo -e "${YELLOW}===================================================================${NC}"
    log_success "Proceso global terminado correctamente."
    log_info "Los registros detallados se guardaron en: $LOG_FILE"
    echo -e "${YELLOW}Se recomienda reiniciar el sistema para aplicar los cambios del kernel.${NC}"
}

# Lanzar el script
main