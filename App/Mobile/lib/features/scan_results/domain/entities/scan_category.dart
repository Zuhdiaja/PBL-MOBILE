/// Canonical class names the app renders.
///
/// The API returns the raw labels of the trained pipeline, so the mapping and
/// the safety rules live here instead of in widgets.
class ScanCategory {
  ScanCategory._();

  static const benign = 'Benign';
  static const legitimate = 'Legitimate';
  static const phishing = 'Phishing';
  static const malware = 'Malware';
  static const spam = 'Spam';
  static const defacement = 'Defacement';
  static const exploit = 'Exploit';
  static const unknown = 'Tidak diketahui';

  /// Maps a raw model label onto a canonical category.
  ///
  /// `legitimate` stays distinct from `benign`: the first means the URL is
  /// valid according to the rules, the second means it is harmless.
  static String fromRaw(String raw) => switch (raw.trim().toLowerCase()) {
    'benign' => benign,
    'legitimate' => legitimate,
    'phishing' => phishing,
    'malware' => malware,
    'spam' => spam,
    'defacement' => defacement,
    'exploit' => exploit,
    _ => unknown,
  };

  /// True when the model found nothing harmful in the URL.
  static bool isSafe(String category) =>
      category == benign || category == legitimate;

  /// Risk wording shown next to the category.
  static String riskLevel(String category) => switch (category) {
    benign || legitimate => 'Low Risk',
    spam || defacement => 'Medium Risk',
    phishing || malware || exploit => 'High Risk',
    _ => 'Perlu peninjauan',
  };

  /// Advice shown under the result.
  ///
  /// `legitimate` and `benign` are worded differently on purpose: a URL can be
  /// valid according to the rules without being harmless, and the other way
  /// around.
  static String recommendation(String category) => switch (category) {
    benign => 'URL ini tidak menunjukkan pola berbahaya menurut model. Tetap periksa alamat domain sebelum memasukkan data pribadi.',
    legitimate => 'URL ini dikenali sah menurut aturan model. Pastikan tetap berasal dari sumber resmi sebelum membuka.',
    _ =>
      'PERINGATAN: Tautan terklasifikasi $category. Jangan masukkan data pribadi atau kredensial.',
  };

  /// Bullet points describing what the model looked at.
  static List<String> indicators(String category) => [
    'Diperiksa dengan model SVM + TF-IDF di server',
    'Teks URL dinormalisasi (huruf kecil, tanpa skema http/https)',
    if (isSafe(category))
      'Tidak ditemukan pola berbahaya pada kategori $category'
    else
      'Model mengenali pola $category pada tautan ini',
  ];
}
