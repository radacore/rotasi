import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    setState(() => _loading = true);
    final local = await _repository.getLocal();
    final remote = await _repository.fetchRemote();
    if (!mounted) return;
    setState(() {
      _booklet = remote.meta ?? local;
      _needsDownload = remote.needsDownload;
      _loading = false;
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
    Navigator.of(context).push(
      MaterialPageRoute(
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

  String _formatBytes(int? bytes) {
    if (bytes == null) return '';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final available = booklet.isDownloaded && !needsDownload;
    final uploaded = booklet.uploadedAt == null
        ? ''
        : DateFormat('dd MMM yyyy').format(booklet.uploadedAt!.toLocal());

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 36, color: AppColors.crisis),
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
                      const SizedBox(height: 2),
                      Text(
                        'Versi ${booklet.version}'
                        '${uploaded.isEmpty ? '' : ' · $uploaded'}'
                        '${_formatBytes(booklet.fileSize).isEmpty ? '' : ' · ${_formatBytes(booklet.fileSize)}'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
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
            else if (available)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Buka PDF'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Periksa pembaruan',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
    );
  }
}
