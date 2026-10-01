class ScanResultItem {
  const ScanResultItem({
    required this.url,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.isSafe,
    this.recommendation,
    this.indicators,
    this.scanTime = '18 Sep 2026, 09:12 WIB',
    this.modelName = 'LinkGuard URL Classifier - Demo v1.0',
    this.method = 'Simulasi klasifikasi URL',
  });

  final String url;
  final String category;
  final String riskLevel;
  final int confidence;
  final bool isSafe;
  final String? recommendation;
  final List<String>? indicators;
  final String scanTime;
  final String modelName;
  final String method;

  String get defaultRecommendation => isSafe
      ? 'URL ini tampak aman dalam contoh analisis. Tetap periksa alamat domain sebelum memasukkan data pribadi.'
      : 'PERINGATAN: Tautan terdeteksi berpotensi bahaya ($category). Disarankan untuk tidak memasukkan data pribadi atau kredensial.';

  List<String> get defaultIndicators => isSafe
      ? const [
          'Struktur domain terlihat wajar',
          'Tidak ada pola berisiko pada contoh URL',
        ]
      : const [
          'Domain menggunakan nama merek terkenal secara tidak sah',
          'Terdeteksi struktur URL dengan indikasi manipulasi',
        ];
}

final List<ScanResultItem> demoScanResults = [
  const ScanResultItem(
    url: 'bank-login.example.test',
    category: 'Phishing',
    riskLevel: 'High Risk',
    confidence: 96,
    isSafe: false,
    scanTime: '18 Sep 2026, 09:42 WIB',
  ),
  const ScanResultItem(
    url: 'docs.example.com',
    category: 'Benign',
    riskLevel: 'Low Risk',
    confidence: 98,
    isSafe: true,
    scanTime: '18 Sep 2026, 08:15 WIB',
  ),
  const ScanResultItem(
    url: 'update-package.example.test',
    category: 'Malware',
    riskLevel: 'High Risk',
    confidence: 94,
    isSafe: false,
    scanTime: '17 Sep 2026, 21:03 WIB',
  ),
  const ScanResultItem(
    url: 'news.example.com',
    category: 'Benign',
    riskLevel: 'Low Risk',
    confidence: 91,
    isSafe: true,
    scanTime: '17 Sep 2026, 19:27 WIB',
  ),
];
