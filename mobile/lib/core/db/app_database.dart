import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Helper database SQLite lokal (offline-first).
///
/// Semua data inti ditulis ke database ini; sinkronisasi hanya perlu koneksi.
class AppDatabase {
  AppDatabase._();

  static const _dbName = 'rotasi.db';
  static const _dbVersion = 7;

  static Database? _db;

  /// Path pengganti untuk test (mis. `inMemoryDatabasePath`).
  static String? testDatabasePath;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = testDatabasePath ?? p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createPatients(db);
    await _createBpMeasurements(db);
    await _createSymptomChecks(db);
    await _createKickCounts(db);
    await _createAncChecks(db);
    await _createBooklets(db);
    await _createSyncLog(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS patients');
      await db.execute('DROP TABLE IF EXISTS bp_measurements');
      await db.execute('DROP TABLE IF EXISTS sync_log');
      await _createPatients(db);
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS bp_measurements');
      await db.execute('DROP TABLE IF EXISTS sync_log');
      await _createBpMeasurements(db);
      await _createSyncLog(db);
    }
    if (oldVersion < 4) {
      await _createSymptomChecks(db);
    }
    if (oldVersion < 5) {
      await _createKickCounts(db);
    }
    if (oldVersion < 6) {
      await _createAncChecks(db);
    }
    if (oldVersion < 7) {
      await _createBooklets(db);
    }
  }

  static Future<void> _createPatients(Database db) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        gestational_weeks INTEGER,
        due_date TEXT,
        last_systolic INTEGER,
        last_diastolic INTEGER,
        history_type TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        phone TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  static Future<void> _createBpMeasurements(Database db) async {
    await db.execute('''
      CREATE TABLE bp_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        patient_uuid TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        session_code TEXT NOT NULL,
        systolic_1 INTEGER NOT NULL,
        diastolic_1 INTEGER NOT NULL,
        systolic_2 INTEGER NOT NULL,
        diastolic_2 INTEGER NOT NULL,
        avg_systolic INTEGER NOT NULL,
        avg_diastolic INTEGER NOT NULL,
        status_color TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_bp_measured_at ON bp_measurements (measured_at)',
    );
  }

  static Future<void> _createSymptomChecks(Database db) async {
    await db.execute('''
      CREATE TABLE symptom_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        patient_uuid TEXT NOT NULL,
        checked_at TEXT NOT NULL,
        headache INTEGER NOT NULL DEFAULT 0,
        blurred_vision INTEGER NOT NULL DEFAULT 0,
        epigastric_pain INTEGER NOT NULL DEFAULT 0,
        shortness_of_breath INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_symptom_checked_at ON symptom_checks (checked_at)',
    );
  }

  static Future<void> _createKickCounts(Database db) async {
    await db.execute('''
      CREATE TABLE kick_counts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        patient_uuid TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        kick_count INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_kick_started_at ON kick_counts (started_at)',
    );
  }

  static Future<void> _createAncChecks(Database db) async {
    await db.execute('''
      CREATE TABLE anc_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        patient_uuid TEXT NOT NULL,
        visited_at TEXT NOT NULL,
        t_items TEXT NOT NULL DEFAULT '[]',
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_anc_visited_at ON anc_checks (visited_at)',
    );
  }

  static Future<void> _createBooklets(Database db) async {
    await db.execute('''
      CREATE TABLE booklets (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        title TEXT NOT NULL,
        version TEXT NOT NULL,
        file_url TEXT NOT NULL,
        file_size INTEGER,
        uploaded_at TEXT,
        local_path TEXT,
        downloaded_at TEXT
      )
    ''');
  }

  static Future<void> _createSyncLog(Database db) async {
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        reference_uuid TEXT,
        status TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  /// Menutup koneksi database (dipakai oleh test).
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Menutup lalu menghapus file database (isolasi antar test).
  ///
  /// Saat memakai DB in-memory (test), cukup tutup: bukaan berikutnya
  /// otomatis menghasilkan database kosong baru.
  static Future<void> reset() async {
    await close();
    if (testDatabasePath != null) return;
    final path = p.join(await getDatabasesPath(), _dbName);
    await databaseFactory.deleteDatabase(path);
  }

  /// Utilitas log sinkronisasi (idempoten).
  static Future<void> logSync({
    required String type,
    String? referenceUuid,
    required String status,
    String? payload,
  }) async {
    final db = await instance;
    await db.insert('sync_log', {
      'type': type,
      'reference_uuid': referenceUuid,
      'status': status,
      'payload': payload,
    });
  }
}
