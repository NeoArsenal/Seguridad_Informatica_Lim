# Guía Paso a Paso: Configuración de OPNsense, NAT y Monitoreo (Semanas 11 y 12)

Esta guía reproduce **exactamente** la arquitectura exigida en las **Semanas 11 y 12** del curso, adaptada al caso **Clínica Limatambo**.

---

## 1. Configuración de Adaptadores de Red en VirtualBox

### A. Máquina Virtual: `OPNsense-Clinica-Limatambo`
Configura **3 adaptadores de red** en VirtualBox antes de encenderla:
1. **Adaptador 1 (`em0` - WAN):** Conectado a **Adaptador Puente (Bridged)** o **NAT** (recibe IP por DHCP, ej. `192.168.1.x`).
2. **Adaptador 2 (`em1` - LAN):** Conectado a **Red Interna**, Nombre: `RedLAN` (IP estática: `10.0.0.1/24` o `192.168.10.1/24`).
3. **Adaptador 3 (`em2` - OPT1 / DMZ):** Conectado a **Red Interna**, Nombre: `RedDMZ` (IP estática: `172.16.10.1/24`).

### B. Máquina Virtual: `Ubuntu-Server-Portal-HCE` (En la DMZ)
- **Adaptador 1:** Conectado a **Red Interna**, Nombre: `RedDMZ`.
- **Configuración IP estática:**
  - IP: `172.16.10.10/24`
  - Gateway: `172.16.10.1`
  - DNS: `8.8.8.8`
- Ejecuta el script [`02_Deploy_Portal_Clinica_Limatambo_DMZ.sh`](file:///c:/Users/alons/OneDrive/Escritorio/Seguridad%20Informatica/Proyecto_Final_Pivote/02_Deploy_Portal_Clinica_Limatambo_DMZ.sh) para levantar el portal web de la Clínica Limatambo en Nginx.

### C. Máquina Virtual: `Cliente-Medicos-LAN` (y/o `Metasploitable2`)
- **Adaptador 1:** Conectado a **Red Interna**, Nombre: `RedLAN`.
- **Configuración IP:**
  - Cliente Médico: `10.0.0.10/24` (Gateway: `10.0.0.1`)
  - Servidor Legado (Metasploitable2): `10.0.0.20/24` (Gateway: `10.0.0.1`)

---

## 2. Reglas de Firewall en OPNsense (Semana 11)

Ingresa al panel web de OPNsense desde la VM de la LAN (`https://10.0.0.1`):

### Regla 1: Habilitar y renombrar la interfaz DMZ
1. Ve a **Interfaces > [OPT1]**, marca **Enable Interface**, cámbiale la descripción a `DMZ_CLINICA`, selecciona **Static IPv4** y asigna `172.16.10.1/24`. Guarda y aplica cambios.

### Regla 2: Permitir a la LAN Médica acceder al Portal Web en la DMZ (Con Logging)
1. Ve a **Firewall > Rules > LAN** y haz clic en **Add (+)**.
2. Configura:
   - **Action:** `Pass`
   - **Interface:** `LAN`
   - **Protocol:** `TCP`
   - **Source:** `LAN net`
   - **Destination:** `Single host or Network` -> `172.16.10.10/32`
   - **Destination port range:** `HTTP (80)` (y opcionalmente `HTTPS (443)`)
   - **Log:** Marca **`Log packets that are handled by this rule`** (Fundamental para la evidencia de Live View).
   - **Description:** `PERMITIR_LAN_A_PORTAL_HCE_DMZ`

### Regla 3: Bloquear estrictamente cualquier tráfico de DMZ hacia LAN (Aislamiento de Zona)
1. Ve a **Firewall > Rules > DMZ_CLINICA** y haz clic en **Add (+)**.
2. Configura:
   - **Action:** `Block` (o `Reject`)
   - **Interface:** `DMZ_CLINICA`
   - **Protocol:** `any`
   - **Source:** `DMZ_CLINICA net`
   - **Destination:** `LAN net`
   - **Log:** Marca **`Log packets that are handled by this rule`**
   - **Description:** `BLOQUEAR_MOVIMIENTO_LATERAL_DMZ_HACIA_LAN`
3. Guarda y haz clic en **Apply changes**.

---

## 3. Regla de NAT Port Forwarding desde WAN (Semana 12)

Para permitir que pacientes o médicos externos (o Kali Linux en la WAN) consulten el Portal Web sin exponer la red interna:
1. Ve a **Firewall > NAT > Port Forward** y haz clic en **Add (+)**.
2. Configura:
   - **Interface:** `WAN`
   - **TCP/IP Version:** `IPv4`
   - **Protocol:** `TCP`
   - **Destination:** `WAN address`
   - **Destination port range:** `HTTP (80)`
   - **Redirect target IP:** `172.16.10.10`
   - **Redirect target port:** `HTTP (80)`
   - **Log:** Marca **`Log packets that are handled by this rule`**
   - **Description:** `DNAT_PUBLICACION_PORTAL_HCE_DMZ`
   - **Filter rule association:** `Add associated filter rule`
3. Nota: En **Interfaces > WAN**, asegúrate de desmarcar *Block private networks* si tu WAN de laboratorio usa direcciones privadas (`192.168.x.x` o `10.x.x.x`).

---

## 4. Lista Exacta de Capturas (Evidencias Reales S11 y S12)

1. **Captura 1 (Consola OPNsense):** Pantalla negra de consola de OPNsense mostrando las 3 interfaces (`WAN`, `LAN 10.0.0.1/24`, `DMZ 172.16.10.1/24`).
2. **Captura 2 (Portal Web Clínica Limatambo):** Navegador desde el Cliente LAN (o desde WAN vía DNAT) abriendo `http://172.16.10.10` donde se ve el portal azul de **Clínica Limatambo — Sede San Isidro**.
3. **Captura 3 (Prueba de Aislamiento DMZ → LAN):** Terminal del Ubuntu Server en la DMZ (`172.16.10.10`) ejecutando `ping 10.0.0.10` y `nmap -p 21,22,80 10.0.0.20` mostrando **100% packet loss / bloqueado**.
4. **Captura 4 (Evidencia Reina - OPNsense Live View):** Ve a **Firewall > Log Files > Live View**:
   - Filtra o muestra en pantalla las líneas en **VERDE (`pass`)** hacia `172.16.10.10:80` (`PERMITIR_LAN_A_PORTAL_HCE_DMZ`).
   - Muestra inmediatamente debajo las líneas en **ROJO (`block`)** desde `172.16.10.10` hacia `10.0.0.10` / `10.0.0.20` (`BLOQUEAR_MOVIMIENTO_LATERAL_DMZ_HACIA_LAN`).
