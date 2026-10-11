import 'url_input.dart';

class ScanPreview {
  ScanPreview(Iterable<UrlInput> urls) : urls = List.unmodifiable(urls);

  final List<UrlInput> urls;
}
