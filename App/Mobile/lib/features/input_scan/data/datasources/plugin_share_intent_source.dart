import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../domain/repositories/share_intent_source.dart';

/// Receives text through the Android share sheet.
///
/// The plugin also reports files and images; only text is used here because
/// the checker only accepts a URL.
class PluginShareIntentSource implements ShareIntentSource {
  PluginShareIntentSource({ReceiveSharingIntent? plugin})
    : _plugin = plugin ?? ReceiveSharingIntent.instance;

  final ReceiveSharingIntent _plugin;

  @override
  Future<String?> takeInitialText() async {
    final text = _textOf(await _plugin.getInitialMedia());
    if (text != null) await _plugin.reset();
    return text;
  }

  @override
  Stream<String> textStream() => _plugin
      .getMediaStream()
      .map(_textOf)
      .where((text) => text != null)
      .cast<String>();

  static String? _textOf(List<SharedMediaFile> files) {
    for (final file in files) {
      final text = file.path.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  @override
  void dispose() {}
}
