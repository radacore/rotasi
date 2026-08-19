# API.md: ROTASI

## Autentikasi & Otorisasi

ROTASI menggunakan **Laravel Sanctum** untuk dua jalur autentikasi:

1. **Web admin** — autentikasi berbasis sesi (cookie + CSRF). Halaman admin dirender via Inertia.js; endpoint `/api/admin/*` dilindungi sesi.
2. **Aplikasi mobile** — autentikasi berbasis **token Bearer** (personal access token). Perangkat mendaftar sekali (`device/register`), lalu membawa token pada setiap request `/api/v1/*`.

**Format Header (Web Sesi):**
```
Cookie: XSRF-TOKEN=<token>; laravel_session=<session_id>
X-CSRF-TOKEN: <token>
```

**Format Header (Mobile Token):**
```
Authorization: Bearer <device_token>
Accept: application/json
```

**Tingkat Otorisasi:**
- **Public:** Tanpa autentikasi (hanya unduhan lanjutan non-data).
- **Device (Mobile):** Token perangkat, terbatas pada data milik perangkat sendiri.
- **Admin:** Sesi administrator tunggal.

## Format Respons Standar & Paginasi

**Respons Sukses (200 OK):**
```json
{
  "success": true,
  "data": { "resource atau array resource" },
  "message": "Operasi berhasil"
}
```

**Respons Error (4xx/5xx):**
```json
{
  "success": false,
  "error": "kode_error",
  "message": "Deskripsi error yang dapat dibaca"
}
```

**Format Paginasi (endpoint list):**
```json
{
  "success": true,
  "data": [ "array item" ],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total": 120,
    "last_page": 6,
    "from": 1,
    "to": 20
  }
}
```

## API Mobile (Aplikasi Android) — `/api/v1/*`

Semua endpoint mobile memerlukan token device (`Authorization: Bearer`), kecuali `/api/v1/app/jadwal-unduh` (publik) dan `/api/v1/device/register`.

### Pendaftaran Perangkat

#### Daftarkan Perangkat
- **Method:** `POST`
- **Path:** `/api/v1/device/register`
- **Description:** Mendaftarkan perangkat aplikasi (pertama kali dibuka). Menghasilkan token device.
- **Auth Level:** Public
- **Request Body:**
```json
{
  "android_id": "string (required, id perangkat yang stabil)",
  "app_version": "string (required, versi aplikasi)",
  "device_name": "string (optional)"
}
```
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "device_uuid": "string (UUID)",
    "token": "string (Bearer token)"
  },
  "message": "Perangkat terdaftar"
}
```
- **Status Codes:** 201 (Created), 422 (Unprocessable Entity), 500 (Server Error)

### Profil Pasien

#### Simpan/Ubah Profil Pasien (Upsert)
- **Method:** `PUT`
- **Path:** `/api/v1/patient`
- **Description:** Menyinkronkan profil ibu dari perangkat (FR-01, FR-02). Idempoten berdasarkan `patient_uuid`.
- **Auth Level:** Device
- **Request Body:**
```json
{
  "patient_uuid": "string (required, UUID client-side)",
  "name": "string (required)",
  "age": "integer (required)",
  "height_cm": "number (required)",
  "weight_kg": "number (required)",
  "gestational_weeks": "integer|nullable",
  "due_date": "date|nullable",
  "last_systolic": "integer|nullable",
  "last_diastolic": "integer|nullable",
  "history_type": "string (required: none|hypertension|prior_preeclampsia|family)",
  "risk_level": "string (required: low|medium|high)",
  "phone": "string|nullable"
}
```
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "patient_uuid": "string",
    "risk_level": "string",
    "sync_status": "synced"
  },
  "message": "Profil pasien tersinkron"
}
```
- **Status Codes:** 200 (OK), 422 (Unprocessable Entity), 401 (Unauthorized), 500 (Server Error)

