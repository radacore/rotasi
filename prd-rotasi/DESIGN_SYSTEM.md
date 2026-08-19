# DESIGN.md: ROTASI

## Brand & Visual Identity

ROTASI mengusung tema **"Pesisir yang Sehat dan Modern"** — hangat, bersahabat, dan dapat dipercaya. Visual identity menggabungkan nuansa pesisir (biru laut, teal, kuning matahari, putih) dengan **bahasa warna indikator medis** (hijau/kuning/oranye/merah) yang menjadi inti komunikasi alat. Desain menekankan **ikon-first**, teks besar, dan kontras tinggi karena target utama adalah ibu hamil pesisir dengan literasi rendah — keputusan penting harus terbaca dari warna dan ikon, bukan hanya kata.

## User Experience Goals

1. **Penyelesaian Tanpa Bantuan** — 80% peserta menyelesaikan sesi pengukuran tensi harian tanpa pendampingan, dengan alur maksimal 3 langkah dari beranda ke hasil status warna.

2. **Kepastian Status** — pengguna dapat mengetahui status tekanan darahnya (warna roda) dalam < 90 detik; status direpresentasikan oleh warna + ikon + teks (tidak hanya warna) agar aman bagi buta warna.

3. **Nyaman untuk Literasi Rendah** — semua teks ≥ 16sp, ikon ≥ 44×44px, bahasa sederhana tanpa istilah medis, dukungan mode pendamping (suami/kader).

4. **Konsistensi Hibrid** — roda fisik, aplikasi, dan booklet menampilkan roda warna & istilah yang identik sehingga pengguna tidak kebingungan berpindah media.

## Color Palette

### Primary Colors
| Warna | Hex | CSS Variable | Penggunaan |
|:---|:---|:---|:---|
| Biru Laut Dalam | `#0C4A6E` | `--color-primary` | Header, tombol utama, judul besar |
| Biru Pesisir | `#0284C7` | `--color-primary-light` | Aksen, tautan, elemen sekunder |
| Teal Kesehatan | `#0D9488` | `--color-accent` | Hover, highlight, tombol sekunder |

### Secondary & Nuansa Pesisir
| Warna | Hex | CSS Variable | Penggunaan |
|:---|:---|:---|:---|
| Kuning Matahari | `#F59E0B` | `--color-sun` | Aksen ceria, highlight panduan |
| Pasir | `#FDF6EC` | `--color-sand` | Background kartu, section |
| Air Langit | `#E0F2FE` | `--color-sky-light` | Background soft, badge |
| Abu Abu Hujan | `#F1F5F9` | `--color-neutral-light` | Border, section alternatif |

### Neutral
| Warna | Hex | CSS Variable | Penggunaan |
|:---|:---|:---|:---|
| Teks Utama | `#0F172A` | `--color-text-primary` | Konten utama |
| Teks Sekunder | `#475569` | `--color-text-secondary` | Deskripsi, metadata |
| Border | `#CBD5E1` | `--color-border` | Divider, input |
| Putih | `#FFFFFF` | `--color-white` | Kartu, background |

### Semantic & Indikator Medis (Inti ROTASI)
Warna indikator harus identik antara aplikasi, roda fisik, dan booklet.

| Status | Hex | CSS Variable | Makna (AHA 2025) |
|:---|:---|:---|:---|
| Hijau (Normal) | `#16A34A` | `--indicator-green` | SYS <120 & DIA <80 |
| Kuning (Elevated) | `#CA8A04` | `--indicator-yellow` | SYS 120–129 & DIA <80 |
| Oranye (Stage 1) | `#EA580C` | `--indicator-orange` | SYS 130–139 atau DIA 80–89 |
| Merah (Stage 2/Krisis) | `#DC2626` | `--indicator-red` | SYS ≥140 atau DIA ≥90 |

### CSS Custom Properties

```css
:root {
  --color-primary: #0C4A6E;
  --color-primary-light: #0284C7;
  --color-accent: #0D9488;
  --color-sun: #F59E0B;
  --color-sand: #FDF6EC;
  --color-sky-light: #E0F2FE;
  --color-neutral-light: #F1F5F9;
  --color-text-primary: #0F172A;
  --color-text-secondary: #475569;
  --color-border: #CBD5E1;
  --color-white: #FFFFFF;

  --indicator-green: #16A34A;
  --indicator-yellow: #CA8A04;
  --indicator-orange: #EA580C;
  --indicator-red: #DC2626;
}
```

