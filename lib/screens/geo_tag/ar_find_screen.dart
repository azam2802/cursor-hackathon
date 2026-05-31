import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo/cache_repository.dart';
import '../../core/geo/location_service.dart';
import '../../core/geo/models/geo_cache.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'ar_camera_view.dart';
import 'widgets/ar_overlay.dart';
import 'widgets/cache_reveal_card.dart';

/// AR "walk close then open" experience for a single target [GeoCache].
///
/// Subscribes to the user's live position, continuously feeds the live bearing
/// and distance into [ArCameraView], and gates the open interaction by
/// proximity: beyond [kOpenRadiusMeters] only "get closer" guidance is shown;
/// within the radius a glowing CTA lets the user reveal the cache contents.
///
/// Opening records the user's uid via [CacheRepository.markOpened] (skipping
/// the write for the owner or a cache already opened by this user to avoid
/// redundant writes) and animates a [CacheRevealCard].
class ArFindScreen extends StatefulWidget {
  const ArFindScreen({
    super.key,
    required this.cache,
    this.cacheRepository,
    this.locationService,
  });

  /// The target cache the user is navigating to and may open.
  final GeoCache cache;

  /// Injectable repository; defaults to a real [CacheRepository].
  final CacheRepository? cacheRepository;

  /// Injectable location service; defaults to a real [LocationService].
  final LocationService? locationService;

  @override
  State<ArFindScreen> createState() => _ArFindScreenState();
}

class _ArFindScreenState extends State<ArFindScreen>
    with SingleTickerProviderStateMixin {
  late final CacheRepository _repository;
  late final LocationService _location;
  late final AnimationController _revealController;
  late final Animation<double> _scaleAnimation;

  StreamSubscription<Position>? _positionSub;
  Position? _position;

  /// Guards against duplicate open taps while the write is in flight.
  bool _opening = false;

  /// Whether the cache contents have been revealed.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.cacheRepository ?? CacheRepository();
    _location = widget.locationService ?? const LocationService();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
    );
    _subscribe();
  }

  void _subscribe() {
    // A missing/failed position simply leaves distance unknown (guidance shows
    // "Поиск GPS…"); it must never crash the AR view, so errors are swallowed.
    _positionSub = _location.positionStream().listen(
      (position) => setState(() => _position = position),
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  /// Live distance from the user to the target, or `null` without a GPS fix.
  double? get _distanceMeters {
    final position = _position;
    if (position == null) {
      return null;
    }
    return LocationService.distanceMeters(
      position.latitude,
      position.longitude,
      widget.cache.lat,
      widget.cache.lng,
    );
  }

  /// Live bearing from the user to the target, or `null` without a GPS fix.
  double? get _bearingDegrees {
    final position = _position;
    if (position == null) {
      return null;
    }
    return LocationService.bearingDegrees(
      position.latitude,
      position.longitude,
      widget.cache.lat,
      widget.cache.lng,
    );
  }

  bool get _isOpenable {
    final distance = _distanceMeters;
    return distance != null && LocationService.isWithinOpenRadius(distance);
  }

  Future<void> _handleOpen() async {
    if (_revealed || _opening || !_isOpenable) {
      return;
    }
    setState(() => _opening = true);
    await _recordOpenIfNeeded();
    if (!mounted) {
      return;
    }
    setState(() {
      _opening = false;
      _revealed = true;
    });
    _revealController.forward();
  }

  /// Persists the open for first-time openers only. Skips the write when there
  /// is no signed-in user, when this user already opened the cache, or when the
  /// viewer is the owner — so re-opening never produces duplicate writes.
  Future<void> _recordOpenIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cache = widget.cache;
    final shouldRecord =
        uid != null && !cache.isOpenedBy(uid) && cache.ownerId != uid;
    if (!shouldRecord) {
      return;
    }
    try {
      await _repository.markOpened(cache.id, uid);
    } catch (_) {
      // A failed write must not block the reveal; the contents are local.
    }
  }

  void _exit() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final cache = widget.cache;
    final distance = _distanceMeters;
    final cacheLabel = cache.title.isEmpty ? 'Тайник' : cache.title;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ArCameraView(
            targetBearing: _bearingDegrees ?? 0,
            distanceMeters: distance ?? 0,
            openable: _isOpenable,
            cacheLabel: cacheLabel,
            child: _BottomGuidance(
              distanceMeters: distance,
              openable: _isOpenable,
              opening: _opening,
              onOpen: _handleOpen,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _CloseButton(onPressed: _exit),
              ),
            ),
          ),
          if (_revealed)
            _RevealOverlay(
              controller: _revealController,
              scale: _scaleAnimation,
              cache: cache,
              onClose: _exit,
            ),
        ],
      ),
    );
  }
}

/// Bottom-of-screen affordance: a glowing "tap to open" CTA within the open
/// radius, otherwise a "get closer" guidance pill with the live distance.
class _BottomGuidance extends StatelessWidget {
  const _BottomGuidance({
    required this.distanceMeters,
    required this.openable,
    required this.opening,
    required this.onOpen,
  });

  final double? distanceMeters;
  final bool openable;
  final bool opening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: openable
              ? _OpenCta(opening: opening, onOpen: onOpen)
              : _ProximityHint(distanceMeters: distanceMeters),
        ),
      ),
    );
  }
}

/// Static "подойдите ближе" pill that surfaces the live distance (or a GPS
/// search state when no fix is available yet).
class _ProximityHint extends StatelessWidget {
  const _ProximityHint({required this.distanceMeters});

  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final text = distanceMeters == null
        ? 'Поиск GPS…'
        : 'Подойдите ближе — ${formatDistance(distanceMeters!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: AppColors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing, gently pulsing "нажмите, чтобы открыть" call-to-action shown once
/// the user is within the open radius.
class _OpenCta extends StatefulWidget {
  const _OpenCta({required this.opening, required this.onOpen});

  final bool opening;
  final VoidCallback onOpen;

  @override
  State<_OpenCta> createState() => _OpenCtaState();
}

class _OpenCtaState extends State<_OpenCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.opening ? null : widget.onOpen,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 12 + _pulseController.value * 16;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mint.withValues(alpha: 0.7),
                  blurRadius: glow,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.opening)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            else
              const Icon(
                Icons.lock_open_rounded,
                color: AppColors.white,
                size: 22,
              ),
            const SizedBox(width: 10),
            Text(
              'Нажмите, чтобы открыть',
              style: AppTextStyles.body(
                size: 15,
                weight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round, frosted close button used to exit the AR view.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.textDark.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, color: AppColors.white),
        tooltip: 'Закрыть',
      ),
    );
  }
}

/// Full-screen scrim hosting the animated [CacheRevealCard].
class _RevealOverlay extends StatelessWidget {
  const _RevealOverlay({
    required this.controller,
    required this.scale,
    required this.cache,
    required this.onClose,
  });

  final AnimationController controller;
  final Animation<double> scale;
  final GeoCache cache;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: SingleChildScrollView(
            child: ScaleTransition(
              scale: scale,
              child: CacheRevealCard(cache: cache, onClose: onClose),
            ),
          ),
        ),
      ),
    );
  }
}
