import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/extract_shared_url.dart';

void main() {
  group('ExtractSharedUrl', () {
    const extract = ExtractSharedUrl();

    test('finds the link inside a shared sentence', () {
      expect(
        extract('Cek ini ya https://contoh.example.test/login sekarang'),
        'https://contoh.example.test/login',
      );
    });

    test('drops punctuation that follows the link', () {
      expect(
        extract('Hati-hati: https://jahat.example.test/klaim.'),
        'https://jahat.example.test/klaim',
      );
      expect(
        extract('(lihat https://contoh.example.test)'),
        'https://contoh.example.test',
      );
    });

    test('keeps the first link when several are shared', () {
      expect(
        extract('https://satu.example.test lalu https://dua.example.test'),
        'https://satu.example.test',
      );
    });

    test('accepts uppercase schemes', () {
      expect(
        extract('HTTPS://CONTOH.EXAMPLE.TEST'),
        'HTTPS://CONTOH.EXAMPLE.TEST',
      );
    });

    test('ignores text without a link', () {
      expect(extract('Halo, apa kabar?'), isNull);
      expect(extract('contoh.example.test tanpa skema'), isNull);
    });

    test('rejects schemes the checker does not open', () {
      expect(extract('ftp://contoh.example.test/berkas'), isNull);
      expect(extract('javascript:alert(1)'), isNull);
    });

    test('treats empty and missing text as no link', () {
      expect(extract(null), isNull);
      expect(extract('   '), isNull);
    });
  });
}
