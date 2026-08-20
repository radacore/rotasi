import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../anc_check/anc_check_page.dart';
import '../anc_check/anc_guide_page.dart';
import '../kick_count/kick_count_page.dart';
import '../symptom_check/symptom_check_page.dart';

/// Tab "Pantau" — pemantauan harian: gejala bahaya, gerakan janin, 10T ANC.
class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantau')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MonitorTile(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Cek Gejala Harian',
            subtitle: 'Sakit kepala, pandangan kabur, nyeri ulu hati, sesak napas.',
            page: SymptomCheckPage(),
          ),
          SizedBox(height: 12),
          _MonitorTile(
            icon: Icons.child_care,
            title: 'Hitung Gerakan Janin',
            subtitle: 'Hitung tendangan dalam 30 menit.',
            page: KickCountPage(),
          ),
          SizedBox(height: 12),
          _MonitorTile(
            icon: Icons.checklist_outlined,
            title: 'Ceklis 10T ANC',
            subtitle: 'Pemeriksaan antenatal standar 10T.',
            page: AncCheckPage(),
          ),
          SizedBox(height: 12),
          _MonitorTile(
            icon: Icons.menu_book_outlined,
            title: 'Panduan Pemeriksaan',
            subtitle: '10T, lab, dan USG — ANC minimal 6 kali.',
            page: AncGuidePage(),
          ),
        ],
      ),
    );
  }
}

class _MonitorTile extends StatelessWidget {
  const _MonitorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
