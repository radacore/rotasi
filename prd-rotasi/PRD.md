# PRD: ROTASI

## Ringkasan Eksekutif & Visi Produk

Dokumen ini memuat Product Requirements untuk **ROTASI (Roda Pantau Tensi)** — sebuah sistem hibrid pemantauan mandiri tekanan darah untuk pencegahan preeklamsia dan stunting pada ibu hamil di wilayah pesisir.

Visi produk adalah menghadirkan **aplikasi Android offline-first** sebagai produk utama yang mudah diakses kapan pun dan di mana pun oleh ibu hamil pesisir dengan literasi rendah dan keterbatasan jaringan. Aplikasi didampingi oleh **roda fisik ROTASI** (alat putar kode warna) dan **booklet cetak** (file PDF yang diunggah ke web admin). Kelengkapan sistem ditutup oleh **web admin** (Laravel + Inertia + React) untuk mengelola booklet edukasi, merilis versi aplikasi, dan memantau sinkronisasi data — seluruhnya berbasis rekomendasi **AHA Guideline 2025** dan mendukung **SDG 3.2** serta **Asta Cita 4**.

## Pernyataan Masalah & Target Pengguna

**Masalah:** Preeklamsia adalah silent killer pada kehamilan yang menyumbang 23% kematian ibu di Indonesia. Deteksi dini melalui pemantauan tekanan darah mandiri (self-monitoring) di rumah belum optimal di wilayah pesisir karena: (1) ketiadaan teknologi yang mudah diakses dan terjangkau; (2) akses jaringan internet yang tidak stabil; (3) literasi kesehatan dan digital yang rendah. Akibatnya terjadi keterlambatan diagnosis, kelahiran bayi BBLR, dan risiko stunting dari hulu kehamilan.

**Target Pengguna:**
*   **Ibu Hamil (Peserta):** Ibu hamil di wilayah kerja Puskesmas Barombong, Kota Makassar. Literasi rendah, akses internet terbatas, menggunakan smartphone Android kelas bawah. Pemakai utama aplikasi ROTASI.
*   **Pendamping (Suami/Kader):** Keluarga atau kader kesehatan yang membantu pengisian data bagi ibu yang kesulitan. Menjadi aktor pada mode pendamping.
*   **Bidan Puskesmas:** Tenaga kesehatan di Puskesmas Barombong sebagai tujuan konsultasi, penerima data pemantauan, dan titik rujukan (tanpa aplikasi/login terpisah).
*   **Administrator Riset:** Tim peneliti (dosen Promosi Kesehatan, Kesehatan Reproduksi, Teknologi Informatika) yang mengelola booklet, merilis versi aplikasi, dan memantau sinkronisasi.

## Ruang Lingkup Sistem & Peran Pengguna

Sistem terdiri dari tiga komponen: **aplikasi Android** (produk utama, offline-first), **web admin** (Laravel + Inertia + React), dan **backend API** (Laravel + Sanctum). Roda fisik dan booklet merupakan artefak pendamping hibrid yang booklet-nya diunggah dari web admin.

| Peran | Deskripsi | Izin (Permissions) |
|:---|:---|:---|
| **Ibu Hamil / Peserta** (Pendamping) | Pengguna aplikasi Android. | - Registrasi biodata. - Mengisi sesi pengukuran tensi, ceklis gejala, dan hitung gerakan janin. - Membaca edukasi offline. - Mengakses panduan rujukan dan tombol hubungi bidan (WhatsApp). - Melakukan sinkronisasi data saat online. |
| **Bidan Puskesmas** | Mitra klinis non-login, terdaftar sebagai kontak di web admin. | - Menerima pesan WhatsApp dari peserta. - Menerima pasien rujukan berdasar indikasi aplikasi. |
| **Administrator** | Pengguna tunggal web admin. | - Login web admin. - Unggah booklet PDF (riwayat versi & satu aktif). - CRUD data bidan (nama, no WA, dll.). - Upload rilis APK dan atur versi aktif. - Kelola pengaturan global (kontak darurat, puskesmas). - Memantau data tersinkron & log sinkronisasi. |

## Functional Requirements

