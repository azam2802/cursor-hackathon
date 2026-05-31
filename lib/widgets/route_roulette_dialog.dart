import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_destinations.dart';
import '../models/route_destination.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Popup roulette that cycles through destinations and returns the winner.
class RouteRouletteDialog extends StatefulWidget {
  const RouteRouletteDialog({super.key});

  static Future<RouteDestination?> show(BuildContext context) {
    return showDialog<RouteDestination>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RouteRouletteDialog(),
    );
  }

  @override
  State<RouteRouletteDialog> createState() => _RouteRouletteDialogState();
}

class _RouteRouletteDialogState extends State<RouteRouletteDialog>
    with SingleTickerProviderStateMixin {
  static const _spinTicks = 14;
  static const _resultPause = Duration(milliseconds: 900);

  late final AnimationController _wheelController;
  final _random = Random();

  RouteDestination? _preview;
  bool _spinning = true;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _startSpin();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  Future<void> _startSpin() async {
    final pool = List<RouteDestination>.from(mockDestinations)..shuffle(_random);
    final winner = pool.first;

    _wheelController.repeat();
    for (var i = 0; i < _spinTicks; i++) {
      if (!mounted) return;
      setState(() {
        _preview = pool[_random.nextInt(pool.length)];
      });
      await Future<void>.delayed(Duration(milliseconds: 80 + i * 12));
    }

    if (!mounted) return;
    _wheelController.stop();
    HapticFeedback.mediumImpact();

    setState(() {
      _spinning = false;
      _preview = winner;
    });

    await Future<void>.delayed(_resultPause);
    if (mounted) Navigator.of(context).pop(winner);
  }

  @override
  Widget build(BuildContext context) {
    final label = _preview?.title.replaceAll('\n', ' ') ?? '...';

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Рулетка авто-маршрутов',
              textAlign: TextAlign.center,
              style: AppTextStyles.display(size: 20),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: 120,
              child: AnimatedBuilder(
                animation: _wheelController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _wheelController.value * pi * 6,
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        AppColors.coral,
                        AppColors.sun,
                        AppColors.mint,
                        AppColors.warm,
                        AppColors.coral,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route,
                        color: AppColors.coral,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                label,
                key: ValueKey(label),
                textAlign: TextAlign.center,
                style: AppTextStyles.display(size: 18, color: AppColors.coral),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _spinning ? 'Крутим...' : 'Ваш маршрут готов!',
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
