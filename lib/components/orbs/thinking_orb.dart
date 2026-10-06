import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:miraa_shadowing/components/orbs/soving_painter.dart';

class ThinkingOrb extends StatefulWidget {
  final double size;
  final bool dark;
  final double speed;
  final bool paused;

  const ThinkingOrb({
    super.key,
    this.size = 64,
    this.dark = true,
    this.speed = 1.0,
    this.paused = false,
  });

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  double _elapsed = 0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      if (!widget.paused) {
        setState(() {
          _elapsed =
              elapsed.inMicroseconds /
              Duration.microsecondsPerSecond *
              widget.speed;
        });
      }
    });

    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: SolvingPainter(time: _elapsed * 1.82, dark: widget.dark),
      ),
    );
  }
}
