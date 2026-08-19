# DEPLOYMENT.md: ROTASI

## Overview

Dokumen ini memuat strategi deployment, konfigurasi infrastruktur, CI/CD, monitoring, backup, dan prosedur rollback untuk **ROTASI** — backend **Laravel + Inertia + React** (web admin + API sinkronisasi mobile) serta aplikasi **Flutter Android** (produk utama).

Arsitektur deployment dirancang untuk kebutuhan riset (PDP, TKT 2-3): **VPS kecil**, biaya rendah, mudah dikelola oleh tim riset. Aplikasi mobile didistribusikan langsung dari **VPS (URL unduhan) / QR code** — bukan Play Store dan bukan Google Drive (diblokir di lapangan) — sehingga "deployment" mobile berupa build APK + publikasi tautan dari server.

## Strategi Environment

### Tiers Environment

| Environment | Tujuan | Database | Storage | URL Pola |
|:---|:---|:---|:---|:---|
| **Development** | Pengembangan & testing fitur lokal. | MySQL lokal (Sail) | Object storage (MinIO) | `localhost:8000` / `localhost:5173` |
| **Staging** | UAT tim & demo stakeholder. | MySQL staging | Object storage staging | `staging.rotasi-riset.id` |
| **Production** | Deployment riset (uji coba 15 ibu hamil). | MySQL production | Object storage production | `rotasi-riset.id` |

> Nama domain mengikuti ketersediaan; alternatif memakai subdomain dari domain kampus. Seluruh env memakai HTTPS.

### Environment Variables

Buat `.env` per environment. Variabel penting:

```
APP_NAME=ROTASI
APP_ENV=production
APP_DEBUG=false
APP_URL=https://rotasi-riset.id

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rotasi_prod
DB_USERNAME=rotasi
DB_PASSWORD=<secure-password>

SANCTUM_STATEFUL_DOMAINS=rotasi-riset.id
SESSION_DOMAIN=.rotasi-riset.id
SESSION_DRIVER=database

FILESYSTEM_DISK=s3
S3_DRIVER=s3
S3_KEY=<access-key>
S3_SECRET=<secret-key>
S3_REGION=<region>
S3_BUCKET=rotasi-media
S3_URL=https://<object-storage-endpoint>
S3_USE_PATH_STYLE_ENDPOINT=true

# Disk APK: disajikan langsung dari VPS (folder storage/app/public/releases)
APK_DISK=public
CACHE_STORE=file
QUEUE_CONNECTION=database
```

**Catatan keamanan:** jangan pernah meng-commit `.env`. Gunakan template `.env.example` dan kelola rahasia via secrets pada deployment.

## Infrastruktur & Hosting

### Spesifikasi VPS (Rekomendasi: 2GB RAM, 2 vCPU)

- **OS:** Ubuntu 22.04 LTS
- **RAM:** 2 GB (cukup untuk skala riset)
- **vCPU:** 2 core
- **Storage:** 50 GB SSD
- **Bandwidth:** ≥ 1 TB/bulan

### Setup Awal Server

```bash
ssh-keygen -t ed25519 -C "rotasi-deploy"   # tambahkan public key ke authorized_keys server
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential
```

### Instalasi PHP & Dependensi

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php8.3 php8.3-fpm php8.3-mysql php8.3-curl \
  php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-bcmath
```

### Instalasi MySQL 8

```bash
sudo apt install -y mysql-server
sudo mysql_secure_installation
# Buat database & user dengan hak terbatas
sudo mysql -e "CREATE DATABASE rotasi_prod;"
sudo mysql -e "CREATE USER 'rotasi'@'localhost' IDENTIFIED BY '<secure-password>';"
sudo mysql -e "GRANT ALL PRIVILEGES ON rotasi_prod.* TO 'rotasi'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### Instalasi Node, Composer, Nginx

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
sudo apt install -y nginx
sudo systemctl enable nginx
```

### Konfigurasi Nginx

Buat `/etc/nginx/sites-available/rotasi`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name rotasi-riset.id www.rotasi-riset.id;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rotasi-riset.id www.rotasi-riset.id;

    ssl_certificate /etc/letsencrypt/live/rotasi-riset.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rotasi-riset.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/rotasi/public;
    index index.php index.html;

    client_max_body_size 110M;   # izinkan upload APK (100MB)

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # Aset static dari folder publik (media lokal & asset Vite)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Unduhan APK dari VPS: jangan cache lama agar versi baru selalu terambil
    location /storage/releases/ {
        add_header Content-Disposition 'attachment';
        expires -1;
        add_header Cache-Control "no-cache";
        try_files $uri =404;
    }
}
```

Aktifkan site:

```bash
sudo ln -s /etc/nginx/sites-available/rotasi /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

### SSL (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d rotasi-riset.id -d www.rotasi-riset.id
sudo certbot renew --dry-run
```

### Storage File (Media vs APK)

Dua jalur penyimpanan berbeda:

