import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/theme/app_theme.dart';
import 'booklet.dart';
import 'booklet_repository.dart';
import 'booklet_viewer_page.dart';

/// Pustaka Edukasi offline (FR-09).
///
/// Menampilkan booklet aktif; PDF diunduh sekali saat online lalu tersedia
/// penuh tanpa jaringan. Versi baru otomatis diunduh bila berubah.
class EducationPage extends StatefulWidget {
  const EducationPage({super.key, this.repository});

  final BookletRepository? repository;

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  late final BookletRepository _repository;
  Booklet? _booklet;
  bool _loading = true;
  bool _downloading = false;
  bool _needsDownload = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookletRepository();
    _load();
  }

  Future<void> _load() async {
    if (_booklet == null) setState(() => _loading = true);
    final seeded = await _repository.ensureSeeded();
    final local = seeded ?? await _repository.getLocal();
    if (!mounted) return;
    setState(() {
      if (local != null) _booklet = local;
      _loading = false;
    });
    final remote = await _repository.fetchRemote();
    if (!mounted) return;
    setState(() {
      _booklet = remote.meta ?? _booklet;
      _needsDownload = remote.needsDownload;
    });
  }

  Future<void> _download() async {
    final meta = _booklet;
    if (meta == null) return;
    setState(() => _downloading = true);
    final updated = await _repository.download(meta);
    if (!mounted) return;
    setState(() {
      _downloading = false;
      if (updated != null) {
        _booklet = updated;
        _needsDownload = false;
      }
    });
  }

  void _open() {
    final path = _booklet?.localPath;
    if (path == null) return;
    // Push lewat root navigator agar layar full (bottom nav & FAB tertutup)
    // dan observer bisa menyembunyikan tombol "Hubungi Bidan".
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: bookletViewerRouteName),
        builder: (_) => BookletViewerPage(
          title: _booklet!.title,
          path: path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pustaka Edukasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CoverageCard(),
                  const SizedBox(height: 12),
                  if (_booklet == null)
                    _EmptyView(onRefresh: _load)
                  else
                    _BookletCard(
                      booklet: _booklet!,
                      needsDownload: _needsDownload,
                      downloading: _downloading,
                      onDownload: _download,
                      onOpen: _open,
                      onRefresh: _load,
                    ),
                ],
              ),
            ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.skyLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.menu_book_outlined, color: AppColors.primaryLight),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Materi: preeklamsia & stunting, nutrisi DASH, '
                '1000 HPK, manajemen stres, dan pascapersalinan. '
                'Bisa dibuka tanpa internet setelah diunduh.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            const Text('Belum ada booklet aktif'),
            const SizedBox(height: 4),
            Text(
              'Hubungkan internet lalu periksa pembaruan.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Periksa Pembaruan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookletCard extends StatelessWidget {
  const _BookletCard({
    required this.booklet,
    required this.needsDownload,
    required this.downloading,
    required this.onDownload,
    required this.onOpen,
    required this.onRefresh,
  });

  final Booklet booklet;
  final bool needsDownload;
  final bool downloading;
  final VoidCallback onDownload;
  final VoidCallback onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final available = booklet.isDownloaded && !needsDownload;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookletCover(path: available ? booklet.localPath : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booklet.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        available
                            ? Icons.offline_pin_outlined
                            : Icons.download_for_offline_outlined,
                        color: available
                            ? AppColors.normal
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        available
                            ? 'Tersedia offline'
                            : 'Perlu diunduh agar bisa dibuka offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: available
                                  ? AppColors.normal
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (downloading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Mengunduh PDF…'),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: available
                              ? ElevatedButton.icon(
                                  onPressed: onOpen,
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Buka Booklet'),
                                )
                              : OutlinedButton.icon(
                                  onPressed: onDownload,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Unduh PDF'),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Periksa pembaruan',
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sampul booklet = halaman pertama PDF lokal, dirender sebagai pratinjau.
///
/// Menampilkan placeholder bila file belum diunduh atau gagal dirender.
class _BookletCover extends StatefulWidget {
  const _BookletCover({required this.path});

  final String? path;

  @override
  State<_BookletCover> createState() => _BookletCoverState();
}

class _BookletCoverState extends State<_BookletCover> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_BookletCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final path = widget.path;
    if (path == null) return;
    try {
      final doc = await PdfDocument.openFile(path);
      final page = await doc.getPage(1);
      final scale = 1.2;
      final image = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      await doc.close();
      if (!mounted) return;
      setState(() => _bytes = image?.bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        child: AspectRatio(
          aspectRatio: 1 / 1.4142,
          child: bytes == null
              ? _placeholder(context)
              : Image.memory(bytes, fit: BoxFit.fill),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: _failed ? AppColors.neutralLight : AppColors.skyLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: _failed ? AppColors.textSecondary : AppColors.primaryLight,
          ),
          const SizedBox(height: 4),
          Text(
            _failed ? 'Sampul tidak tersedia' : 'Booklet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _failed
                      ? AppColors.textSecondary
                      : AppColors.primaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
