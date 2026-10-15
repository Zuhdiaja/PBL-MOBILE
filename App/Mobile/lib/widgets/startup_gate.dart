import 'package:flutter/material.dart';

import '../presentation/load_controller.dart';
import 'loading_states.dart';

/// Session restoration and the brand entrance must both finish before entry.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.controller, required this.child});
  final LoadController controller;
  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _entranceComplete = false;
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      if (_entranceComplete &&
          c.hasLoaded &&
          !c.isLoading &&
          c.loadError == null) {
        return widget.child;
      }
      return SplashScreen(
        busy: c.isLoading,
        onComplete: () {
          if (mounted && !_entranceComplete) {
            setState(() => _entranceComplete = true);
          }
        },
        recovery: c.loadError == null
            ? null
            : Column(
                children: [
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Sesi belum dapat dimuat.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: c.load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
      );
    },
  );
}
