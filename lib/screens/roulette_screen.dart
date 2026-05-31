import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/equalizer_bars.dart';

/// Roadtrip Roulette screen — surfaces a single randomly picked destination.
///
/// This is a static UI implementation. Hooks (e.g. [_onSpin]) are left as
/// placeholders so the roulette logic can be wired in later.
class RouletteScreen extends StatelessWidget {
  const RouletteScreen({super.key});

  void _onSpin() {
    // TODO: trigger a new random destination roll.
  }

  void _onPlayMusic() {
    // TODO: connect to the road-trip playlist / music provider.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.rouletteBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RouletteHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RandomRouteChip(),
                    const SizedBox(height: 12),
                    Text(
                      'Горное озеро\nс каяками',
                      style: AppTextStyles.display(size: 26, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Радиус 100 км · Прямо сейчас',
                      style: AppTextStyles.body(
                        size: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _StatsRow(),
                    const SizedBox(height: 16),
                    _SpinButton(onPressed: _onSpin),
                    const SizedBox(height: 12),
                    _MusicCard(onPlay: _onPlayMusic),
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

class _RouletteHero extends StatelessWidget {
  const _RouletteHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.rouletteHero)),
          // Decorative suns peeking from the top-right corner.
          Positioned(
            top: -40,
            right: -40,
            child: _circle(140, AppColors.sun.withValues(alpha: 0.6)),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: _circle(100, const Color(0xFFFFBA08).withValues(alpha: 0.8)),
          ),
          // Road with dashed center line.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _RoadClipper(),
              child: Container(height: 80, color: const Color(0xFFE8C95C)),
            ),
          ),
          const Positioned(
            bottom: 22,
            left: 40,
            right: 40,
            child: _DashedLine(),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(child: Text('🚗', style: TextStyle(fontSize: 40))),
          ),
          // Destination card.
          Positioned(
            top: 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 15,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluestone Lake',
                        style: AppTextStyles.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '87 км · 1ч 12м',
                        style: AppTextStyles.body(
                          size: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Clips a container into the slanted road shape used in the hero.
class _RoadClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 14.0;
        const gapWidth = 10.0;
        var count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();
        if (count < 1) count = 1;
        if (count > 60) count = 60;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RandomRouteChip extends StatelessWidget {
  const _RandomRouteChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF8B6A00)),
          const SizedBox(width: 5),
          Text(
            'Случайный маршрут',
            style: AppTextStyles.body(
              size: 12,
              weight: FontWeight.w800,
              color: const Color(0xFF8B6A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(value: '87', label: 'км')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '4.8', label: 'рейтинг')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: 'бесплатно', label: 'вход')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: AppTextStyles.display(size: 20),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.body(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  const _SpinButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.refresh, size: 20),
        label: Text(
          'Крутить снова!',
          style: AppTextStyles.display(
            size: 16,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MusicCard extends StatelessWidget {
  const _MusicCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const EqualizerBars(color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Road Trip Vibes ☀️',
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '12 треков · Spotify',
                  style: AppTextStyles.body(
                    size: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow, color: AppColors.coral),
          ),
        ],
      ),
    );
  }
}
