import '../../domain/entities/input_scan_failure.dart';
import '../../domain/repositories/clipboard_repository.dart';
import '../datasources/clipboard_data_source.dart';

class ClipboardRepositoryImpl implements ClipboardRepository {
  const ClipboardRepositoryImpl(this._dataSource);

  final ClipboardDataSource _dataSource;

  @override
  Future<ClipboardResult> readText() async {
    try {
      final text = (await _dataSource.readText())?.trim() ?? '';
      if (text.isNotEmpty) return (text: text, failure: null);
      return (
        text: null,
        failure: const InputScanFailure(
          'Belum ada teks untuk ditempel. Salin URL dahulu.',
        ),
      );
    } catch (_) {
      return (
        text: null,
        failure: const InputScanFailure(
          'Teks belum bisa ditempel. Masukkan URL manual.',
        ),
      );
    }
  }
}
