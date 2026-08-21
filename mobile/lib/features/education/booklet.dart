/// Booklet edukasi PDF (FR-09) — beberapa versi aktif dikelola web admin.
class Booklet {
  const Booklet({
    required this.id,
    required this.title,
    required this.version,
    required this.fileUrl,
    this.fileSize,
    this.uploadedAt,
    this.localPath,
    this.downloadedAt,
  });

  final int id;
  final String title;
  final String version;
  final String fileUrl;
  final int? fileSize;
  final DateTime? uploadedAt;

  /// Path file PDF lokal setelah diunduh; null bila belum tersedia offline.
  final String? localPath;
  final DateTime? downloadedAt;

  bool get isDownloaded => localPath != null;

  String get fileName => 'booklet_${id}_v$version.pdf';

  factory Booklet.fromRemote(Map<String, dynamic> data) {
    final rawVersion = data['version'];
    return Booklet(
      id: (data['id'] as num?)?.toInt() ?? 1,
      title: data['title'] as String? ?? 'Booklet Edukasi',
      version: rawVersion == null
          ? '1'
          : rawVersion is String
              ? rawVersion
              : rawVersion.toString(),
      fileUrl: data['file_url'] as String,
      fileSize: (data['file_size'] as num?)?.toInt(),
      uploadedAt: data['uploaded_at'] == null
          ? null
          : DateTime.tryParse(data['uploaded_at'] as String),
    );
  }

  factory Booklet.fromMap(Map<String, dynamic> map) {
    return Booklet(
      id: map['id'] as int,
      title: map['title'] as String,
      version: map['version'] as String,
      fileUrl: map['file_url'] as String,
      fileSize: map['file_size'] as int?,
      uploadedAt: map['uploaded_at'] == null
          ? null
          : DateTime.tryParse(map['uploaded_at'] as String),
      localPath: map['local_path'] as String?,
      downloadedAt: map['downloaded_at'] == null
          ? null
          : DateTime.tryParse(map['downloaded_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'file_url': fileUrl,
      'file_size': fileSize,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'local_path': localPath,
      'downloaded_at': downloadedAt?.toIso8601String(),
    };
  }

  Booklet copyWith({
    int? id,
    String? title,
    String? version,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedAt,
    String? localPath,
    DateTime? downloadedAt,
  }) {
    return Booklet(
      id: id ?? this.id,
      title: title ?? this.title,
      version: version ?? this.version,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }
}
