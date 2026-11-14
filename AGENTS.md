# AGENTS.md — Guía y Reglas del Proyecto de Seguridad Informática (Clínica Limatambo)

## 1. Contexto del Proyecto
- **Curso:** Seguridad Informática (UPN)
- **Docente:** Ing. Adolfo Eliseo Luna Izquierdo
- **Caso de Estudio:** *Seguridad de Historias Clínicas Electrónicas (HCE) y Sistemas de Imagenología: Implementación de Seguridad Perimetral, Hardening y Auditoría de Vulnerabilidades para la Clínica Limatambo (Sede San Isidro).*
- **Objetivo del Repositorio:** Centralizar la infraestructura como código (Docker / VirtualBox / Cisco Packet Tracer), los scripts de auditoría ofensiva/defensiva y la documentación técnica del proyecto final, asegurando **100% de alineación con los laboratorios reales de las Semanas 2 a 12**.

---

## 2. Reglas Estrictas para Agentes de IA y Colaboradores

1. **Alineación 100% con el Sílabo (S2 a S12):**
   - Toda propuesta técnica, comando, diagrama o evidencia **DEBE** corresponder a las herramientas vistas en el curso:
     - **S2:** SGSI (Ciclo PHVA, ISO/IEC 27001 y 27002), Inventario de Activos y Valoración CID, Matriz de Riesgos ($P \times I$), Declaración de Aplicabilidad (SoA), Gestión de Proyectos PMI/PMBOK (Project Charter, EDT/WBS, Cronograma) y Cisco IOS Hardening básico (`enable secret`, `service password-encryption`, `security passwords min-length 10`, `banner motd`, OSPF `passive-interface`).
     - **S3:** Metodologías de Ethical Hacking (**PTES** y **OSSTMM v3 / RAV**), SSH v2 en Cisco IOS (`crypto key generate rsa`, `transport input ssh`), y reconocimiento en Kali Linux (`ip a`, `netdiscover`, `nmap -sV -O`).
     - **S4:** Fingerprinting pasivo/activo, OSINT (`whois`, `nslookup`/`dig`, Google Dorks e IA aplicada a reconocimiento), **AAA Local** en Cisco IOS (`aaa new-model`, `debug aaa authentication`), y análisis web con `whatweb` y `nikto`.
     - **S5:** Escaneo de puertos (`nmap -sS -sV -O -T4`), Banner Grabbing con **Netcat** (`nc -v`), enumeración SMB con **Enum4linux** (`enum4linux -a`), y control de acceso basado en roles en Cisco IOS (**RBAC CLI Views**: `parser view admin1`, `parser view tech`) + marco Cisco NFP (Control, Management y Data Plane).
     - **S7:** Gestión de vulnerabilidades (CVE, CWE, CVSS v3.x, catálogo CISA KEV), Cisco `auto secure`, y explotación controlada con **Metasploit Framework** (`msfconsole`, `exploit/unix/ftp/vsftpd_234_backdoor`) contra **Metasploitable2** (representando el servidor clínico legado HCE/PACS).
     - **S8:** Persistencia, antiforense (MITRE ATT&CK `T1070`), ataque **Man-in-the-Middle (MITM) / ARP Spoofing** con **Ettercap** (`ip neigh`, `arp-scan`, `sysctl net.ipv4.ip_forward=1`, `ettercap`, `tcpdump`) y contramedidas de Capa 2 (Port Security, DHCP Snooping, Dynamic ARP Inspection - DAI).
     - **S9:** Seguridad perimetral en 3 zonas (**WAN, LAN, DMZ**) en Cisco Packet Tracer con **ACL 101 / 102 extendidas** (permitiendo `LAN -> DMZ` HTTP/HTTPS y bloqueando `DMZ -> LAN`).
     - **S11:** Despliegue de firewall perimetral **OPNsense** con 3 interfaces (`WAN`, `LAN`, `DMZ`), servidor **Ubuntu + Nginx** en la DMZ sirviendo el portal web de la **Clínica Limatambo**, reglas de filtrado por mínimo privilegio y auditoría en **Firewall > Log Files > Live View** (eventos `PASS` en verde y `BLOCK` en rojo).
     - **S12:** Publicación mediante **NAT Port Forwarding (DNAT)** desde WAN hacia la DMZ, validación integral de aislamiento entre zonas y monitoreo con **Honeypot (T-Pot CE / Cowrie)** en la DMZ.

2. **Prohibición de Tecnologías Fuera del Curso ("Cero Humo Consultivo"):**
   - **NO** incluir ni proponer herramientas empresariales que no se puedan demostrar en el laboratorio local del curso (prohibido inventar despliegues de Cisco ISE 802.1X, Duo MFA, AWS S3 Object Lock, DLP comercial, túneles GRE multi-sede ficticios o pruebas BOLA en APIs no existentes).

