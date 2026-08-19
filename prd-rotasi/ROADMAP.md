# ROADMAP.md: ROTASI

## Phased Delivery Plan

Roadmap ini selaras dengan jadwal riset PDP 12 bulan (kerangka **ADDIE**) di wilayah kerja Puskesmas Barombong. Produk yang dibangun: aplikasi Flutter offline-first, web admin Laravel + Inertia + React, serta backend API sinkronisasi.

| Phase | Durasi | Tujuan | Deliverables Utama |
|:---|:---|:---|:---|
| **Phase 1: Analysis** | Bulan 1–2 | Identifikasi kebutuhan desain & pengguna. | Studi literatur AHA 2025; FGD stakeholder (ibu hamil, bidan, kader); survei lapangan; dokumen analisis kebutuhan; pemetaan hambatan akses. |
| **Phase 2: Design** | Bulan 2–4 | Merancang model prototipe & materi edukasi. | Blueprint prototipe hibrid (fisik + digital); desain UI/UX aplikasi; desain DB & API; materi edukasi 10T & booklet (draft). |
| **Phase 3: Development** | Bulan 3–7 | Membangun prototipe + validasi ahli. | Prototipe fisik roda; aplikasi Flutter (fitur inti + offline); web admin Laravel; validasi ahli (rating scale ≥ 75%); revisi. |
| **Phase 4: Implementation** | Bulan 8–10 | Uji coba terbatas pada pengguna nyata. | Uji coba 15 ibu hamil (2 minggu); pengumpulan data kuesioner (Likert) & FGD kecil; laporan penggunaan. |
| **Phase 5: Evaluation** | Bulan 10–12 | Evaluasi, luaran riset, dan penyempurnaan. | Analisis data deskriptif & sintesis FGD; laporan akhir; pendaftaran HAKI (2); submit artikel SINTA 4; dokumentasi & serah terima. |

**Disclaimer timeline:** asumsi **3 anggota inti** (1 klinis/promkes — ketua, 1 teknis IT backend+web, 1 teknis IT mobile), dibantu mahasiswa pada Phase 3–5. Penyesuaian durasi proporsional terhadap ketersediaan anggota.

---

## MVP Feature List

### P0: Wajib Ada (Launch)

| Fitur | Referensi | Status | Catatan |
|:---|:---|:---|:---|
| Registrasi biodata ibu | FR-01 | Core | Termasuk HPL/usia kehamilan |
| Skrining risiko otomatis (NICE/KIA) | FR-02 | Core | Dari biodata, tanpa input tambahan |
| Sesi pengukuran tensi (2x + rata-rata) | FR-03 | Core | Protokol AHA 2025 |
| Klasifikasi warna ROTASI | FR-04 | Core | Aturan kategori terburuk; konsisten roda fisik |
| Grafik tren tensi | FR-05 | Core | Pagi/sore + ambang warna |
| Ceklis gejala bahaya | FR-06 | Core | Sakit kepala, kabur, ulu hati, sesak |
| Hitung gerakan janin (timer 30 menit) | FR-07 | Core | Kriteria ≥3/30 menit |
| Ceklis 10T (ANC) | FR-08 | Core | Per kunjungan |
| Pustaka edukasi offline | FR-09 | Core | Bundle booklet awal + unduhan PDF aktif |
| Panduan rujukan & kontak darurat | FR-10 | Core | Dari pengaturan global |
| Hubungi bidan (WhatsApp) | FR-11 | Core | Daftar bidan aktif + pesan ringkasan otomatis |
| Sinkronisasi data idempoten | FR-13 | Core | Online; antrean aman saat offline |
| Notifikasi & pengingat lokal | FR-14 | Core | Tanpa FCM |
| Login admin + dashboard | FR-16, FR-17 | Core | Rate limit login |
| Manajemen booklet PDF (upload + aktif) | FR-18 | Core | Unggah PDF, riwayat versi, satu aktif |
| Manajemen rilis APK | FR-19 | Core | Versi aktif + endpoint versi |
| Pengaturan global | FR-20 | Core | Kontak darurat, puskesmas |
| Manajemen bidan (CRUD) | FR-22 | Core | Nama, no WA, jadwal; daftar aktif untuk aplikasi |
| Pemantauan data tersinkron | FR-21 | Core | Daftar pasien & log sync |