### Tailwind Configuration Snippet

```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#0C4A6E',
        'primary-light': '#0284C7',
        accent: '#0D9488',
        sun: '#F59E0B',
        sand: '#FDF6EC',
        'sky-light': '#E0F2FE',
        'neutral-light': '#F1F5F9',
        indicator: {
          green: '#16A34A',
          yellow: '#CA8A04',
          orange: '#EA580C',
          red: '#DC2626',
        },
        text: {
          primary: '#0F172A',
          secondary: '#475569',
        },
        border: '#CBD5E1',
      },
    },
  },
};
```

## Typography

### Font Families

| Penggunaan | Font | Catatan |
|:---|:---|:---|
| Headings & Body | **Plus Jakarta Sans** | Font Indonesia open-source, ramah & modern; di-bundle sebagai aset aplikasi (bukan dari jaringan, demi offline) |
| Angka tensi (tabular) | Plus Jakarta Sans (feature tabular-nums) | Penting: angka sejajar agar mudah dibandingkan |
| Fallback | -apple-system, Segoe UI, sans-serif | Untuk sistem/emulator |

### Font Size Scale

| Elemen | Ukuran | Line Height | Berat | Penggunaan |
|:---|:---|:---|:---|:---|
| H1 (Hero/Beranda) | 28px / 1.75rem | 1.2 | 800 | Judul besar di layar utama |
| H2 (Section) | 24px / 1.5rem | 1.3 | 700 | Judul section |
| H3 (Subsection) | 20px / 1.25rem | 1.4 | 700 | Subjudul, kartu |
| Body Besar | 18px / 1.125rem | 1.5 | 400 | Teks utama aplikasi (baca nyaman) |
| Body Reguler | 16px / 1rem | 1.5 | 400 | Minimum untuk konten |
| Caption | 14px / 0.875rem | 1.4 | 500 | Metadata, label kecil |
| Status Label | 20px / 1.25rem | 1.2 | 800 | Label status warna (mis. "Waspada") |

> **Aturan offline:** font & aset tidak boleh diambil dari CDN pada aplikasi mobile; di-bundle dalam instalasi.

## Komponen & Spacing

### Grid & Unit Spacing

**Base Unit:** 8px. Semua spacing kelipatan 8 untuk ritme visual konsisten.

| Token | Nilai | Penggunaan |
|:---|:---|:---|
| sm | 8px | Gap kecil, ikon |
| md | 16px | Padding default, kartu kecil |
| lg | 24px | Padding kartu, section |
| xl | 32px | Jarak antar section besar |
| 2xl | 48px | Header/hero |

### Border Radius

| Ukuran | Nilai | Penggunaan |
|:---|:---|:---|
| sm | 8px | Input, chip |
| md | 12px | Kartu, tombol |
| lg | 16px | Kartu besar, modal |
| full | 9999px | Badge, avatar, lingkaran roda |

### Komponen Standar

| Komponen | Padding | Radius | Min Ukuran |
|:---|:---|:---|:---|
| Tombol Utama | 16px 24px | 12px | 56px tinggi |
| Tombol Sekunder | 12px 20px | 12px | 48px tinggi |
| Input | 16px 20px | 12px | 56px tinggi |
| Kartu Status | 20px | 16px | — |
| Badge Indikator | 8px 12px | full | 40px tinggi |
| Target Sentuh | — | — | **≥ 48×48px** |

## Responsive Breakpoints

| Breakpoint | Lebar | Prefix | Penggunaan |
|:---|:---|:---|:---|
| Mobile | 320–767px | (default) | Mobile-first; ukuran utama aplikasi |
| Tablet | 768–1023px | `md:` | Web admin & booklet web |
| Desktop | 1024px+ | `lg:` | Web admin |

## Screen Priorities

