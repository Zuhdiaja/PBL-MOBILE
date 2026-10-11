import 'package:flutter/services.dart';

abstract class ClipboardDataSource {
  Future<String?> readText();
}

class SystemClipboardDataSource implements ClipboardDataSource {
  const SystemClipboardDataSource();

  @override
  Future<String?> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
