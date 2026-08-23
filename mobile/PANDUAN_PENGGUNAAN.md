# Panduan Penggunaan Aplikasi ROTASI (Mobile)

Aplikasi ROTASI adalah pendamping ibu hamil untuk memantau tekanan darah dan
kesehatan kehamilan secara mandiri. Semua data penting tersimpan di perangkat
(offline-first) dan otomatis tersinkron ke server saat internet tersedia.

> Aplikasi ini adalah **alat pendamping**, bukan pengganti pemeriksaan
> kehamilan (ANC). Segera ke fasilitas kesehatan bila ada keluhan atau hasil
> yang mencurigakan.

---

## 1. Memulai Aplikasi (Pertama Kali)

Saat aplikasi pertama kali dibuka, Anda akan diarahkan ke halaman **Registrasi
Biodata**:

1. Isi **Nama ibu** (wajib).
2. Isi **Usia** (12–55 tahun) dan **Usia kehamilan** dalam minggu (opsional).
3. Isi **Tinggi badan** (100–250 cm) dan **Berat badan** (30–200 kg).
4. Tekanan darah terakhir (opsional): **Sistolik (atas)** dan **Diastolik
   (bawah)**.
5. Pilih **Riwayat hipertensi**: Tidak ada / Hipertensi / Pernah
   preeklamsia / Riwayat turunan.
6. Masukkan **Nomor WhatsApp** (opsional).
7. Tekan **Simpan dan Mulai**.

Setelah tersimpan, Anda masuk ke halaman Beranda. Jika aplikasi terbuka lagi,
Anda langsung menuju Beranda tanpa perlu mengisi ulang. Profil bisa diubah
kapan saja lewat **Lainnya → Data Ibu**.

---

## 2. Navigasi Utama

Di bagian bawah layar ada 5 menu utama:

| Tab | Fungsi |
|-----|--------|
| **Beranda** | Status tekanan darah terakhir + tombol ukur & sinkron |
| **Ukur Tensi** | Melakukan sesi pengukuran tekanan darah |
| **Tren** | Grafik perkembangan tekanan darah harian |
| **Pantau** | Cek gejala, gerakan janin, dan ceklis ANC |
| **Edukasi** | Pustaka materi kesehatan (PDF offline) |

Di kanan atas halaman Beranda ada ikon **menu (⋮)** untuk membuka **Lainnya**
berisi fitur sekunder (lihat bagian 7).

---

## 3. Beranda (Status Hari Ini)

Beranda menampilkan:

- **Sapaan** dengan nama Anda (font kaligrafi).
- **Roda Status** — lingkaran berwarna yang menunjukkan kategori tekanan darah
  terakhir.
- Nilai **Terakhir: sistolik/diastolik** dan sesi (Pagi/Sore).
- Penjelasan status yang sedang aktif.
- Tombol **Ukur Tensi** untuk memulai pengukuran baru.
- Tombol **Sinkron** untuk mengirim data tertunda ke server secara manual.

### Arti warna roda status

| Warna | Label | Ambang (AHA 2025) |
|-------|-------|-------------------|
| Hijau | Normal | Sistolik < 120 dan Diastolik < 80 |
| Kuning | Waspada | Sistolik 120–129 dan Diastolik < 80 |
| Oranye | Berisiko | Sistolik 130–139 **atau** Diastolik 80–89 |
| Merah | Bahaya | Sistolik ≥ 140 **atau** Diastolik ≥ 90 |

Kategori diambil dari nilai terburuk antara sistolik dan diastolik.

---

## 4. Mengukur Tekanan Darah

Melalui **Ukur Tensi**:

1. Pilih **Sesi** (Pagi atau Sore) di bagian atas.
2. Isi **Pengukuran 1**: duduk rileks **5 menit** sebelum mengukur, lalu
   masukkan nilai Sistolik dan Diastolik. Tekan **Simpan Pengukuran 1**.
3. Aplikasi menampilkan hitung mundur **istirahat 60 detik** sebelum
   pengukuran kedua.
4. Setelah hitung mundur selesai, isi **Pengukuran 2** dan tekan
   **Simpan Pengukuran 2**.

Nilai yang diterima: Sistolik 50–180, Diastolik 30–120. Di luar rentang itu
akan diminta diperiksa kembali.

### Halaman Hasil Pengukuran

Setelah pengukuran kedua, muncul halaman **Hasil Pengukuran** berisi:

- Roda status (ukuran besar) untuk hasil **rata-rata** dari 2 pengukuran.
- Nilai rata-rata, sesi, dan kategori status.
- Penjelasan status dan **panduan tindakan** sesuai kategori:
  - **Normal**: pertahankan pola hidup sehat.
  - **Waspada**: terus pantau, kurangi garam, kelola stres.
  - **Berisiko**: periksa ulang rutin dan sampaikan ke bidan.
  - **Bahaya**: segera hubungi faskes/layanan darurat.
- Rincian Pengukuran 1 dan 2.
- Tombol **Simpan Hasil** — hasil tersimpan di perangkat dan disinkronkan
  otomatis bila ada internet.

---

## 5. Tren Tekanan Darah

Menu **Tren** menampilkan perkembangan tekanan darah dari data tersimpan:

- **Ringkasan**: nilai terakhir, kategori status, dan arah perubahan (Naik/
  Turun/Sama) dibanding hari sebelumnya.
- **Rentang**: menampilkan 28 hari terakhir otomatis (tanpa filter).
- **Distribusi Status**: jumlah hari per kategori (Normal, Waspada, Berisiko,
  Bahaya).
