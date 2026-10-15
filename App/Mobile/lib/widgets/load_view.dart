import 'package:flutter/material.dart';

import '../presentation/load_controller.dart';
import 'loading_states.dart';
import 'scan_components.dart';

/// Binds the rendered state to the repository operation, never to a timer.
class LoadView extends StatefulWidget {
  const LoadView({
    super.key,
    required this.controller,
    required this.kind,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.subpage = false,
  });
  final LoadController controller;
  final String kind;
  final WidgetBuilder builder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? errorBuilder;
  final bool subpage;

  @override
  State<LoadView> createState() => _LoadViewState();
}

class _LoadViewState extends State<LoadView> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasLoaded) widget.controller.load();
  }

  @override
  void didUpdateWidget(LoadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller &&
        !widget.controller.hasLoaded) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final busy = c.isLoading || (!c.hasLoaded && c.loadError == null);
      Widget child;
      if (busy) {
        child =
            widget.loadingBuilder?.call(context) ??
            LoadingScreen(kind: widget.kind);
        if (widget.subpage) {
          child = Scaffold(body: SafeArea(child: child));
        }
      } else if (c.loadError != null && widget.errorBuilder != null) {
        child = widget.errorBuilder!(context);
      } else if (c.loadError != null) {
        final content = [
          Semantics(liveRegion: true, child: Text(c.loadError!)),
          const SizedBox(height: 20),
          ScanButton(
            label: 'Coba lagi',
            icon: Icons.refresh_rounded,
            onPressed: c.load,
          ),
        ];
        child = widget.subpage
            ? ScanSubpage(
                title: LoadingScreen.titles[widget.kind] ?? 'Muat data',
                children: content,
              )
            : ScanPage(
                children: [
                  Text(
                    LoadingScreen.titles[widget.kind] ?? 'Muat data',
                    style: pageTitleStyle,
                  ),
                  const SizedBox(height: 24),
                  ...content,
                ],
              );
      } else {
        child = widget.builder(context);
      }
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        layoutBuilder: (current, previous) =>
            current ?? const SizedBox.shrink(),
        child: KeyedSubtree(
          key: ValueKey(
            busy
                ? 'loading'
                : c.loadError != null
                ? 'error'
                : 'data',
          ),
          child: child,
        ),
      );
    },
  );
}

class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(liveRegion: true, child: Text(message)),
      const SizedBox(height: 16),
      ScanButton(
        label: 'Coba lagi',
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
      ),
    ],
  );
}
