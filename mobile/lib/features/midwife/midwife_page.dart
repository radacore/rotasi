import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../measurement/bp_repository.dart';
import '../registration/patient_repository.dart';
import 'midwife.dart';
import 'midwife_repository.dart';

/// Hubungi Bidan via WhatsApp (FR-11).
///
/// Daftar bidan aktif dicache offline; pesan awal berisi ringkasan status
/// terakhir (nama ibu, tanggal, status warna).
class MidwifePage extends StatefulWidget {
  const MidwifePage({
    super.key,
    this.repository,
    this.messageBuilder,
    this.onLaunch,
  });

  final MidwifeRepository? repository;

  /// Membangun ringkasan status untuk pesan awal (uji/injeksi).
  final Future<String> Function()? messageBuilder;

  /// Hook untuk uji: membuka tautan (default pakai url_launcher).
  final Future<void> Function(String url)? onLaunch;

  @override
  State<MidwifePage> createState() => _MidwifePageState();
}

class _MidwifePageState extends State<MidwifePage> {
  late final MidwifeRepository _repository;
  List<Midwife> _midwives = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MidwifeRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final local = await _repository.getLocal();
    final remote = await _repository.fetchRemote();
    if (!mounted) return;
    setState(() {
      _midwives = remote.isNotEmpty ? remote : local;
      _loading = false;
    });
  }

  Future<String> _buildSummary() async {
    final builder = widget.messageBuilder;
    if (builder != null) return builder();
    final patient = await PatientRepository().getLocal();
    final bp = await BpRepository().last();
    final name = patient?.name ?? 'ibu hamil';
    if (bp == null) {
      return 'Saya $name. Ingin konsultasi status kehamilan saya.';
    }
    final date = DateFormat('dd MMM yyyy').format(bp.measuredAt.toLocal());
    return 'Saya $name. Tekanan darah terakhir ($date) '
        '${bp.status.label} (${bp.avgSystolic}/${bp.avgDiastolic} mmHg). '
        'Mohon arahannya.';
  }

  Future<void> _chat(Midwife midwife) async {
    final summary = await _buildSummary();
    final message = 'Halo Bidan ${midwife.name}, $summary';
    final uri = Uri.parse('https://wa.me/${midwife.waNumber}')
        .replace(queryParameters: {'text': message});
    try {
      final onLaunch = widget.onLaunch;
      if (onLaunch != null) {
        await onLaunch(uri.toString());
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Bidan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    color: AppColors.skyLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.chat_outlined,
                              color: AppColors.primaryLight),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Daftar bidan aktif. Tombol membuka WhatsApp '
                              'dengan pesan ringkasan status Anda.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_midwives.isEmpty)
                    _EmptyView(onRefresh: _load)
                  else
                    for (final m in _midwives) ...[
                      _MidwifeTile(midwife: m, onChat: () => _chat(m)),
                      const SizedBox(height: 8),
                    ],
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
            const Icon(Icons.person_off_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            const Text('Belum ada daftar bidan'),
            const SizedBox(height: 4),
            Text(
              'Hubungkan internet lalu muat ulang.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MidwifeTile extends StatelessWidget {
  const _MidwifeTile({required this.midwife, required this.onChat});

  final Midwife midwife;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.skyLight,
          child: const Icon(Icons.medical_services_outlined,
              color: AppColors.primary),
        ),
        title: Text(
          midwife.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: midwife.role.isEmpty
            ? null
            : Text(midwife.role),
        trailing: FilledButton.tonalIcon(
          onPressed: onChat,
          icon: const Icon(Icons.chat, size: 18),
          label: const Text('Chat'),
        ),
      ),
    );
  }
}
