# Self-Hosting Downhill Revived Online Server on Linux VPS

Panduan deployment standalone online server untuk Downhill Revived pada VPS Linux (Ubuntu 22.04 / 24.04).

## Struktur File
- `install.sh`: Script instalasi otomatis (Node 22 LTS, dependensi, unit tests, Nginx, systemd service, firewall).
- `downhill-server.service`: Unit systemd agar server berjalan di latar belakang (*daemon*) dan otomatis mulai ulang saat VPS boot.
- `nginx-downhill.conf`: Konfigurasi Nginx reverse proxy dengan dukungan WebSocket Upgrade (`ws://`) dan timeout panjang untuk balapan online.

## Cara Instalasi Cepat
1. Salin folder repositori atau folder `online/server` ke VPS Anda (misalnya di `/tmp/server`).
2. Jalankan script installer sebagai `root`:
   ```bash
   sudo bash install.sh
   ```
3. Cek apakah server sudah aktif:
   ```bash
   curl http://127.0.0.1/v1/health
   curl http://127.0.0.1/v1/lobbies
   ```

## Menghubungkan Game Client
Pada file `dhd.ini` di sisi pemain:
```ini
server = ws://IP_VPS_ANDA
```
(atau `server = ws://IP_VPS_ANDA:8787`)
