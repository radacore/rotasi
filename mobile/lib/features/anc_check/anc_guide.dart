import 'package:flutter/material.dart';

/// Satu bagian panduan (mis. Standar 10 T, Lab, USG).
class AncGuideSection {
  const AncGuideSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<AncGuideItem> items;
}

/// Satu poin dalam bagian panduan. [code] opsional, mis. "T1"–"T10".
class AncGuideItem {
  const AncGuideItem({
    this.code,
    required this.title,
    required this.description,
  });

  final String? code;
  final String title;
  final String description;
}

/// Konten panduan pemeriksaan kehamilan (ANC) — hardcoded sesuai standar
/// Kementerian Kesehatan (Kemenkes) yang sejalan dengan WHO:
/// ANC minimal 6 kali dengan standar 10 T, plus lab dan USG.
const ancGuideSections = <AncGuideSection>[
  AncGuideSection(
    icon: Icons.medical_services_outlined,
    title: 'Pemeriksaan Fisik Klinis & Medis (Standar 10 T)',
    description: 'Setiap kali berkunjung ke bidan atau dokter spesialis '
        'kandungan (Sp.OG), ibu hamil akan menjalani pemeriksaan dasar berikut:',
    items: [
      AncGuideItem(
        code: 'T1',
        title: 'Timbang Berat Badan & Ukur Tinggi Badan',
        description: 'Memantau kecukupan nutrisi dan mencegah obesitas/kurang gizi.',
      ),
      AncGuideItem(
        code: 'T2',
        title: 'Ukur Tekanan Darah',
        description: 'Sangat krusial untuk mendeteksi dini hipertensi '
            'gestasional dan risiko preeklamsia (standar <140/90 mmHg).',
      ),
      AncGuideItem(
        code: 'T3',
        title: 'Ukur Lingkar Lengan Atas (LiLA)',
        description: 'Mendeteksi risiko Kurang Energi Kronis (KEK) yang '
            'memicu bayi lahir dengan berat rendah dan stunting.',
      ),
      AncGuideItem(
        code: 'T4',
        title: 'Ukur Tinggi Fundus Uteri (Puncak Rahim)',
        description: 'Memantau pertumbuhan ukuran janin di dalam kandungan.',
      ),
      AncGuideItem(
        code: 'T5',
        title: 'Tentukan Presentasi Janin & Denyut Jantung Janin (DJJ)',
        description: 'Mengetahui posisi bayi dan memastikan jantung janin '
            'berdetak sehat.',
      ),
      AncGuideItem(
        code: 'T6',
        title: 'Skrining Status Imunisasi Tetanus',
        description: 'Memberikan suntikan vaksin Tetanus Toksoid (TT) bila '
            'diperlukan.',
      ),
      AncGuideItem(
        code: 'T7',
        title: 'Pemberian Tablet Tambah Darah (TTD)',
        description: 'Ibu hamil wajib mengonsumsi minimal 90 tablet selama '
            'kehamilan untuk mencegah anemia.',
      ),
      AncGuideItem(
        code: 'T8',
        title: 'Tes Laboratorium',
        description: 'Pemeriksaan rutin & khusus (detail di bagian bawah).',
      ),
      AncGuideItem(
        code: 'T9',
        title: 'Tata Laksana / Penanganan Kasus',
        description: 'Penanganan medis segera jika ditemukan masalah kesehatan.',
      ),
      AncGuideItem(
        code: 'T10',
        title: 'Temu Wicara (Konseling/Edukasi)',
        description: 'Sesi diskusi mengenai gizi, kesiapan persalinan, dan '
            'tanda bahaya kehamilan.',
      ),
    ],
  ),
  AncGuideSection(
    icon: Icons.science_outlined,
    title: 'Pemeriksaan Laboratorium (Tes Darah & Urine)',
    description: 'Pemeriksaan penunjang ini biasanya diwajibkan minimal pada '
        'trimester pertama dan trimester ketiga:',
    items: [
      AncGuideItem(
        title: 'Golongan Darah & Rhesus',
        description: 'Mengantisipasi kebutuhan transfusi darah darurat dan '
            'mendeteksi ketidakcocokan rhesus ibu-janin.',
      ),
      AncGuideItem(
        title: 'Kadar Hemoglobin (Hb)',
        description: 'Mendeteksi anemia. Anemia parah dapat mengurangi suplai '
            'oksigen ke janin dan memicu hambatan pertumbuhan (stunting).',
      ),
      AncGuideItem(
        title: 'Tes Gula Darah (Glukosa)',
        description: 'Skrining terhadap Diabetes Melitus Gestasional '
            '(diabetes akibat kehamilan).',
      ),
      AncGuideItem(
        title: 'Tes Urine (Proteinuria & Glukosuria)',
        description: 'Adanya protein dalam urine merupakan indikator utama '
            'penyakit preeklamsia.',
      ),
      AncGuideItem(
        title: 'Skrining Penyakit Menular (Triple Elimination)',
        description: 'Tes wajib untuk mendeteksi HIV, Sifilis, dan Hepatitis B '
            '(HBsAg) guna mencegah penularan dari ibu ke janin.',
      ),
    ],
  ),
  AncGuideSection(
    icon: Icons.monitor_heart_outlined,
    title: 'Pemeriksaan Ultrasonografi (USG)',
    description: 'Berdasarkan aturan terbaru, ibu hamil disarankan melakukan '
        'USG minimal 2 kali yang ditangani langsung oleh dokter selama masa '
        'kehamilan:',
    items: [
      AncGuideItem(
        title: 'USG Trimester 1 (sebelum 12 minggu)',
        description: 'Mengonfirmasi kehamilan di dalam rahim, mendeteksi detak '
            'jantung janin dini, serta menentukan Hari Perkiraan Lahir (HPL) '
            'yang paling akurat.',
      ),
      AncGuideItem(
        title: 'USG Trimester 3 (sekitar 32–36 minggu)',
        description: 'Memantau pertumbuhan berat badan janin, memeriksa posisi '
            'plasenta (apakah menutupi jalan lahir), jumlah air ketuban, serta '
            'posisi bayi menjelang persalinan.',
      ),
    ],
  ),
];
