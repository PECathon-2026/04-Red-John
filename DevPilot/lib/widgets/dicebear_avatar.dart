import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Cute Avatar widget for AI agents.
/// Deterministic, zero-dependency offline cute vector robot avatar generator.
/// Every agent gets a unique, cute robot face with antenna, eyes/visor, and blush cheeks.
class CuteAvatar extends StatelessWidget {
  final String name;
  final double size;

  const CuteAvatar({
    super.key,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final seed = name.trim().toLowerCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: T.surfaceMuted,
        border: Border.all(color: T.border, width: 1),
        borderRadius: T.zero, // Zero radius — square crop
      ),
      clipBehavior: Clip.hardEdge,
      child: CustomPaint(
        size: Size(size, size),
        painter: CuteRobotPainter(seed: seed),
      ),
    );
  }
}

typedef DiceBearAvatar = CuteAvatar;

/// Deterministic vector robot painter for offline cute avatars.
class CuteRobotPainter extends CustomPainter {
  final String seed;

  CuteRobotPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFF;
    }
    final rand = Random(hash);

    final w = size.width;
    final h = size.height;

    // Palette variants
    final faceColors = [
      const Color(0xFF1E1E1E),
      const Color(0xFF262626),
      const Color(0xFF2A2A2A),
      const Color(0xFF222222),
    ];
    final eyeColors = [
      const Color(0xFF22C55E), // emerald
      const Color(0xFF38BDF8), // sky blue
      const Color(0xFFFACC15), // yellow
      const Color(0xFFFAFAFA), // white
      const Color(0xFFA78BFA), // lavender
    ];

    final faceBg = faceColors[rand.nextInt(faceColors.length)];
    final eyeColor = eyeColors[rand.nextInt(eyeColors.length)];

    final bgPaint = Paint()..color = const Color(0xFF151515);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Antenna style
    final antennaType = rand.nextInt(3);
    final antennaPaint = Paint()
      ..color = const Color(0xFF8E8E8E)
      ..strokeWidth = max(1.5, w * 0.04)
      ..style = PaintingStyle.stroke;

    if (antennaType == 0) {
      // Single center ball
      canvas.drawLine(Offset(w * 0.5, h * 0.28), Offset(w * 0.5, h * 0.12), antennaPaint);
      final ballPaint = Paint()..color = eyeColor;
      canvas.drawCircle(Offset(w * 0.5, h * 0.10), w * 0.06, ballPaint);
    } else if (antennaType == 1) {
      // Twin angled antennas
      canvas.drawLine(Offset(w * 0.35, h * 0.28), Offset(w * 0.25, h * 0.12), antennaPaint);
      canvas.drawLine(Offset(w * 0.65, h * 0.28), Offset(w * 0.75, h * 0.12), antennaPaint);
      final tipPaint = Paint()..color = const Color(0xFFFAFAFA);
      canvas.drawCircle(Offset(w * 0.25, h * 0.12), w * 0.04, tipPaint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.12), w * 0.04, tipPaint);
    } else {
      // Little radar dish
      canvas.drawLine(Offset(w * 0.5, h * 0.28), Offset(w * 0.5, h * 0.14), antennaPaint);
      final arcPaint = Paint()
        ..color = const Color(0xFF8E8E8E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, w * 0.04);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.12), radius: w * 0.08),
        pi * 1.1,
        pi * 0.8,
        false,
        arcPaint,
      );
    }

    // Robot head block
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.55),
      width: w * 0.68,
      height: h * 0.52,
    );
    final headPaint = Paint()..color = faceBg;
    final headStroke = Paint()
      ..color = const Color(0xFF383838)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(headRect, headPaint);
    canvas.drawRect(headRect, headStroke);

    // Ears / Bolts on side
    final boltPaint = Paint()..color = const Color(0xFF525252);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(headRect.left - w * 0.03, headRect.center.dy), width: w * 0.06, height: h * 0.14),
      boltPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(headRect.right + w * 0.03, headRect.center.dy), width: w * 0.06, height: h * 0.14),
      boltPaint,
    );

    // Visor or individual eyes
    final eyeStyle = rand.nextInt(3);
    final eyeCenterY = headRect.top + headRect.height * 0.40;

    if (eyeStyle == 0) {
      // Big cute round eyes with sparkle highlight
      final eyeRadius = w * 0.09;
      final leftEye = Offset(headRect.left + headRect.width * 0.32, eyeCenterY);
      final rightEye = Offset(headRect.left + headRect.width * 0.68, eyeCenterY);

      final eyePaint = Paint()..color = eyeColor;
      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);

      // Pupil highlight
      final highlightPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(leftEye.dx - eyeRadius * 0.3, leftEye.dy - eyeRadius * 0.3), eyeRadius * 0.35, highlightPaint);
      canvas.drawCircle(Offset(rightEye.dx - eyeRadius * 0.3, rightEye.dy - eyeRadius * 0.3), eyeRadius * 0.35, highlightPaint);
    } else if (eyeStyle == 1) {
      // Visor band
      final visorRect = Rect.fromCenter(
        center: Offset(headRect.center.dx, eyeCenterY),
        width: headRect.width * 0.78,
        height: headRect.height * 0.32,
      );
      final visorBg = Paint()..color = const Color(0xFF0F0F0F);
      canvas.drawRect(visorRect, visorBg);

      // Digital slit or glow
      final glowPaint = Paint()..color = eyeColor;
      canvas.drawRect(
        Rect.fromCenter(center: visorRect.center, width: visorRect.width * 0.75, height: visorRect.height * 0.4),
        glowPaint,
      );
    } else {
      // Cute square retro pixel eyes
      final eyeSize = w * 0.13;
      final leftEye = Rect.fromCenter(center: Offset(headRect.left + headRect.width * 0.32, eyeCenterY), width: eyeSize, height: eyeSize);
      final rightEye = Rect.fromCenter(center: Offset(headRect.left + headRect.width * 0.68, eyeCenterY), width: eyeSize, height: eyeSize);

      final eyePaint = Paint()..color = eyeColor;
      canvas.drawRect(leftEye, eyePaint);
      canvas.drawRect(rightEye, eyePaint);
    }

    // Cute blush cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF5A1F).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(headRect.left + headRect.width * 0.20, eyeCenterY + h * 0.12), w * 0.04, cheekPaint);
    canvas.drawCircle(Offset(headRect.right - headRect.width * 0.20, eyeCenterY + h * 0.12), w * 0.04, cheekPaint);

    // Mouth: happy smile or audio bar
    final mouthY = headRect.top + headRect.height * 0.76;
    final mouthType = rand.nextInt(2);
    if (mouthType == 0) {
      // Smile arc
      final smilePaint = Paint()
        ..color = const Color(0xFFFAFAFA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, w * 0.035);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(headRect.center.dx, mouthY - h * 0.02), width: w * 0.22, height: h * 0.12),
        pi * 0.1,
        pi * 0.8,
        false,
        smilePaint,
      );
    } else {
      // Audio dots
      final dotPaint = Paint()..color = const Color(0xFF8E8E8E);
      final dotRadius = w * 0.025;
      canvas.drawCircle(Offset(headRect.center.dx - w * 0.07, mouthY), dotRadius, dotPaint);
      canvas.drawCircle(Offset(headRect.center.dx, mouthY), dotRadius, dotPaint);
      canvas.drawCircle(Offset(headRect.center.dx + w * 0.07, mouthY), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CuteRobotPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