#### Ambil Profil Pasien
- **Method:** `GET`
- **Path:** `/api/v1/patient`
- **Description:** Mengambil profil pasien milik perangkat.
- **Auth Level:** Device
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "patient_uuid": "string",
    "name": "string",
    "age": "integer",
    "height_cm": "number",
    "weight_kg": "number",
    "gestational_weeks": "integer|null",
    "due_date": "date|null",
    "risk_level": "string"
  }
}
```
- **Status Codes:** 200 (OK), 404 (Not Found), 401 (Unauthorized), 500 (Server Error)

### Sinkronisasi Data

#### Sinkronisasi Massal
- **Method:** `POST`
- **Path:** `/api/v1/sync`
- **Description:** Mengirim semua data lokal yang belum tersinkron sekaligus (FR-13): record tekanan darah, ceklis gejala, hitungan gerakan janin, dan ceklis 10T. Idempoten via `uuid` client-side.
- **Auth Level:** Device
- **Request Body:**
```json
{
  "patient_uuid": "string (required)",
  "records": {
    "bp_records": [
      {
        "uuid": "string (required)",
        "measured_at": "datetime (required)",
        "session_code": "string (required: pagi|sore)",
        "systolic_1": "integer",
        "diastolic_1": "integer",
        "systolic_2": "integer",
        "diastolic_2": "integer",
        "avg_systolic": "integer",
        "avg_diastolic": "integer",
        "status_color": "string (green|yellow|orange|red)"
      }
    ],
    "symptom_checks": [
      {
        "uuid": "string (required)",
        "checked_at": "datetime (required)",
        "headache": "boolean",
        "blurred_vision": "boolean",
        "epigastric_pain": "boolean",
        "shortness_of_breath": "boolean"
      }
    ],
    "kick_counts": [
      {
        "uuid": "string (required)",
        "started_at": "datetime (required)",
        "ended_at": "datetime",
        "kick_count": "integer",
        "is_active": "boolean"
      }
    ],
    "anc_checks": [
      {
        "uuid": "string (required)",
        "visited_at": "date (required)",
        "t_items": {
          "t1": "boolean", "t2": "boolean", "t3": "boolean", "t4": "boolean",
          "t5": "boolean", "t6": "boolean", "t7": "boolean", "t8": "boolean",
          "t9": "boolean", "t10": "boolean"
        }
      }
    ]
  }
}
```
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "accepted_bp": ["uuid", "..."],
    "accepted_symptoms": ["uuid", "..."],
    "accepted_kicks": ["uuid", "..."],
    "accepted_anc": ["uuid", "..."],
    "duplicates_skipped": 0
  },
  "message": "Sinkronisasi berhasil, x record diproses"
}
```
- **Status Codes:** 200 (OK), 422 (Unprocessable Entity), 401 (Unauthorized), 500 (Server Error)

#### Sinkronisasi Single (Record Tekanan Darah)
- **Method:** `POST`
- **Path:** `/api/v1/sync/bp`
- **Description:** Mengirim satu record tekanan darah (FR-03, FR-04).
- **Auth Level:** Device
- **Request Body:** (objek `bp_records` tunggal seperti di atas)
- **Status Codes:** 201 (Created), 200 (duplicate diabaikan), 422, 401, 500

#### Sinkronisasi Single (Ceklis Gejala)
- **Method:** `POST`
- **Path:** `/api/v1/sync/symptom`
- **Description:** Mengirim satu ceklis gejala harian (FR-06).
- **Auth Level:** Device
- **Request Body:** (objek `symptom_checks` tunggal)
- **Status Codes:** 201 (Created), 200 (duplicate), 422, 401, 500

#### Sinkronisasi Single (Gerakan Janin)
- **Method:** `POST`
- **Path:** `/api/v1/sync/kick`
- **Description:** Mengirim satu hasil hitung gerakan janin (FR-07).
- **Auth Level:** Device
- **Request Body:** (objek `kick_counts` tunggal)
- **Status Codes:** 201 (Created), 200 (duplicate), 422, 401, 500

#### Sinkronisasi Single (Ceklis 10T)
- **Method:** `POST`
- **Path:** `/api/v1/sync/anc`
- **Description:** Mengirim satu ceklis kunjungan ANC 10T (FR-08).
- **Auth Level:** Device
- **Request Body:** (objek `anc_checks` tunggal)
- **Status Codes:** 201 (Created), 200 (duplicate), 422, 401, 500

### Booklet & Pengaturan

