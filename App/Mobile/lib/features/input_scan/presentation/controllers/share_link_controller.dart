import 'package:flutter/material.dart';

import '../../domain/entities/url_input.dart';
import '../../domain/repositories/clipboard_repository.dart';
import '../../domain/usecases/prepare_scan_preview.dart';

class ShareLinkController extends ChangeNotifier {
  ShareLinkController({
    required this.clipboardRepository,
    required this.prepareScanPreview,
    required this.exampleUrl,
  }) {
    field.addListener(notifyListeners);
  }

  final ClipboardRepository clipboardRepository;
  final PrepareScanPreview prepareScanPreview;
  final String exampleUrl;
  final field = TextEditingController();
  bool _usingExample = false;
  bool _disposed = false;

  String get url => field.text.trim();
  String? get host => UrlInput(url).host;
  bool get usingExample => _usingExample;

  void markEdited() {
    _usingExample = false;
    notifyListeners();
  }

  void useExample() {
    field.text = exampleUrl;
    _usingExample = true;
    notifyListeners();
  }

  Future<ClipboardResult?> paste() async {
    final result = await clipboardRepository.readText();
    if (_disposed) return null;
    if (result.text != null) {
      field.text = result.text!;
      _usingExample = false;
      notifyListeners();
    }
    return result;
  }

  PreviewResult preparePreview() => prepareScanPreview([field.text]);

  @override
  void dispose() {
    _disposed = true;
    field.dispose();
    super.dispose();
  }
}
