# REQUIREMENTS.md: ROTASI

## 1. Functional Requirements

### 1.1. Aplikasi Mobile (Ibu Hamil / Pendamping)

**FR-01: Registrasi Biodata Ibu**
Sistem SHALL menyediakan form registrasi biodata ibu hamil yang tersimpan lokal dan dapat tersinkron saat online.
*   Aplikasi MUST menyediakan field: nama, usia, tinggi badan, berat badan, usia kehamilan/HPL, hasil tensi terakhir, dan riwayat hipertensi (tidak ada, hipertensi, pernah preeklamsia, riwayat turunan).
*   Data biodata MUST tersimpan di penyimpanan lokal (SQLite) dan bisa dilengkapi tanpa koneksi internet.
*   Registrasi SHOULD dapat diisi ulang/diperbaiki oleh pendamping tanpa mengunci perangkat.

**FR-02: Skrining Risiko Otomatis**
Sistem SHALL menghitung kategori risiko preeklamsia (rendah/sedang/tinggi) secara otomatis dari biodata.
*   Perhitungan MUST berdasarkan kriteria NICE & KIA 2024 (usia >35 tahun, IMT >30, jarak kehamilan >10 tahun, riwayat medis, kehamilan ganda).
*   Hasil skrining MUST ditampilkan dengan bahasa sederhana dan ikon, tanpa istilah medis rumit.
*   Sistem MUST tidak meminta input tambahan literasi; kategori risiko cukup dihitung dari biodata yang sudah diisi.
*   Hasil skrining SHOULD menampilkan rekomendasi "disarankan konsultasi bidan" (bukan diagnosis).

**FR-03: Sesi Pengukuran Tekanan Darah**
Sistem SHALL mendukung protokol pengukuran tekanan darah AHA 2025: dua sesi per hari (pagi & sore), masing-masing 2x pengukuran yang dirata-ratakan.
*   Aplikasi MUST memandu pengukuran pertama dan kedua dengan jeda 1–2 menit (timer otomatis).
*   Sistem MUST menghitung rata-rata sistolik dan diastolik dari 2 pengukuran sesi.
*   Aplikasi MUST menampilkan nilai rata-rata sebagai hasil resmi yang diklasifikasikan.

**FR-04: Klasifikasi Status Warna ROTASI**
Sistem SHALL mengklasifikasikan hasil tekanan darah ke 4 status warna sesuai AHA 2025.
*   Klasifikasi MUST mengikuti aturan "ambil kategori terburuk" antara Sistolik dan Diastolik.
*   Warna MUST konsisten dengan roda fisik ROTASI: Hijau (Normal <120/<80), Kuning (Elevated 120–129/<80), Oranye (Stage 1 130–139/80–89), Merah (Stage 2/Krisis ≥140/≥90).
*   Aplikasi MUST menampilkan roda visual yang menyerupai roda fisik beserta label teks status.

**FR-05: Grafik Tren Tekanan Darah**
Sistem SHALL menampilkan grafik tren tekanan darah harian.
*   Grafik MUST menampilkan titik pagi dan sore untuk sistolik dan diastolik.
*   Grafik MUST dapat di-screenshot/ekspor ringkas untuk ditunjukkan ke bidan saat ANC.
*   Grafik SHOULD menandai garis ambang warna untuk memudahkan pembacaan.

**FR-06: Ceklis Gejala Bahaya Harian**
Sistem SHALL menyediakan ceklis gejala bahaya harian.
*   Ceklis MUST memuat: sakit kepala hebat, pandangan kabur, nyeri ulu hati, sesak napas (✓/✗).
*   Ceklis MUST dapat diisi pagi dan sore bersamaan dengan sesi pengukuran.
*   Sistem SHOULD menandai peringatan bila ada gejala tercentang (bukan diagnosa, hanya panduan rujukan).

