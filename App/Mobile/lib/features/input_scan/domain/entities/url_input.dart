/// Validates format only; it does not assess the safety of a URL.
String? validateUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Masukkan URL yang ingin diperiksa.';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty ||
      !uri.host.contains('.') ||
      RegExp(r'\s').hasMatch(text)) {
    return 'Gunakan URL lengkap, misalnya https://contoh.com.';
  }
  return null;
}

class UrlInput {
  UrlInput(String value) : value = value.trim();

  final String value;

  String? get validationMessage => validateUrl(value);
  String? get host => validationMessage == null ? Uri.parse(value).host : null;
}
