# LinkGuard Admin

Dashboard V1 untuk login admin, satu dataset CSV aktif, pengelolaan pengguna, dan profil. Tidak ada registrasi publik. Admin pertama dibuat lewat CLI; admin berikutnya dapat ditambahkan dari dashboard. Admin web hanya masuk dengan email dan password.

## Docker Compose

Dari folder `App/Web`:

```sh
cp .env.example .env
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Isi `SECRET_KEY` dan `POSTGRES_PASSWORD` di `.env` dengan dua nilai acak yang berbeda, lalu:

```sh
docker compose up -d --build --wait
docker compose exec api flask --app app:create_app create-admin \
  --email admin@example.com --name "Admin LinkGuard"
```

CLI meminta password minimal 12 karakter secara interaktif. Buka **http://localhost:3000**. Compose menjalankan gateway Nginx, dashboard Next.js, API Flask, worker RQ, scheduler training, PostgreSQL, Redis, dan migrasi otomatis. Endpoint health memeriksa revisi skema yang dipakai API. Hanya port web yang dibuka ke host; API, database, dan Redis berada di jaringan internal. CSV sementara dan avatar berada pada volume privat bersama API/worker.

```sh
docker compose logs -f api worker scheduler admin web
docker compose stop
```

Volume data tetap tersimpan saat layanan dihentikan. Jalankan kembali `docker compose up -d --build --wait` setelah mengganti `MAX_UPLOAD_MB`.

### Push Android

Simpan Firebase Admin service account JSON di path privat dan set `FIREBASE_CREDENTIALS_FILE`. Jalankan `docker compose --profile push up -d --build --wait`. Worker memvalidasi kredensial saat mulai dan mencatat kegagalan akhir setelah lima percobaan. Jalankan `docker compose exec api flask --app app:create_app push-status` untuk melihat jumlah `pending`, `failed`, dan `handled`. Tanpa profile ini, status laporan tetap tersedia di mobile melalui API.

## HTTPS

Untuk deployment HTTPS, arahkan reverse proxy ke web dan set `COOKIE_SECURE=true`. Sesuaikan batas request reverse proxy minimal `MAX_UPLOAD_MB + 1` MB. Gateway Docker meneruskan `/api/v1` ke Flask dan mengisi identitas IP dari koneksi yang diterima. Untuk reverse proxy HTTPS eksternal, konfigurasikan real-IP Nginx hanya untuk alamat proxy tepercaya. Di mode dev tanpa Nginx, rewrite Next.js meneruskan API secara lokal. Cookie sesi Redis bersifat HttpOnly, SameSite=Lax, dan berlaku maksimal delapan jam. Request perubahan memerlukan CSRF. Password memakai scrypt; perubahan password mengakhiri sesi perangkat lain.

Implementasi mengacu pada [shadcn Next.js](https://ui.shadcn.com/docs/installation/next), [pagination TanStack](https://tanstack.com/table/latest/docs/framework/react/guide/pagination).

## Pengguna

Menu **Pengguna** memiliki tab **Admin dashboard** dan **Pengguna mobile**. Keduanya mendukung tambah akun, edit nama, pengaturan ulang password, serta aktif/nonaktif. Email tetap dan unik pada masing-masing jenis akun. Password minimal 12 karakter disimpan sebagai hash scrypt. Daftar memakai pagination server 25/50/100 akun.

Semua admin aktif memiliki izin pengelolaan yang sama. Akun sendiri tidak dapat dinonaktifkan atau diatur ulang passwordnya lewat menu ini; gunakan Profil untuk mengubah password dengan password lama. Perubahan status atau pengaturan ulang password admin membatalkan sesi akun tersebut. Perubahan admin diserialisasi dalam transaksi PostgreSQL untuk menjaga akses saat dua admin saling menonaktifkan.

Akun mobile disimpan terpisah di PostgreSQL dan tidak mempunyai akses dashboard. **Aplikasi Flutter sudah memakai `/api/v1/mobile/auth` untuk masuk dan mendaftar dengan email dan password.** Status serta password mobile yang dikelola di sini berlaku pada API tersebut; reset password atau perubahan status membatalkan token bearer yang aktif. Tidak ada endpoint registrasi web publik. Login Google hanya untuk pengguna mobile: backend memverifikasi ID token Google dan membuat akun mobile otomatis pada login pertama. Aplikasi Flutter mengaktifkan tombol Google-nya bila dibangun dengan `--dart-define=GOOGLE_WEB_CLIENT_ID`. Tabel **Pengguna → Mobile** menampilkan metode **Google SSO** untuk akun yang tertaut dan **Password** untuk akun yang memiliki password. Kedua metode dapat tampil bersama.

Login desktop memakai dua kolom (form dan penjelasan akses); layar di bawah 1024px memakai satu kolom.

## Autentikasi mobile

API mobile berada di `/api/v1/mobile/auth` dan memakai bearer token, bukan cookie dashboard. Aktifkan login Google dengan mengisi `GOOGLE_MOBILE_CLIENT_IDS` (client ID OAuth Web, Android, dan iOS, dipisah koma); kosong berarti login Google dimatikan. `MOBILE_TOKEN_TTL` mengatur masa berlaku token dalam detik, default 30 hari.

```sh
curl -X POST http://localhost:3000/api/v1/mobile/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"name":"Nadia","email":"nadia@example.com","password":"password-nadia-2026"}'
```

Respons berisi `user`, `token`, `token_type`, dan `expires_in`; token hanya dikembalikan sekali. Kirim token sebagai `Authorization: Bearer <token>` ke `/auth/me` atau `/auth/logout`. Endpoint ini hanya menyentuh `mobile_users`, sehingga token mobile tidak dapat membuka `/users`, `/dataset`, atau `/profile` admin.

## Dataset

Sumber yang dituju adalah [MURL 2026 di Mendeley](https://data.mendeley.com/datasets/5fk24y4xmg/1). CSV asli belum tersedia di repository; fixture pengujian adalah data sintetis.

- CSV UTF-8 atau UTF-8 BOM, maksimal 512 MB secara default. Header menentukan kolom; maksimal 1024 kolom.
- Semua nilai disimpan sebagai string; spasi, label, header duplikat, duplikat baris, urutan, dan newline di dalam field dipertahankan. Tidak ada asumsi kolom atau jumlah kelas.
- CSV harus memiliki header dan jumlah field konsisten. File encoding salah, kutipan rusak, karakter NUL, atau baris yang tidak sesuai ditolak. CSV dengan header saja diterima sebagai dataset kosong.
- Unggahan mengembalikan `202` dan masuk antrean. Hanya satu impor aktif; unggahan lain menerima `409`.
- Worker membaca streaming dan menyimpan batch maksimal 1000 baris atau sekitar 4 MB nilai. Dataset baru menggantikan dataset lama dalam transaksi setelah seluruh impor selesai. Data lama dibersihkan setelah pergantian; file unggahan sementara dihapus setelah selesai/gagal.
- Pekerjaan gagal/terhenti dipulihkan sebagai `failed` saat metadata/status dibaca atau unggahan berikutnya dilakukan. Heartbeat yang kedaluwarsa lebih dari satu jam ditandai gagal; worker yang sudah ditandai gagal tidak boleh mengaktifkan dataset. Dataset lama tetap tersedia.
- Pagination 25/50/100 baris dijalankan di PostgreSQL melalui indeks `(dataset_id, row_number)`. URL menyimpan halaman, ukuran halaman, dan identitas dataset; pergantian dataset kembali ke halaman pertama.

## Laporan

Menu **Laporan** menampung koreksi prediksi dari pengguna mobile. Admin dapat meninjau, mengubah status dan kategori, lalu menyetujui laporan sehingga satu baris baru ditambahkan ke dataset aktif. Gunakan **Unduh CSV aktif** untuk membawa koreksi ke unggahan training berikutnya. Ejaan kategori mengikuti dataset yang sedang aktif, dan kelas `legitimate` tidak pernah diubah.

Alur, aturan kategori, kode error, serta cara menguji dengan dataset MURL asli dijelaskan di [reports/README.md](reports/README.md).

## Pipeline ML

**Pipeline ML** menampilkan model aktif yang melayani pemindaian mobile. Halaman memeriksa status setiap 15 detik selama tab terlihat. Buka **Riwayat model** untuk menelusuri hasil sebelumnya per halaman dan membandingkan metrik, split, laporan klasifikasi, serta confusion matrix. Distribusi kelas menggambarkan dataset CSV aktif, sementara jumlah baris sumber dan URL unik pada hasil training menggambarkan dataset yang benar-benar dilatih. Contoh demo diberi label saat dataset atau hasil model belum tersedia.

Di **Alur Pipeline**, tahap **Pembersihan input** dan **Normalisasi URL** menampilkan perubahan dari baris CSV aktif beserta nomor baris sumber. Form normalisasi juga menerima URL pilihan admin.

Di **Detail Training**, pilih kartu **Train**, **Validation**, atau **Test** untuk melihat jumlah dan persentase label dari split model terpilih. Run baru mencatat jumlah kelas Train saat split dibuat. Untuk run lama, Validation dan Test memakai jumlah aktual dari laporan evaluasi jika tersedia.

### Training manual

Di **Pipeline ML**, klik **Train sekarang** saat dataset aktif sudah selesai diimpor dan belum berhasil dilatih. Permintaan masuk ke antrean scheduler yang juga menangani jadwal harian. Status antrean, proses, dan hasil tampil di Pipeline ML. Setelah evaluasi selesai, jadwal harian melewati unggahan yang sama. Pilih kandidat berstatus **Siap ditinjau** di Riwayat model, periksa hasilnya, lalu pilih **Setujui dan aktifkan**.

### Training terjadwal

1. Unggah CSV melalui **Dataset** dan tunggu impor selesai. Training membutuhkan tepat satu kolom `url` dan satu kolom kelas (`label`, `category`, `class`, atau `type`).
2. Buka **Jadwal Training**, aktifkan jadwal, pilih jam WIB, lalu simpan. Jadwal awal nonaktif.
3. Scheduler berjalan di proses sendiri dan memeriksa dataset aktif setiap hari pada menit yang dipilih. Dataset yang sudah berhasil dilatih dilewati. Penyuntingan melalui sinkronisasi laporan saja tidak memicu retraining. Jika scheduler mati pada menit jadwal, pemeriksaan berikutnya berlangsung pada jadwal hari berikutnya.
4. Training memakai preprocessing URL yang sama dengan inference, menghapus duplikat URL hasil preprocessing, dan membagi data berdasarkan grup domain. CSV harus memiliki minimal dua kelas yang dapat terwakili di train, validation, dan test. Hasil tetap tercatat di riwayat. Kandidat dapat disetujui jika semua kelas dikenali mobile dan artefaknya valid. Admin dapat meninjau metrik per kelas sebelum menyetujui kandidat. Selama training dan peninjauan, pemindaian memakai model yang sudah aktif. Jika training gagal atau dataset berubah saat proses berjalan, model aktif dipertahankan.

Untuk membandingkan metrik notebook tanpa mengubah model pemindaian, gunakan **Impor hasil** atau perintah berikut:

```sh
docker compose exec api flask --app app:create_app ml-import \
  --path /path/to/svm_tfidf_metrics.json
