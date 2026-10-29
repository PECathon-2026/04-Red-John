import 'dart:math';
import 'package:flutter/material.dart';

/// Modern Dimensional & Human Avatar for AI agents.
/// 100% offline, zero network requests, deterministic vector painter.
/// No enclosing box/frame behind the avatar — clean, friendly circular avatar with
/// soft accent backgrounds and Apple-style dimensional minimalist illustration.
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

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: ModernHumanAvatarPainter(seed: seed),
        ),
      ),
    );
  }
}

typedef DiceBearAvatar = CuteAvatar;
typedef AgentAvatar = CuteAvatar;

/// Deterministic vector human portrait painter for offline avatars.
class ModernHumanAvatarPainter extends CustomPainter {
  final String seed;

  ModernHumanAvatarPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFF;
    }
    final rand = Random(hash);

    final w = size.width;
    final h = size.height;

    // Pleasant soft pastel/accent backgrounds for light theme
    final bgGradients = [
      [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)], // Indigo
      [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)], // Sky
      [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)], // Purple
      [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)], // Emerald
      [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)], // Amber
      [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)], // Rose
      [const Color(0xFFCCFBF1), const Color(0xFF99F6E4)], // Teal
    ];

    final skinTones = [
      const Color(0xFFFFDFBA),
      const Color(0xFFFBD1A2),
      const Color(0xFFE8B282),
      const Color(0xFFD4976A),
      const Color(0xFFBA7647),
      const Color(0xFF8D5524),
    ];

    final hairColors = [
      const Color(0xFF1E293B), // Slate dark
      const Color(0xFF334155), // Slate
      const Color(0xFF451A03), // Espresso
      const Color(0xFF78350F), // Chestnut
      const Color(0xFF92400E), // Auburn
      const Color(0xFFD97706), // Honey blonde
      const Color(0xFF6366F1), // Electric indigo hair
    ];

    final shirtColors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF0284C7), // Ocean
      const Color(0xFF0D9488), // Teal
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFE11D48), // Rose
      const Color(0xFFEA580C), // Orange
      const Color(0xFF15803D), // Forest
    ];

    final bgPair = bgGradients[rand.nextInt(bgGradients.length)];
    final skin = skinTones[rand.nextInt(skinTones.length)];
    final hair = hairColors[rand.nextInt(hairColors.length)];
    final shirt = shirtColors[rand.nextInt(shirtColors.length)];

    // 1. Background gradient disc
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: bgPair,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.5, bgPaint);

    // 2. Body / Shirt (bottom curve)
    final shirtPaint = Paint()..color = shirt;
    final shirtPath = Path();
    shirtPath.moveTo(w * 0.15, h);
    shirtPath.quadraticBezierTo(w * 0.2, h * 0.72, w * 0.5, h * 0.72);
    shirtPath.quadraticBezierTo(w * 0.8, h * 0.72, w * 0.85, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Collar / neckline detail
    final collarPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.035);
    final collarPath = Path();
    collarPath.moveTo(w * 0.42, h * 0.72);
    collarPath.lineTo(w * 0.5, h * 0.82);
    collarPath.lineTo(w * 0.58, h * 0.72);
    canvas.drawPath(collarPath, collarPaint);

    // 3. Neck
    final neckPaint = Paint()..color = skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.22, height: h * 0.18),
        Radius.circular(w * 0.06),
      ),
      neckPaint,
    );

    // 4. Head / Face
    final facePaint = Paint()..color = skin;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.46, height: h * 0.50),
      facePaint,
    );

    // 5. Hair styles
    final hairStyle = rand.nextInt(4);
    final hairPaint = Paint()..color = hair;

    if (hairStyle == 0) {
      // Modern side-swept / crop
      final p = Path();
      p.moveTo(w * 0.24, h * 0.45);
      p.quadraticBezierTo(w * 0.22, h * 0.20, w * 0.5, h * 0.18);
      p.quadraticBezierTo(w * 0.78, h * 0.20, w * 0.76, h * 0.42);
      p.quadraticBezierTo(w * 0.68, h * 0.26, w * 0.5, h * 0.28);
      p.quadraticBezierTo(w * 0.32, h * 0.30, w * 0.24, h * 0.45);
      p.close();
      canvas.drawPath(p, hairPaint);
    } else if (hairStyle == 1) {
      // Full curls / volume
      canvas.drawCircle(Offset(w * 0.5, h * 0.30), w * 0.28, hairPaint);
      canvas.drawCircle(Offset(w * 0.30, h * 0.38), w * 0.14, hairPaint);
      canvas.drawCircle(Offset(w * 0.70, h * 0.38), w * 0.14, hairPaint);
    } else if (hairStyle == 2) {
      // Bob / sleek fringe
      final p = Path();
      p.moveTo(w * 0.24, h * 0.55);
      p.lineTo(w * 0.24, h * 0.30);
      p.quadraticBezierTo(w * 0.5, h * 0.16, w * 0.76, h * 0.30);
      p.lineTo(w * 0.76, h * 0.55);
      p.quadraticBezierTo(w * 0.70, h * 0.34, w * 0.50, h * 0.32);
      p.quadraticBezierTo(w * 0.30, h * 0.34, w * 0.24, h * 0.55);
      p.close();
      canvas.drawPath(p, hairPaint);
    } else {
      // Top knot / beanie
      canvas.drawCircle(Offset(w * 0.5, h * 0.16), w * 0.10, hairPaint);
      final p = Path();
      p.moveTo(w * 0.25, h * 0.40);
      p.quadraticBezierTo(w * 0.5, h * 0.22, w * 0.75, h * 0.40);
      p.quadraticBezierTo(w * 0.5, h * 0.30, w * 0.25, h * 0.40);
      p.close();
      canvas.drawPath(p, hairPaint);
    }

    // 6. Eyes & Eyebrows (Dimensional minimalist clean look)
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final eyeRadius = max(1.5, w * 0.032);
    canvas.drawCircle(Offset(w * 0.42, h * 0.46), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.46), eyeRadius, eyePaint);

    // Friendly smile
    final smilePaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.2, w * 0.03);
    final smilePath = Path();
    smilePath.moveTo(w * 0.45, h * 0.56);
    smilePath.quadraticBezierTo(w * 0.5, h * 0.60, w * 0.55, h * 0.56);
    canvas.drawPath(smilePath, smilePaint);

    // Subtle soft blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFB7185).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.52), w * 0.045, blushPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.52), w * 0.045, blushPaint);

    // Optional glasses for some agents
    final hasGlasses = rand.nextBool();
    if (hasGlasses) {
      final glassesPaint = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, w * 0.028);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.41, h * 0.46), width: w * 0.16, height: h * 0.12),
          Radius.circular(w * 0.03),
        ),
        glassesPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.59, h * 0.46), width: w * 0.16, height: h * 0.12),
          Radius.circular(w * 0.03),
        ),
        glassesPaint,
      );
      canvas.drawLine(Offset(w * 0.49, h * 0.46), Offset(w * 0.51, h * 0.46), glassesPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ModernHumanAvatarPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
