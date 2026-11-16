/// Outcome of reading a QR code.
///
/// Exactly one of [url] and [message] is set: a usable URL, or the reason the
/// code cannot be checked.
typedef QrExtraction = ({String? url, String? message});
