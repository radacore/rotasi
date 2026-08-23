import 'package:flutter/material.dart';

import '../../core/sync/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../breathing/breathing_page.dart';
import '../measurement/bp_repository.dart';
import '../midwife/midwife_page.dart';
import '../referral/referral_page.dart';
import '../registration/data_ibu_page.dart';
import '../registration/patient_repository.dart';
import '../reminder/reminder_page.dart';

/// Halaman "Lainnya" — fitur sekunder yang dikelompokkan per kategori.
///
/// Diakses lewat ikon menu di AppBar Beranda agar 5 menu utama tetap
/// menjadi satu-satunya navigasi utama (DESIGN_SYSTEM.md).
class MorePage extends StatefulWidget {
  const MorePage({
    super.key,
    this.repository,
    this.bpRepository,
    this.syncService,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;
  final SyncService? syncService;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  late final SyncService _syncService;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncService = widget.syncService ?? SyncService();
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(_instantRoute(page));
  }

  static Route<T> _instantRoute<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => page,
      );

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final summary = await _syncService.syncAll();
    if (!mounted) return;
    setState(() => _syncing = false);
    final message = summary.sent == 0 && summary.failed == 0
        ? 'Semua data sudah tersinkron.'
        : summary.failed == 0
            ? 'Sinkron selesai: ${summary.sent} data terkirim.'
            : 'Sinkron selesai: ${summary.sent} terkirim, '
                '${summary.failed} gagal (dicoba lagi nanti).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final patientRepository = widget.repository ?? PatientRepository();
    final bpRepo = widget.bpRepository ?? BpRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _CategoryTitle('Data & Profil'),
          _MoreTile(
            icon: Icons.person_outline,
            title: 'Data Ibu',
            subtitle: 'Lihat dan ubah profil serta skrining risiko.',
            onTap: () => _push(
              context,
              DataIbuPage(
                repository: patientRepository,
                bpRepository: bpRepo,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _CategoryTitle('Kesehatan & Kebiasaan'),
          _MoreTile(
            icon: Icons.air,
            title: 'Latihan Napas',
            subtitle: 'Relaksasi dan teknik napas saat kontraksi.',
            onTap: () => _push(context, const BreathingPage()),
          ),
          const SizedBox(height: 12),
          _MoreTile(
            icon: Icons.notifications_active_outlined,
            title: 'Pengingat',
            subtitle: 'Atur pengingat pagi & sore.',
            onTap: () => _push(context, const ReminderPage()),
          ),
          const SizedBox(height: 20),
          const _CategoryTitle('Bantuan & Kontak'),
          _MoreTile(
            icon: Icons.emergency_outlined,
            title: 'Rujukan & Darurat',
            subtitle: 'Info rujukan dan kontak darurat.',
            onTap: () => _push(context, const ReferralPage()),
          ),
          const SizedBox(height: 12),
          _MoreTile(
            icon: Icons.medical_services_outlined,
            title: 'Hubungi Bidan',
            subtitle: 'Kontak dan jadwal bidan pendamping.',
            onTap: () => _push(context, const MidwifePage()),
          ),
          const SizedBox(height: 20),
          const _CategoryTitle('Sinkronisasi'),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.skyLight,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.cloud_done_outlined, color: AppColors.primaryLight),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Data tersimpan otomatis di HP dan akan terkirim saat ada internet. '
                      'Tidak perlu sinkron manual — gunakan tombol di bawah hanya jika ingin memastikan.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Menyinkron…' : 'Sinkron Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  const _CategoryTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.skyLight,
          child: Icon(icon, color: AppColors.primaryLight),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
