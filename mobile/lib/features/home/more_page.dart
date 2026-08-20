import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../breathing/breathing_page.dart';
import '../measurement/bp_repository.dart';
import '../midwife/midwife_page.dart';
import '../referral/referral_page.dart';
import '../registration/patient_repository.dart';
import '../registration/registration_page.dart';
import '../reminder/reminder_page.dart';

/// Halaman "Lainnya" — fitur sekunder yang dikelompokkan per kategori.
///
/// Diakses lewat ikon menu di AppBar Beranda agar 5 menu utama tetap
/// menjadi satu-satunya navigasi utama (DESIGN_SYSTEM.md).
class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.repository,
    this.bpRepository,
  });

  final PatientRepository? repository;
  final BpRepository? bpRepository;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final patientRepository = repository ?? PatientRepository();
    final bpRepo = bpRepository ?? BpRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _CategoryTitle('Data & Profil'),
          _MoreTile(
            icon: Icons.person_outline,
            title: 'Data Ibu',
            subtitle: 'Kelola profil dan skrining risiko.',
            onTap: () => _push(
              context,
              RegistrationPage(
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
