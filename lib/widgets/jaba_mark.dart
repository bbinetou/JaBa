import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Monogramme de marque : deux arcs entrelacés évoquant l'échange entre deux
/// personnes (le cœur du concept JaBa), plutôt qu'une simple icône générique
/// de sac ou de tag. Utilisé dans tous les en-têtes pour donner à
/// l'application une identité visuelle plus originale qu'un wordmark seul.
class JaBaMark extends StatelessWidget {
  final double size;
  const JaBaMark({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bg = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.28)),
      bg,
    );

    // Deux arcs opposés, terracotta et vert, symbolisant l'échange main-à-main.
    final strokeW = w * 0.16;
    final arcGreen = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    final arcTerracotta = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68);
    canvas.drawArc(rect, -2.5, 2.0, false, arcGreen);
    canvas.drawArc(rect, 0.65, 2.0, false, arcTerracotta);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wordmark complet (monogramme + texte), pour les en-têtes principaux.
///
/// Le nom se lit « Ja » + « BA », la terminaison étant détachée en
/// terracotta — la même bichromie que le monogramme.
class JaBaWordmark extends StatelessWidget {
  final bool light; // true = fond foncé (texte clair), false = fond clair
  final double fontSize;
  const JaBaWordmark({super.key, this.light = true, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final textColor = light ? AppColors.background : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        JaBaMark(size: fontSize + 12),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            children: [
              TextSpan(text: 'Ja', style: TextStyle(color: textColor)),
              const TextSpan(text: 'BA', style: TextStyle(color: AppColors.accent)),
            ],
          ),
        ),
      ],
    );
  }
}
