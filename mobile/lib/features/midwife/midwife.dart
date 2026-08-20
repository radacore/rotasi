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

  /// Nomor tanpa karakter non-digit untuk `wa.me`.
  String get waNumber => phone.replaceAll(RegExp(r'[^0-9]'), '');
}
