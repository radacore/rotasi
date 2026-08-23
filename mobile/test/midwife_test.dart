import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/midwife/midwife.dart';

void main() {
  group('Midwife', () {
    test('fromJson memetakan data bidan', () {
      final m = Midwife.fromJson({
        'id': 1,
        'name': 'Bidan Rini',
        'role': 'Bidan Desa',
        'phone': '08123456789',
      });
      expect(m.id, 1);
      expect(m.name, 'Bidan Rini');
      expect(m.role, 'Bidan Desa');
      expect(m.phone, '08123456789');
    });

    test('waNumber menghapus karakter non-digit', () {
      const m = Midwife(id: 1, name: 'Bidan Rini', role: '', phone: '+62 812-3456 789');
      expect(m.waNumber, '628123456789');
    });

    test('waNumber normalisasi 0 awalan ke 62', () {
      expect(const Midwife(id: 1, name: '', role: '', phone: '085298805432').waNumber,
          '6285298805432');
      expect(const Midwife(id: 1, name: '', role: '', phone: '081227088313').waNumber,
          '6281227088313');
      expect(const Midwife(id: 1, name: '', role: '', phone: '85298805432').waNumber,
          '6285298805432');
      expect(const Midwife(id: 1, name: '', role: '', phone: '6285298805432').waNumber,
          '6285298805432');
    });

    test('toJson/fromJson roundtrip', () {
      const m = Midwife(id: 2, name: 'Bidan Sari', role: 'Bidan', phone: '0811');
      final restored = Midwife.fromJson(m.toJson());
      expect(restored.id, 2);
      expect(restored.name, 'Bidan Sari');
      expect(restored.phone, '0811');
    });
  });
}