### P1: Sebaiknya (Dalam 3 Bulan Setelah Launch)

| Fitur | Referensi | Status | Catatan |
|:---|:---|:---|:---|
| Mode pendamping (suami/kader) | FR-15 | Enhancement | Multi-profil ringan di satu perangkat |
| Latihan napas 4-2-6 | FR-12 | Enhancement | Timer + visual |
| Ekspor/screenshot laporan untuk bidan | FR-05 | Enhancement | Format ringkas |
| 2FA admin | Security | Enhancement | Lapisan keamanan ekstra |

### P2: Nanti (Fase Lanjutan / Tahun 2-5)

| Fitur | Referensi | Status | Catatan |
|:---|:---|:---|:---|
| Dashboard khusus bidan (akses data real-time) | FR-21 (ekstensi) | Future | Ditunda; pakai WhatsApp dulu |
| Push notification cloud (FCM) | FR-14 (ekstensi) | Future | Pengingat jarak jauh |
| Integrasi SatuSehat/EMR | Out of Scope | Future | Kemenkes |
| Bahasa daerah (Makassar/Bugis) | Out of Scope | Future | Ekspansi literasi |
| Multi-puskesmas (multi-tenant) | Out of Scope | Future | Setelah riset |
| Distribusi Play Store | Out of Scope | Future | Bila resmi diadopsi |

---

## Milestones

| Milestone | Phase | Target | Deliverables |
|:---|:---|:---|:---|
| Analisis kebutuhan tuntas | 1 | Bulan 2 | Dokumen kebutuhan; hasil FGD & survei; pemetaan hambatan |
| Blueprint & desain tuntas | 2 | Bulan 4 | Desain UI/UX, DB & API; materi edukasi draft; daftar ambang warna AHA |
| Prototipe ter-validasi | 3 | Bulan 7 | Roda fisik + aplikasi Flutter + web admin; skor validasi ahli ≥ 75% |
| Uji coba 15 ibu selesai | 4 | Bulan 10 | Data kuesioner & FGD; laporan penggunaan; umpan balik perbaikan |
| Evaluasi & luaran | 5 | Bulan 12 | Laporan akhir; 2 HAKI terdaftar; artikel SINTA 4 ter-submit; dokumentasi |

---

## Dependencies

### Dependensi Eksternal

| Dependensi | Tujuan | Status | Catatan |
|:---|:---|:---|:---|
| **Izin etik riset** | Kelayakan uji coba manusia | Wajib | Komite etik sebelum Phase 4 |
| **Persetujuan Puskesmas Barombong** | Lokasi & bidan mitra | Wajib | Koordinasi sejak Phase 1 |
| **Validasi ahli obstetri** | Validitas klinis booklet | Wajib | Sebelum Phase 3 unggah booklet |
| **VPS & domain** | Backend/API/web admin & distribusi APK | Wajib | Anggaran riset; sebelum Phase 3 |
| **Object storage (S3-compatible)** | Media edukasi & PDF booklet | Wajib | Bisa MinIO/Spaces; sebelum Phase 3 |
| **Data bidan kontak (nama, no WA, jadwal)** | Kanal komunikasi | Wajib | Dikumpulkan saat FGD; diinput via CRUD web admin |

### Dependensi Internal