**FR-07: Hitung Gerakan Janin**
Sistem SHALL menyediakan alat hitung gerakan janin dengan timer.
*   Aplikasi MUST menyediakan timer pengamatan 30 menit dan tombol menghitung setiap gerakan.
*   Sistem MUST menandai status aktif (≥3 gerakan/30 menit) atau kurang aktif (<3 gerakan/30 menit).
*   Hasil hitungan MUST tercatat di riwayat harian bersama data lainnya.

**FR-08: Ceklis Standar 10T (ANC)**
Sistem SHALL menyediakan daftar periksa pemeriksaan ANC standar 10T.
*   Daftar periksa MUST mencakup 10 item pemeriksaan standar (timbang/ukur TB, tekanan darah, LiLA, tinggi fundus, presentasi & DJJ, imunisasi TT, TTD, lab, tata laksana, temu wicara).
*   Setiap item MUST dapat ditandai selesai/terlewat per kunjungan.
*   Riwayat kunjungan SHOULD tercatat beserta tanggal kunjungan.

**FR-09: Pustaka Edukasi (Booklet PDF) Offline**
Sistem SHALL menyediakan pustaka edukasi berupa file PDF booklet yang dapat diakses penuh tanpa koneksi.
*   Aplikasi MUST menampilkan booklet PDF versi aktif (dikelola administrator web) sebagai pustaka edukasi.
*   Booklet MUST dapat dibuka penuh offline setelah file tersedia di perangkat (bundle awal/unduhan sekali saat online).
*   Saat online, aplikasi MUST memeriksa versi booklet aktif dan mengunduh PDF terbaru bila berubah; PDF lama tetap terbaca offline.
*   Isi booklet MUST mencakup materi: preeklamsia/stunting, nutrisi DASH, 1000 HPK, manajemen stres, pascapersalinan.

**FR-10: Panduan Rujukan & Kontak Darurat**
Sistem SHALL menampilkan panduan kapan harus segera ke faskes dan kontak darurat.
*   Panduan MUST mencakup kriteria: warna oranye/merah konsisten, ≥1 tanda bahaya, gerakan janin kurang aktif.
*   Kontak darurat (ambulance, puskesmas, bidan) MUST bersumber dari pengaturan global dan dapat dibuka (panggilan/WhatsApp).
*   Sistem MUST menampilkan disclaimer "aplikasi pendamping, bukan pengganti pemeriksaan ANC".

**FR-11: Hubungi Bidan via WhatsApp**
Sistem SHALL menyediakan daftar bidan aktif dan tombol hubungi bidan melalui WhatsApp.
*   Aplikasi MUST menampilkan daftar bidan aktif (dari data bidan web admin) yang diunduh dan dicache saat online.
*   Tombol MUST membuka WhatsApp ke bidan terpilih (nomor dari data bidan).
*   Pesan awal SHOULD terisi otomatis berisi ringkasan status terakhir (nama, tanggal, status warna).
*   Fitur ini MUST tetap tersedia (daftar & tombol terlihat) meskipun jaringan tidak ada, selama WhatsApp terpasang dan daftar sudah diunduh sebelumnya.

**FR-12: Latihan Napas Lambat (Slow Breathing)**
Sistem SHALL menyediakan timer panduan napas lambat 4-2-6.
*   Timer MUST memandu: tarik napas 4 detik, tahan 2 detik, buang napas 6 detik.
*   Aplikasi MUST menyediakan durasi latihan (default 15 menit) dengan hitungan mundur dan visual ringan.
*   Latihan SHOULD berjalan penuh offline.

**FR-13: Sinkronisasi Data Saat Online**
Sistem SHALL menyinkronkan data lokal ke server secara idempoten saat koneksi tersedia.
*   Setiap record MUST memiliki UUID client-side sebagai kunci idempoten; sinkronisasi ulang tidak menduplikasi data.
*   Sinkronisasi MUST mencakup: profil pasien, record tekanan darah, ceklis gejala, hitungan gerakan janin, dan ceklis 10T.
*   Data yang belum tersinkron MUST tetap tersimpan aman secara lokal hingga berhasil dikirim.
*   Status sinkronisasi SHOULD ditampilkan kepada pengguna (tersinkron / menunggu / gagal).

