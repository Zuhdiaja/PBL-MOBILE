import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/features/input_scan/domain/entities/url_input.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/prepare_scan_preview.dart';

void main() {
  const preparePreview = PrepareScanPreview();

  test('preview trims URLs and preserves their order and exact contents', () {
    final result = preparePreview([
      '  https://contoh.com/a?q=1#bagian  ',
      'http://docs.example.com/',
    ]);

    expect(result.failure, isNull);
    expect(result.preview!.urls.map((url) => url.value), [
      'https://contoh.com/a?q=1#bagian',
      'http://docs.example.com/',
    ]);
    expect(result.preview!.urls.first.host, 'contoh.com');
    expect(() => result.preview!.urls.clear(), throwsUnsupportedError);
  });

  test('one invalid URL prevents the whole batch from being previewed', () {
    for (final value in [
      '',
      'contoh.com',
      'ftp://contoh.com',
      'https://localhost',
      'https://contoh.com/a b',
    ]) {
      final result = preparePreview(['https://contoh.com', value]);
      expect(result.preview, isNull);
      expect(result.failure!.message, validateUrl(value));
    }
    expect(UrlInput('bukan-url').host, isNull);
  });

  test('the domain accepts at most five URLs and rejects empty batches', () {
    expect(preparePreview([]).failure, isNotNull);
    expect(
      preparePreview(List.filled(5, 'https://contoh.com')).failure,
      isNull,
    );
    expect(
      preparePreview(List.filled(6, 'https://contoh.com')).preview,
      isNull,
    );
  });
}