| Dependensi | Pemilik | Batas | Catatan |
|:---|:---|:---|:---|
| Materi edukasi 10T & booklet | Tim klinis (Serli, Rasdiana) | Bulan 4 | Basis booklet aplikasi (diunggah ke web admin) |
| Desain roda fisik (kode warna) | Tim promkes | Bulan 4 | Rule sama dengan aplikasi |
| Skema DB & API spec | Tim IT | Bulan 5 | Sebelum coding penuh |
| Prototipe UI aplikasi | Tim IT mobile | Bulan 5 | Disetujui tim sebelum develop |
| Panduan instalasi QR/unduhan VPS | Tim IT | Bulan 7 | Untuk booklet & posyandu |

---

## Risks & Mitigation

| Risiko | Dampak | Probabilitas | Mitigasi |
|:---|:---|:---|:---|
| Literasi pengguna rendah → salah pakai | Tinggi | Tinggi | Desain ikon-first; mode pendamping; FGD uji coba; edukasi tatap muka |
| Distribusi via VPS (warning Android, tak update) | Sedang | Sedang | Panduan bergambar; notifikasi versi di aplikasi; QR konsisten |
| Klasifikasi warna keliru (SYS vs DIA) | Tinggi | Rendah | Unit test engine warna; validasi ahli; roda fisik & aplikasi satu rule |
| Data sensitif bocor / isu UU PDP | Tinggi | Rendah | Consent; TLS; minimasi data; akses admin terbatas; audit log |
| Protokol AHA tidak diikuti | Sedang | Sedang | Panduan visual; timer jeda; edukasi |
| Jaringan tidak stabil di pesisir | Sedang | Tinggi | Offline-first; antrean sync + retry; status sync jelas |
| Tim IT kecil & banyak stack | Sedang | Sedang | Batasi scope; library stabil; dokumentasi; mahasiswa dibina |
| Izin etik/puskesmas terlambat | Tinggi | Sedang | Mulai proses izin sejak Bulan 1 |
| Keterlambatan materi booklet klinis | Sedang | Sedang | Deadline materi booklet Bulan 4; placeholder di tahap awal |

---

## Technical Milestones per Phase

### Phase 1: Analysis (Bulan 1–2)
- Studi literatur AHA 2025 & INAPRES; klarifikasi ambang warna & protokol.
- FGD & wawancara (bidan, kader, ibu hamil); pemetaan literasi digital & kendala jaringan.
- Penyusunan instrumen riset (kuesioner Likert, panduan FGD).

### Phase 2: Design (Bulan 2–4)
- Wireframe & prototipe UI aplikasi (beranda, input tensi, grafik, ceklis, edukasi).
- Skema DB server (MySQL) & lokal (SQLite); spesifikasi API `/api/v1` dan `/api/admin`.
- Blueprint roda fisik & penyusunan materi edukasi 10T/booklet (draft).

### Phase 3: Development (Bulan 3–7)
- **Bulan 3–4:** setup repo; backend Laravel (auth, booklet, pengaturan); Flutter (registrasi, skrining, engine warna).
- **Bulan 5–6:** fitur tensi+grafik, ceklis, gerakan janin, edukasi offline (booklet), napas; admin (unggah booklet, rilis APK, CRUD bidan); uji unit engine warna.
- **Bulan 7:** integrasi sync idempoten; produksi roda fisik; validasi ahli (media & materi); revisi produk.

### Phase 4: Implementation (Bulan 8–10)
- Onboarding 15 ibu hamil (bantuan kader; QR + panduan instalasi).
- Uji coba 2 minggu; pendampingan; pengumpulan kuesioner Likert & FGD kecil.
- Pencatatan bug & usulan perbaikan untuk evaluasi.

### Phase 5: Evaluation (Bulan 10–12)
- Analisis deskriptif (frekuensi/persentase) + sintesis FGD.
- Penyusunan laporan akhir; pendaftaran HAKI (2: fisik & digital).
- Submit artikel jurnal SINTA 4; dokumentasi & penyerahan ringkasan ke stakeholder.

---

