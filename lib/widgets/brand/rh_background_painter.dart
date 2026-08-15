import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated futuristic background for ReserveHub brand panel.
/// Uses CustomPainter to draw scheduling-inspired geometry:
/// subtle grid, flowing lines, connected nodes, soft glow.
class RHFuturisticBackground extends StatefulWidget {
  const RHFuturisticBackground({super.key});

  @override
  State<RHFuturisticBackground> createState() => _RHFuturisticBackgroundState();
}

class _RHFuturisticBackgroundState extends State<RHFuturisticBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RHBackgroundPainter(progress: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _RHBackgroundPainter extends CustomPainter {
  final double progress;

  const _RHBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBaseGradient(canvas, size);
    _drawGrid(canvas, size);
    _drawFlowingLines(canvas, size);
    _drawNodes(canvas, size);
    _drawGlowOrb(canvas, size);
  }

  void _drawBaseGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A0F1E),
          Color(0xFF0D1530),
          Color(0xFF0F1E3D),
          Color(0xFF0A0F1E),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D3B82F6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const cellSize = 56.0;
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    // Subtle offset animation
    final offsetX = (progress * cellSize) % cellSize;
    final offsetY = (progress * cellSize * 0.4) % cellSize;

    for (int c = -1; c < cols; c++) {
      final x = c * cellSize + offsetX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int r = -1; r < rows; r++) {
      final y = r * cellSize + offsetY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawFlowingLines(Canvas canvas, Size size) {
    // 5 flowing diagonal lines representing scheduling flows
    final lines = [
      _FlowLine(
        startFraction: const Offset(0.0, 0.2),
        endFraction: const Offset(1.0, 0.6),
        phase: 0.0,
        opacity: 0.18,
      ),
      _FlowLine(
        startFraction: const Offset(0.0, 0.5),
        endFraction: const Offset(1.0, 0.85),
        phase: 0.25,
        opacity: 0.12,
      ),
      _FlowLine(
        startFraction: const Offset(0.1, 0.0),
        endFraction: const Offset(0.7, 1.0),
        phase: 0.5,
        opacity: 0.10,
      ),
      _FlowLine(
        startFraction: const Offset(0.3, 0.0),
        endFraction: const Offset(1.0, 0.7),
        phase: 0.75,
        opacity: 0.14,
      ),
      _FlowLine(
        startFraction: const Offset(0.0, 0.8),
        endFraction: const Offset(0.6, 0.1),
        phase: 0.6,
        opacity: 0.08,
      ),
    ];

    for (final line in lines) {
      _drawAnimatedLine(canvas, size, line);
    }
  }

  void _drawAnimatedLine(Canvas canvas, Size size, _FlowLine line) {
    final animPhase = (progress + line.phase) % 1.0;

    final start = Offset(
      line.startFraction.dx * size.width,
      line.startFraction.dy * size.height,
    );
    final end = Offset(
      line.endFraction.dx * size.width,
      line.endFraction.dy * size.height,
    );

    // Draw the base line
    final basePaint = Paint()
      ..color = Color.fromRGBO(59, 130, 246, line.opacity * 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, basePaint);

    // Draw the travelling glow segment
    final glowStart = Offset.lerp(start, end, animPhase)!;
    final glowEnd = Offset.lerp(start, end, (animPhase + 0.15).clamp(0, 1))!;

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x003B82F6),
          Color.fromRGBO(59, 130, 246, line.opacity * 2.5),
          const Color(0x003B82F6),
        ],
      ).createShader(Rect.fromPoints(glowStart, glowEnd))
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(glowStart, glowEnd, glowPaint);
  }

  void _drawNodes(Canvas canvas, Size size) {
    // Fixed node positions (calendar/scheduling inspired)
    final nodes = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.35, size.height * 0.15),
      Offset(size.width * 0.65, size.height * 0.30),
      Offset(size.width * 0.80, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.70),
      Offset(size.width * 0.55, size.height * 0.80),
      Offset(size.width * 0.90, size.height * 0.20),
      Offset(size.width * 0.10, size.height * 0.85),
    ];

    // Draw connections between nearby nodes
    final connPaint = Paint()
      ..color = const Color(0x153B82F6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < size.width * 0.35) {
          canvas.drawLine(nodes[i], nodes[j], connPaint);
        }
      }
    }

    // Draw nodes with pulse animation
    for (int i = 0; i < nodes.length; i++) {
      final nodePhase = (progress + i * 0.12) % 1.0;
      final pulseRadius = 3.0 + math.sin(nodePhase * math.pi * 2) * 1.5;

      // Outer glow
      final glowPaint = Paint()
        ..color = const Color(0x203B82F6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodes[i], pulseRadius * 2.5, glowPaint);

      // Core dot
      final dotPaint = Paint()
        ..color = const Color(0x803B82F6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodes[i], pulseRadius * 0.7, dotPaint);
    }
  }

  void _drawGlowOrb(Canvas canvas, Size size) {
    // Soft ambient glow orb — bottom left
    final orbCenter = Offset(size.width * 0.15, size.height * 0.85);
    final orbRadius = size.width * 0.45;

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x151E3A8A),
          const Color(0x0A1E3A8A),
          const Color(0x001E3A8A),
        ],
      ).createShader(Rect.fromCircle(center: orbCenter, radius: orbRadius));
    canvas.drawCircle(orbCenter, orbRadius, orbPaint);

    // Top right secondary orb
    final orb2Center = Offset(size.width * 0.85, size.height * 0.1);
    final orb2Radius = size.width * 0.35;
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x103B82F6),
          const Color(0x053B82F6),
          const Color(0x003B82F6),
        ],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);
  }

  @override
  bool shouldRepaint(_RHBackgroundPainter old) => old.progress != progress;
}

class _FlowLine {
  final Offset startFraction;
  final Offset endFraction;
  final double phase;
  final double opacity;

  const _FlowLine({
    required this.startFraction,
    required this.endFraction,
    required this.phase,
    required this.opacity,
  });
}
