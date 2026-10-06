import 'dart:math' as math;

class OrbDot {
  final double x;
  final double y;
  final double z;
  final double radius;
  final double white;

  const OrbDot({
    required this.x,
    required this.y,
    required this.z,
    required this.radius,
    required this.white,
  });
}

class _Move {
  final int axis;
  final double lo;
  final double hi;
  final double angle;

  const _Move({
    required this.axis,
    required this.lo,
    required this.hi,
    required this.angle,
  });
}

class SolvingEngine {
  static const double speed = 1.82;

  // Resolved from the original 64px preset:
  //
  // latRings 15 * sqrt(0.35) → 9
  // lonDensity 40 * sqrt(0.35) → 24
  // radius × 1.05
  static const int latRings = 9;
  static const int lonDensity = 24;
  static const int moveCount = 14;

  static const double rBase = 0.6 * 1.05;
  static const double rDepth = 1.7 * 1.05;
  static const double rActive = 0.3 * 1.05;

  static List<OrbDot> frame({required double size, required double time}) {
    final cx = size / 2;
    final cy = size / 2;
    final radius = (size / 2) * 0.82;

    final yaw = time * 0.55;
    final tilt = 0.35 + 0.1 * math.sin(time * 0.9);

    final rs = math.pow(size / 300, 0.6).toDouble();

    final moves = _makeMoves(moveCount);
    final cycle = _solveCycle(time, moveCount, 0.42, 1.2);

    final dots = <OrbDot>[];

    for (int li = 0; li <= latRings; li++) {
      final lat = -math.pi / 2 + (li / latRings) * math.pi;

      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);

      final lonCount = math.max(1, (cosLat.abs() * lonDensity).round());

      for (int lj = 0; lj < lonCount; lj++) {
        final lon = (lj / lonCount) * 2 * math.pi;

        final x = cosLat * math.cos(lon);

        final y = sinLat;

        final z = cosLat * math.sin(lon);

        final moved = _applyMoves(x, y, z, moves, cycle);

        final projected = _project(
          moved.x,
          moved.y,
          moved.z,
          yaw,
          tilt,
          cx,
          cy,
          radius,
        );

        final projectedZ = projected.z;

        final depth = (projectedZ + 1) / 2;

        final activeBonus = moved.active ? rActive : 0;

        final dotRadius = (rBase + rDepth * depth + activeBonus) * rs;

        final white = 0.62 - 0.54 * depth - (moved.active ? 0.14 : 0);

        dots.add(
          OrbDot(
            x: projected.x,
            y: projected.y,
            z: projectedZ,
            radius: math.max(0.3, dotRadius),
            white: white.clamp(0.0, 1.0),
          ),
        );
      }
    }

    // Original library sorts far → near.
    dots.sort((a, b) => a.z.compareTo(b.z));

    return dots;
  }

  static double _hash(double a, double b) {
    final h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;

    return h - h.floorToDouble();
  }

  static List<_Move> _makeMoves(int count) {
    final moves = <_Move>[];

    for (int i = 0; i < count; i++) {
      final axis = math.min(2, (_hash(i.toDouble(), 2.3) * 3).floor());

      final lo =
          -1.0 + 0.5 * math.min(3, (_hash(i.toDouble(), 5.9) * 4).floor());

      final direction = _hash(i.toDouble(), 7.7) < 0.5 ? 1 : -1;

      moves.add(
        _Move(axis: axis, lo: lo, hi: lo + 0.5, angle: direction * math.pi / 2),
      );
    }

    return moves;
  }

  static _SolveCycle _solveCycle(
    double time,
    int count,
    double slotDuration,
    double rest,
  ) {
    final cycle = 2 * count * slotDuration + rest;

    final tc = time % cycle;

    final amount = List<double>.filled(count, 0);

    int active = -1;

    if (tc < 2 * count * slotDuration) {
      final slot = (tc / slotDuration).floor();

      final p = (tc - slot * slotDuration) / slotDuration;

      final cl = math.min(1, p / 0.7);

      // ease-out cubic
      final ep = 1 - math.pow(1 - cl, 3);

      if (slot < count) {
        for (int i = 0; i < slot; i++) {
          amount[i] = 1;
        }

        amount[slot] = ep.toDouble();
        active = slot;
      } else {
        final u = 2 * count - 1 - slot;

        for (int i = 0; i < u; i++) {
          amount[i] = 1;
        }

        amount[u] = 1 - ep.toDouble();

        active = u;
      }
    }

    return _SolveCycle(amount: amount, active: active);
  }

  static _MovedPoint _applyMoves(
    double originalX,
    double originalY,
    double originalZ,
    List<_Move> moves,
    _SolveCycle cycle,
  ) {
    double x = originalX;
    double y = originalY;
    double z = originalZ;

    bool active = false;

    for (int i = 0; i < moves.length; i++) {
      if (cycle.amount[i] <= 0) {
        continue;
      }

      final move = moves[i];

      final coordinate = switch (move.axis) {
        0 => x,
        1 => y,
        _ => z,
      };

      if (coordinate < move.lo || coordinate >= move.hi) {
        continue;
      }

      if (i == cycle.active) {
        active = true;
      }

      final angle = move.angle * cycle.amount[i];

      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      if (move.axis == 0) {
        final newY = y * cosA - z * sinA;

        z = y * sinA + z * cosA;

        y = newY;
      } else if (move.axis == 1) {
        final newX = x * cosA + z * sinA;

        z = -x * sinA + z * cosA;

        x = newX;
      } else {
        final newX = x * cosA - y * sinA;

        y = x * sinA + y * cosA;

        x = newX;
      }
    }

    return _MovedPoint(x: x, y: y, z: z, active: active);
  }

  static _ProjectedPoint _project(
    double x,
    double y,
    double z,
    double yaw,
    double tilt,
    double cx,
    double cy,
    double scale,
  ) {
    final sinTilt = math.sin(tilt);
    final cosTilt = math.cos(tilt);

    final sinYaw = math.sin(yaw);
    final cosYaw = math.cos(yaw);

    final x1 = x * cosYaw + z * sinYaw;

    final z1 = -x * sinYaw + z * cosYaw;

    final y1 = y * cosTilt - z1 * sinTilt;

    final z2 = y * sinTilt + z1 * cosTilt;

    return _ProjectedPoint(x: cx + x1 * scale, y: cy - y1 * scale, z: z2);
  }
}

class _SolveCycle {
  final List<double> amount;
  final int active;

  const _SolveCycle({required this.amount, required this.active});
}

class _MovedPoint {
  final double x;
  final double y;
  final double z;
  final bool active;

  const _MovedPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.active,
  });
}

class _ProjectedPoint {
  final double x;
  final double y;
  final double z;

  const _ProjectedPoint({required this.x, required this.y, required this.z});
}
