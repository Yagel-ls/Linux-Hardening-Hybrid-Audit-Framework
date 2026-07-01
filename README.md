#  Linux Hardening & Hybrid Audit Framework

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Debian](https://img.shields.io/badge/OS-Debian_Linux-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Security](https://img.shields.io/badge/Security-OpenVAS_%7C_Lynis-00599C?style=for-the-badge)

Este repositorio contiene los scripts de automatización desarrollados para el endurecimiento (Hardening) lógico y perimetral de servidores Linux (Debian). El framework nace como respuesta directa a la remediación de vulnerabilidades detectadas a través de una **auditoría de seguridad híbrida** (escaneos de red con Greenbone/OpenVAS y análisis de cumplimiento interno con Lynis).

**Autor:** Emmanuel Galeana Letras  
**Institución:** Benemérita Universidad Autónoma de Puebla (BUAP)

---

##  Arquitectura del Entorno de Pruebas

El diseño del laboratorio bajo el cual se programaron estos scripts operó en un modelo de virtualización aislado:
- **Capa Anfitriona:** Windows 11 operando hipervisores concurrentes.
- **Nodo Objetivo (Caja Blanca):** Máquina Virtual Debian vulnerable, evaluada internamente mediante `Lynis`.
- **Nodo Auditor (Caja Negra):** Contenedor Docker aislado ejecutando `Greenbone GVM` para simular ataques externos e inyección de tráfico TCP/UDP.

---

##  Estructura del Repositorio

En este repositorio encontrarás dos iteraciones del código que demuestran la evolución técnica hacia la **Infraestructura como Código (IaC)**:

1. `hardening.sh`: Versión inicial procedimental. Un script lineal que ejecuta inyecciones de seguridad de arriba hacia abajo sin manejo de errores. *(Uso educativo/comparativo)*.
2. `hardening_pro.sh`: **[RECOMENDADO]** Versión modular avanzada. Funciona como un orquestador que aísla procesos, genera bitácoras de registro locales (`.log`) y protege el sistema en caso de fallos de privilegios.

---

##  Módulos de Remediación (`hardening_pro.sh`)

El framework principal está estructurado en 4 módulos lógicos de seguridad:

* **Módulo 1: Depuración de Superficie de Ataque:** Purga automática de servicios huérfanos que abren puertos innecesarios (ej. `rpcbind`, `nis`) y remoción de dependencias basura (`apt autoremove`).
* **Módulo 2: Criptografía y Acceso SSH:** Edición invisible (`sed`) de `/etc/ssh/sshd_config` para prohibir el inicio de sesión remoto del usuario `Root` y forzar cifrado moderno (SHA-2), evitando ataques de Fuerza Bruta y MITM.
* **Módulo 3: Aislamiento de Red (Firewall):** Implementación de políticas paranoicas en `UFW` (bloquear todo el tráfico entrante, permitiendo solo el puerto de administración `2222`). Adicionalmente, altera el Kernel (`sysctl.conf`) para desactivar `tcp_timestamps=0`, evitando fugas de información del *Uptime*.
* **Módulo 4: Políticas de Identidad:** Inyección de directivas en `/etc/login.defs` para forzar la caducidad máxima de contraseñas de usuarios a 90 días (`PASS_MAX_DAYS`).

---

##  Guía de Uso e Instalación

### Requisitos Previos
- Sistema Operativo basado en Debian/Ubuntu.
- Privilegios de Superusuario (`root`).
- Se recomienda fuertemente ejecutarlo primero en un entorno de pruebas (Máquina Virtual) antes de pasarlo a producción.

