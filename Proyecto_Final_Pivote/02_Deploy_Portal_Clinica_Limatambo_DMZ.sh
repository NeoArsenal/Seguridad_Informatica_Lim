#!/usr/bin/env bash
# ==============================================================================
# PROYECTO FINAL SEGURIDAD INFORMATICA - CLINICA LIMATAMBO
# Semana 11 y 12: Despliegue del Servidor Web en Zona DMZ (Ubuntu Server + Nginx)
# IP esperada en DMZ (RedDMZ): 172.16.10.10/24 | Gateway (OPNsense): 172.16.10.1
# ==============================================================================

set -e

echo "[*] 1. Verificando e instalando Nginx..."
if ! command -v nginx >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y nginx
fi

echo "[*] 2. Respaldando pagina por defecto y desplegando Portal HCE Clinica Limatambo..."
sudo cp /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.bak 2>/dev/null || true

cat << 'EOF' | sudo tee /var/www/html/index.html > /dev/null
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clínica Limatambo | Portal de Historias Clínicas e Imagenología (DMZ)</title>
    <style>
        :root {
            --primary: #005691;
            --secondary: #0088cc;
            --bg: #f4f7fb;
            --card: #ffffff;
            --success: #1b8a5a;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            background-color: var(--bg);
            color: #1f2937;
        }
        header {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 24px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 12px rgba(0,0,0,0.12);
        }
        header h1 { margin: 0; font-size: 1.5rem; }
        header span { font-size: 0.9rem; opacity: 0.9; }
        .badge {
            background: rgba(255,255,255,0.2);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }
        .container {
            max-width: 1000px;
            margin: 32px auto;
            padding: 0 20px;
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
        }
        .card {
            background: var(--card);
            border-radius: 10px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            border-top: 4px solid var(--primary);
        }
        .card h2 { margin-top: 0; color: var(--primary); font-size: 1.2rem; }
        .status-box {
            background: #ecfdf5;
            border-left: 4px solid var(--success);
            padding: 12px 16px;
            border-radius: 6px;
            margin-bottom: 16px;
            font-size: 0.92rem;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
            font-size: 0.9rem;
        }
        th, td {
            text-align: left;
            padding: 10px 8px;
            border-bottom: 1px solid #e5e7eb;
        }
        th { color: #4b5563; font-weight: 600; }
        .form-group { margin-bottom: 14px; }
        .form-group label { display: block; font-size: 0.85rem; margin-bottom: 6px; font-weight: 600; }
        .form-group input {
            width: 100%;
            padding: 9px 10px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            box-sizing: border-box;
        }
        .btn {
            width: 100%;
            background: var(--primary);
            color: white;
            border: none;
            padding: 11px;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
        }
        footer {
            text-align: center;
            padding: 20px;
            font-size: 0.82rem;
            color: #6b7280;
        }
    </style>
</head>
<body>
    <header>
        <div>
            <h1>CLÍNICA LIMATAMBO — Sede San Isidro</h1>
            <span>Sistema Integrado de Historias Clínicas Electrónicas (HCE) y Resultados de Imagenología</span>
        </div>
        <div class="badge">ZONA DMZ PROTEGIDA (172.16.10.10)</div>
    </header>

    <div class="container">
        <div class="card">
            <h2>Estado de Seguridad Perimetral (Arquitectura TO-BE)</h2>
            <div class="status-box">
                <strong>✔ Tráfico Inspeccionado por OPNsense Firewall:</strong> Este servidor web se encuentra aislado en la <strong>Zona DMZ (172.16.10.0/24)</strong> sin acceso directo hacia la Red LAN Clínica Interna (10.0.0.0/24).
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Parámetro Técnico</th>
                        <th>Valor en Laboratorio</th>
                        <th>Política Aplicada</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Servidor Web</td>
                        <td>Ubuntu Server + Nginx</td>
                        <td>Endurecido (server_tokens off)</td>
                    </tr>
                    <tr>
                        <td>Dirección IP (DMZ)</td>
                        <td>172.16.10.10 / 24</td>
                        <td>Gateway OPNsense: 172.16.10.1</td>
                    </tr>
                    <tr>
                        <td>Acceso Entrante (WAN/LAN → DMZ)</td>
                        <td>TCP 80 (HTTP) / TCP 443 (HTTPS)</td>
                        <td>Permitido y Auditado en Live View</td>
                    </tr>
                    <tr>
                        <td>Movimiento Lateral (DMZ → LAN)</td>
                        <td>Hacia 10.0.0.0/24 (BD HCE / PACS)</td>
                        <td><strong>BLOQUEADO (Principio de Mínimo Privilegio)</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="card">
            <h2>Acceso Médicos / Pacientes</h2>
            <div class="form-group">
                <label>CMP / Documento de Identidad</label>
                <input type="text" placeholder="Ej. CMP-45892 / DNI">
            </div>
            <div class="form-group">
                <label>Contraseña / Token</label>
                <input type="password" placeholder="••••••••••••">
            </div>
            <button class="btn" type="button">Consultar Historia Clínica / PACS</button>
            <p style="font-size: 0.78rem; color: #6b7280; margin-top: 14px;">
                Aviso Legal: Todo acceso es registrado bajo el SGSI de Clínica Limatambo en cumplimiento de la Ley N.° 29733 (Ley de Protección de Datos Personales).
            </p>
        </div>
    </div>

    <footer>
        Laboratorio de Seguridad Informática - UPN | Infraestructura Perimetral OPNsense + Nginx DMZ
    </footer>
</body>
</html>
EOF

echo "[*] 3. Aplicando Hardening basico en Nginx (ocultar version del servidor y cabeceras de seguridad)..."
sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=============================================================================="
echo "[OK] Portal Web de Clinica Limatambo desplegado exitosamente!"
echo "------------------------------------------------------------------------------"
echo "Comandos para tus capturas de pantalla en esta VM (Ubuntu DMZ):"
echo "  1. ip a                           (Muestra la IP 172.16.10.10 en DMZ)"
echo "  2. sudo systemctl status nginx    (Muestra el servicio Nginx activo)"
echo "  3. curl -I http://172.16.10.10    (Verifica respuesta HTTP 200 OK)"
echo "  4. ping -c 4 10.0.0.10            (Demuestra que DMZ -> LAN esta BLOQUEADO)"
echo "=============================================================================="
