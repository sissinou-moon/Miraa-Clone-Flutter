import 'package:flutter/material.dart';

import 'solving_engine.dart';

class SolvingPainter extends CustomPainter {
  final double time;
  final bool dark;

  const SolvingPainter({required this.time, this.dark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final dots = SolvingEngine.frame(size: size.width, time: time);

    for (final dot in dots) {
      final value = dark ? 0.6 - dot.white : dot.white;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromARGB(255, 0, 0, 0);

      canvas.drawCircle(Offset(dot.x, dot.y), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(SolvingPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.dark != dark;
  }
}
