# USERFLOW.md: ROTASI

## Overview

Dokumen ini merinci alur pengguna utama ROTASI — sistem pemantauan mandiri tekanan darah ibu hamil pesisir. Alur dikelompokkan per aktor: **Ibu Hamil/Pendamping** (aplikasi Android offline-first) dan **Administrator** (web admin Laravel + Inertia + React). Setiap alur bersumber dari Functional Requirements di PRD.md dan difasilitasi backend API (`/api/v1/*` untuk mobile, `/api/admin/*` untuk web).

---

## Flow 1: Ibu Hamil – Instalasi & Registrasi Biodata

### Trigger
Ibu/pendamping memindai QR code (booklet/posyandu) atau menerima link unduhan aplikasi ROTASI.

### Pre-conditions
- Smartphone Android tersedia; QR dapat dipindai atau tautan dapat dibuka.
- Aplikasi belum terpasang / profil belum diisi.
- (Untuk uji coba) perangkat telah disetujui tim riset.

### Post-conditions
- Aplikasi terpasang dan dibuka pertama kali.
- Profil ibu tersimpan lokal (SQLite) dengan `patient_uuid`; skrining risiko ditampilkan.
- Token device terdaftar ke server bila online (opsional).
- Pendamping (suami/kader) dapat mengisi data atas nama ibu melalui mode pendamping (FR-15).

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Memindai QR / membuka link unduhan | Browser membuka halaman unduhan di VPS; user menekan "Unduh" APK | Link tidak valid → kontak kader/puskesmas |
| 2 | Ibu/Pendamping | Mengizinkan "instal dari sumber tidak dikenal" sesuai panduan | Android menginstal APK | Warning keamanan → panduan bergambar menjelaskan |
| 3 | Ibu/Pendamping | Membuka aplikasi ROTASI | Aplikasi menampilkan sambutan & form biodata (FR-01) | — |
| 3b | Ibu/Pendamping | (Bila diisi pendamping) mengaktifkan Mode Pendamping | Aplikasi menandai sesi sebagai pendamping; nama ibu aktif selalu tampil (FR-15) | — |
| 4 | Ibu/Pendamping | Mengisi biodata: nama, usia, TB, BB, HPL/usia kehamilan, tensi terakhir, riwayat hipertensi | Aplikasi memvalidasi (usia 12–55, tensi 50–180, dll.) | Field tidak valid → pesan error ramah |
| 5 | Ibu/Pendamping | Menekan "Simpan" | Profil tersimpan ke SQLite; `patient_uuid` dibuat | Gagal simpan → pesan dan ulangi |
| 6 | Ibu/Pendamping | (Online) melanjutkan | Aplikasi mendaftarkan perangkat ke `POST /api/v1/device/register` dan mengirim profil ke `PUT /api/v1/patient` | Offline → profil tetap tersimpan; sinkron ditunda |

---

## Flow 2: Ibu Hamil – Skrining Risiko Otomatis

### Trigger
Registrasi biodata selesai (Flow 1).

### Pre-conditions
- Biodata lengkap tersimpan lokal.

### Post-conditions
- Kategori risiko (rendah/sedang/tinggi) ditampilkan dalam bahasa sederhana + ikon.
- Rekomendasi "disarankan konsultasi bidan" muncul bila risiko sedang/tinggi.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Sistem | Menghitung risiko dari biodata (usia, IMT, riwayat, HPL) | Engine menghitung kategori sesuai NICE/KIA (FR-02), tanpa input tambahan | Data tidak lengkap → risiko dihitung sebagian + catatan |
| 2 | Sistem | Menampilkan hasil | Layar menampilkan: ikon + warna kategori + penjelasan sederhana | — |
| 3 | Ibu/Pendamping | (Bila sedang/tinggi) membaca saran | Aplikasi menampilkan saran konsultasi bidan (bukan diagnosis) | — |
| 4 | Sistem | Menyimpan `risk_level` | Nilai risiko disimpan di profil lokal & tersinkron | — |

---

## Flow 3: Ibu Hamil – Sesi Pengukuran Tekanan Darah

### Trigger
Ibu menekan tombol "Ukur Tensi" di beranda (pagi atau sore).