```

Impor metrik eksternal tidak memverifikasi asal dataset. Preview URL di dashboard menampilkan normalisasi dan frekuensi n-gram, sementara prediksi memakai endpoint pemindaian mobile.

## Menjalankan tanpa container web

Bun 1.4.3+, Python 3.13+, PostgreSQL dan Redis diperlukan. Dari `admin`:

```sh
bun install --frozen-lockfile
cp .env.example .env.local
bun run dev
```

Dari `api`, buat virtual environment dan install `requirements.lock`. Isi `SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`, dan `PRIVATE_STORAGE` sebagai environment, lalu:

```sh
python -m flask --app app:create_app db upgrade
python -m flask --app app:create_app run --port 5001
# Terminal terpisah, environment yang sama:
python worker.py
# Terminal terpisah, environment yang sama:
python scheduler.py
```

Frontend memakai `API_URL=http://127.0.0.1:5001` secara default. Geist disajikan lokal, tanpa unduhan font Google saat build.

## Pemeriksaan

Dari `admin`:

```sh
bun run lint
bun run format:check
bun run typecheck
bun run build
```

Pengujian API memakai database **khusus pengujian** `linkguard_test` dan Redis DB 15. Pengujian membuat ulang tabel database tersebut, bukan database aplikasi:

```sh
# Dari App/Web, buat sekali:
docker compose exec postgres createdb -U linkguard linkguard_test
docker compose --profile test run --build --rm test
```

Playwright menguji web dan API yang benar-benar berjalan, pada 1440 px dan 390 px. Buat akun khusus uji, bukan akun produksi:

```sh
docker compose exec api flask --app app:create_app create-admin \
  --email e2e@example.com --name "Admin E2E" --password e2e-only-password-2026
cd admin
bunx playwright install chromium
bun run test:e2e
```

Akun, dataset, foto, dan nama akun E2E akan berubah selama pengujian. `E2E_BASE_URL`, `E2E_EMAIL`, dan `E2E_PASSWORD` dapat dikonfigurasi. Screenshot ada di `test-results/screenshots`; trace kegagalan ada di `test-results`.

CI menjalankan lint, format, typecheck, build web, migration, pytest PostgreSQL, serta alur Playwright. Verifikasi dengan CSV MURL asli menunggu file tersedia.
