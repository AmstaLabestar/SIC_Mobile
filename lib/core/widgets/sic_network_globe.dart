import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import 'sic_logo.dart';

/// Un widget premium representant un globe de reseaux d'operateurs connectes.
/// Affiche le logo de marque SIC au centre et les logos des operateurs
/// (Orange, Wave, Moov, Telecel, Coris, Sank) positionnes de maniere circulaire,
/// relies par des lignes animees (avec particules).
/// Concu pour un fond blanc ou tres clair.
class SicNetworkGlobe extends StatefulWidget {
  const SicNetworkGlobe({super.key, this.size = 280});

  final double size;

  @override
  State<SicNetworkGlobe> createState() => _SicNetworkGlobeState();
}

class _SicNetworkGlobeState extends State<SicNetworkGlobe>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.size * 0.35;
    final double centerX = widget.size / 2;
    final double centerY = widget.size / 2;

    final double step = 2 * math.pi / 7;
    final List<_OperatorNodeData> nodes = [
      _OperatorNodeData(
        angle: -math.pi / 2, // Haut (Orange Money)
        label: 'Orange Money',
        asset: AppAssets.orangeMoney,
        color: const Color(0xFFFF7900),
        isActive: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + step, // Haut Droite (Wave)
        label: 'Wave',
        asset: AppAssets.waveMoney,
        color: const Color(0xFF1A73E8),
        isActive: true,
        showBadge: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + 2 * step, // Bas Droite (Moov Money)
        label: 'Moov Money',
        asset: AppAssets.moovMoney,
        color: const Color(0xFF005DAA),
        isActive: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + 3 * step, // Bas (Telecel)
        label: 'Telecel Money',
        asset: AppAssets.telecelMoney,
        color: const Color(0xFF1B8C5E),
        isActive: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + 4 * step, // Bas Gauche (Coris Money)
        label: 'Coris Money',
        asset: AppAssets.corisMoney,
        color: const Color(0xFF8B1A1A),
        isActive: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + 5 * step, // Gauche (MTN Money)
        label: 'MTN Money',
        asset: AppAssets.mtnMoney,
        color: const Color(0xFFFFCC00),
        isActive: true,
      ),
      _OperatorNodeData(
        angle: -math.pi / 2 + 6 * step, // Haut Gauche (Sank Money)
        label: 'Sank Money',
        asset: AppAssets.sankMoney,
        color: const Color(0xFFE52E2E),
        isActive: true,
      ),
    ];

    // Definition des flux dynamiques de reseau a reseau
    final List<_NetworkFlow> flows = [
      // Flux circulaires peripheriques
      const _NetworkFlow(from: 0, to: 1, delay: 0.0, color: Color(0xFFFF7900)),
      const _NetworkFlow(from: 1, to: 2, delay: 0.14, color: Color(0xFF1A73E8)),
      const _NetworkFlow(from: 2, to: 3, delay: 0.28, color: Color(0xFF005DAA)),
      const _NetworkFlow(from: 3, to: 4, delay: 0.42, color: Color(0xFF1B8C5E)),
      const _NetworkFlow(from: 4, to: 5, delay: 0.56, color: Color(0xFF8B1A1A)),
      const _NetworkFlow(from: 5, to: 6, delay: 0.70, color: Color(0xFFFFCC00)),
      const _NetworkFlow(from: 6, to: 0, delay: 0.84, color: Color(0xFFE52E2E)),

      // Flux transversaux croises
      const _NetworkFlow(from: 0, to: 3, delay: 0.20, color: Color(0xFFFF7900)),
      const _NetworkFlow(from: 1, to: 4, delay: 0.35, color: Color(0xFF1A73E8)),
      const _NetworkFlow(from: 2, to: 5, delay: 0.50, color: Color(0xFF005DAA)),
      const _NetworkFlow(from: 3, to: 6, delay: 0.65, color: Color(0xFF1B8C5E)),
      const _NetworkFlow(from: 4, to: 0, delay: 0.80, color: Color(0xFF8B1A1A)),
      const _NetworkFlow(from: 5, to: 1, delay: 0.10, color: Color(0xFFFFCC00)),
      const _NetworkFlow(from: 6, to: 2, delay: 0.40, color: Color(0xFFE52E2E)),
    ];

    return SizedBox(
      width: widget.size,
      height: widget.size + 15,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Trace des lignes et du cercle principal
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GlobePainter(
                  radius: radius,
                  nodes: nodes,
                  flows: flows,
                  animationValue: _controller.value,
                ),
              );
            },
          ),

          // Noeud central : Logo de marque SIC (le Globe)
          Positioned(
            left: centerX - 35,
            top: centerY - 35,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: const ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(3.0),
                  child: SicLogo(size: 64, elevated: false),
                ),
              ),
            ),
          ),

          // Noeuds des differents operateurs tout autour
          ...nodes.map((node) {
            final x = centerX + radius * math.cos(node.angle);
            final y = centerY + radius * math.sin(node.angle);
            const double logoSize = 54;

            return Positioned(
              left: x - (logoSize / 2),
              top: y - (logoSize / 2),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (node.isActive) {
                    scale =
                        1.0 + 0.04 * math.sin(_controller.value * 2 * math.pi);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: node.isActive
                              ? node.color.withOpacity(0.8)
                              : const Color(0xFFE2E8F0),
                          width: node.isActive ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: node.isActive
                                ? node.color.withOpacity(0.22)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: node.isActive ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Image.asset(
                            node.asset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Text(
                                node.label.substring(0, 2).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OperatorNodeData {
  _OperatorNodeData({
    required this.angle,
    required this.label,
    required this.asset,
    required this.color,
    required this.isActive,
    this.showBadge = false,
  });

  final double angle;
  final String label;
  final String asset;
  final Color color;
  final bool isActive;
  final bool showBadge;
}

class _NetworkFlow {
  final int from;
  final int to;
  final double delay;
  final Color color;

  const _NetworkFlow({
    required this.from,
    required this.to,
    required this.delay,
    required this.color,
  });
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({
    required this.radius,
    required this.nodes,
    required this.flows,
    required this.animationValue,
  });

  final double radius;
  final List<_OperatorNodeData> nodes;
  final List<_NetworkFlow> flows;
  final double animationValue;

  double _distanceToLine(Offset p, Offset a, Offset b) {
    final num = ((b.dy - a.dy) * p.dx -
            (b.dx - a.dx) * p.dy +
            b.dx * a.dy -
            b.dy * a.dx)
        .abs();
    final den = math.sqrt(math.pow(b.dy - a.dy, 2) + math.pow(b.dx - a.dx, 2));
    return den == 0 ? 0 : num / den;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // 1. Cercle exterieur principal
    final circlePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, circlePaint);

    // 2. Lignes de connexion radiales centre -> operateurs (subtiles/statiques pour eviter la surcharge)
    for (final node in nodes) {
      final double targetX = centerX + radius * math.cos(node.angle);
      final double targetY = centerY + radius * math.sin(node.angle);
      final target = Offset(targetX, targetY);

      final radialPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(center, target, radialPaint);
    }

    // 3. Dessin des courbes de flux de reseau a reseau
    for (final flow in flows) {
      final double fromAngle = nodes[flow.from].angle;
      final double toAngle = nodes[flow.to].angle;

      final p0 = Offset(centerX + radius * math.cos(fromAngle),
          centerY + radius * math.sin(fromAngle));
      final p2 = Offset(centerX + radius * math.cos(toAngle),
          centerY + radius * math.sin(toAngle));

      // Calcul du point de controle pour courber la ligne
      final double dist = _distanceToLine(center, p0, p2);
      Offset control;
      if (dist < 15) {
        // La corde passe tres pres du centre : on decale perpendiculairement pour contourner le logo central
        final dx = p2.dx - p0.dx;
        final dy = p2.dy - p0.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final nx = -dy / len;
        final ny = dx / len;
        control = center + Offset(nx, ny) * 35;
      } else {
        // Courbe plus simple vers le centre
        control = center * 0.4 + (p0 + p2) * 0.3;
      }

      final path = Path();
      path.moveTo(p0.dx, p0.dy);
      path.quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);

      // Dessin de la ligne de flux
      final curvePaint = Paint()
        ..color = flow.color.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      canvas.drawPath(path, curvePaint);

      // Animation de la particule sur la courbe
      final double t = (animationValue + flow.delay) % 1.0;
      final double mt = 1.0 - t;
      final double px =
          mt * mt * p0.dx + 2 * mt * t * control.dx + t * t * p2.dx;
      final double py =
          mt * mt * p0.dy + 2 * mt * t * control.dy + t * t * p2.dy;
      final particleOffset = Offset(px, py);

      // Glow de la particule
      final glowPaint = Paint()
        ..color = flow.color.withOpacity(0.30)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particleOffset, 8.0, glowPaint);

      // Noyau de la particule
      final particlePaint = Paint()
        ..color = flow.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particleOffset, 4.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