### Aplikasi Mobile (Urutan Prioritas Pengguna)
1. **Beranda / Status Hari Ini** — roda ROTASI besar dengan status terakhir, tombol "Ukur Tensi" dominan.
2. **Sesi Pengukuran Tensi** — panduan langkah, 2x input, jeda timer, hasil warna.
3. **Grafik Tren** — riwayat pagi/sore dengan ambang warna.
4. **Ceklis Harian** — gejala bahaya & gerakan janin.
5. **Pustaka Edukasi** — booklet PDF offline (preeklamsia, nutrisi DASH, 1000 HPK, stres, pascapersalinan).
6. **Rujukan & Kontak** — panduan "kapan ke faskes" + daftar bidan (pilih via WA) & ambulance.
7. **Latihan Napas 4-2-6** — timer visual.
8. **Registrasi Biodata** — form sederhana pertama kali.
9. **Status Sinkron** — indikator kecil di beranda (tersinkron/menunggu).

### Web Admin (Urutan Prioritas Admin)
1. **Login** — ringkas & aman.
2. **Dashboard** — statistik riset + tautan cepat.
3. **Booklet** — daftar riwayat + unggah PDF + set aktif.
4. **Rilis APK** — unggah, set aktif.
5. **Bidan** — CRUD data bidan (nama, jabatan, no WA, jadwal, aktif).
6. **Pengaturan Global** — kontak darurat, puskesmas.
7. **Data Riset** — pasien tersinkron & log sinkronisasi.

## Interaction & Motion

### Hover/Active States (Web Admin)

| Elemen | Efek | Transisi | Penggunaan |
|:---|:---|:---|:---|
| Tombol Utama | bg `#0C4A6E` → `#075985`, shadow lift | 200ms ease-out | Aksi utama |
| Tautan | warna `#0284C7` → `#0D9488` | 150ms ease-out | Navigasi, tautan |
| Kartu | shadow 1px → 8px, scale 1.02 | 250ms ease-out | Daftar booklet/rilis |
| Input (focus) | border `#CBD5E1` → `#0284C7` + ring | 150ms ease-out | Form |

### Transisi & Animasi

| Animasi | Durasi | Trigger | Penggunaan |
|:---|:---|:---|:---|
| Fade-In | 300ms | Route change | Perpindahan layar |
| Slide-Up | 400ms | Beranda load | Elemen hero/roda |
| Pulse (roda) | 1s | Timer napas | Fase tarik/tahan/buang |
| Toast | 300ms in/out | Submit form | Feedback aksi |
| Skeleton | 1.5s | Loading | Booklet/rilis |

### Motion Principles
- **Umpan balik cepat:** tombol & input merespons dalam 150–200ms.
- **Animası halus:** durasi 300ms, tanpa distraksi.
- **Aksesibilitas:** hormati `prefers-reduced-motion`.

```css
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## Aksesibilitas

### Kontras (WCAG AA)

| Pasangan Warna | Rasio | Level | Penggunaan |
|:---|:---|:---|:---|
| Teks Utama (#0F172A) on Putih | 16:1 | AAA | Konten utama |
| Putih on Biru Laut (#0C4A6E) | 9:1 | AAA | Tombol utama |
| Merah Indikator (#DC2626) on Putih | 4.9:1 | AA | Status merah |
| Oranye (#EA580C) on Putih | 3.6:1 | AA (teks besar) | Status oranye — selalu disertai ikon+teks |
| Kuning (#CA8A04) on Putih | 3.4:1 | AA (teks besar) | Status kuning — selalu disertai ikon+teks |

> **Penting:** warna indikator TIDAK boleh menjadi satu-satunya pembeda status. Setiap status wajib memiliki **label teks** (Normal/Waspada/Berisiko/Bahaya) + **ikon** + **warna**.

### Navigasi Keyboard (Web Admin)
- Tab order logis; focus ring 2px `#0284C7`; skip link "Langsung ke konten"; form label eksplisit; modal trap focus + Escape; error via `aria-live`.

### Checklist Aksesibilitas Developer
- [ ] Semua status ROTASI punya label teks + ikon + warna (bukan warna saja).
- [ ] Kontras ≥ 4.5:1 teks normal, ≥ 3:1 teks besar.
- [ ] Target sentuh mobile ≥ 48×48px.
- [ ] Gambar punya alt text deskriptif.
- [ ] Hierarki heading benar (H1→H2→H3).
- [ ] Animasi hormati `prefers-reduced-motion`.
- [ ] Form error jelas & terdengar via screen reader.

---

**Document Version:** 1.0
**Last Updated:** 2026
**Status:** Siap Pengembangan