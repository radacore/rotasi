import 'package:flutter/material.dart';

import '../../core/notifications/notification_scheduler.dart';
import 'reminder_repository.dart';
import 'reminder_settings.dart';

/// Halaman pengaturan pengingat lokal (FR-14).
///
/// Notifikasi dijadwalkan lewat plugin lokal sehingga tetap berjalan tanpa
/// koneksi (bukan push cloud). Waktu pagi & sore dapat diatur pengguna.
class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key, this.repository, this.scheduler});

  final ReminderRepository? repository;
  final NotificationScheduler? scheduler;

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  static const _morningId = 1;
  static const _eveningId = 2;

  late final ReminderRepository _repository;
  late final NotificationScheduler _scheduler;
  ReminderSettings? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ReminderRepository();
    _scheduler = widget.scheduler ?? LocalNotificationScheduler();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.getLocal();
    if (!mounted) return;
    setState(() => _settings = settings ?? const ReminderSettings());
  }

  Future<void> _pickTime({required bool morning}) async {
    final current = morning ? _settings!.morning : _settings!.evening;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    setState(() {
      _settings = _settings!.copyWith(
        morning: morning ? picked : _settings!.morning,
        evening: morning ? _settings!.evening : picked,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = _settings!;
    if (settings.enabled) {
      await _scheduler.schedule(
        id: _morningId,
        title: 'Ukur Tensi Pagi',
        body: 'Waktunya mengukur tekanan darah pagi. Jangan lupa istirahat dulu ya.',
        hour: settings.morning.hour,
        minute: settings.morning.minute,
      );
      await _scheduler.schedule(
        id: _eveningId,
        title: 'Ukur Tensi Sore',
        body: 'Waktunya mengukur tekanan darah sore. Jangan lupa istirahat dulu ya.',
        hour: settings.evening.hour,
        minute: settings.evening.minute,
      );
    } else {
      await _scheduler.cancel(_morningId);
      await _scheduler.cancel(_eveningId);
    }
    await _repository.save(settings);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(settings.enabled
            ? 'Pengingat diaktifkan untuk pagi & sore.'
            : 'Pengingat dimatikan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Pengukuran')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pengingat berjalan tanpa koneksi (notifikasi lokal) '
                            'setiap hari pada waktu yang kamu atur.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: settings.enabled,
                  onChanged: _saving
                      ? null
                      : (v) => setState(
                          () => _settings = settings.copyWith(enabled: v)),
                  title: const Text('Aktifkan pengingat'),
                  subtitle: const Text('Ukur tensi 2x sehari, pagi & sore'),
                  secondary: const Icon(Icons.alarm),
                ),
                const SizedBox(height: 8),
                ListTile(
                  enabled: settings.enabled && !_saving,
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Waktu pagi'),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatTimeOfDay(settings.morning),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _pickTime(morning: true),
                ),
                ListTile(
                  enabled: settings.enabled && !_saving,
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: const Text('Waktu sore'),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatTimeOfDay(settings.evening),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _pickTime(morning: false),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan…' : 'Simpan Pengaturan'),
                ),
              ],
            ),
    );
  }
}
