# LinkGuard API

Flask application factory, PostgreSQL/SQLAlchemy, Redis session, dan RQ untuk impor CSV. Setup, bootstrap admin, Docker Compose, serta pengujian ada di [panduan web](../README.md).

Semua endpoint memakai `/api/v1`:

| Kelompok | Endpoint |
| --- | --- |
| Auth | `GET /auth/csrf`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/me` |
| Profil | `PATCH /profile`, `PUT/GET /profile/avatar`, `POST /profile/password` |
| Dataset | `GET /dataset`, `POST /dataset/imports`, `GET /dataset/imports/{id}`, `GET /dataset/rows` |
| Pengguna | `GET /users?kind=admin|mobile&page=1&page_size=25`, `POST /users/{kind}`, `PATCH /users/{kind}/{id}`, `POST /users/{kind}/{id}/password` |
| Operasional | `GET /health` |

Ambil `csrf_token` dari `/auth/csrf`; kirim lewat header `X-CSRF-Token` pada request perubahan, termasuk login. Login merotasi sesi dan token; gunakan token baru dari respons. Upload memakai multipart field `file`. `/dataset/rows` memerlukan `dataset_id`, `page` (default 1), dan `page_size` (25/50/100). Respons error: `{"error":{"code":"...","message":"..."}}`.

File privat tidak disajikan sebagai direktori statis. Avatar diakses hanya melalui endpoint terautentikasi. Migration tersimpan di `migrations`; tambahkan migration baru ketika schema berubah.

Pengelolaan pengguna memerlukan sesi admin aktif dan CSRF untuk perubahan. `kind` adalah `admin` atau `mobile`; daftar menggunakan `page_size` 25/50/100. Pembuatan menerima `name`, `email`, dan `password` wajib. Pembaruan menerima `name`, `active`; email tetap. Reset menerima `password`. Respons daftar berisi `items`, `kind`, `page`, `page_size`, `row_count`, `page_count`; respons mutasi berisi `user` dan `message`. Hash password dan identitas provider tidak dikirim.

Akun mobile berada di tabel `mobile_users` dan tidak dapat login sebagai admin. API autentikasi Flutter belum diintegrasikan; pengelolaan ini hanya menyimpan akun mobile, bukan mengganti demo auth Flutter.

Admin web hanya memakai email/password. Endpoint `/auth/google` dan callback tidak tersedia, termasuk ketika environment Google lama masih terpasang. Kolom Google pada tabel admin dipertahankan sebagai data legacy yang tidak dipakai autentikasi atau pemberian akses. Akun legacy tanpa password harus diatur passwordnya oleh admin lain sebelum diaktifkan. Google SSO mobile belum diimplementasikan.
