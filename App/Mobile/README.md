# LinkGuard Mobile

Aplikasi pemeriksa tautan berbasis Flutter. Autentikasi (masuk, daftar, dan
login Google) sudah terhubung ke API LinkGuard dan tercatat di database.
Riwayat, statistik, status laporan, dan notifikasi masih memakai data contoh.

## Halaman

- Beranda
- Scan URL (maksimal 5 URL)
- Scan QR Code
- Bagikan ke LinkGuard

Login, daftar, profil, dan pengaturan tersedia. Riwayat, statistik, status
laporan, dan notifikasi menggunakan data contoh.

## Menjalankan

```sh
flutter pub get
git branch --show-current
flutter run   # lengkapi dengan perintah per platform di bawah
```

**Pastikan branch yang aktif adalah branch fitur yang sedang dikerjakan.**
Kode autentikasi nyata berada di branch fitur, bukan di `main`. Kalau
`git branch --show-current` menunjukkan `main` atau branch dokumentasi, aplikasi
akan terkompilasi dari kode lama: cirinya email terprefill `nadia@gmail.com`,
hint kata sandi "Minimal 6 karakter", dan keterangan "Login Google belum
terhubung." selalu muncul walau client ID sudah diberikan.

### Client ID OAuth proyek ini

Nilai berikut bukan rahasia dan sengaja ditulis di sini supaya perintah bisa
disalin langsung. Yang rahasia adalah *client secret* di Google Cloud Console;
jangan pernah menyalinnya ke repository atau chat.

| Jenis | Client ID |
| --- | --- |
| Web application | `855765000526-dcagltlb62fkdpqv0bkhhceu8a57ssps.apps.googleusercontent.com` |
| Android | `855765000526-ghe5ee2om1llevphi01hcik8pg9ttriv.apps.googleusercontent.com` |

Client Android dicocokkan Google lewat package name
`com.example.pbl_semester5` dan SHA-1 debug keystore mesin yang menjalankan
aplikasi, jadi client Android tidak pernah ditulis di perintah; yang selalu
dipakai di perintah adalah client **Web** (sebagai `serverClientId` agar Google
mengeluarkan ID token).

### Perintah siap salin per platform

Chrome (browser):

```sh
flutter run -d chrome --web-port 8080 --dart-define=GOOGLE_WEB_CLIENT_ID=855765000526-dcagltlb62fkdpqv0bkhhceu8a57ssps.apps.googleusercontent.com
```

Emulator Android:

```sh
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=855765000526-dcagltlb62fkdpqv0bkhhceu8a57ssps.apps.googleusercontent.com
```

HP fisik Android (ganti `192.168.1.10` dengan IP laptop di jaringan yang sama):

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000 --dart-define=GOOGLE_WEB_CLIENT_ID=855765000526-dcagltlb62fkdpqv0bkhhceu8a57ssps.apps.googleusercontent.com
```

### Kenapa `--dart-define` wajib dan apa akibatnya kalau terlupa

`GOOGLE_WEB_CLIENT_ID` dibaca saat **kompilasi**, bukan saat aplikasi berjalan.
Akibatnya:

- Tanpa define itu, tombol Google dinonaktifkan dan keterangan
  "Login Google belum terhubung." ditampilkan. Ini perilaku sengaja, bukan bug.
- Menekan **R** (hot restart) tidak menambahkan define ke sesi yang sudah
  berjalan. Aplikasi harus dihentikan (`q` atau Ctrl+C) lalu dijalankan ulang
  dengan perintah lengkap.
- Menyalin placeholder seperti `<web-client-id>` apa adanya membuat shell
  menolak perintah karena tanda `<` dibaca sebagai redirect. Salin nilai
  client ID yang utuh dari tabel di atas.

### Catatan per platform

- **Chrome**: alamat harus persis `http://localhost:8080` karena origin itu
  yang terdaftar di `MOBILE_CORS_ORIGINS` pada `App/Web/.env`. Tanpa
  `--web-port 8080`, Flutter memakai port acak dan browser akan membuang
  respons API dengan pesan "Tidak dapat terhubung ke server.". Di Chrome,
  Google mengirim **access token** (bukan ID token) dan API memverifikasinya
  lewat endpoint `tokeninfo` + `userinfo`.
- **Device Mode di DevTools bukan HP sungguhan.** Meniru iPhone/Android di
  DevTools tetap menjalankan Flutter web, sehingga yang berlaku client Web dan
  aturan CORS. Untuk merasakan aplikasi mobile, pakai emulator atau HP fisik.
- **Emulator Android**: alamat API default `http://10.0.2.2:3000` sudah benar;
  Google mengirim ID token.
- **HP fisik Android**: HP dan laptop satu jaringan Wi-Fi, firewall Windows
  mengizinkan port 3000, dan SHA-1 debug keystore laptop harus sama dengan yang
  terdaftar pada OAuth client Android di Google Cloud. Google mengirim ID
  token.

### Arti pesan error dan solusinya

| Pesan di aplikasi | Penyebab | Solusi |
| --- | --- | --- |
| "Login Google belum terhubung." | Define `GOOGLE_WEB_CLIENT_ID` tidak ikut saat kompilasi, atau branch yang aktif bukan branch fitur | Hentikan aplikasi, jalankan perintah siap salin di atas, pastikan branch benar |
| "Tidak dapat terhubung ke server. Periksa koneksi Anda." | Origin browser tidak terdaftar di CORS, atau stack Docker belum jalan | Pakai `--web-port 8080`, pastikan `docker compose up` aktif |
| "Login Google gagal: popup tertutup tanpa akun" | Popup Google tertutup sebelum selesai, atau akun bukan test user saat status masih Testing | Selesaikan popup sampai tuntas; tambah akun di Audience → Test users, atau publish aplikasi |
| "Login Google dibatalkan." | Popup ditutup pengguna, atau Google menolak lalu menutup popup | Coba lagi; periksa isi popup |
| "OAuth client was not found / invalid_client" di popup | Nilai client ID yang terkirim salah atau tertukar dengan client Android | Salin client Web dari tabel di atas |
| "People API has not been used in project ..." | API People belum diaktifkan di project Google Cloud | Aktifkan People API di console, tunggu beberapa menit |
| Email terprefill `nadia@gmail.com` dan hint "Minimal 6 karakter" | Aplikasi terkompilasi dari kode lama (branch salah) | `git checkout feat/mobile-google-signin` lalu run ulang |

### Memastikan akun benar-benar tercatat

Setelah daftar atau login Google di aplikasi, akun muncul di dashboard web:
masuk sebagai admin di `http://localhost:3000`, buka menu **Pengguna** → tab
**Pengguna mobile**. Akun hasil Google ditandai metode masuk "Belum diatur"
karena tidak memakai password.

Pengecekan: `flutter analyze --no-pub` dan `flutter test --no-pub`.
