import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Menampilkan PDF booklet penuh dari file lokal (FR-09).
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
  PdfController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : PdfView(controller: _controller!),
    );
  }
}
