import 'package:flutter/material.dart';

/// A custom painter that draws a dashed border around a container
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final List<double> dashPattern;
  final double strokeWidth;
  final BorderRadius borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.dashPattern,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path();
    
    path.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    ));

    final Path dashedPath = Path();
    final double dashLength = dashPattern[0];
    final double gapLength = dashPattern[1];
    bool isDash = true;
    
    for (final metric in path.computeMetrics()) {
      double currentDistance = 0.0;
      while (currentDistance < metric.length) {
        final double segmentLength = isDash ? dashLength : gapLength;
        if (currentDistance + segmentLength > metric.length) {
          final segment = metric.extractPath(
            currentDistance,
            metric.length,
          );
          dashedPath.addPath(segment, Offset.zero);
          currentDistance = metric.length;
        } else {
          final segment = metric.extractPath(
            currentDistance,
            currentDistance + segmentLength,
          );
          if (isDash) {
            dashedPath.addPath(segment, Offset.zero);
          }
          currentDistance += segmentLength;
        }
        isDash = !isDash;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// A widget that applies a dashed border to its child
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final List<double> dashPattern;
  final double strokeWidth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const DashedBorderContainer({
    Key? key,
    required this.child,
    required this.color,
    required this.dashPattern,
    this.strokeWidth = 1.0,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        dashPattern: dashPattern,
        strokeWidth: strokeWidth,
        borderRadius: borderRadius,
      ),
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}
