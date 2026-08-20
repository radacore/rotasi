import 'package:flutter/material.dart';
import 'package:flutter_pdf_flipbook/flutter_pdf_flipbook.dart';

import '../../core/theme/app_theme.dart';

/// Nama route viewer booklet, dipakai observer untuk menyembunyikan tombol
/// mengambang "Hubungi Bidan" saat booklet dibuka.
const bookletViewerRouteName = '/booklet-viewer';

/// Menampilkan PDF booklet full sebagai buku flip (efek 3D + zoom) dari file lokal (FR-09).
class BookletViewerPage extends StatelessWidget {
  const BookletViewerPage({
    super.key,
    required this.title,
    required this.path,
  });

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.neutralLight,
      body: PdfBookViewer(
        pdfUrl: path,
        filePath: path,
        backgroundColor: AppColors.neutralLight,
        style: PdfBookViewerStyle(
          loadingIndicatorColor: AppColors.primary,
        ),
      ),
    );
  }
}
