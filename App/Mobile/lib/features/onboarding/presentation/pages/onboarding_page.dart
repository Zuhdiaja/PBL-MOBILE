import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

const _splashCopyColor = Color(0xFFC6D7EF);
const _splashAccentColor = Color(0xFF9BBCFF);
const _artworkTint = Color(0xFFF1F5FC);
const _artworkLine = Color(0xFFE3EAF4);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    _OnboardingSlide(
      eyebrow: 'PERIKSA DULU',
      title: 'Kenali tautan sebelum dibuka.',
      description: 'Tempel URL untuk memeriksa indikasi risiko sebelum Anda mengunjunginya.',
      icon: Icons.link_rounded,
      cardTitle: 'Pemeriksaan tautan',
      cardSubtitle: 'Analisis dimulai',
    ),
    _OnboardingSlide(
      eyebrow: 'LEBIH WASPADA',
      title: 'Deteksi ancaman lebih awal.',
      description: 'Kenali tautan mencurigakan seperti phishing, malware, dan ancaman lainnya.',
      icon: Icons.verified_user_outlined,
      cardTitle: 'Perlindungan aktif',
      cardSubtitle: 'Tautan diperiksa',
    ),
    _OnboardingSlide(
      eyebrow: 'SEMUA TERCATAT',
      title: 'Pantau hasil pindai Anda.',
      description: 'Lihat kembali riwayat pemeriksaan dan ringkasan keamanan kapan saja.',
      icon: Icons.manage_search_rounded,
      cardTitle: 'Riwayat tersimpan',
      cardSubtitle: 'Aktivitas mudah dipantau',
    ),
  ];

  int _currentIndex = 0;

  void _next() {
    if (_currentIndex == _slides.length - 1) {
      widget.onComplete();
      return;
    }
    setState(() => _currentIndex++);
  }

  void _back() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    return Scaffold(
      backgroundColor: context.colors.scanner,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, constraints.maxWidth),
                    const SizedBox(height: 18),
                    _OnboardingArtwork(
                      slide: slide,
                      index: _currentIndex,
                      height: (constraints.maxHeight * .39)
                          .clamp(230, 330)
                          .toDouble(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      slide.eyebrow,
                      style: TextStyle(
                        color: _splashAccentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        slide.title,
                        key: ValueKey(slide.title),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.16,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        slide.description,
                        key: ValueKey(slide.description),
                        style: TextStyle(
                          color: _splashCopyColor,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _pageIndicator(context, constraints.maxWidth),
                    const Spacer(),
                    const SizedBox(height: 16),
                    _navigationButtons(context, constraints.maxWidth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double width) => Row(
    children: [
      if (width >= 350) ...[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'LinkGuard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
          ),
        ),
      ],
      const Spacer(),
      TextButton(
        onPressed: widget.onComplete,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          foregroundColor: _splashAccentColor,
        ),
        child: const Text('Lewati'),
      ),
    ],
  );

  Widget _pageIndicator(BuildContext context, double width) => Row(
    children: [
      for (var index = 0; index < _slides.length; index++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: index == _currentIndex ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: index == _currentIndex ? _splashAccentColor : Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      if (width >= 240) ...[
        const Spacer(),
        Text(
          '${(_currentIndex + 1).toString().padLeft(2, '0')} / ${_slides.length.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: _splashCopyColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
          ),
        ),
      ],
    ],
  );

  Widget _navigationButtons(BuildContext context, double width) {
    final compact = width < 340;
    final iconOnly = width < 220;
    return Row(
      children: [
        if (compact)
          IconButton.outlined(
            onPressed: _currentIndex == 0 ? null : _back,
            tooltip: 'Kembali',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white30),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          OutlinedButton.icon(
            onPressed: _currentIndex == 0 ? null : _back,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: context.colors.line),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              backgroundColor: Colors.transparent,
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: iconOnly
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              minimumSize: iconOnly ? const Size(48, 48) : null,
            ),
            child: iconOnly
                ? const Icon(Icons.arrow_forward_rounded, size: 18)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentIndex == _slides.length - 1
                            ? 'Mulai'
                            : compact
                            ? 'Next'
                            : 'Berikutnya',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.cardTitle,
    required this.cardSubtitle,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String cardTitle;
  final String cardSubtitle;
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork({
    required this.slide,
    required this.index,
    required this.height,
  });

  final _OnboardingSlide slide;
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('onboarding-artwork'),
    height: height,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _artworkLine),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: -70, right: -55, child: _outlineCircle(context, 230)),
        Positioned(
          bottom: -140,
          left: -70,
          child: _outlineCircle(context, 270),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: Text(
            'LINK SAFETY',
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: _artworkTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            slide.icon,
            key: const ValueKey('onboarding-feature-icon'),
            size: 72,
            color: context.colors.scanner,
          ),
        ),
        Positioned(
          bottom: 26,
          left: 20,
          right: 20,
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 180
                ? const SizedBox.shrink()
                : _statusCard(context),
          ),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: Text(
            '0${index + 1}',
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _outlineCircle(BuildContext context, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.blue.withValues(alpha: .10),
        width: 1,
      ),
    ),
  );

  Widget _statusCard(BuildContext context) => Container(
    key: const ValueKey('onboarding-status-card'),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _artworkLine),
      boxShadow: [
        BoxShadow(
          color: context.colors.scanner.withValues(alpha: .08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.colors.paleBlue,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.verified_outlined,
            size: 19,
            color: context.colors.blue,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slide.cardSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.colors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_outward_rounded, size: 17, color: context.colors.ink),
      ],
    ),
  );
}