**FR-14: Notifikasi & Pengingat Lokal**
Sistem SHALL menyediakan pengingat lokal pengukuran pagi & sore.
*   Pengingat MUST berjalan tanpa koneksi (notifikasi lokal, bukan push cloud).
*   Pengingat SHOULD dapat diatur waktu pagi dan sore oleh pengguna.

**FR-15: Mode Pendamping**
Sistem SHALL menyediakan mode pendamping untuk pengisian atas nama ibu.
*   Pendamping (suami/kader) SHOULD dapat membuka aplikasi dan mengisi data ibu pada perangkat yang sama.
*   Aplikasi MUST menampilkan nama ibu yang aktif agar tidak terjadi kesalahan entri.
*   Mode ini SHOULD dapat diaktifkan/dinonaktifkan di pengaturan.

### 1.2. Web Admin

**FR-16: Autentikasi Admin**
Sistem SHALL menyediakan halaman login untuk akun administrator tunggal dengan autentikasi berbasis sesi (Laravel Sanctum).
*   Administrator MUST dapat login dengan kredensial valid.
*   Percobaan login gagal MUST menampilkan pesan error dan diterapkan rate limiting.
*   Sesi MUST bertahan antar navigasi hingga logout atau kedaluwarsa.

**FR-17: Dashboard Admin**
Sistem SHALL menampilkan dashboard ringkasan.
*   Dashboard MUST menampilkan: versi booklet aktif, jumlah rilis APK, jumlah pasien tersinkron, dan riwayat sinkronisasi terbaru.
*   Dashboard MUST menyediakan tautan cepat ke kelola booklet dan rilis APK.

**FR-18: Manajemen Booklet PDF (Upload + Riwayat + Aktif)**
Sistem SHALL menyediakan pengelolaan file PDF booklet yang dikonsumsi aplikasi mobile.
*   Administrator MUST dapat mengunggah file PDF booklet beserta judul dan catatan versi; file MUST tersimpan di object storage (S3-compatible).
*   Setiap unggahan MUST tercatat sebagai riwayat versi (riwayat + satu versi aktif, pola rilis APK).
*   Administrator MUST dapat menetapkan satu versi booklet sebagai aktif; hanya satu versi aktif pada satu waktu.
*   Endpoint aplikasi mobile MUST hanya menyajikan versi booklet aktif.

**FR-19: Manajemen Rilis APK**
Sistem SHALL menyediakan pengelolaan rilis APK.
*   Administrator MUST dapat mengunggah file APK beserta versi (version code/name) dan catatan rilis.
*   Administrator MUST dapat menetapkan satu versi aktif untuk dilaporkan oleh endpoint versi aplikasi.
*   Rilis yang salah SHOULD dapat dihapus atau dinonaktifkan.

**FR-20: Pengaturan Global**
Sistem SHALL menyediakan pengaturan global yang dikonsumsi aplikasi.
*   Pengaturan MUST mencakup: nama aplikasi, nomor darurat (ambulance), nama & lokasi puskesmas, dan pesan WA bawaan.
*   Perubahan pengaturan SHOULD langsung tersedia pada pengaturan endpoint yang diunduh aplikasi.
*   Nomor WhatsApp bidan TIDAK lagi menjadi bagian pengaturan global; nomor bersumber dari data bidan (FR-22).

**FR-21: Pemantauan Data Tersinkron**
Sistem SHALL menyediakan pemantauan data pasien tersinkron dan log sinkronisasi.
*   Administrator MUST dapat melihat daftar pasien tersinkron (agregat, tanpa mengekspos data berlebih).
*   Administrator MUST dapat melihat detail record tekanan darah per pasien dan log sinkronisasi (status, waktu, perangkat).
*   Akses data ini SHOULD dilindungi sesi admin dan dicatat untuk audit riset.

