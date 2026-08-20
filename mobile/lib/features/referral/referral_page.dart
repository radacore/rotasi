import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'referral_settings.dart';
import 'setting_repository.dart';

/// Panduan Rujukan & Kontak Darurat (FR-10).
class ReferralPage extends StatefulWidget {
  const ReferralPage({
    super.key,
    this.repository,
    this.onLaunch,
  });

  final SettingRepository? repository;

  /// Hook untuk uji: membuka tautan (default pakai url_launcher).
  final Future<void> Function(String url)? onLaunch;

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  late final SettingRepository _repository;
  ReferralSettings? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SettingRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final local = await _repository.getLocal();
    final remote = await _repository.fetchRemote();
    if (!mounted) return;
    setState(() {
      _settings = remote ?? local;
      _loading = false;
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final onLaunch = widget.onLaunch;
      if (onLaunch != null) {
        await onLaunch(uri.toString());
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      // Telpon tidak tersedia; abaikan.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan Rujukan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _DisclaimerCard(),
                  const SizedBox(height: 12),
                  if (_settings == null)
                    _OfflineEmpty(onRefresh: _load)
                  else ...[
                    _ReferralCriteria(rules: _settings!.rules),
                    const SizedBox(height: 12),
                    _ContactCard(
                      settings: _settings!,
                      onCall: _call,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.sand,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.health_and_safety_outlined, color: AppColors.sun),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aplikasi pendamping, bukan pengganti pemeriksaan ANC. '
                'Segera ke faskes bila ada keluhan atau hasil yang '
                'mencurigakan.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineEmpty extends StatelessWidget {
  const _OfflineEmpty({required this.onRefresh});

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
            const Text('Belum ada panduan rujukan'),
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

class _ReferralCriteria extends StatelessWidget {
  const _ReferralCriteria({required this.rules});

  final ReferralRules rules;

  @override
  Widget build(BuildContext context) {
    final colorLabel = rules.persistentColors
        .map((c) => c == 'red' ? 'merah' : 'oranye')
        .join('/');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kapan harus segera ke faskes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _CriteriaRow(
              icon: Icons.monitor_heart_outlined,
              color: AppColors.crisis,
              text:
                  'Tekanan darah ${colorLabel.isEmpty ? 'tinggi' : colorLabel} '
                  'berulang pada pemeriksaan berikutnya',
            ),
            _CriteriaRow(
              icon: Icons.warning_amber_outlined,
              color: AppColors.crisis,
              text:
                  rules.symptomCheckTrigger
                  ? 'Ada minimal satu tanda bahaya pada cek gejala harian'
                  : 'Ada tanda bahaya yang menetap',
            ),
            _CriteriaRow(
              icon: Icons.child_care_outlined,
              color: AppColors.crisis,
              text:
                  'Gerakan janin kurang aktif '
                  '(${rules.kickThreshold} gerakan atau kurang dalam 30 menit)',
            ),
          ],
        ),
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  const _CriteriaRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.settings, required this.onCall});

  final ReferralSettings settings;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final hasEmergency = settings.emergencyPhone.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontak darurat',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_hospital_outlined,
                  color: AppColors.crisis),
              title: const Text('Darurat / Ambulans'),
              subtitle: hasEmergency
                  ? Text(settings.emergencyPhone)
                  : Text(
                      'Belum diatur pengelola',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
              trailing: hasEmergency
                  ? FilledButton.icon(
                      onPressed: () => onCall(settings.emergencyPhone),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Panggil'),
                    )
                  : null,
            ),
            const Divider(height: 1),
            if (settings.puskesmasName.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_hospital_outlined,
                    color: AppColors.primary),
                title: Text(settings.puskesmasName),
                subtitle: settings.puskesmasAddress.isEmpty
                    ? null
                    : Text(settings.puskesmasAddress),
              ),
          ],
        ),
      ),
    );
  }
}