### Aplikasi Mobile (Ibu Hamil / Pendamping)
*   **FR-01: Registrasi Biodata Ibu:** Input profil ibu saat pertama kali membuka aplikasi: nama, usia, tinggi badan, berat badan, usia kehamilan/HPL, hasil tensi terakhir, dan riwayat hipertensi (tidak ada, hipertensi, pernah preeklamsia, riwayat turunan). Seluruh data tersimpan lokal (offline) dan opsional tersinkron saat online.
*   **FR-02: Skrining Risiko Otomatis:** Sistem menghitung kategori risiko (rendah/sedang/tinggi) secara otomatis dari biodata berdasar kriteria NICE & KIA 2024 (mis. usia >35 tahun, IMT >30, jarak kehamilan >10 tahun, riwayat medis) tanpa input tambahan dari pengguna. Menampilkan rekomendasi konsultasi.
*   **FR-03: Sesi Pengukuran Tekanan Darah:** Mendukung protokol AHA 2025: sesi pagi dan sore, masing-masing 2x pengukuran (jarak 1–2 menit) yang dirata-ratakan, dengan penghitungan otomatis rata-rata.
*   **FR-04: Klasifikasi Status Warna ROTASI:** Mengklasifikasikan hasil ke 4 status warna (Hijau Normal, Kuning Elevated, Oranye Stage 1, Merah Stage 2/Krisis) sesuai AHA 2025 dengan aturan *ambil kategori terburuk* antara Sistolik dan Diastolik. Visual roda menyerupai roda fisik.
*   **FR-05: Grafik Tren Tekanan Darah:** Menampilkan grafik trajectory harian (pagi & sore) sehingga tren kenaikan dapat terlihat dan dapat ditunjukkan ke bidan.
*   **FR-06: Ceklis Gejala Bahaya Harian:** Form ceklis harian: sakit kepala hebat, pandangan kabur, nyeri ulu hati, dan sesak napas (✓/✗).
*   **FR-07: Hitung Gerakan Janin:** Timer pengamatan 30 menit dengan penghitungan ketukan gerakan janin; menandai status aktif (≥3 gerakan/30 menit) atau kurang aktif.
*   **FR-08: Ceklis Standar 10T (ANC):** Daftar periksa pemeriksaan Antenatal Care standar 10T per kunjungan, dapat dibuka dan ditandai saat kontrol ke faskes.
*   **FR-09: Pustaka Edukasi Offline:** Booklet PDF edukasi (preeklamsia, stunting, nutrisi DASH, 1000 HPK, manajemen stres, pascapersalinan) dapat diakses penuh tanpa jaringan; versi aktif terbaru diunduh saat online.
*   **FR-10: Panduan Rujukan & Kontak Darurat:** Menampilkan kriteria "kapan harus segera ke faskes" (warna oranye/merah konsisten, ≥1 tanda bahaya, gerakan janin kurang) beserta nomor darurat (ambulance, puskesmas) dari pengaturan global.
*   **FR-11: Hubungi Bidan via WhatsApp:** Menampilkan daftar bidan aktif (dari data bidan di web admin) dan tombol yang membuka WhatsApp ke bidan terpilih dengan pesan terisi otomatis berisi ringkasan status.
*   **FR-12: Latihan Napas Lambat (Slow Breathing):** Timer panduan 4-2-6 detik (tarik 4s, tahan 2s, buang 6s) selama 15 menit.
*   **FR-13: Sinkronisasi Data Saat Online:** Menyinkronkan data lokal (profil, tensi, gejala, gerakan janin, 10T) ke server secara idempoten (UUID client-side) saat tersedia koneksi; tanpa kehilangan data saat offline.
*   **FR-14: Notifikasi & Pengingat Lokal:** Pengingat pengukuran pagi & sore yang berjalan penuh secara lokal tanpa koneksi.
*   **FR-15: Mode Pendamping:** Opsi pembukaan akses pendamping (suami/kader) untuk mengisi data atas nama ibu pada satu perangkat.

### Web Admin
*   **FR-16: Autentikasi Admin:** Login aman berbasis sesi (Laravel Sanctum) untuk akun administrator tunggal, dengan rate limiting.
*   **FR-17: Dashboard Admin:** Ringkasan versi booklet aktif, jumlah rilis APK, jumlah pasien tersinkron, riwayat sinkronisasi terbaru, dan tautan cepat kelola booklet.
*   **FR-18: Manajemen Booklet PDF:** Unggah file PDF booklet (judul + file), riwayat versi, dan penetapan satu versi aktif. Aplikasi mobile mengunduh versi aktif untuk dibaca offline.
*   **FR-19: Manajemen Rilis APK:** Upload file APK + nomor versi + catatan rilis, menetapkan versi aktif, dan menghapus rilis. Endpoint versi untuk aplikasi mobile.
*   **FR-20: Pengaturan Global:** Mengelola pengaturan global: nama aplikasi, nomor darurat (ambulance), nama/lokasi puskesmas, dan pengaturan lain yang dipakai aplikasi.
*   **FR-21: Pemantauan Data Tersinkron:** Melihat daftar pasien tersinkron, detail catatan, dan log sinkronisasi (status, waktu, perangkat) untuk evaluasi riset.
*   **FR-22: Manajemen Bidan (CRUD):** CRUD data bidan: nama lengkap, jabatan, puskesmas/lokasi bertugas, nomor WhatsApp, telepon alternatif, jam bertugas, status aktif, urutan tampil, dan catatan. Daftar bidan aktif ditampilkan di aplikasi mobile untuk fitur hubungi bidan (FR-11).

