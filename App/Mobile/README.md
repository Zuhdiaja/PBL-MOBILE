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

Token disimpan di perangkat melalui `shared_preferences`.

### Menjalankan tombol Google per platform

`GOOGLE_WEB_CLIENT_ID` wajib disertakan di **semua** platform, termasuk emulator
dan HP fisik, karena `serverClientId` memakai client Web agar Google
mengeluarkan ID token. Tanpa itu tombol Google tetap nonaktif dan keterangan
"Login Google belum terhubung." ditampilkan.

| Platform | Perintah |
| --- | --- |
| Chrome | `flutter run -d chrome --web-port 8080 --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>` |
| Emulator Android | `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>` |
| HP fisik Android | `flutter run --dart-define=API_BASE_URL=http://<ip-laptop>:3000 --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>` |

Catatan per platform:

- **Chrome**: alamat harus persis `http://localhost:8080` dan origin itu
  terdaftar di `MOBILE_CORS_ORIGINS` pada `App/Web/.env`. Google mengirim
  access token, bukan ID token, dan API memverifikasinya lewat `tokeninfo`.
- **Emulator Android**: alamat API default `http://10.0.2.2:3000` sudah benar;
  Google mengirim ID token.
- **HP fisik Android**: HP dan laptop harus satu jaringan Wi-Fi, firewall
  Windows mengizinkan port 3000, dan SHA-1 debug keystore laptop harus sama
  dengan yang terdaftar pada OAuth client Android di Google Cloud. Google
  mengirim ID token.

Pengecekan: `flutter analyze --no-pub` dan `flutter test --no-pub`.
