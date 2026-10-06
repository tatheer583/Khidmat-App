import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The same simple home mark is rendered into the Android and iOS app icons.
class KhidmatBrandMark extends StatelessWidget {
  const KhidmatBrandMark({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(size * .27),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: .22),
          blurRadius: size * .32,
          offset: Offset(0, size * .11),
        ),
      ],
    ),
    padding: EdgeInsets.all(size * .16),
    child: CustomPaint(painter: _KhidmatMarkPainter()),
  );
}

class _KhidmatMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 108;
    canvas.save();
    canvas.scale(scale, scale);
    final ink = Paint()
      ..color = const Color(0xFF1A0A05)
      ..style = PaintingStyle.fill;
    final cream = Paint()
      ..color = const Color(0xFFFFF4EE)
      ..style = PaintingStyle.fill;

    final house = Path()
      ..moveTo(14, 49)
      ..lineTo(54, 17)
      ..lineTo(94, 49)
      ..lineTo(85, 49)
      ..lineTo(85, 90)
      ..lineTo(62, 90)
      ..lineTo(62, 68)
      ..lineTo(46, 68)
      ..lineTo(46, 90)
      ..lineTo(23, 90)
      ..lineTo(23, 49)
      ..close();
    canvas.drawPath(house, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 54, 12, 12),
        const Radius.circular(2),
      ),
      cream,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(64, 54, 12, 12),
        const Radius.circular(2),
      ),
      cream,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
