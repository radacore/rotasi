import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/theme/app_theme.dart';

/// Nama route viewer booklet, dipakai observer untuk menyembunyikan tombol
/// mengambang "Hubungi Bidan" saat booklet dibuka.
const bookletViewerRouteName = '/booklet-viewer';

/// Render cepat halaman PDF: resolusi cukup untuk layar agar swipe terasa instan.
Future<PdfPageImage?> _fastRenderer(PdfPage page) => page.render(
      width: page.width * 1.5,
      height: page.height * 1.5,
      format: PdfPageImageFormat.jpeg,
      quality: 85,
      backgroundColor: '#FFFFFF',
    );

/// Menampilkan PDF booklet sebagai halaman geser (swipe samping) dengan
/// tombol next/prev dan pencarian nomor halaman (FR-09).
class BookletViewerPage extends StatefulWidget {
  const BookletViewerPage({
    super.key,
    required this.title,
    required this.path,
  });

  final String title;
  final String path;

  @override
  State<BookletViewerPage> createState() => _BookletViewerPageState();
}

class _BookletViewerPageState extends State<BookletViewerPage> {
  late final PdfController _controller;
  PdfDocument? _document;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(document: PdfDocument.openFile(widget.path));
  }

  @override
  void dispose() {
    _controller.dispose();
    _document?.close();
    super.dispose();
  }

  Future<void> _openPageSearch() async {
    final total = _controller.pagesCount;
    if (total == null) return;
    final fieldController = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lompat ke halaman'),
        content: TextField(
          controller: fieldController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 – $total',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(fieldController.text)),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
    if (value == null) return;
    _controller.jumpToPage(value.clamp(1, total));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: AppColors.neutralLight,
      body: Column(
        children: [
          Expanded(
            child: PdfView(
              controller: _controller,
              renderer: _fastRenderer,
              onDocumentLoaded: (document) {
                _document = document;
                setState(() {});
              },
              backgroundDecoration:
                  const BoxDecoration(color: AppColors.neutralLight),
            ),
          ),
          _BottomControls(
            controller: _controller,
            onSearch: _openPageSearch,
          ),
        ],
      ),
    );
  }
}

/// Bar kendali bawah: tombol prev, indikator + pencarian halaman, tombol next.
class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.controller, required this.onSearch});

  final PdfController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.pageListenable,
      builder: (context, page, _) {
        final total = controller.pagesCount;
        return Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Halaman sebelumnya',
                    onPressed: page > 1
                        ? () => controller.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  InkWell(
                    onTap: onSearch,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '$page / ${total ?? '…'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Halaman berikutnya',
                    onPressed: total != null && page < total
                        ? () => controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