3. **Prohibición Absoluta de Placeholders Vacíos:**
   - Ningún documento o entregable puede contener textos tipo `[Completar...]`, `PEGAR CAPTURA EVxx`, `[N] coincidencias` o `[nombre del .pkt]`. Toda sección de evidencia debe incluir el comando exacto ejecutado, la salida real de consola y el análisis técnico del hallazgo.

---

## 3. Plan de Direccionamiento IP Oficial del Proyecto

Para mantener coherencia total entre **Docker**, **VirtualBox** y el **Informe Final**, todos los scripts y capturas deben respetar el siguiente esquema de red:

| Zona de Seguridad | Red / Máscara | Gateway (Firewall) | Host / Servidor | IP Asignada | Rol en Clínica Limatambo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Zona WAN** | `203.0.113.0/24` *(Docker)* o DHCP *(Bridged)* | `203.0.113.1` | `kali-auditor` | `203.0.113.50` *(o en LAN para pruebas internas)* | Auditor PTES / Atacante Externo (Kali Linux) |
| **Zona DMZ (`RedDMZ`)** | `172.16.10.0/24` | `172.16.10.1` | `portal-clinica-dmz` | `172.16.10.10` | Servidor Ubuntu + Nginx (Portal Web HCE e Imagenología) |
| **Zona DMZ (`RedDMZ`)** | `172.16.10.0/24` | `172.16.10.1` | `honeypot-dmz` | `172.16.10.20` | Sensor Honeypot SSH/Telnet (Cowrie / T-Pot S12) |
| **Zona LAN (`RedLAN`)** | `10.0.0.0/24` | `10.0.0.1` | `cliente-medico-lan` | `10.0.0.10` | Estación Médica de Consulta HCE |
| **Zona LAN (`RedLAN`)** | `10.0.0.0/24` | `10.0.0.1` | `metasploitable-hce` | `10.0.0.20` | Servidor Clínico Legado HCE/PACS (Metasploitable2) |

*(Nota: En la simulación de Cisco Packet Tracer de la Semana 9 se emplean `WAN: 200.100.50.0/24`, `LAN: 192.168.10.0/24` y `DMZ: 172.16.20.0/24` según la guía oficial del laboratorio S9).*

---

## 4. Estructura de Archivos del Proyecto

- `AGENTS.md`: Este archivo de reglas y arquitectura para agentes IA y colaboradores.
- `Proyecto_Final_Pivote/`:
  - `01_Cisco_Hardening_Perimetral_S2_a_S9.ios`: Configuración consolidada de Cisco IOS para Packet Tracer (S2, S3, S4, S5, S7, S9).
  - `02_Deploy_Portal_Clinica_Limatambo_DMZ.sh`: Script de despliegue del portal web de Clínica Limatambo en Ubuntu + Nginx (S11).
  - `03_Kali_Auditoria_Completa_S3_a_S8.sh`: Script automatizado de auditoría en Kali Linux (S3, S4, S5, S7, S8).
  - `04_Guia_Configuracion_OPNsense_S11_S12.md`: Guía paso a paso para OPNsense en VirtualBox (S11, S12).
  - `docker/`:
    - `docker-compose.yml`: Infraestructura completa en contenedores (WAN, LAN, DMZ, Portal Clínica, Metasploitable2, Honeypot, Firewall y Kali) para ejecución ligera y trabajo colaborativo.
    - `portal_html/index.html`: Código fuente del Portal Web HCE e Imagenología de la Clínica Limatambo.

---

## 5. Flujo de Trabajo Colaborativo (Equipo de 2+ Integrantes)

1. **Sincronización por Git:** Antes de trabajar, ejecutar `git pull`. Nunca subir imágenes `.ova` o `.vdi` al repositorio; usar `docker compose up -d` o los scripts `.sh`.
2. **División de Responsabilidades Recomendada:**
   - **Rol A (Auditoría Ofensiva y Vulnerabilidades — S3, S4, S5, S7, S8):** Ejecuta las pruebas desde `kali-auditor` contra `portal-clinica-dmz` (`172.16.10.10`) y `metasploitable-hce` (`10.0.0.20`), recolectando salidas de Nmap, WhatWeb, Nikto, Netcat, Enum4linux, Metasploit y Ettercap.
   - **Rol B (Seguridad Perimetral, Hardening y Gestión — S2, S9, S11, S12):** Ejecuta la topología Cisco en Packet Tracer (`01_Cisco_Hardening_Perimetral_S2_a_S9.ios`), configura OPNsense en VirtualBox (`04_Guia_Configuracion_OPNsense_S11_S12.md`) y documenta la matriz de riesgos y gestión PMI.