### Pre-conditions
- Profil tersimpan.
- Tensiimeter digital terpasang sesuai panduan (manset lengan atas sejajar jantung).

### Post-conditions
- 2 pengukuran terekam + rata-rata dihitung.
- Status warna ROTASI (Hijau/Kuning/Oranye/Merah) ditampilkan.
- Record tersimpan lokal dengan `sync_status=pending`.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Menekan "Ukur Tensi" | Menampilkan panduan posisi HBPM & tombol mulai (FR-03) | — |
| 2 | Ibu/Pendamping | Input pengukuran 1 (SYS/DIA) | Validasi rentang 50–180 mmHg | Di luar rentang → konfirmasi ulang |
| 3 | Sistem | Menjalankan timer jeda 1–2 menit | Layar menunggu; tombol input 2 terkunci hingga jeda selesai | — |
| 4 | Ibu/Pendamping | Input pengukuran 2 (SYS/DIA) | Validasi; bila beda > 10 mmHg dari ukur-1 → saran ukur ulang | Pengguna membatalkan → sesi dibatalkan |
| 5 | Sistem | Menghitung rata-rata & status | Engine menghitung rata-rata + warna (FR-04, aturan terburuk) | — |
| 6 | Sistem | Menampilkan hasil | Roda visual + label teks + ikon status; saran sesuai status (FR-10) | — |
| 7 | Sistem | Menyimpan record | Record (uuid, sync_status=pending) ke SQLite (FR-13) | — |
| 8 | Ibu/Pendamping | (Opsional) mencocokkan roda fisik | Roda fisik menunjukkan warna sama | Bedanya indikasi alat → ulangi pengukuran |
| 9 | Ibu/Pendamping | (Opsional) membuka "Grafik Tren" | Aplikasi merender grafik pagi/sore dari data lokal dengan ambang warna (FR-05) | — |

---

## Flow 4: Ibu Hamil – Ceklis Gejala, Gerakan Janin & Ceklis 10T

### Trigger
Ibu menyelesaikan sesi tensi atau membuka menu "Ceklis Harian".

### Pre-conditions
- Aplikasi terbuka; profil aktif.

### Post-conditions
- Ceklis gejala harian (4 item) tersimpan.
- Hasil hitung gerakan janin (aktif/kurang aktif) tersimpan.
- Ceklis kunjungan ANC 10T diperbarui (bila dibuka setelah kunjungan faskes).

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Membuka "Ceklis Harian" | Menampilkan 4 gejala: sakit kepala hebat, pandangan kabur, nyeri ulu hati, sesak napas (FR-06) | — |
| 2 | Ibu/Pendamping | Mencentang gejala yang ada | Aplikasi menandai item (✓/✗) | — |
| 3 | Sistem | Bila ada gejala tercentang | Menampilkan pengingat panduan rujukan (FR-10) — bukan diagnosa | — |
| 4 | Ibu/Pendamping | Menekan "Mulai Hitung Gerakan Janin" | Timer 30 menit dimulai; tombol "Gerakan!" untuk menghitung (FR-07) | — |
| 5 | Ibu/Pendamping | Mengetuk setiap gerakan yang terasa | Hitungan bertambah; sisa waktu tampil | Timer habis → hitungan disimpan otomatis |
| 6 | Sistem | Menyimpulkan | Status aktif (≥3/30 menit) atau kurang aktif; disimpan ke lokal | Kurang aktif → saran hubungi bidan |
| 7 | Ibu/Pendamping | (Setelah kunjungan faskes) membuka "Ceklis 10T" | Menampilkan daftar periksa 10 item ANC (FR-08) | — |
| 8 | Ibu/Pendamping | Menandai item yang dilakukan saat kunjungan | Setiap item berstatus ✓/✗; tanggal kunjungan dicatat | — |
| 9 | Sistem | Menyimpan semua record | Gejala, gerakan janin, dan 10T tersimpan dengan `sync_status=pending` (FR-13) | — |

---

## Flow 5: Ibu Hamil – Panduan Rujukan & Hubungi Bidan

