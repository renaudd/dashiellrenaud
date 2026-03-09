import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_item.dart';

/// A widget that renders a visual representation of a [GameItem]
/// using a geometric shape and color.
class GameItemRenderer extends StatelessWidget {
  final GameItem item;
  final double size;
  final bool showLabel;

  const GameItemRenderer({
    super.key,
    required this.item,
    this.size = 24.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ItemShapePainter(shape: item.shape, color: item.color),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            item.name,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _ItemShapePainter extends CustomPainter {
  final ItemShape shape;
  final Color color;

  _ItemShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (shape) {
      case ItemShape.circle:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, borderPaint);
        break;
      case ItemShape.square:
        final rect = Rect.fromCircle(center: center, radius: radius * 0.9);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
        break;
      case ItemShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx - radius, center.dy + radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
      case ItemShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
      case ItemShape.hexagon:
        final hexPath = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * (pi / 180);
          final px = center.dx + radius * cos(angle);
          final py = center.dy + radius * sin(angle);
          if (i == 0) {
            hexPath.moveTo(px, py);
          } else {
            hexPath.lineTo(px, py);
          }
        }
        hexPath.close();
        canvas.drawPath(hexPath, paint);
        canvas.drawPath(hexPath, borderPaint);
        break;
      case ItemShape.pill:
        final rRect = RRect.fromLTRBR(
          center.dx - radius * 0.8,
          center.dy - radius * 0.4,
          center.dx + radius * 0.8,
          center.dy + radius * 0.4,
          Radius.circular(radius * 0.4),
        );
        canvas.drawRRect(rRect, paint);
        canvas.drawRRect(rRect, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
