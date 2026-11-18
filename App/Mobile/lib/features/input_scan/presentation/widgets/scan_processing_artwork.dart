import 'package:flutter/widgets.dart';

import '../../../../theme/app_colors.dart';

/// The decorative scan pass shares the processing screen's two-second timeline.
class ScanProcessingArtwork extends StatelessWidget {
  const ScanProcessingArtwork({super.key, required this.intro});

  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? const AlwaysStoppedAnimation(1.0)
        : intro;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 144,
            child: CustomPaint(
              painter: _ScanPass(motion, background: context.colors.scanner),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanPass extends CustomPainter {
  _ScanPass(this.motion, {required this.background}) : super(repaint: motion);

  final Animation<double> motion;
  final Color background;
  static const _accent = AppColors.scannerAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final panel = Offset.zero & size;
    canvas.drawRect(
      panel,
      Paint()
        ..shader = RadialGradient(
          radius: 0.74,
          colors: [Color.lerp(background, _accent, 0.18)!, background],
        ).createShader(panel),
    );

    canvas.translate(size.width / 2, size.height / 2);
    final fit = (size.width / 184).clamp(0.0, 1.0);
    canvas.scale(fit);

    final grid = Paint()..color = _accent.withValues(alpha: 0.22);
    for (var x = -80; x <= 80; x += 16) {
      for (var y = -48; y <= 48; y += 16) {
        canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), 0.8, grid);
      }
    }

    final focus = const Interval(
      0,
      0.24,
      curve: Curves.easeOutExpo,
    ).transform(motion.value);
    final frame = Paint()
      ..color = _accent.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.5;
    for (final horizontal in [-1.0, 1.0]) {
      for (final vertical in [-1.0, 1.0]) {
        final x = (77 - 9 * focus) * horizontal;
        final y = (53 - 8 * focus) * vertical;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 10 * vertical)
            ..lineTo(x, y)
            ..lineTo(x - 12 * horizontal, y),
          frame,
        );
      }
    }

    final shield = Path()
      ..moveTo(0, -33)
      ..quadraticBezierTo(11, -27, 26, -24)
      ..lineTo(26, -5)
      ..cubicTo(26, 13, 14, 24, 0, 31)
      ..cubicTo(-14, 24, -26, 13, -26, -5)
      ..lineTo(-26, -24)
      ..quadraticBezierTo(-11, -27, 0, -33)
      ..close();
    canvas.drawPath(shield, Paint()..color = background);
    canvas.drawPath(shield, frame);

    canvas.save();
    canvas.translate(0, -4);
    canvas.rotate(-0.65);
    final link = frame
      ..color = AppColors.scannerCopy
      ..strokeWidth = 2.2;
    canvas.drawRRect(
      RRect.fromLTRBR(-15, -5, -2, 5, const Radius.circular(5)),
      link,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(2, -5, 15, 5, const Radius.circular(5)),
      link,
    );
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), link);
    canvas.restore();

    final sweep = const Interval(
      0.12,
      0.86,
      curve: Curves.easeInOutCubic,
    ).transform(motion.value);
    final visibility = (4 * sweep * (1 - sweep)).clamp(0.0, 1.0);
    final y = -46 + 92 * sweep;
    final band = Rect.fromLTRB(-86, y - 22, 86, y);
    final clear = _accent.withValues(alpha: 0);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            clear,
            _accent.withValues(alpha: 0.34 * visibility),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(band.left, y),
      Offset(band.right, y),
      Paint()
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [
            clear,
            _accent.withValues(alpha: visibility),
            clear,
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPass oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.background != background;
}
