# LinkGuard API

Flask application factory, PostgreSQL/SQLAlchemy, Redis session, dan RQ untuk impor CSV. Setup, bootstrap admin, Docker Compose, serta pengujian ada di [panduan web](../README.md).

Semua endpoint memakai `/api/v1`:

### Integrasi laporan mobile (Prioritas 2)

Jalankan `flask --app app:create_app db upgrade` sebelum memakai kode ini.
Migration `d91f02c437ab` menambah `prediction_reports.reporter_id` yang nullable
dan terindeks. Laporan lama tetap tanpa pemilik; email lama tidak dipakai untuk
mengklaim kepemilikan. Tidak ada perubahan kode Flutter pada pekerjaan ini.

Gunakan `Authorization: Bearer <token>` dari login mobile untuk endpoint berikut:

| Method | Endpoint | Perilaku |
| --- | --- | --- |
| POST | `/mobile/reports` | Kirim koreksi dengan `url`, `type`, `category`, dan `notes` opsional; respons 201 `{report, message}` |
| GET | `/mobile/reports?page=1&page_size=25` | Hanya laporan akun aktif; respons `{items, page, page_size, row_count, page_count}` |
| GET | `/mobile/reports/{id}` | Detail milik akun; laporan milik orang lain/tidak ada menghasilkan 404 |

`type` adalah `False Positive` atau `False Negative`; kategori dan batas field
mengikuti panduan laporan. `page` harus >= 1 dan `page_size` salah satu 25/50/100;
halaman melebihi jumlah halaman dijepit ke halaman terakhir. Hasil terbaru dahulu.
Respons laporan mobile berisi `id`, `url`, `report_type`, `reported_category`,
`status`, `notes`, `dataset_synced`, `created_at`, `updated_at`.
Catatan internal admin, email/ID pelapor, dan ID dataset tidak dikirim.
Identitas pelapor selalu dari bearer token; `reporter_id` dan `reporter_email`
yang dikirim klien tidak menentukan pemilik. Cookie admin tidak menggantikan token.
Token hilang, tidak valid, kedaluwarsa, dicabut, atau akun nonaktif menghasilkan 401.
Endpoint ini memakai CORS mobile yang sama dengan autentikasi dan tidak memakai CSRF.

Endpoint lama `POST /reports/submit` tetap tersedia sebagai submit anonim;
`reporter_email` di sana hanya informasi kontak yang belum diverifikasi.
Untuk fitur laporan saya, Flutter harus memakai `/mobile/reports`.

Status `completed` hanya dihasilkan oleh `/reports/{id}/sync-dataset`.
PATCH ke `completed` sebelum sync ditolak 409 `sync_required`.
Setelah sync, perubahan status/kategori ditolak 409 `report_synced`; nilai yang
sama tetap diterima agar catatan admin dapat diedit lewat form dashboard.
Laporan `rejected` harus dibuka kembali menjadi `review` atau `submitted`
sebelum sync, atau mendapat 409 `report_rejected`.
Header dataset untuk sync harus tepat satu `url` dan tepat satu dari
`label`, `category`, `class`, `type` (case-insensitive, spasi tepi diabaikan).
Header hilang/ambigu ditolak 409 `unsupported_dataset`; kolom lain tidak ditebak.
Record historis tidak diubah otomatis oleh migration selain penambahan kolom.

