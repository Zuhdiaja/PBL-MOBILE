# LinkGuard Mobile

Tampilan Flutter berbahasa Indonesia, mengikuti referensi mobile biru-putih. Login dengan akun contoh yang sudah terisi untuk membuka Beranda.

## Halaman

- **Beranda:** sapaan, tombol Mulai scan, akses cepat Tempel URL / Scan QR / Bagikan link, serta aktivitas contoh.
- **Scan URL:** satu hingga lima URL, tempel dari clipboard, hapus field, validasi format, dan pratinjau pemeriksaan. Draft tetap ada saat berpindah tab.
- **Scan QR Code:** area pemindai dan tombol Pindai contoh QR. Kamera belum terhubung.
- **Bagikan ke LinkGuard:** panduan berbagi dari aplikasi lain, keadaan belum menerima tautan, tombol Gunakan tautan contoh, pratinjau domain, URL yang dapat diedit, dan Periksa URL.

Riwayat dan Statistik tetap berupa placeholder. Profil dan Pengaturan tetap tersedia. Tulisan Mockup v1.0 telah dihapus.

## Alur berbagi

Alur yang dipilih: pilih tautan di aplikasi asal → Bagikan → LinkGuard → tinjau URL → Periksa URL. Pengguna melihat domain dan bisa memperbaiki URL sebelum melanjutkan. Pemeriksaan dimulai melalui tindakan pengguna; tautan tidak dibuka otomatis.

Pada implementasi ini, Gunakan tautan contoh menirukan tautan masuk. Penerimaan melalui menu Bagikan sistem operasi belum diimplementasikan. Ke depan, tautan masuk dapat langsung membuka pratinjau ini; panduan tetap berguna ketika halaman dibuka tanpa tautan.

## Batas implementasi

Tidak ada panggilan API, klasifikasi keamanan untuk input pengguna, akses kamera, atau integrasi penerimaan share sistem operasi. Tombol pemeriksaan hanya menampilkan URL yang akan diperiksa dan keterangan bahwa penilaian keamanan belum tersedia. Label Aman dan Phishing pada aktivitas Beranda merupakan data contoh.

Clipboard memakai layanan lokal perangkat. Pratinjau tidak menyimpan atau mengirim URL. Tema terang mengikuti referensi; tema gelap belum menjadi ruang lingkup desain ini.

## Menjalankan dan memeriksa

```sh
flutter pub get
flutter run
flutter analyze --no-pub
flutter test --no-pub
```

Kode layar ada di `lib/screens/`. Komponen form dan pratinjau dipakai bersama dari `lib/widgets/scan_components.dart`.

Screenshot emulator Android tersedia di `.impeccable/review/`. Bukti ini berasal dari emulator, bukan pengujian perangkat fisik atau iOS.