**FR-22: Manajemen Bidan (CRUD)**
Sistem SHALL menyediakan CRUD data bidan yang dikonsumsi aplikasi mobile.
*   Administrator MUST dapat membuat, membaca, mengubah, dan menghapus data bidan dengan field: nama lengkap, jabatan, puskesmas/lokasi bertugas, nomor WhatsApp, telepon alternatif, jam bertugas, status aktif, urutan tampil, dan catatan.
*   Sistem MUST hanya menyediakan bidan berstatus aktif ke aplikasi mobile (endpoint daftar bidan), terurut sesuai urutan tampil.
*   Perubahan data bidan SHOULD langsung tersedia di aplikasi pada sinkronisasi berikutnya.

## 2. Non-Functional Requirements

| Kategori | Kebutuhan | Target Terukur |
|:---|:---|:---|
| Offline-First | Fitur inti berfungsi tanpa koneksi | 100% fitur FR-01 s.d. FR-12 & FR-14 berfungsi penuh tanpa jaringan; tanpa kehilangan data. |
| Kinerja | Aplikasi & web responsif | Cold start < 3 detik; sesi tensi < 90 detik; render grafik < 1 detik; LCP web admin < 2,5s. |
| Keamanan | Perlindungan data kesehatan | HTTPS; password bcrypt; token Sanctum; proteksi OWASP Top 10; consent & kebijakan privasi; minimasi data. |
| Kegunaan | Ramah literasi rendah | Teks ≥ 16sp; ikon besar; kontras AA; 80% peserta menyelesaikan input harian tanpa bantuan; SUS ≥ 70. |
| Reliabilitas | Data tidak hilang & sinkronisasi benar | Sync idempoten; tingkat keberhasilan ≥ 95% saat online; recovery antrean gagal. |
| Keberlanjutan | Kode mudah dirawat | Struktur modular; tes unit dasar; dokumentasi setup & deploy. |
| Skalabilitas | Menampung uji coba | ≥ 200 perangkat & 1.000 sinkronisasi/jam pada VPS kecil. |
| Validitas Klinis | Klasifikasi sesuai AHA 2025 | Validasi ahli ≥ 75%; kelayakan peserta ≥ 80%. |

## 3. Technical Constraints

*   Aplikasi utama MUST berupa aplikasi Android (Flutter) dengan pola offline-first (SQLite lokal).
*   Web admin MUST dibangun dengan Laravel + Inertia.js + React; backend MUST melayani API sinkronisasi mobile dengan Laravel Sanctum (token).
*   Distribusi APK MUST melalui VPS (URL unduhan dari server), bukan Google Play Store; Google Drive tidak dipakai (diblokir).
*   Bahasa aplikasi MUST Bahasa Indonesia.
*   Sistem MUST single-tenant (satu puskesmas) dan single administrator pada tahap riset.
*   Aplikasi MUST menampilkan disclaimer bahwa aplikasi bukan pengganti pemeriksaan ANC.
*   Isi booklet klinis MUST ditinjau ahli obstetri sebelum diunggah.

## 4. Assumptions

*   Peserta uji coba (15 ibu hamil) WILL memiliki smartphone Android yang dapat memindai QR atau didampingi kader.
*   WhatsApp WILL terpasang pada perangkat peserta sebagai kanal komunikasi utama.
*   Izin etik riset dan persetujuan Puskesmas Barombong WILL diperoleh sebelum uji coba.
*   Tim riset WILL memiliki kemampuan dasar Flutter dan Laravel.
*   File PDF booklet awal WILL disediakan tim riset dan divalidasi ahli sebelum pengembangan; diunggah ke web admin.
*   Server VPS kecil WILL tersedia dan dialokasikan dari anggaran riset.