### Trigger
Status tensi oranye/merah, gejala tercentang, gerakan janin kurang, atau ibu memilih menu "Bantuan/Rujukan".

### Pre-conditions
- Pengaturan global (nomor darurat ambulance, puskesmas) tersedia di cache lokal (diunduh saat online).
- Daftar bidan aktif tersimpan di cache lokal (`GET /api/v1/midwives`, diunduh saat online).

### Post-conditions
- Ibu mendapat panduan kapan harus ke faskes.
- WhatsApp terbuka ke bidan terpilih dengan pesan ringkasan status (bila tombol ditekan).

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Membuka menu "Rujukan & Kontak" | Menampilkan kriteria rujukan + nomor darurat (FR-10) | Kontak belum di-cache → tampil kontak default |
| 2 | Ibu/Pendamping | Menekan "Hubungi Bidan" | Menampilkan daftar bidan aktif (nama, jabatan, jam bertugas) dari cache (FR-11, FR-22) | Daftar kosong → saran kontak puskesmas/ambulance |
| 3 | Ibu/Pendamping | Memilih bidan | Membuka `whatsapp://send?phone=<phone>` ke bidan terpilih dengan pesan ringkasan (FR-11) | WhatsApp tidak terpasang → instruksi menghubungi via telepon |
| 4 | Ibu/Pendamping | Menekan nomor ambulance | Membuka panggilan ke nomor darurat | — |
| 5 | Sistem | (Online) memeriksa pembaruan | Menyegarkan cache pengaturan (`GET /api/v1/settings`) dan daftar bidan (`GET /api/v1/midwives`) | Offline → memakai cache tersimpan |

---

## Flow 6: Ibu Hamil – Membaca Pustaka Edukasi (Booklet PDF) Offline

### Trigger
Ibu membuka menu "Edukasi" pada aplikasi.

### Pre-conditions
- Booklet PDF tersedia di cache lokal (bundle awal saat instalasi atau hasil unduhan).

### Post-conditions
- Ibu membaca booklet tanpa membutuhkan jaringan.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Membuka "Edukasi" | Menampilkan booklet PDF aktif (FR-09) | — |
| 2 | Ibu/Pendamping | Membuka booklet | Menampilkan PDF dari `booklet_cache` (offline penuh) | PDF belum terunduh → pesan "unduh saat online" + opsi unduh |
| 3 | Sistem | (Online) memeriksa versi booklet | Memanggil `GET /api/v1/booklet` dan mengunduh PDF bila versi berubah | Offline → memakai versi tersimpan |

---

## Flow 7: Ibu Hamil – Latihan Napas Lambat (Slow Breathing)

### Trigger
Ibu membuka menu "Latihan Napas" (mis. saat merasa cemas/stres).

### Pre-conditions
- Aplikasi terbuka; fitur tersedia offline.

### Post-conditions
- Sesi latihan selesai; tidak ada data tersimpan (aktivitas sesaat).

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Ibu/Pendamping | Membuka "Latihan Napas" | Menampilkan pola 4-2-6 + tombol mulai (FR-12) | — |
| 2 | Ibu/Pendamping | Menekan "Mulai" | Timer 15 menit berjalan; panduan visual tarik 4s / tahan 2s / buang 6s | Pengguna berhenti → sesi diakhiri |
| 3 | Sistem | Menyelesaikan sesi | Menampilkan ringkasan & ajakan mengulang | — |

---

## Flow 8: Ibu Hamil – Sinkronisasi Data Saat Online

### Trigger
Koneksi internet tersedia (aplikasi mendeteksi otomatis) atau ibu menekan "Sinkronkan".

### Pre-conditions
- Ada record lokal dengan `sync_status=pending` atau `failed`.
- Token device valid (jika kedaluwarsa, aplikasi mendaftar ulang).