## Success Criteria & Go-Live Checklist

### Kelayakan & Validitas
- [ ] Skor validasi ahli ≥ 75% (skala 100).
- [ ] ≥ 80% dari 15 ibu hamil menyatakan prototipe layak.
- [ ] SUS ≥ 70; input sesi tensi < 90 detik.

### Fungsional
- [ ] 100% fitur inti (FR-01..FR-12, FR-14) berfungsi offline.
- [ ] Sinkronisasi idempoten; keberhasilan ≥ 95% saat online; tidak ada data hilang.
- [ ] Klasifikasi warna sesuai AHA 2025 (uji unit + validasi ahli).
- [ ] Admin dapat mengunggah & mengaktifkan booklet serta rilis APK < 5 menit.

### Keamanan & Kepatuhan
- [ ] HTTPS aktif; password bcrypt; rate limit login.
- [ ] Consent & kebijakan privasi tersedia; data riset dianonimkan.
- [ ] Izin etik & persetujuan puskesmas terdokumentasi.

### Luaran Riset
- [ ] 2 sertifikat HAKI terdaftar.
- [ ] Artikel ilmiah ter-submit ke jurnal SINTA 4.
- [ ] Laporan akhir tersimpan di perpustakaan & diserahkan ke stakeholder.

---

## Post-Launch Roadmap (Tahun 2–5)

- **Tahun 2:** penelitian terapan — dashboard bidan, FCM, ekspor laporan formal, multi-puskesmas pilot.
- **Tahun 3:** hilirisasi — integrasi SatuSehat, distribusi resmi (Play Store atau kebijakan Dinkes), pelatihan bidan/kader.
- **Tahun 4–5:** skala regional pesisir; bahasa daerah; evaluasi dampak (indikator stunting/BBLR).

---

## Resource Allocation

| Peran | Alokasi | Tanggung Jawab |
|:---|:---|:---|
| Ketua Peneliti (Promosi Kesehatan) | 50% | Koordinasi, FGD, analisis data, luaran riset. |
| Anggota Kesehatan Reproduksi (klinis) | 40% | Validasi materi booklet & protokol, kontak bidan/puskesmas. |
| Anggota Teknologi Informatika (backend+web) | 80% | Laravel, API, admin, deploy, DB. |
| Anggota Teknologi Informatika (mobile) | 80% | Flutter, SQLite, offline, sync client. |
| Mahasiswa (pendamping teknis) | 60% | Build/bugfix, uji coba, dokumentasi. |
| Bidan Puskesmas (mitra) | 10% | Supervisi klinis uji coba, umpan balik. |

---

## Communication & Governance

- **Koordinasi mingguan** internal tim riset (progress, blocker, tugas).
- **Check-in bulanan** dengan ketua prodi SI & stakeholder puskesmas.
- **Kontrol perubahan:** semua tambahan scope dicatat di backlog & diprioritaskan MoSCoW; dampak timeline dikomunikasikan.
- **Dokumentasi:** keputusan desain, skema API/DB, dan booklet terpusat di repository dokumentasi tim.

---

## Assumptions & Constraints

**Asumsi:**
- Tim inti tersedia sesuai alokasi; mahasiswa terlibat mulai Phase 3.
- Izin etik & persetujuan puskesmas keluar sebelum Phase 4.
- 15 ibu hamil bersedia dan mampu memakai smartphone Android (didampingi kader bila perlu).
- Materi booklet klinis awal disediakan tim sebelum Bulan 4.

**Constraint:**
- Timeline 12 bulan (anggaran PDP); produk digital dibangun paralel dengan riset lapangan.
- Stack tetap: Flutter (mobile) + Laravel/Inertia/React (web/admin) + MySQL + SQLite.
- Distribusi non-Play Store (VPS/unduhan & QR).
- Single-tenant, single-admin, Bahasa Indonesia, Android-only untuk rilis awal.