# ==============================================================================
# PROYECTO FINAL SEGURIDAD INFORMATICA - CLINICA LIMATAMBO (UPN)
# Script Automatizado para Iniciar y Preparar todo el Laboratorio en Docker
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "  LABORATORIO DOCKER MULTI-ZONA - CLINICA LIMATAMBO (SEMANAS 3 A 12)    " -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# 1. Verificar si Docker esta instalado
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Docker Desktop no se encontro en el sistema." -ForegroundColor Yellow
    Write-Host "[*] Instalando Docker Desktop mediante winget..." -ForegroundColor Cyan
    winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
    Write-Host "[!] Una vez instalado, abre 'Docker Desktop' desde el menu Inicio, espera a que el motor este en verde y vuelve a ejecutar este script." -ForegroundColor Green
    exit 0
}

# 2. Ubicarse en la carpeta docker
Set-Location -Path $PSScriptRoot

Write-Host "`n[+] 1. Levantando los 6 contenedores de la arquitectura (WAN, DMZ, LAN)..." -ForegroundColor Cyan
docker compose up -d

Write-Host "`n[+] 2. Verificando estado de los contenedores desplegados..." -ForegroundColor Cyan
docker compose ps

Write-Host "`n[+] 3. Instalando herramientas del silabo (S3-S8) dentro de 'kali-auditor'..." -ForegroundColor Cyan
docker exec -it kali-auditor bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nmap netdiscover whatweb nikto netcat-traditional enum4linux metasploit-framework ettercap-text-only arp-scan tcpdump iproute2 iputils-ping curl dnsutils whois"

Write-Host "`n[+] 4. Abriendo el Portal Web HCE de Clinica Limatambo (DMZ -> localhost:8080)..." -ForegroundColor Green
Start-Process "http://localhost:8080"

Write-Host "`n=========================================================================" -ForegroundColor Green
Write-Host "  INFRAESTRUCTURA LISTA PARA CAPTURAS Y AUDITORIA                        " -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "Comandos rapidos para tus pruebas:"
Write-Host "  - Entrar a Kali Linux:           docker exec -it kali-auditor bash"
Write-Host "  - Correr Auditoria S3 a S8:      docker exec -it kali-auditor bash /workspace/03_Kali_Auditoria_Completa_S3_a_S8.sh"
Write-Host "  - Entrar a Estacion Medica LAN:  docker exec -it cliente-medico-lan bash"
Write-Host "  - Ver Logs del Honeypot (S12):   docker logs -f honeypot-dmz"