1. **Object storage (S3-compatible)** — PDF booklet (unggahan admin) dan gambar ilustrasi. Laravel memakai disk `s3` (`FILESYSTEM_DISK=s3`). Tidak perlu di-serve oleh Nginx; akses via URL objek storage.

2. **Disk VPS (folder `storage/app/public/releases`)** — file APK. Disajikan langsung oleh Nginx via symlink `public/storage`. Jalur ini menggantikan Google Drive (diblokir di lapangan).

```bash
cd /var/www/rotasi
php artisan storage:link   # symlink public/storage -> storage/app/public (khusus APK)
```

Folder tujuan: `storage/app/public/releases` (file APK) disajikan Nginx; PDF booklet & gambar ilustrasi disimpan ke object storage (disk `s3`) dan diakses via URL objek storage.

## Deployment Aplikasi (Backend + Web Admin)

### Repository

Backend dan mobile dipisah dalam dua repository:

```
github.com/rotasi/rotasi-backend    # Laravel backend + web admin
github.com/rotasi/rotasi-mobile     # Flutter aplikasi Android
```

### Install & Konfigurasi (deploy manual pertama kali)

```bash
cd /var/www
sudo git clone https://github.com/rotasi/rotasi-backend.git
cd rotasi
sudo chown -R www-data:www-data .

composer install --optimize-autoloader --no-dev
npm install && npm run build

php artisan key:generate
php artisan migrate --force --seed
php artisan storage:link

php artisan config:cache && php artisan route:cache && php artisan view:cache
sudo systemctl restart php8.3-fpm nginx
```

File permission:

```bash
sudo chown -R www-data:www-data /var/www/rotasi
sudo chmod -R 755 /var/www/rotasi
sudo chmod -R 775 /var/www/rotasi/storage
sudo chmod -R 775 /var/www/rotasi/bootstrap/cache
```

### Deployment Aplikasi Mobile (Flutter)

**Build via GitHub Actions** (lihat CI/CD) menghasilkan artefak `app-release.apk`. Proses rilis:

1. Admin login web admin → menu **Rilis APK** → unggah file APK (`version_code`, `version_name`, `release_notes`). `download_url` otomatis dibuat dari path VPS (`/storage/releases/<file>`).
2. Aplikasi saat online memanggil `/api/v1/app/latest-release` dan memberi tahu pengguna bila versi baru tersedia.
3. QR code di booklet/posyandu mengarah ke halaman unduhan (URL unduhan dari VPS).

> **Catatan:** karena distribusi di luar Play Store, beri panduan bergambar di booklet "cara mengizinkan install dari sumber tidak dikenal" dan jelaskan risiko warning Android.

## CI/CD Pipeline

### GitHub Actions — Backend (`rotasi-backend/.github/workflows/deploy.yml`)

```yaml
name: Deploy ROTASI Backend

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: rotasi_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: mbstring, xml, gd, bcmath, zip, pdo_mysql
      - run: composer install --no-interaction --prefer-dist
      - run: npm ci && npm run build
      - run: cp .env.testing .env && php artisan key:generate
      - run: php artisan migrate --env=testing && php artisan test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Deploy ke VPS
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /var/www/rotasi
            git pull origin main
            composer install --optimize-autoloader --no-dev
            npm ci && npm run build
            php artisan migrate --force
            php artisan queue:restart
            php artisan config:cache && php artisan route:cache && php artisan view:cache
            sudo systemctl restart php8.3-fpm nginx
```

### GitHub Actions — Mobile (`rotasi-mobile/.github/workflows/build.yml`)

```yaml
name: Build APK ROTASI

on:
  push:
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
```

### Deployment Checklist

- [ ] Semua test lulus (CI backend & mobile).
- [ ] Migrasi reversibel & backup DB dibuat.
- [ ] `.env` produksi benar (APP_ENV, debug=false, DB, session).
- [ ] Aset di-build & storage:link aktif.
- [ ] APK rilis diunggah ke VPS dan `download_url` otomatis aktif di admin.

## Monitoring & Logging

- **Aplikasi:** log di `storage/logs/laravel.log` (rotasi harian); log sinkronisasi tersimpan di tabel `sync_logs` dan tampil di dashboard admin.
- **Server:** `htop`, `df -h`; uptime monitoring gratis (UptimeRobot) untuk `https://rotasi-riset.id`.
- **Error tracking (opsional):** `sentry/sentry-laravel` di staging/production.
- **Analisis riset:** dashboard admin menyediakan statistik data tersinkron (jumlah pasien, jumlah sync) — pengganti kebutuhan Google Analytics.

## Caching

- `CACHE_STORE=file` (opsional Redis bila nanti perlu).
- Cache metadata booklet & pengaturan global, di-invalidasi saat unggah/aktifkan booklet atau pengaturan diubah.
- Konfigurasi caching di-deploy via `php artisan config:cache && route:cache && view:cache`.

## Manajemen Database

### Backup Strategi

