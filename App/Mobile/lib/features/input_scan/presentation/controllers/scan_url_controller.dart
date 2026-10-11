import 'package:flutter/material.dart';

import '../../domain/repositories/clipboard_repository.dart';
import '../../domain/usecases/prepare_scan_preview.dart';

class ScanUrlController extends ChangeNotifier {
  ScanUrlController({
    required this.clipboardRepository,
    required this.prepareScanPreview,
  });

  final ClipboardRepository clipboardRepository;
  final PrepareScanPreview prepareScanPreview;
  final _fields = [TextEditingController()];
  bool _disposed = false;

  List<TextEditingController> get fields => List.unmodifiable(_fields);
  int get maxUrls => PrepareScanPreview.maxUrls;
  bool get canAddUrl => _fields.length < maxUrls;

  void addUrl() {
    if (!canAddUrl) return;
    _fields.add(TextEditingController());
    notifyListeners();
  }

  void removeUrl(int index) {
    if (_fields.length == 1) return;
    final field = _fields.removeAt(index);
    notifyListeners();
    // Keep the field alive until its widget has unmounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => field.dispose());
  }

  Future<String?> pasteIntoFirstField() => paste(_fields.first);

  Future<String?> paste(TextEditingController field) async {
    final result = await clipboardRepository.readText();
    if (_disposed || !_fields.contains(field)) return null;
    if (result.text != null) field.text = result.text!;
    return result.failure?.message;
  }

  PreviewResult preparePreview() =>
      prepareScanPreview(_fields.map((field) => field.text));

  @override
  void dispose() {
    _disposed = true;
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }
}
