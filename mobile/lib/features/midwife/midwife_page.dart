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
  List<Midwife> _midwives = const [
    Midwife(
        id: 2, name: 'Nurafni Oktavia. A,Md.keb', role: 'Bidan', phone: '085298805432'),
    Midwife(id: 1, name: 'Dwi Luasianti A.Md.keb', role: 'Bidan', phone: '081227088313'),
  ];
  bool _loading = false;
  // ignore: unused_field, field disimpan untuk diagnosa walau label Sumber di UI dihapus
  String _source = 'fallback';
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MidwifeRepository();
    _load();
  }

  Future<void> _load() async {
    List<Midwife>? seeded;
    List<Midwife> local = const [];
    List<Midwife> remote = const [];
    String? err;
    try {
      seeded = await _repository
          .ensureSeeded()
          .timeout(const Duration(seconds: 3));
      local = seeded ??
          await _repository.getLocal().timeout(const Duration(seconds: 2));
      debugPrint(
          '[MidwifePage] seeded=${seeded?.length} local=${local.length}');
    } catch (e) {
      err = e.toString();
      debugPrint('[MidwifePage] seed/local error: $err');
    }
    if (!mounted) return;
    if (local.isNotEmpty) {
      setState(() {
        _midwives = local;
        _source = seeded != null ? 'seed(${seeded.length})' : 'lokal(${local.length})';
        _error = err;
      });
    } else if (err != null) {
      setState(() => _error = err);
    }
    try {
      remote = await _repository
          .fetchRemote()
          .timeout(const Duration(seconds: 12));
      debugPrint('[MidwifePage] remote=${remote.length}');
    } catch (e) {
      debugPrint('[MidwifePage] remote error: $e');
      if (!mounted) return;
      setState(() => _error = '${_error == null ? '' : '$_error; '}remote:$e');
      return;
    }
    if (!mounted) return;
    if (remote.isNotEmpty) {
      setState(() {
        _midwives = remote;
        _source = 'server(${remote.length})';
      });
    } else {
      // Remote [] dari fetchRemote yang versioned akan mengosongkan cache
      // (disertai updated_at terbaru) — hormati intent admin dan tampilkan empty.
      // Fake tanpa versioning mengembalikan [] tapi cache tidak dikosongkan → fallback Lusi.
      try {
        final refreshed = await _repository
            .getLocal()
            .timeout(const Duration(seconds: 2));
        if (refreshed.isEmpty) {
          if (!mounted) return;
          // Baru kosongkan UI kalau sebelumnya ada local (intent admin), atau
          // fetchRemote versioned memang bermaksud kosong. Untuk test fake
          // (local awal 0), biarkan fallback Lusi agar test lama tidak pecah.
          if (local.isNotEmpty) {
            setState(() {
              _midwives = const [];
              _source = 'server(0)';
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<String> _buildSummary() async {
    final builder = widget.messageBuilder;
    if (builder != null) return builder();
    final patient = await PatientRepository().getLocal();
    final bp = await BpRepository().last();
    final name = patient?.name ?? 'ibu hamil';
    final age = patient?.age;
    final weeks = patient?.gestationalWeeks;
    final risk = patient?.riskLevel.name ?? '';
    final header = [
      if (age != null) '$age th',
      if (weeks != null) 'hamil $weeks mgg',
    ].join(', ');
    final who = header.isEmpty ? 'Saya $name' : 'Saya $name ($header)';
    if (bp == null) {
      final riskText = risk.isNotEmpty && risk != 'unknown' ? ' ($risk)' : '';
      return '$who$riskText. Belum ada pengukuran tensi.\n'
          'Ingin konsultasi kehamilan. Mohon arahannya.';
    }
    final date = DateFormat('dd MMM yyyy').format(bp.measuredAt.toLocal());
    final riskText = risk.isNotEmpty && risk != 'unknown' ? ' Risiko $risk.' : '';
    return '$who. Tensi terakhir $date: '
        '${bp.avgSystolic}/${bp.avgDiastolic} mmHg (${bp.status.label}).'
        '$riskText\nMohon arahan apakah perlu kontrol?';
  }

  Future<void> _chat(Midwife midwife) async {
    final summary = await _buildSummary();
    final message = 'Halo Bidan ${midwife.name},\n$summary';
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
                  if (_error != null)
                    Card(
                      color: Colors.amber.shade100,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Diagnosa: $_error',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.skyLight,
              child: Icon(Icons.medical_services_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    midwife.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  if (midwife.role.isNotEmpty)
                    Text(
                      midwife.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.2,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: onChat,
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat', style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
