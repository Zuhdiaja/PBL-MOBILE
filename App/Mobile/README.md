# LinkGuard Mobile

Aplikasi pemeriksa tautan berbasis Flutter. Saat ini masih menggunakan data contoh; API, kamera, dan integrasi berbagi belum terhubung.

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
flutter run
```

Autentikasi memakai API LinkGuard di `/api/v1/mobile/auth`. Alamat default
mengikuti platform: emulator Android memakai `http://10.0.2.2:3000`, sedangkan
web dan desktop memakai `http://localhost:3000`. Untuk perangkat fisik atau API
yang sudah di-deploy, timpa lewat `--dart-define`:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

Token disimpan di perangkat melalui `shared_preferences`. Tombol Google aktif
bila client ID OAuth diberikan saat build:

```sh
flutter run -d chrome --web-port 8080 --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Untuk emulator atau HP fisik, client Android dicocokkan otomatis lewat package
name dan SHA-1; `serverClientId` tetap memakai client Web agar ID token keluar.
Tanpa `--dart-define`, tombol Google tetap nonaktif dan keterangan
"Login Google belum terhubung." ditampilkan.

Pengecekan: `flutter analyze --no-pub` dan `flutter test --no-pub`.