## Non-Functional Requirements

| Kategori | Kebutuhan | Metrik / Target |
|:---|:---|:---|
| **Offline-First** | Semua fitur inti pemantauan dapat dipakai tanpa koneksi | 100% fitur FR-01 s.d. FR-12 & FR-14 berfungsi penuh tanpa jaringan; tidak ada data hilang saat offline. |
| **Kinerja** | Aplikasi responsif di perangkat kelas bawah | Cold start < 3 detik; satu sesi pengukuran tensi selesai < 90 detik; render grafik < 1 detik; LCP web admin < 2,5s (SSR Inertia). |
| **Keamanan** | Perlindungan data kesehatan (UU PDP) | HTTPS wajib; password admin di-hash (bcrypt); token Sanctum; data sensitif tidak diekspos; kebijakan privasi & consent dalam aplikasi; proteksi OWASP Top 10 pada web admin. |
| **Kegunaan (Usability)** | Ramah literasi rendah | Teks ≥ 16sp, ikon besar, kontras memenuhi AA; 80% peserta menyelesaikan input harian tanpa bantuan; skor System Usability Scale (SUS) ≥ 70. |
| **Reliabilitas** | Data tidak hilang & sinkronisasi benar | Sinkronisasi idempoten; tingkat keberhasilan sinkronisasi saat online ≥ 95%; recovery otomatis dari antrean gagal. |
| **Keberlanjutan (Maintainability)** | Kode mudah dirawat | Struktur modular Flutter (fitur per-module); tes unit dasar; dokumentasi setup & deploy. |
| **Skalabilitas** | Server menampung uji coba | Menangani ≥ 200 perangkat & 1.000 sinkronisasi/jam pada VPS kecil (pembuktian konsep TKT 2-3). |
| **Validitas Klinis** | Klasifikasi sesuai AHA 2025 | Skor validasi ahli ≥ 75% (skala 100); uji kelayakan peserta ≥ 80% menyatakan layak. |

## Technology Stack & Rationale

| Komponen | Teknologi | Alasan (Rationale) |
|:---|:---|:---|
| Mobile (produk utama) | **Flutter** | Satu basis kode Android, performa baik di kelas bawah, mudah di-bundle offline (SQLite, aset booklet), tidak butuh Play Store. |
| Penyimpanan lokal mobile | **SQLite** (via drift/sqflite) | Offline-first: seluruh data pemantauan tersimpan di perangkat. |
| Web admin & frontend | **Laravel + Inertia.js + React** | Stack ditentukan pengguna; admin panel CRUD yang produktif tanpa API terpisah. |
| Styling | **Tailwind CSS** | Pengembangan UI cepat dan konsisten dengan design system. |
| Backend API | **Laravel + Sanctum** | Satu backend melayani web admin (sesi) dan sinkronisasi mobile (token). |
| Database | **MySQL 8+** | Didukung penuh Laravel, cukup untuk skala riset. |
| Penyimpanan file | **Object storage (S3-compatible)** | Menyimpan PDF booklet & gambar ilustrasi; skala aman dan terpisah dari VPS. |
| Distribusi APK | **Disajikan langsung dari VPS** (URL unduhan) | Tidak memakai Google Play Store maupun Google Drive (diblokir); link unduhan dibagikan lewat QR booklet/posyandu. |
| Build tool | **Vite** | Default Laravel 12, HMR cepat dan build produksi optimal. |
| Hosting | **VPS kecil (Ubuntu + Nginx)** | Kontrol penuh, biaya terjangkau sesuai anggaran riset PDP. |

## Success Metrics & KPIs

| Metrik | KPI | Target |
|:---|:---|:---|
| Kelayakan Produk | Persentase peserta menyatakan layak | ≥ 80% dari 15 ibu hamil uji coba (sesuai proposal). |
| Validitas Klinis | Skor validasi ahli (feasibility, safety, usability) | ≥ 75% (skala 100). |
| Kepuasan Penggunaan | System Usability Scale (SUS) | ≥ 70. |
| Efisiensi Input | Waktu menyelesaikan satu sesi tensi | < 90 detik. |
| Offline Capability | Fitur inti berfungsi tanpa jaringan | 100% (FR-01 s.d. FR-12, FR-14). |
| Sinkronisasi | Tingkat keberhasilan sync saat online | ≥ 95%, tanpa kehilangan data. |
| Efisiensi Admin | Waktu mengunggah booklet/rilis APK | < 5 menit per item. |
| Capaian Riset | HAKI & publikasi | 2 sertifikat HAKI; artikel submit ke jurnal SINTA 4. |

