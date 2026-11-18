import '../entities/qr_extraction.dart';
import 'extract_shared_url.dart';

/// Turns the text of a scanned QR code into a URL the checker accepts.
///
/// A QR code can hold a Wi-Fi network, a contact card, a phone number, or plain
/// text. Only http/https links are checkable, so everything else is refused
/// with a message that says what the code actually contains instead of a
/// generic "invalid" error.
class ExtractQrUrl {
  const ExtractQrUrl({this.sharedUrl = const ExtractSharedUrl()});

  final ExtractSharedUrl sharedUrl;

  QrExtraction call(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return (url: null, message: 'Kode QR tidak berisi teks.');
    }

    final url = sharedUrl(text);
    if (url != null) return (url: url, message: null);

    final lower = text.toLowerCase();
    if (lower.startsWith('wifi:')) {
      return (
        url: null,
        message: 'Kode QR ini berisi jaringan Wi-Fi, bukan tautan.',
      );
    }
    if (lower.startsWith('begin:vcard') ||
        lower.startsWith('begin:vcalendar') ||
        lower.startsWith('mecard:')) {
      return (
        url: null,
        message: 'Kode QR ini berisi kartu kontak, bukan tautan.',
      );
    }
    if (lower.startsWith('tel:') ||
        lower.startsWith('sms:') ||
        lower.startsWith('smsto:')) {
      return (
        url: null,
        message: 'Kode QR ini berisi nomor telepon, bukan tautan.',
      );
    }
    if (lower.startsWith('mailto:')) {
      return (
        url: null,
        message: 'Kode QR ini berisi alamat email, bukan tautan.',
      );
    }
    if (lower.startsWith('geo:')) {
      return (url: null, message: 'Kode QR ini berisi lokasi, bukan tautan.');
    }
    if (lower.startsWith('bitcoin:') || lower.startsWith('ethereum:')) {
      return (
        url: null,
        message: 'Kode QR ini berisi alamat dompet digital, bukan tautan.',
      );
    }

    // Text without a link, or a link with a scheme the checker cannot open.
    return (
      url: null,
      message: 'Kode QR ini tidak berisi tautan http atau https yang bisa diperiksa.',
    );
  }
}
