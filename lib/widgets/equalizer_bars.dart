import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small animated equalizer / sound-bars indicator used by the music card.
///
/// Purely decorative for now; it animates continuously regardless of any
/// real playback state.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    required this.color,
    this.barCount = 5,
    this.maxHeight = 18,
  });

  final Color color;
  final int barCount;
  final double maxHeight;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _phases = List.generate(
      widget.barCount,
      (_) => random.nextDouble() * math.pi * 2,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        final t = _controller.value * math.pi * 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            final wave = (math.sin(t + _phases[i]) + 1) / 2; // 0..1
            final height = widget.maxHeight * (0.3 + 0.7 * wave);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