## Risk Analysis & Mitigation

| Risiko | Dampak | Mitigasi |
|:---|:---|:---|
| **Literasi rendah pengguna** | Tinggi | Ibu salah memahami status warna / gagal input. | Desain ikon-first & teks besar; mode pendamping; edukasi tatap muka saat FGD; uji coba langsung oleh tim. |
| **Distribusi via VPS (URL unduhan)** | Sedang | Warning keamanan Android saat instal di luar Play Store, pengguna tidak update. | Panduan instalasi bergambar; notifikasi versi di aplikasi (endpoint versi); QR konsisten; dokumentasi. |
| **Data kesehatan sensitif (UU PDP)** | Tinggi | Kebocoran/pelanggaran privasi. | Consent & kebijakan privasi dalam aplikasi; enkripsi TLS; minimasi data; akses admin dibatasi; data riset dianonimkan saat analisis. |
| **Klasifikasi warna salah (SYS vs DIA)** | Tinggi | Status salah → keputusan keliru. | Aturan "kategori terburuk" diuji di aplikasi & roda fisik; validasi ahli obstetri; unit test engine warna. |
| **Protokol AHA tidak diikuti** | Sedang | Pengukuran tidak valid. | Panduan visual langkah; timer jeda antar pengukuran; edukasi. |
| **Jaringan tidak stabil** | Sedang | Gagal sinkronisasi. | Offline-first; antrean sync idempoten + retry; status sinkron terlihat pengguna. |
| **Keterbatasan tim & waktu (PDP 12 bulan)** | Sedang | Scope melebar. | MoSCoW pada ROADMAP; booklet MVP jelas; backend & mobile satu bahasa tim minimal (PHP+Dart+React). |
| **Validitas klinis booklet** | Tinggi | Informasi keliru membahayakan. | Booklet ditinjau ahli obstetri; disclaimer "pendamping, bukan pengganti ANC"; sumber rujukan terdokumentasi. |

## Constraints & Assumptions

*   **Constraint:** Produk utama adalah aplikasi **Android offline-first**; iOS tidak termasuk rilis awal.
*   **Constraint:** Distribusi aplikasi melalui **VPS (URL unduhan) / QR code**, bukan Google Play Store. Google Drive tidak dipakai karena aksesnya diblokir di lapangan.
*   **Constraint:** Bahasa aplikasi **Bahasa Indonesia**; tidak ada bahasa daerah pada rilis awal.
*   **Constraint:** **Single tenant** — satu puskesmas (Barombong) pada tahap riset; multi-tenancy tidak diperlukan.
*   **Constraint:** Hanya **satu akun administrator**; RBAC tidak diperlukan.
*   **Constraint:** Aplikasi adalah alat **pendamping pemantauan**, bukan alat diagnosis medis atau pengganti kunjungan ANC.
*   **Assumption:** Peserta uji coba (15 ibu hamil) memiliki smartphone Android yang dapat memindai QR atau didampingi kader.
*   **Assumption:** WhatsApp terpasang pada perangkat peserta (kanal komunikasi utama).
*   **Assumption:** Data bidan (nama lengkap, nomor WhatsApp, jam bertugas) disediakan bidan koordinator/Puskesmas dan dikelola via CRUD di web admin.
*   **Assumption:** Izin etik riset dan persetujuan Puskesmas Barombong diperoleh sebelum uji coba.
*   **Assumption:** Tim riset memiliki kemampuan dasar Flutter dan Laravel; bagian mahasiswa disupervisi dosen.

## Out of Scope

Rilis awal ROTASI **TIDAK** akan mencakup:
*   Aplikasi iOS / distribusi Google Play Store.
*   Integrasi dengan SatuSehat/EMR Kemenkes atau sistem rekam medis puskesmas.
*   Telemedicine penuh (video call, janji temu online).
*   Diagnosis medis otomatis atau pengganti penilaian klinisi.
*   Dashboard khusus bidan dengan akses real-time data pasien (ditunda; memakai WhatsApp pada rilis awal).
*   Push notification berbasis cloud (FCM) — memakai notifikasi lokal.
*   Fitur bahasa daerah (Makassar/Bugis) pada rilis awal.
*   Multi-puskesmas / multi-tenant.
*   Fitur pembayaran atau monetisasi.
