import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/extract_qr_url.dart';

void main() {
  group('ExtractQrUrl', () {
    const extract = ExtractQrUrl();

    test('accepts a plain https link', () {
      final result = extract('https://contoh.example.test/login');

      expect(result.url, 'https://contoh.example.test/login');
      expect(result.message, isNull);
    });

    test('accepts an http link', () {
      expect(extract('http://contoh.example.test').url, isNotNull);
    });

    test('finds the link inside a longer payload', () {
      final result = extract('Buka https://contoh.example.test/klaim sekarang');

      expect(result.url, 'https://contoh.example.test/klaim');
    });

    test('refuses a Wi-Fi code and says what it contains', () {
      final result = extract('WIFI:S:Rumah;T:WPA;P:rahasia;;');

      expect(result.url, isNull);
      expect(result.message, contains('Wi-Fi'));
    });

    test('refuses a contact card', () {
      expect(extract('BEGIN:VCARD\nFN:Nadia').message, contains('kontak'));
      expect(extract('MECARD:N:Nadia;;').message, contains('kontak'));
    });

    test('refuses phone numbers', () {
      expect(extract('tel:+628123456789').message, contains('telepon'));
      expect(extract('SMS:+628123456789').message, contains('telepon'));
    });

    test('refuses an email address', () {
      expect(extract('mailto:nadia@example.test').message, contains('email'));
    });

    test('refuses a location', () {
      expect(extract('geo:-7.9,112.6').message, contains('lokasi'));
    });

    test('refuses a wallet address', () {
      expect(extract('bitcoin:1A2b3C').message, contains('dompet'));
    });

    test('refuses plain text', () {
      final result = extract('Halo, ini bukan tautan.');

      expect(result.url, isNull);
      expect(result.message, contains('tidak berisi tautan'));
    });

    test('refuses a link with an unsupported scheme', () {
      final result = extract('ftp://contoh.example.test/berkas');

      expect(result.url, isNull);
      expect(result.message, contains('tidak berisi tautan'));
    });

    test('refuses an empty code', () {
      expect(extract('').message, contains('tidak berisi teks'));
      expect(extract(null).message, contains('tidak berisi teks'));
      expect(extract('   ').message, contains('tidak berisi teks'));
    });
  });
}
