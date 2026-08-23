/// Bidan aktif dari web admin (FR-11).
class Midwife {
  const Midwife({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
  });

  final int id;
  final String name;
  final String role;
  final String phone;

  factory Midwife.fromJson(Map<String, dynamic> json) {
    return Midwife(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
      };

  /// Nomor internasional untuk `wa.me` — normalisasi 0→62.
  String get waNumber {
    var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return d;
    if (d.startsWith('0')) return '62${d.substring(1)}';
    if (d.startsWith('62')) return d;
    if (d.startsWith('8')) return '62$d';
    return d;
  }
}