| Kelompok | Endpoint |
| --- | --- |
| Auth | `GET /auth/csrf`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/me` |
| Profil | `PATCH /profile`, `PUT/GET /profile/avatar`, `POST /profile/password` |
| Dataset | `GET /dataset`, `POST /dataset/imports`, `GET /dataset/imports/{id}`, `GET /dataset/rows` |
| Laporan | `POST /reports/submit`, `GET /reports`, `GET/PATCH/DELETE /reports/{id}`, `POST /reports/{id}/sync-dataset` |
| Pipeline ML | `GET /ml/runs`, `GET /ml/runs/{id}`, `POST /ml/runs/import`, `GET /ml/dataset-summary`, `POST /ml/preview` |
| Pengguna | `GET /users?kind=admin|mobile&page=1&page_size=25`, `POST /users/{kind}`, `PATCH /users/{kind}/{id}`, `POST /users/{kind}/{id}/password` |
| Mobile auth | `POST /mobile/auth/register`, `POST /mobile/auth/login`, `POST /mobile/auth/google`, `GET /mobile/auth/me`, `POST /mobile/auth/logout` |
| Operasional | `GET /health` |

Ambil `csrf_token` dari `/auth/csrf`; kirim lewat header `X-CSRF-Token` pada request perubahan, termasuk login. Login merotasi sesi dan token; gunakan token baru dari respons. Upload memakai multipart field `file`. `/dataset/rows` memerlukan `dataset_id`, `page` (default 1), dan `page_size` (25/50/100). Respons error: `{"error":{"code":"...","message":"..."}}`.

File privat tidak disajikan sebagai direktori statis. Avatar diakses hanya melalui endpoint terautentikasi. Migration tersimpan di `migrations`; tambahkan migration baru ketika schema berubah.

Pengelolaan pengguna memerlukan sesi admin aktif dan CSRF untuk perubahan. `kind` adalah `admin` atau `mobile`; daftar menggunakan `page_size` 25/50/100. Pembuatan menerima `name`, `email`, dan `password` wajib. Pembaruan menerima `name`, `active`; email tetap. Reset menerima `password`. Respons daftar berisi `items`, `kind`, `page`, `page_size`, `row_count`, `page_count`; respons mutasi berisi `user` dan `message`. Hash password dan identitas provider tidak dikirim.

Akun mobile berada di tabel `mobile_users` dan tidak dapat login sebagai admin. API autentikasi mobile tersedia di `/api/v1/mobile/auth` dan memakai bearer token, bukan cookie dashboard: kirim `Authorization: Bearer <token>`. Token disimpan ter-hash di Redis selama `MOBILE_TOKEN_TTL` (default 30 hari). Registrasi dan login email/password memakai batas yang sama dengan akun lain (password 12–256 karakter). Reset password atau perubahan status oleh admin menaikkan `token_version` sehingga token lama langsung berakhir. Endpoint mobile tidak pernah membaca sesi admin dan tidak dapat mengakses `/users`, `/dataset`, atau `/profile`.

Laporan prediksi memakai alur tersendiri: `POST /reports/submit` bersifat publik tanpa CSRF karena dipanggil aplikasi mobile, sedangkan endpoint lainnya memerlukan sesi admin. Aturan kategori, perilaku sinkronisasi dataset, dan kode error dijelaskan di [panduan laporan](../reports/README.md).

Login Google memverifikasi ID token di server: tanda tangan lewat sertifikat Google, `iss`, `aud` terhadap `GOOGLE_MOBILE_CLIENT_IDS`, masa berlaku, serta `email_verified`. Login Google pertama membuat akun `mobile_users` otomatis; email yang sudah terdaftar dan belum tertaut akan ditautkan, sedangkan email yang tertaut ke `sub` Google lain ditolak `409`. Akun nonaktif ditolak. `GOOGLE_MOBILE_CLIENT_IDS` kosong mematikan endpoint Google dengan `503`. Aplikasi Flutter memakai endpoint email/password di atas untuk masuk dan mendaftar, serta mengirim ID token ke `/mobile/auth/google` ketika dibangun dengan client ID OAuth.

Admin web hanya memakai email/password. Endpoint `/auth/google` dan callback tidak tersedia, termasuk ketika environment Google lama masih terpasang. Kolom Google pada tabel admin dipertahankan sebagai data legacy yang tidak dipakai autentikasi atau pemberian akses. Akun legacy tanpa password harus diatur passwordnya oleh admin lain sebelum diaktifkan. Login Google hanya tersedia untuk pengguna mobile.