- **Grafik Sistolik** dan **Grafik Diastolik**: garis harian dengan latar
  berwarna sesuai ambang (hijau = normal, dst).
- **Interpretasi otomatis**: ringkasan kecenderungan (naik/turun/stabil) dan
  peringatan bila ada hari dengan kategori Bahaya.

Grafik dapat ditunjukkan ke bidan saat kontrol. Tarik layar ke bawah untuk
memuat ulang.

---

## 6. Tab Pantau

Menu **Pantau** berisi empat alat pemantauan harian:

### a. Cek Gejala Harian
Centang gejala yang Anda rasakan hari ini: **sakit kepala**, **pandangan
kabur**, **nyeri ulu hati**, dan **sesak napas**. Bila ada satu saja, muncul
peringatan untuk segera menghubungi bidan/faskes. Tekan **Simpan Ceklis**.

### b. Hitung Gerakan Janin
1. Tekan **Mulai Hitung** — pengamatan berjalan **30 menit**.
2. Setiap kali bayi bergerak, **ketuk tombol besar** "Ketuk saat bayi
   bergerak".
3. Bila minimal **3 gerakan** dalam 30 menit, bayi dianggap **aktif**; kurang
   dari itu disarankan coba lagi nanti dan hubungi bidan bila tetap kurang
   aktif.
4. Tekan **Simpan Hasil**.

### c. Ceklis 10T ANC
Tandai pemeriksaan standar 10 T (T1–T10) yang sudah dilakukan pada tanggal
kunjungan tertentu (tanggal bisa diubah). Bar progres menunjukkan jumlah yang
sudah ditandai. Tekan **Simpan Ceklis** setelah selesai.

### d. Panduan Pemeriksaan
Informasi singkat standar ANC: pemeriksaan minimal **6 kali** selama
kehamilan, standar **10 T**, pemeriksaan laboratorium (golongan darah,
hemoglobin, gula darah, urine, skrining penyakit menular), dan **USG**
(trimester 1 dan sekitar 32–36 minggu).

---

## 7. Tab Edukasi (Pustaka)

Menu **Edukasi** menampilkan booklet/materi kesehatan dari server:

- Materi mencakup preeklamsia & stunting, nutrisi DASH, 1000 Hari Pertama
  Kehidupan (HPK), manajemen stres, dan pascapersalinan.
- **Unduh PDF** untuk membaca tanpa internet (ditandai "Tersedia offline").
- Ikon refresh untuk **Periksa Pembaruan** bila ada versi baru.
- **Buka PDF** untuk membaca booklet yang sudah diunduh.

---

## 8. Menu Lainnya (⋮)

Dibuka dari ikon menu di kanan atas Beranda. Berisi:

### Data & Profil
- **Data Ibu** — ubah profil dan riwayat hipertensi.

### Kesehatan & Kebiasaan
- **Latihan Napas** — latihan napas lambat **4-2-6** (tarik 4 detik, tahan
  2 detik, buang 6 detik) dengan durasi 5/10/15 menit dan lingkaran visual
  yang mengembang/mengempis. Berjalan penuh tanpa internet.
- **Pengingat** — aktifkan notifikasi pengingat ukur tensi **pagi & sore**
  (berjalan lokal tanpa koneksi). Waktu pagi/sore bisa diubah.

### Bantuan & Kontak
- **Rujukan & Darurat** — panduan kapan harus segera ke faskes: tekanan darah
  tinggi (merah/oranye) berulang, ada tanda bahaya pada cek gejala, atau
  gerakan janin kurang aktif (≤ 3 gerakan/30 menit). Dilengkapi tombol
  **Panggil** ke nomor darurat/ambulans bila diatur pengelola.
- **Hubungi Bidan** — daftar bidan aktif; tombol **Chat** membuka WhatsApp
  dengan pesan ringkas berisi nama Anda dan ringkasan status tekanan darah
  terakhir. (Bisa diakses juga lewat tombol hijau mengambang.)

---

## 9. Tombol Mengambang "Hubungi Bidan"

Logo WhatsApp hijau **mengambang di pojok kanan bawah**, di atas menu
navigasi, muncul di hampir semua halaman:

- **Tahan (long-press)** logo untuk melihat label "Hubungi Bidan".
- **Ketuk** untuk langsung membuka halaman Hubungi Bidan.

Tombol ini otomatis disembunyikan saat berada di halaman Hubungi Bidan itu
sendiri atau saat ada dialog/bottom sheet terbuka.

---

## 10. Sinkronisasi & Mode Offline

- Semua data (profil, pengukuran, ceklis, hasil) **disimpan lokal dulu**,
  lalu disinkronkan ke server bila online.
- Saat offline, data tetap tersimpan di perangkat; setelah online, tekan
  **Sinkron** di Beranda untuk mengirim data tertunda.
- Pemberitahuan "…tersinkron" berarti terkirim ke server; "…tersimpan di
  perangkat (offline)" berarti menunggu koneksi.
- Booklet edukasi, daftar bidan, dan panduan rujukan diunduh dari server dan
  di-cache sehingga tetap bisa dibuka tanpa internet setelah diunduh.

---

## 11. Catatan Penting

- Aplikasi menampilkan kategori risiko (Normal/Waspada/Berisiko/Bahaya)
  berdasarkan klasifikasi AHA 2025 sebagai **informasi awal**.
- Hasil **Bahaya** (merah) atau gejala bahaya yang menetap bukan berarti Anda
  harus menunggu — segera hubungi **bidan, Puskesmas, atau layanan darurat**.
- Beritahukan hasil tren dan pengukuran kepada bidan pada kontrol berikutnya.
