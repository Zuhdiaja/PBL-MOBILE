import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    (
      title: 'Kenali tautan\nsebelum dibuka.',
      description: 'Mulai dari satu tautan. Tempel URL dan tinjau informasi pemeriksaannya di LinkGuard.',
      image: 'inspect',
    ),
    (
      title: 'Jangan buru-buru.\nKenali risikonya.',
      description: 'Waspadai phishing dan tautan mencurigakan. Luangkan waktu untuk memeriksa sebelum melanjutkan.',
      image: 'shield',
    ),
    (
      title: 'Pemeriksaan lalu,\nmudah ditelusuri.',
      description: 'Temukan kembali hasil pemeriksaan melalui riwayat. Mulai jelajahi LinkGuard dari sini.',
      image: 'history',
    ),
  ];

  final _pages = PageController();
  int _index = 0;
  bool _completed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  void _goTo(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope<void>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _goTo(_index - 1);
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width:
                              MediaQuery.sizeOf(context).width < 220 &&
                                  _index == 0
                              ? 0
                              : 48,
                          height: 48,
                          child: _index == 0
                              ? Icon(
                                  Icons.verified_user_outlined,
                                  color: colors.blue,
                                )
                              : IconButton(
                                  tooltip: 'Kembali',
                                  onPressed: () => _goTo(_index - 1),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                        ),
                        Expanded(
                          child: MediaQuery.sizeOf(context).width < 260
                              ? const SizedBox.shrink()
                              : Text(
                                  'LinkGuard',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                        ),
                        TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text('Lewati'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('onboarding-pages'),
                      controller: _pages,
                      itemCount: _slides.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return LayoutBuilder(
                          builder: (context, size) => SingleChildScrollView(
                            key: PageStorageKey(index),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: (size.maxHeight * .64).clamp(
                                    240.0,
                                    440.0,
                                  ),
                                  width: double.infinity,
                                  child: ExcludeSemantics(
                                    child: Image.asset(
                                      'assets/images/onboarding/${slide.image}.webp',
                                      key: ValueKey(
                                        'onboarding-artwork-$index',
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: colors.muted),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Semantics(
                    liveRegion: true,
                    label: 'Halaman ${_index + 1} dari ${_slides.length}',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            width: index == _index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _index
                                  ? colors.blue
                                  : colors.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _index == _slides.length - 1
                            ? _complete()
                            : _goTo(_index + 1),
                        child: Text(
                          _index == _slides.length - 1
                              ? 'Mulai sekarang'
                              : 'Berikutnya',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
