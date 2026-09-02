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
  ReferralSettings? _settings = const ReferralSettings(
    appName: 'ROTASI',
    emergencyPhone: '119',
    ambulancePhone: '119',
    homecarePhone: '112',
    puskesmasPhone: '081343677797',
    puskesmasPhoneAlt: '0812417777718',
    puskesmasName: 'Puskesmas Barombong',
    puskesmasAddress:
        'Jl. Perjanjian Bongaya, Barombong, Kec. Tamalate, Kota Makassar, Sulawesi Selatan 90225',
    rules: ReferralRules(
      persistentColors: ['orange', 'red'],
      symptomCheckTrigger: true,
      kickThreshold: 3,
    ),
  );
  bool _loading = false;
  // ignore: unused_field, disimpan untuk debug walau label UI dihapus
  String _source = 'fallback';
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SettingRepository();
    // Tampilkan fallback langsung (anti blank), lalu refresh di background.
    _load();
  }

  Future<void> _load() async {
    ReferralSettings? seeded;
    ReferralSettings? local;
    ReferralSettings? remote;
    String? err;
    try {
      seeded = await _repository
          .ensureSeeded()
          .timeout(const Duration(seconds: 3));
      local = seeded ??
          await _repository.getLocal().timeout(const Duration(seconds: 2));
      debugPrint(
          '[ReferralPage] seeded=${seeded != null} local=${local != null} puskes=${local?.puskesmasName} phone=${local?.emergencyPhone}');
    } catch (e) {
      err = e.toString();
      debugPrint('[ReferralPage] seed/local error: $err');
    }
    if (!mounted) return;
    if (local != null) {
      setState(() {
        _settings = local;
        _source = seeded != null ? 'seed' : 'lokal';
        _error = err;
      });
    } else if (err != null) {
      setState(() => _error = err);
    }
    try {
      remote = await _repository
          .fetchRemote()
          .timeout(const Duration(seconds: 12));
      debugPrint(
          '[ReferralPage] remote puskes=${remote?.puskesmasName} phone=${remote?.emergencyPhone}');
    } catch (e) {
      debugPrint('[ReferralPage] remote error: $e');
      if (!mounted) return;
      setState(() => _error = '${_error == null ? '' : '$_error; '}remote:$e');
      return;
    }
    if (!mounted) return;
    if (remote != null) {
      setState(() {
        _settings = remote;
        _source = 'server';
      });
    }
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
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.health_and_safety_outlined,
                color: AppColors.sun, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pendamping ANC, bukan pengganti pemeriksaan. '
                'Segera ke faskes bila ada keluhan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kapan harus segera ke faskes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 6),
            _CriteriaRow(
              icon: Icons.monitor_heart_outlined,
              color: AppColors.crisis,
              text: colorLabel.isEmpty
                  ? 'Tensi tinggi berulang'
                  : 'Tensi $colorLabel berulang',
            ),
            _CriteriaRow(
              icon: Icons.warning_amber_outlined,
              color: AppColors.crisis,
              text: rules.symptomCheckTrigger
                  ? 'Ada tanda bahaya (cek gejala)'
                  : 'Tanda bahaya menetap',
            ),
            _CriteriaRow(
              icon: Icons.child_care_outlined,
              color: AppColors.crisis,
              text: 'Gerakan janin ≤${rules.kickThreshold}/30 menit',
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
            ),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontak darurat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 10),
            _PhoneRow(
              label: 'Call Center Ambulans Makassar',
              phone: settings.ambulancePhone.isNotEmpty
                  ? settings.ambulancePhone
                  : settings.emergencyPhone,
              onCall: onCall,
            ),
            const SizedBox(height: 10),
            _PhoneRow(
              label: "Home Care Dottoro'ta",
              phone: settings.homecarePhone,
              onCall: onCall,
            ),
            if (settings.puskesmasName.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                'Nama Puskesmas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                settings.puskesmasName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
            if (settings.puskesmasAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Alamat Puskesmas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                settings.puskesmasAddress,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.35,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.label,
    required this.phone,
    required this.onCall,
  });

  final String label;
  final String phone;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.isNotEmpty;
    return Row(
      children: [
        const Icon(Icons.call_outlined, color: AppColors.crisis, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                hasPhone ? phone : 'Belum diatur pengelola',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
        if (hasPhone) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => onCall(phone),
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Panggil', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}