#### Ambil Booklet Aktif
- **Method:** `GET`
- **Path:** `/api/v1/booklet`
- **Description:** Mengambil versi booklet PDF aktif beserta metadata (FR-09, FR-18). Aplikasi membandingkan `version` lokal; bila berubah, mengunduh `file_url` untuk cache offline.
- **Auth Level:** Device
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "title": "string",
    "version": "integer",
    "file_url": "string (URL PDF di object storage)",
    "file_size": "integer (bytes)",
    "uploaded_at": "datetime"
  }
}
```
- **Status Codes:** 200 (OK), 404 (belum ada booklet aktif), 401 (Unauthorized), 500 (Server Error)

#### Ambil Pengaturan Global
- **Method:** `GET`
- **Path:** `/api/v1/settings`
- **Description:** Mengambil pengaturan global: nomor darurat, puskesmas, pesan WA bawaan, dan ambang rujukan (FR-10, FR-20).
- **Auth Level:** Device (dijalankan tanpa cache — ringan; aplikasi tetap menyimpan salinan lokal untuk offline)
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "app_name": "string",
    "emergency_phone": "string",
    "puskesmas_name": "string",
    "puskesmas_address": "string",
    "default_wa_message": "string",
    "referral_rules": {
      "persistent_colors": ["orange", "red"],
      "symptom_check_trigger": true,
      "kick_threshold": 3
    }
  }
}
```
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

#### Ambil Daftar Bidan Aktif
- **Method:** `GET`
- **Path:** `/api/v1/midwives`
- **Description:** Mengembalikan daftar bidan berstatus aktif, terurut sesuai `sort_order`, untuk fitur hubungi bidan (FR-11, FR-22). Aplikasi mengunduh & menyimpan daftar ini sebagai cache lokal saat online.
- **Auth Level:** Device
- **Response Body:**
```json
{
  "success": true,
  "data": [
    {
      "id": "integer",
      "name": "string",
      "role": "string",
      "phone": "string (format internasional)"
    }
  ]
}
```
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

### Versi Aplikasi