### Post-conditions
- Record terkirim ke server (idempoten); `sync_status=synced`.
- Booklet & pengaturan diperbarui; info rilis terbaru diperiksa.
- Pengingat lokal pagi/sore (FR-14) tetap berjalan terlepas dari status sinkronisasi.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Sistem | Mendeteksi koneksi | Menandai status "Sinkron..." di beranda | Tanpa koneksi → status "Menunggu", tidak ada aksi |
| 2 | Sistem | Mengirim batch | `POST /api/v1/sync` dengan seluruh record pending (FR-13) | Gagal → record dipertahankan; retry dengan backoff |
| 3 | Server | Memvalidasi & menyimpan | Menyimpan idempoten (dicek by uuid); mengembalikan daftar uuid diterima | Duplikat → dilewati, tidak dihitung ganda |
| 4 | Sistem | Menandai sukses | `sync_status=synced` untuk uuid yang diterima | Sebagian gagal → hanya sukses yang ditandai |
| 5 | Sistem | Memperbarui booklet & pengaturan | Menarik booklet aktif, pengaturan, dan info rilis (`/api/v1/booklet`, `/settings`, `/app/latest-release`) | — |
| 6 | Sistem | Memberi tahu rilis baru | Notifikasi "Versi baru tersedia" bila ada (FR-19) | — |

---

## Flow 9: Administrator – Login Web Admin

### Trigger
Administrator membuka URL web admin ROTASI.

### Pre-conditions
- Akun admin aktif di database.
- URL login diakses via HTTPS.

### Post-conditions
- Administrator terautentikasi; sesi terbentuk; dialihkan ke dashboard.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Administrator | Membuka URL admin | Inertia merender halaman login (React) | URL salah → 404 |
| 2 | Administrator | Mengisi email & password | Validasi client-side | Field kosong → error |
| 3 | Administrator | Menekan "Masuk" | `POST /api/admin/login` (FR-16) | 5 kali gagal → rate limit 15 menit |
| 4 | Server | Memvalidasi kredensial | Hash bcrypt dibandingkan; sesi dibuat | Kredensial salah → 401 "Kredensial tidak valid" |
| 5 | Server | Mengalihkan | Redirect ke dashboard (FR-17) | — |

---

## Flow 10: Administrator – Unggah Booklet PDF & Tetapkan Aktif

### Trigger
Administrator ingin memperbarui pustaka edukasi aplikasi dengan versi booklet terbaru.

### Pre-conditions
- Administrator login.
- File PDF booklet sudah disiapkan tim klinis (dari desain booklet).

### Post-conditions
- Booklet tersimpan sebagai riwayat; satu versi aktif; aplikasi mengunduh versi aktif saat online.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Administrator | Membuka "Booklet" | Daftar riwayat booklet (versi, status aktif) dengan paginasi (FR-18) | — |
| 2 | Administrator | Menekan "Unggah Booklet" | Form: judul + file PDF | Bukan PDF / > 50MB → ditolak |
| 3 | Administrator | Mengunggah | `POST /api/admin/booklet-releases`; file disimpan ke object storage; `version` +1 | Validasi gagal → 422 |
| 4 | Administrator | Menetapkan aktif | `PUT /api/admin/booklet-releases/{id}/activate`; hanya satu aktif | Versi aktif tidak dapat dihapus → pesan |
| 5 | Aplikasi (online) | Menarik booklet baru | `GET /api/v1/booklet` mengunduh PDF versi aktif; versi lama tetap terbaca offline | — |

---

## Flow 11: Administrator – Rilis Versi APK

### Trigger
Ada APK baru hasil build Flutter (via tag git / GitHub Actions).

### Pre-conditions
- Administrator login.
- APK sudah di-build dan siap diunggah ke VPS.

### Post-conditions
- Rilis APK tersimpan; satu versi aktif; aplikasi memberi tahu pengguna saat online.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Administrator | Membuka "Rilis APK" | Daftar rilis (FR-19) | — |
| 2 | Administrator | Menekan "Unggah Rilis" | Form: file APK, version_code, version_name, release_notes; `download_url` otomatis dari VPS | Ukuran > 100MB → ditolak |
| 3 | Server | Menyimpan rilis | `POST /api/admin/apk-releases`; file tersimpan di `releases/` | version_code tidak unik → 422 |
| 4 | Administrator | Menetapkan aktif | `PUT /api/admin/apk-releases/{id}/activate`; hanya satu aktif | Rilis aktif tidak dapat dihapus → pesan |
| 5 | Aplikasi (online) | Memeriksa versi | `GET /api/v1/app/latest-release`; notifikasi "Versi baru" | — |