```bash
# /usr/local/bin/backup-rotasi.sh
#!/bin/bash
BACKUP_DIR="/backups/rotasi"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u rotasi -p"$DB_PASSWORD" rotasi_prod | gzip > $BACKUP_DIR/rotasi_$DATE.sql.gz
# kirim juga ke penyimpanan kedua (opsional: rsync ke lokasi lain / objek storage)
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
```

```bash
sudo crontab -e
# 0 2 * * * /usr/local/bin/backup-rotasi.sh
```

Salinan file media (`storage/app/public`) di-backup terpisah (rsync ke lokasi cadangan).

### Optimasi DB

- `OPTIMIZE TABLE bp_records, sync_logs` berkala.
- Monitor slow query log MySQL.

## Prosedur Rollback

### Rollback Aplikasi (Backend)

```bash
cd /var/www/rotasi
git log --oneline | head -20          # temukan commit stabil
git checkout <commit-stabil>
composer install --optimize-autoloader --no-dev
php artisan migrate:rollback --step=1  # hanya bila migrasi terakhir bermasalah
php artisan config:cache && php artisan route:cache && php artisan view:cache
sudo systemctl restart php8.3-fpm nginx
```

### Rollback Database

```bash
mysql -u rotasi -p rotasi_prod < /backups/rotasi/rotasi_<tanggal>.sql
```

### Rollback Rilis APK

Web admin: atur versi aktif kembali ke rilis sebelumnya (`PUT /api/admin/apk-releases/{id}/activate`). Aplikasi yang sudah terlanjur mengunduh versi baru memakai versi lama — tidak ada downgrade paksa pada tahap riset.

## Security Hardening

- **HTTPS + HSTS**; `security headers` di Nginx.
- **Password admin:** min 12 karakter + kompleksitas; **rate limit login** 5 percobaan/15 menit.
- **2FA** untuk admin (ditunda ke post-launch, ditandai P2 pada ROADMAP).
- **Ganti jalur admin default** bila perlu: gunakan `ADMIN_PATH` dan obfuscate URL login.
- **Firewall:**
  ```bash
  sudo ufw enable
  sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
  sudo ufw deny 3306/tcp   # MySQL hanya lokal
  sudo apt install -y fail2ban && sudo systemctl enable fail2ban
  ```
- **Upload aman:** validasi tipe/MIME gambar, PDF, & APK; ukuran dibatasi; file di luar `public/` sampai `storage:link`.
- **Kepatuhan UU PDP:** consent dalam aplikasi, minimasi data, endpoint hapus data pasien, log audit (BOOKLET_RELEASE, SYNC_LOG).

## Disaster Recovery

| Skenario | RTO | RPO | Aksi |
|:---|:---|:---|:---|
| Korupsi database | 45 menit | 24 jam | Restore dari backup harian |
| Gagal server | 2 jam | 24 jam | Provision VPS baru, restore DB, redeploy |
| Kehilangan file media | 4 jam | 24 jam | Restore rsync storage |
| Outage total | 4 jam | 24 jam | VPS baru + restore |

**Checklist DR:**
- [ ] Test restore backup bulanan.
- [ ] Dokumentasi kredensial di vault aman.
- [ ] Runbook skenario umum.
- [ ] Dokumen penggunaan backup untuk file media.

## Maintenance & Updates

| Tugas | Frekuensi | Pemilik |
|:---|:---|:---|
| Update keamanan sistem | Saat rilis | DevOps/tim IT |
| Optimasi database | Bulanan | DevOps/tim IT |
| Rotasi log | Mingguan | Otomatis |
| Perpanjangan SSL | Otomatis (60 hari) | Certbot |
| Verifikasi backup | Mingguan | DevOps/tim IT |
| Update dependensi (composer/npm/flutter) | Bulanan + review | Tim IT |

```bash
composer outdated && npm outdated
flutter pub outdated
```

## Runbook Deployment

### Langkah Standar

1. **Pre-deployment:** jalankan test; buat backup (`/usr/local/bin/backup-rotasi.sh`).
2. **Deploy:** `git pull origin main` → `composer install --no-dev` → `npm ci && npm run build` → `php artisan migrate --force` → cache + restart.
3. **Post-deploy:** `curl -sI https://rotasi-riset.id` cek 200; cek `storage/logs/laravel.log`; cek dashboard admin.
4. **Rilis mobile:** build via tag git (`flutter build apk`) → upload ke VPS via admin → `download_url` otomatis aktif.

### Rollback (bila perlu)

Ikuti bagian **Prosedur Rollback** di atas.

## Kontak & Dukungan

- **Pengembang Backend/Admin:** Tim Teknologi Informatika (anggota riset).
- **Klinis/Booklet:** Serli (Ketua), Rasdiana R, Sitti Mawaddah Umar, Nurfaida.
- **Insiden/darurat layanan:** hubungi admin riset; lihat SYNC_LOG dan log server untuk investigasi.