# Seguridad_Informatica_Lim

**Proyecto Final de Seguridad Informática (UPN)**  
**Caso de Estudio:** *Seguridad de Historias Clínicas Electrónicas (HCE) y Sistemas de Imagenología: Implementación de Seguridad Perimetral, Hardening y Auditoría de Vulnerabilidades para la Clínica Limatambo (Sede San Isidro).*  
**Docente:** Ing. Adolfo Eliseo Luna Izquierdo

---

## Estructura del Repositorio

- **[`AGENTS.md`](./AGENTS.md):** Reglas de arquitectura, direccionamiento IP oficial y alineación estricta con las Semanas 2 a 12 del curso para colaboradores y agentes de IA.
- **[`Proyecto_Final_Pivote/`](./Proyecto_Final_Pivote/):**
  - **[`Informe_Final_Seguridad_Informatica_Clinica_Limatambo_Pivote_S2_S12.docx`](./Proyecto_Final_Pivote/Informe_Final_Seguridad_Informatica_Clinica_Limatambo_Pivote_S2_S12.docx):** Informe Final completo en formato Word (`.docx`) con las 6 secciones del proyecto y evidencias de las Semanas 2 a 12.
  - **[`Informe_Final_Seguridad_Informatica_Clinica_Limatambo_Pivote_S2_S12.md`](./Proyecto_Final_Pivote/Informe_Final_Seguridad_Informatica_Clinica_Limatambo_Pivote_S2_S12.md):** Versión en Markdown del Informe Final para lectura rápida en GitHub.
  - **[`docker/docker-compose.yml`](./Proyecto_Final_Pivote/docker/docker-compose.yml):** Infraestructura como código en Docker con los 6 contenedores del laboratorio (`fw-perimetral`, `portal-clinica-dmz`, `honeypot-dmz`, `metasploitable-hce`, `cliente-medico-lan` y `kali-auditor`).
  - **[`docker/00_Iniciar_Laboratorio_Docker.ps1`](./Proyecto_Final_Pivote/docker/00_Iniciar_Laboratorio_Docker.ps1):** Script automático en PowerShell para levantar toda la arquitectura Docker e instalar las herramientas de auditoría en Kali Linux.
  - **[`01_Cisco_Hardening_Perimetral_S2_a_S9.ios`](./Proyecto_Final_Pivote/01_Cisco_Hardening_Perimetral_S2_a_S9.ios):** Configuración consolidada de Cisco IOS para Packet Tracer (OSPF pasivo, SSH v2, AAA local, RBAC `parser view` y `ACL 101/102`).
  - **[`02_Deploy_Portal_Clinica_Limatambo_DMZ.sh`](./Proyecto_Final_Pivote/02_Deploy_Portal_Clinica_Limatambo_DMZ.sh):** Despliegue del Portal Web de Clínica Limatambo en Ubuntu Server + Nginx (`172.16.10.10`).
  - **[`03_Kali_Auditoria_Completa_S3_a_S8.sh`](./Proyecto_Final_Pivote/03_Kali_Auditoria_Completa_S3_a_S8.sh):** Script de auditoría en Kali Linux (`netdiscover`, `nmap`, `whatweb`, `nikto`, `nc`, `enum4linux`, `metasploit` y `ettercap`).
  - **[`04_Guia_Configuracion_OPNsense_S11_S12.md`](./Proyecto_Final_Pivote/04_Guia_Configuracion_OPNsense_S11_S12.md):** Guía paso a paso para OPNsense en VirtualBox (`WAN`, `RedLAN`, `RedDMZ`, DNAT y `Live View`).
  - **[`05_Ejecutar_Todas_Las_Pruebas_Docker.ps1`](./Proyecto_Final_Pivote/05_Ejecutar_Todas_Las_Pruebas_Docker.ps1):** Script que ejecuta de forma desatendida todas las pruebas de las Semanas 3 a 12 sobre los contenedores Docker y guarda las salidas reales en `evidencias_reales/`.
- **`S2/` a `S12/`:** Material de referencia, guías de laboratorio y diapositivas oficiales del curso.

---

## Inicio Rápido para Colaboradores (Levantar el Laboratorio en 1 Minuto)

### 1. Clonar el repositorio
```powershell
git clone https://github.com/NeoArsenal/Seguridad_Informatica_Lim.git
cd Seguridad_Informatica_Lim
```

### 2. Iniciar los 6 contenedores de la Clínica Limatambo en Docker
```powershell
powershell -ExecutionPolicy Bypass -File ".\Proyecto_Final_Pivote\docker\00_Iniciar_Laboratorio_Docker.ps1"
```
- **Portal Web HCE e Imagenología (DMZ):** `http://localhost:8080` (`172.16.10.10`)
- **Sensor Honeypot SSH (DMZ):** `localhost:2222` (`172.16.10.20`)
- **Servidor Clínico Legado (Metasploitable2 en LAN):** `10.0.0.20`
- **Estación Médica Interna (LAN):** `10.0.0.10`
- **Auditor Kali Linux:** `10.0.0.50` / `172.16.10.50` / `203.0.113.50`

### 3. Ejecutar la batería completa de pruebas (Semanas 3 a 12)
```powershell
powershell -ExecutionPolicy Bypass -File ".\Proyecto_Final_Pivote\05_Ejecutar_Todas_Las_Pruebas_Docker.ps1"
```
