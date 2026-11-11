import '../entities/url_input.dart';

/// Picks the URL out of a text shared from another app.
///
/// Messaging apps share a whole sentence, so the first complete URL is
/// extracted and checked against the same format rule the form uses. Text
/// without a usable URL returns null instead of guessing.
class ExtractSharedUrl {
  const ExtractSharedUrl();

  static final _candidate = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
  static final _trailingPunctuation = RegExp(r'''[.,;:!?)\]}>'"”’]+$''');

  String? call(String? sharedText) {
    final text = sharedText?.trim() ?? '';
    if (text.isEmpty) return null;
    final match = _candidate.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!.replaceFirst(_trailingPunctuation, '');
    return validateUrl(url) == null ? url : null;
  }
}
