import 'dart:async';

import 'package:flutter/foundation.dart';

/// Owns one repository read. Completion after disposal is ignored, and repeated
/// load requests share the pending operation instead of issuing duplicate reads.
abstract class LoadController extends ChangeNotifier {
  bool _disposed = false;
  Future<void>? _pending;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _loadError;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get loadError => _loadError;

  Future<void> load();

  @protected
  Future<void> loadValue<T>(
    FutureOr<T> Function() read,
    void Function(T value) apply, {
    String? Function(Object error)? describeError,
  }) {
    if (_disposed) return Future.value();
    if (_pending != null) return _pending!;
    _isLoading = true;
    _loadError = null;
    final completion = Completer<void>();
    _pending = completion.future;
    notifyListeners();
    () async {
      try {
        final value = await read();
        if (!_disposed) {
          apply(value);
          _hasLoaded = true;
        }
      } catch (error) {
        if (!_disposed) {
          _loadError =
              describeError?.call(error) ??
              'Data belum dapat dimuat. Silakan coba lagi.';
        }
      } finally {
        _pending = null;
        if (!_disposed) {
          _isLoading = false;
          notifyListeners();
        }
        completion.complete();
      }
    }();
    return completion.future;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
