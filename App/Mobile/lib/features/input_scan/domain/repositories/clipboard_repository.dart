import '../entities/input_scan_failure.dart';

typedef ClipboardResult = ({String? text, InputScanFailure? failure});

abstract class ClipboardRepository {
  Future<ClipboardResult> readText();
}