---

## Flow 12: Administrator – Pantau Data Tersinkron & Log Sinkronisasi

### Trigger
Administrator ingin mengevaluasi data sinkronisasi riset.

### Pre-conditions
- Administrator login.
- Pasien telah tersinkron & pengaturan global lengkap.

### Post-conditions
- Data pasien tersinkron & log sinkronisasi terlihat untuk evaluasi.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Administrator | Membuka menu "Pengaturan Global" | Form nomor darurat, puskesmas, pesan WA bawaan (FR-20) | — |
| 2 | Administrator | Membuka "Data Riset" | Daftar pasien tersinkron + log sinkronisasi (FR-21) | — |
| 3 | Administrator | Membuka detail pasien | Riwayat tensi, gejala, gerakan janin, log sync | Data sensitif → hanya tampil untuk admin |
| 4 | Administrator | (Opsional) meminta penghapusan data | Endpoint hapus data pasien sesuai UU PDP | — |

---

## Flow 13: Administrator – CRUD Data Bidan

### Trigger
Administrator menambah/mengubah/menonaktifkan bidan kontak untuk aplikasi.

### Pre-conditions
- Administrator login.
- Data bidan (nama, no WA, jadwal) diperoleh dari bidan koordinator/Puskesmas.

### Post-conditions
- Data bidan tersimpan; daftar bidan aktif otomatis diperbarui di aplikasi pada sinkronisasi berikutnya.

### Flow Table

| No | Aktor | Aksi/Langkah | Respons Sistem | Jalur Alternatif/Error |
|:---|:---|:---|:---|:---|
| 1 | Administrator | Membuka menu "Bidan" | Daftar bidan (FR-22) via `GET /api/admin/midwives` | — |
| 2 | Administrator | Menekan "Tambah Bidan" | Form: nama, jabatan, puskesmas, no WA, telepon alternatif, jam bertugas, urutan, aktif, catatan | — |
| 3 | Administrator | Mengisi & menyimpan | `POST /api/admin/midwives`; validasi no WA format internasional | No WA tidak valid → 422 |
| 4 | Administrator | Mengubah data bidan | `PUT /api/admin/midwives/{id}` | — |
| 5 | Administrator | Menonaktifkan/mengaktifkan bidan | Status aktif diubah; bidan non-aktif tidak tampil di aplikasi | — |
| 6 | Administrator | Menghapus bidan | `DELETE /api/admin/midwives/{id}` | Bidan pernah dirujuk → konfirmasi/soft-delete |
| 7 | Aplikasi (online) | Menyegarkan daftar | `GET /api/v1/midwives` → cache lokal terbaru | Offline → cache lama tetap dipakai |

---

## Summary of Key User Flows

### Alur Ibu Hamil / Pendamping (Aplikasi Mobile)
- **Onboarding:** Instalasi via QR/unduhan VPS → registrasi biodata → skrining risiko otomatis (Flow 1–2).
- **Pemantauan harian:** Sesi tensi 2x + status warna → ceklis gejala → gerakan janin (Flow 3–4).
- **Tindak lanjut:** Panduan rujukan, hubungi bidan via WhatsApp, edukasi offline, latihan napas (Flow 5–7).
- **Konektivitas:** Sinkronisasi idempoten saat online; booklet & pengaturan diperbarui (Flow 8).

### Alur Administrator (Web Admin)
- **Akses:** Login aman (Flow 9).
- **Booklet:** Unggah PDF + riwayat versi + tetapkan aktif (Flow 10).
- **Distribusi:** Rilis APK + set versi aktif (Flow 11).
- **Kontak:** CRUD data bidan (Flow 13).
- **Evaluasi:** Pantau data pasien & log sinkronisasi (Flow 12).

Seluruh alur memanfaatkan prinsip **offline-first** di sisi mobile (fitur inti tanpa jaringan), sinkronisasi **idempoten** saat online, dan booklet terpusat di web admin sehingga aplikasi, roda fisik, dan booklet selalu sejalan (single source of truth).