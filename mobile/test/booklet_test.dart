import 'package:flutter_test/flutter_test.dart';
import 'package:rotasi_mobile/features/education/booklet.dart';

void main() {
  group('Booklet', () {
    test('fromRemote memetakan metadata server', () {
      final b = Booklet.fromRemote({
        'id': 3,
        'title': 'Panduan Ibu Hamil',
        'version': '1.2',
        'file_url': 'http://x/storage/booklets/abc.pdf',
        'file_size': 2048,
        'uploaded_at': '2026-08-01 10:00:00',
      });
      expect(b.title, 'Panduan Ibu Hamil');
      expect(b.version, '1.2');
      expect(b.fileUrl, 'http://x/storage/booklets/abc.pdf');
      expect(b.fileSize, 2048);
      expect(b.uploadedAt, isNotNull);
      expect(b.isDownloaded, false);
      expect(b.localPath, isNull);
    });

    test('fileName memakai versi', () {
      final b = Booklet(
        title: 't',
        version: '2.0',
        fileUrl: 'http://x/a.pdf',
      );
      expect(b.fileName, 'rotasi_edukasi_2.0.pdf');
    });

    test('toMap/fromMap roundtrip', () {
      final b = Booklet(
        title: 't',
        version: '1.1',
        fileUrl: 'http://x/a.pdf',
        fileSize: 100,
        uploadedAt: DateTime(2026, 8, 1),
        localPath: '/tmp/booklets/a.pdf',
        downloadedAt: DateTime(2026, 8, 2),
      );
      final restored = Booklet.fromMap(b.toMap());
      expect(restored.title, 't');
      expect(restored.version, '1.1');
      expect(restored.fileUrl, 'http://x/a.pdf');
      expect(restored.fileSize, 100);
      expect(restored.localPath, '/tmp/booklets/a.pdf');
      expect(restored.isDownloaded, true);
      expect(restored.downloadedAt, isNotNull);
    });

    test('copyWith menimpa localPath', () {
      final b = Booklet(
        title: 't',
        version: '1',
        fileUrl: 'http://x/a.pdf',
      );
      final updated = b.copyWith(localPath: '/tmp/b.pdf');
      expect(updated.localPath, '/tmp/b.pdf');
      expect(updated.version, '1');
      expect(b.localPath, isNull);
    });
  });
}