#### Ambil Rilis Terbaru
- **Method:** `GET`
- **Path:** `/api/v1/app/latest-release`
- **Description:** Mengembalikan info rilis APK aktif untuk notifikasi pembaruan (FR-19). Merupakan endpoint ringan yang dipanggil aplikasi saat online.
- **Auth Level:** Device
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "version_code": "integer",
    "version_name": "string",
    "release_notes": "string",
    "is_force_update": "boolean",
    "download_url": "string (URL unduhan APK dari VPS)"
  }
}
```
- **Status Codes:** 200 (OK), 404 (belum ada rilis), 401 (Unauthorized), 500 (Server Error)

### Fitur Offline (Tanpa Endpoint Server)

Fitur-fitur berikut berjalan penuh di perangkat dan **tidak memerlukan endpoint server** (offline-first):

| Referensi | Fitur | Implementasi |
|:---|:---|:---|
| FR-05 | Grafik tren tekanan darah | Dibangun lokal dari tabel `bp_records` (SQLite); data tersedia setelah sinkronisasi dipakai server untuk verifikasi riset. |
| FR-12 | Latihan napas lambat 4-2-6 | Timer murni lokal, tanpa data terkirim ke server. |
| FR-14 | Notifikasi & pengingat lokal | Notifikasi lokal (tanpa FCM); konfigurasi disimpan di `app_meta`. |
| FR-15 | Mode pendamping | Pengaturan lokal per perangkat; tidak ada record server tambahan. |

## API Admin (Web) — `/api/admin/*`

Semua endpoint admin memerlukan sesi administrator.

### Autentikasi

#### Login Admin
- **Method:** `POST`
- **Path:** `/api/admin/login`
- **Description:** Login administrator (FR-16). **Rate limit:** 5 kali gagal / 15 menit / IP.
- **Auth Level:** Public (untuk halaman login)
- **Request Body:**
```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 8)"
}
```
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "user": { "id": "integer", "name": "string", "email": "string" }
  },
  "message": "Login berhasil"
}
```
- **Response Body (Error):**
```json
{
  "success": false,
  "error": "invalid_credentials",
  "message": "Kredensial tidak valid"
}
```
- **Status Codes:** 200 (OK), 401 (Unauthorized), 429 (Too Many Requests), 500 (Server Error)

#### Logout Admin
- **Method:** `POST`
- **Path:** `/api/admin/logout`
- **Description:** Mengakhiri sesi admin.
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

#### Ambil Admin Saat Ini
- **Method:** `GET`
- **Path:** `/api/admin/user`
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

### Dashboard

#### Ambil Data Dashboard
- **Method:** `GET`
- **Path:** `/api/admin/dashboard`
- **Description:** Ringkasan dashboard: versi booklet aktif, jumlah rilis APK, jumlah pasien tersinkron, log sinkronisasi terbaru (FR-17).
- **Auth Level:** Admin
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "active_booklet_version": "integer",
      "apk_releases": "integer",
      "synced_patients": "integer",
      "sync_count_24h": "integer"
    },
    "recent_syncs": [
      {
        "id": "integer",
        "device_uuid": "string",
        "status": "string (success|failed)",
        "records_count": "integer",
        "synced_at": "datetime"
      }
    ]
  }
}
```
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

### Manajemen Booklet PDF

#### Daftar Riwayat Booklet (Admin)
- **Method:** `GET`
- **Path:** `/api/admin/booklet-releases`
- **Description:** Daftar seluruh riwayat unggahan PDF booklet dengan paginasi (FR-18).
- **Auth Level:** Admin
- **Query Parameters:** `page=1`, `per_page=20`
- **Response Body:** `{ success, data: [ { id, title, version, file_url, file_size, is_active, uploaded_at } ], pagination }`
- **Status Codes:** 200 (OK), 401 (Unauthorized), 500 (Server Error)

#### Ambil Detail Booklet (Admin)
- **Method:** `GET`
- **Path:** `/api/admin/booklet-releases/{id}`
- **Auth Level:** Admin
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "title": "string",
    "version": "integer",
    "file_url": "string (URL PDF di object storage)",
    "file_size": "integer (bytes)",
    "is_active": "boolean",
    "uploaded_at": "datetime"
  }
}
```
- **Status Codes:** 200 (OK), 404 (Not Found), 401 (Unauthorized), 500 (Server Error)

#### Unggah Booklet PDF
- **Method:** `POST`
- **Path:** `/api/admin/booklet-releases`
- **Description:** Mengunggah file PDF booklet baru. File tersimpan di object storage (S3-compatible); `version` otomatis menaik dari riwayat terakhir (FR-18).
- **Auth Level:** Admin
- **Request Body:** `multipart/form-data`: `file` (PDF, max 50MB, MIME `application/pdf`), `title` (string, required)
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "title": "string",
    "version": "integer",
    "file_url": "string",
    "file_size": "integer",
    "is_active": "boolean",
    "uploaded_at": "datetime"
  },
  "message": "Booklet diunggah"
}
```
- **Status Codes:** 201 (Created), 422 (Unprocessable Entity), 401 (Unauthorized), 500 (Server Error)

#### Aktifkan Booklet
- **Method:** `PUT`
- **Path:** `/api/admin/booklet-releases/{id}/activate`
- **Description:** Menetapkan satu versi sebagai aktif; versi aktif sebelumnya otomatis non-aktif (hanya satu aktif, FR-18).
- **Auth Level:** Admin
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "is_active": true,
    "version": "integer"
  },
  "message": "Booklet diaktifkan"
}
```
- **Status Codes:** 200 (OK), 404, 401, 500

#### Hapus Riwayat Booklet
- **Method:** `DELETE`
- **Path:** `/api/admin/booklet-releases/{id}`
- **Description:** Menghapus riwayat unggahan; versi aktif tidak dapat dihapus (harus pindah aktif dulu).
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 422 (versi aktif), 404, 401, 500

### Media (Gambar Ilustrasi)

#### Daftar Media
- **Method:** `GET`
- **Path:** `/api/admin/media`
- **Auth Level:** Admin
- **Query Parameters:** `page=1`, `per_page=20`
- **Response Body:** `{ success, data: [ { id, filename, url, type, size, uploaded_at } ], pagination }`

#### Upload Media
- **Method:** `POST`
- **Path:** `/api/admin/media`
- **Description:** Upload gambar (mis. ilustrasi edukasi). Tersimpan di object storage (S3-compatible).
- **Auth Level:** Admin
- **Request Body:** `multipart/form-data` dengan field `file` (image, max 10MB)
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "filename": "string",
    "url": "string",
    "type": "image",
    "size": "integer"
  },
  "message": "Media diunggah"
}
```
- **Status Codes:** 201 (Created), 422, 401, 500

#### Hapus Media
- **Method:** `DELETE`
- **Path:** `/api/admin/media/{id}`
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 404, 401, 500

### Manajemen Rilis APK

#### Daftar Rilis APK
- **Method:** `GET`
- **Path:** `/api/admin/apk-releases`
- **Auth Level:** Admin
- **Response Body:** `{ success, data: [ { id, version_code, version_name, release_notes, is_active, file_size, uploaded_at } ], pagination }`

#### Upload Rilis APK
- **Method:** `POST`
- **Path:** `/api/admin/apk-releases`
- **Description:** Upload APK baru (FR-19). File APK disimpan di VPS (folder `releases/`) dan disajikan sebagai URL unduhan; media lain memakai object storage.
- **Auth Level:** Admin
- **Request Body:** `multipart/form-data`:
  - `apk` (file, max 100MB)
  - `version_code` (integer, required)
  - `version_name` (string, required)
  - `release_notes` (string, optional)
  - `download_url` (string, optional — URL publik APK; jika kosong, otomatis dibuat dari file APK yang disimpan & disajikan VPS)
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "version_code": "integer",
    "version_name": "string",
    "release_notes": "string",
    "download_url": "string",
    "is_active": "boolean"
  },
  "message": "Rilis APK diunggah"
}
```
- **Status Codes:** 201 (Created), 422, 401, 500

#### Tetapkan Versi Aktif
- **Method:** `PUT`
- **Path:** `/api/admin/apk-releases/{id}/activate`
- **Description:** Menetapkan rilis ini sebagai aktif (hanya satu aktif).
- **Auth Level:** Admin
- **Response Body:** `{ success, data: { rilis dijabarkan }, message: "Versi aktif diperbarui" }`
- **Status Codes:** 200 (OK), 404, 401, 500

#### Hapus Rilis APK
- **Method:** `DELETE`
- **Path:** `/api/admin/apk-releases/{id}`
- **Description:** Menghapus rilis. Rilis aktif tidak dapat dihapus tanpa menetapkan rilis lain terlebih dahulu.
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 422 (aktif tidak dapat dihapus), 404, 401, 500

### Booklet PDF

Kelola booklet (unggah PDF, riwayat versi, tetapkan aktif) berada pada bagian **Manajemen Booklet PDF** di atas. Tidak ada proses generate PDF di server — booklet disusun di luar sistem dan diunggah administrator (FR-18).

### Bidan (Manajemen Kontak)

#### Daftar Bidan
- **Method:** `GET`
- **Path:** `/api/admin/midwives`
- **Auth Level:** Admin
- **Query Parameters:** `page=1`, `per_page=20`, `is_active` (opsional filter)
- **Response Body:** `{ success, data: [ { id, name, role, puskesmas, phone, alt_phone, duty_hours, is_active, sort_order, notes, created_at, updated_at } ], pagination }`

#### Ambil Detail Bidan
- **Method:** `GET`
- **Path:** `/api/admin/midwives/{id}`
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 404, 401, 500

#### Buat Bidan
- **Method:** `POST`
- **Path:** `/api/admin/midwives`
- **Description:** Membuat data bidan baru (FR-22).
- **Auth Level:** Admin
- **Request Body:**
```json
{
  "name": "string (required)",
  "role": "string (opsional, mis. Bidan Koordinator)",
  "puskesmas": "string (opsional)",
  "phone": "string (required, format internasional)",
  "alt_phone": "string (opsional)",
  "duty_hours": "string (opsional, mis. 'Senin–Jumat 08.00–15.00')",
  "is_active": "boolean (default true)",
  "sort_order": "integer (default 0)",
  "notes": "string (opsional)"
}
```
- **Response Body:** `{ success, data: { id, name, ... } }`
- **Status Codes:** 201 (Created), 422 (validasi), 401, 500

#### Ubah Bidan
- **Method:** `PUT`
- **Path:** `/api/admin/midwives/{id}`
- **Auth Level:** Admin
- **Request Body:** (sama dengan Buat Bidan; semua field opsional pada ubah)
- **Status Codes:** 200 (OK), 404, 422, 401, 500

#### Hapus Bidan
- **Method:** `DELETE`
- **Path:** `/api/admin/midwives/{id}`
- **Auth Level:** Admin
- **Status Codes:** 200 (OK), 404, 401, 500

### Pengaturan Global

#### Ambil Pengaturan
- **Method:** `GET`
- **Path:** `/api/admin/settings`
- **Auth Level:** Admin
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "app_name": "string",
    "emergency_phone": "string",
    "puskesmas_name": "string",
    "puskesmas_address": "string",
    "default_wa_message": "string",
    "kick_threshold": "integer",
    "updated_at": "datetime"
  }
}
```

#### Ubah Pengaturan
- **Method:** `PUT`
- **Path:** `/api/admin/settings`
- **Auth Level:** Admin
- **Request Body:** (field opsional; validasi nomor telepon darurat format internasional)
- **Status Codes:** 200 (OK), 422, 401, 500

### Pemantauan Data (Riset)

#### Daftar Pasien Tersinkron
- **Method:** `GET`
- **Path:** `/api/admin/patients`
- **Description:** Daftar pasien tersinkron (agregat, tanpa field sensitif penuh) untuk evaluasi riset (FR-21).
- **Auth Level:** Admin
- **Query Parameters:** `page=1`, `per_page=20`, `risk=null`
- **Response Body:**
```json
{
  "success": true,
  "data": [
    {
      "patient_uuid": "string",
      "name": "string",
      "age": "integer",
      "risk_level": "string",
      "bp_count": "integer",
      "latest_bp": {
        "avg_systolic": "integer",
        "avg_diastolic": "integer",
        "status_color": "string"
      },
      "last_synced_at": "datetime"
    }
  ],
  "pagination": {}
}
```

#### Detail Pasien
- **Method:** `GET`
- **Path:** `/api/admin/patients/{patient_uuid}`
- **Description:** Detail pasien + riwayat record dan log sinkronisasi.
- **Auth Level:** Admin
- **Response Body:**
```json
{
  "success": true,
  "data": {
    "patient_uuid": "string",
    "profile": {},
    "bp_records": [ "riwayat tekanan darah" ],
    "sync_logs": [ { "id", "status", "records_count", "synced_at" } ]
  }
}
```
- **Status Codes:** 200 (OK), 404, 401, 500

#### Daftar Log Sinkronisasi
- **Method:** `GET`
- **Path:** `/api/admin/sync-logs`
- **Description:** Daftar log sinkronisasi (FR-21) dengan paginasi dan filter status.
- **Auth Level:** Admin
- **Query Parameters:** `page=1`, `per_page=20`, `status=null`
- **Response Body:** `{ success, data: [ { id, device_uuid, status, records_count, synced_at } ], pagination }`

## Error Handling & Status Codes

| Kode | Makna | Contoh Skenario |
|:---|:---|:---|
| **200** | OK | GET, PUT, DELETE berhasil. |
| **201** | Created | POST yang membuat resource baru. |
| **400** | Bad Request | Request salah format. |
| **401** | Unauthorized | Token device tidak valid / sesi admin berakhir. |
| **403** | Forbidden | Terautentikasi tetapi tidak berhak (tidak dipakai untuk single admin). |
| **404** | Not Found | Resource tidak ditemukan. |
| **409** | Conflict | Pelanggaran rule (mis. menghapus rilis APK aktif). |
| **422** | Unprocessable Entity | Validasi gagal (field wajib, format, unik). |
| **429** | Too Many Requests | Rate limit terlampaui (login, sync berlebihan). |
| **500** | Server Error | Kesalahan internal tak terduga. |

## Rate Limiting

| Endpoint | Limit | Window |
|:---|:---|:---|
| `POST /api/admin/login` | 5 percobaan gagal | 15 menit per IP |
| `POST /api/v1/sync` | 60 request | 1 jam per device |
| `POST /api/v1/device/register` | 10 request | 1 jam per IP |

## CORS & Security Headers

- CORS diaktifkan hanya untuk domain web admin (lepaskan wildcard pada produksi).
- Semua API mobile dikenakan middleware `ForceJsonResponse`.
- Security headers (X-Frame-Options, X-Content-Type-Options, Referrer-Policy) dipasang pada Nginx dan sisi Laravel.
- Semua trafik diwajibkan HTTPS (TLS 1.2+); token device tidak pernah dikirim melalui HTTP.

## Spesifikasi Upload File

| Resource | Field | Tipe | Ukuran Maks | Tujuan |
|:---|:---|:---|:---|:---|
| Media gambar | `file` | image (jpg/png/webp) | 10 MB | object storage (folder `media/`) |
| Rilis APK | `apk` | application/vnd.android.package-archive | 100 MB | VPS (folder `releases/`) |