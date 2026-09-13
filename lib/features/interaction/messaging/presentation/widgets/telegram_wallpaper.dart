import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders Telegram's iconic subtle doodle canvas wallpaper.
class TelegramWallpaper extends StatelessWidget {
  final Widget? child;
  final bool isDark;

  const TelegramWallpaper({
    super.key,
    this.child,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0E1621) : const Color(0xFFEFE7DE);
    final doodleColor = isDark
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.black.withValues(alpha: 0.045);

    return Container(
      color: bgColor,
      child: CustomPaint(
        painter: _TelegramDoodlePainter(doodleColor: doodleColor),
        child: child,
      ),
    );
  }
}

class _TelegramDoodlePainter extends CustomPainter {
  final Color doodleColor;

  _TelegramDoodlePainter({required this.doodleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = doodleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = doodleColor
      ..style = PaintingStyle.fill;

    const spacing = 110.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final offsetX = (r % 2 == 1) ? spacing * 0.5 : 0.0;
        final x = c * spacing + offsetX;
        final y = r * spacing;

        final shapeType = (r * 7 + c * 13) % 6;
        _drawDoodle(canvas, x, y, shapeType, paint, fillPaint);
      }
    }
  }

  void _drawDoodle(
    Canvas canvas,
    double cx,
    double cy,
    int type,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    canvas.save();
    canvas.translate(cx, cy);

    switch (type) {
      case 0:
        // Mini paper airplane (Telegram logo motif)
        final path = Path()
          ..moveTo(-10, 8)
          ..lineTo(12, -8)
          ..lineTo(2, 10)
          ..lineTo(-2, 4)
          ..close();
        canvas.drawPath(path, strokePaint);
        break;

      case 1:
        // Mini chat bubble
        final rrect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -8, 20, 14),
          const Radius.circular(5),
        );
        canvas.drawRRect(rrect, strokePaint);
        final tail = Path()
          ..moveTo(-4, 6)
          ..lineTo(-8, 10)
          ..lineTo(0, 6);
        canvas.drawPath(tail, strokePaint);
        break;

      case 2:
        // Sparkle / Four-pointed star
        final star = Path()
          ..moveTo(0, -9)
          ..quadraticBezierTo(0, 0, 9, 0)
          ..quadraticBezierTo(0, 0, 0, 9)
          ..quadraticBezierTo(0, 0, -9, 0)
          ..quadraticBezierTo(0, 0, 0, -9);
        canvas.drawPath(star, strokePaint);
        break;

      case 3:
        // Little heart
        final heart = Path()
          ..moveTo(0, 4)
          ..cubicTo(-7, -4, -10, -8, -5, -11)
          ..cubicTo(-2, -12, 0, -9, 0, -7)
          ..cubicTo(0, -9, 2, -12, 5, -11)
          ..cubicTo(10, -8, 7, -4, 0, 4)
          ..close();
        canvas.drawPath(heart, strokePaint);
        break;

      case 4:
        // Music note
        canvas.drawCircle(const Offset(-4, 6), 3, fillPaint);
        canvas.drawLine(const Offset(-1, 6), const Offset(-1, -6), strokePaint);
        canvas.drawLine(const Offset(-1, -6), const Offset(5, -4), strokePaint);
        break;

      case 5:
      default:
        // Ring of dots
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final px = 7 * math.cos(angle);
          final py = 7 * math.sin(angle);
          canvas.drawCircle(Offset(px, py), 1.0, fillPaint);
        }
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TelegramDoodlePainter oldDelegate) {
    return oldDelegate.doodleColor != doodleColor;
  }
}
