import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Geo-Tag Catch screen — an AR-style cache finder.
///
/// The camera viewport is a static mockup (sky, forest, crosshair, AR pin).
/// Real camera/AR + distance tracking can be layered in later.
class GeoTagScreen extends StatelessWidget {
  const GeoTagScreen({super.key});

  static const List<_CacheStep> _steps = [
    _CacheStep('#12', 'Дуб-великан', 'Найден', done: true),
    _CacheStep('#47', 'Поляна', '38 м', done: true),
    _CacheStep('#33', 'Скала', '890 м'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.geoBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CameraView(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _DistanceProgress(distance: '38 м', progress: 0.62),
                    const SizedBox(height: 10),
                    _StepsRow(steps: _steps),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // Sky / ground bands.
          Positioned.fill(child: Container(color: const Color(0xFFB8EBD8))),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 100, child: ColoredBox(color: Color(0xFFC7EDFF))),
          ),
          const Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: SizedBox(height: 100, child: ColoredBox(color: Color(0xFF7BC67E))),
          ),
          // Trees.
          const Positioned(
            bottom: 0,
            left: 16,
            child: _Tree(treeColor: Color(0xFF1E7D43), topSize: 36, trunkHeight: 40),
          ),
          const Positioned(
            bottom: 0,
            right: 24,
            child: _Tree(treeColor: Color(0xFF2D8A55), topSize: 28, trunkHeight: 28),
          ),
          const Positioned(
            bottom: 4,
            left: 70,
            child: _Tree(treeColor: Color(0xFF247A3C), topSize: 44, trunkHeight: 32),
          ),
          // AR pin bubble.
          Positioned(
            top: 36,
            left: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.mint, width: 2),
                  ),
                  child: Text(
                    'Тайник #47',
                    style: AppTextStyles.body(
                      size: 11,
                      weight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(12, 7),
                  painter: _TrianglePainter(AppColors.mint),
                ),
              ],
            ),
          ),
          // Crosshair.
          const Center(child: _Crosshair()),
          // Distance badge.
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '38 м',
                style: AppTextStyles.body(
                  size: 11,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tree extends StatelessWidget {
  const _Tree({
    required this.treeColor,
    required this.topSize,
    required this.trunkHeight,
  });

  final Color treeColor;
  final double topSize;
  final double trunkHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(topSize, topSize),
          painter: _TrianglePainter(treeColor, pointUp: true),
        ),
        Container(
          width: topSize * 0.22,
          height: trunkHeight,
          color: const Color(0xFF4A7C59),
        ),
      ],
    );
  }
}

/// Draws a filled triangle, either pointing up (tree top) or down (bubble tail).
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color, {this.pointUp = false});

  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointUp != pointUp;
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xCC00C9A7);
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 56, height: 2, color: lineColor),
          Container(width: 2, height: 56, color: lineColor),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mint, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceProgress extends StatelessWidget {
  const _DistanceProgress({required this.distance, required this.progress});

  final String distance;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'До тайника',
                style: AppTextStyles.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(distance, style: AppTextStyles.display(size: 13, color: AppColors.mint)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFD0F5EC),
              valueColor: const AlwaysStoppedAnimation(AppColors.mint),
            ),
          ),
        ],
      ),
    );
  }
}

class _CacheStep {
  const _CacheStep(this.number, this.name, this.distance, {this.done = false});

  final String number;
  final String name;
  final String distance;
  final bool done;
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.steps});

  final List<_CacheStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _StepCard(step: steps[i])),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _CacheStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: step.done ? AppColors.mint : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.number,
            style: AppTextStyles.display(
              size: 13,
              color: step.done ? AppColors.mint : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.name,
            style: AppTextStyles.body(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            step.distance,
            style: AppTextStyles.body(
              size: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
