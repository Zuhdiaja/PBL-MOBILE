import 'dart:async';

import '../../../../presentation/load_controller.dart';
import '../../domain/entities/scan_result.dart';

class ScanDetailController extends LoadController {
  ScanDetailController(this.readResult);
  final FutureOr<ScanResult> Function() readResult;
  ScanResult? result;

  @override
  Future<void> load() => loadValue(readResult, (value) => result = value);
}
