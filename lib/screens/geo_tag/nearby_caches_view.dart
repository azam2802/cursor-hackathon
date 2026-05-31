import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo/cache_repository.dart';
import '../../core/geo/location_service.dart';
import '../../core/geo/models/geo_cache.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/cache_list_card.dart';

/// Callback fired when the user asks to open a cache in the AR view.
///
/// Wired to the AR screen by GEO-007/GEO-008.
typedef OpenInArCallback = void Function(GeoCache cache);

/// «Найти тайник» — a live list of nearby caches plus a per-cache navigation
/// sub-state.
///
/// Combines [CacheRepository.watchCaches] with the user's live position
/// ([LocationService.positionStream]) to compute and sort caches by real
/// distance, updating as the user moves. Tapping a cache opens a navigation
/// view with a large distance readout and a bearing arrow; the «Открыть в AR»
/// CTA unlocks only within [kOpenRadiusMeters].
class NearbyCachesView extends StatefulWidget {
  const NearbyCachesView({
    super.key,
    this.cacheRepository,
    this.locationService,
    this.onOpenInAr,
  });

  /// Injectable repository; defaults to a real [CacheRepository].
  final CacheRepository? cacheRepository;

  /// Injectable location service; defaults to a real [LocationService].
  final LocationService? locationService;

  /// Invoked with the target cache when «Открыть в AR» is tapped while the user
  /// is within the open radius. If `null`, the button is shown but does nothing.
  final OpenInArCallback? onOpenInAr;

  @override
  State<NearbyCachesView> createState() => _NearbyCachesViewState();
}

class _NearbyCachesViewState extends State<NearbyCachesView> {
  late final CacheRepository _repository;
  late final LocationService _location;

  StreamSubscription<List<GeoCache>>? _cachesSub;
  StreamSubscription<Position>? _positionSub;

  List<GeoCache>? _caches;
  Position? _position;
  Object? _error;

  /// Id of the cache currently being navigated to, if any.
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _repository = widget.cacheRepository ?? CacheRepository();
    _location = widget.locationService ?? const LocationService();
    _subscribe();
  }

  void _subscribe() {
    _cachesSub = _repository.watchCaches().listen(
      (caches) => setState(() {
        _caches = caches;
        _error = null;
      }),
      onError: (Object error) => setState(() => _error = error),
    );

    // Position failures (denied permission, no fix) degrade gracefully: the
    // list still renders in default order without distances, so they are not
    // treated as a fatal error.
    _positionSub = _location.positionStream().listen(
      (position) => setState(() => _position = position),
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _cachesSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  double? _distanceTo(GeoCache cache) {
    final position = _position;
    if (position == null) {
      return null;
    }
    return LocationService.distanceMeters(
      position.latitude,
      position.longitude,
      cache.lat,
      cache.lng,
    );
  }

  double? _bearingTo(GeoCache cache) {
    final position = _position;
    if (position == null) {
      return null;
    }
    return LocationService.bearingDegrees(
      position.latitude,
      position.longitude,
      cache.lat,
      cache.lng,
    );
  }

  bool _isOpened(GeoCache cache) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && cache.isOpenedBy(uid);
  }

  /// Caches paired with their live distance, sorted ascending (unknown last).
  List<GeoCache> get _sortedCaches {
    final caches = List<GeoCache>.of(_caches ?? const <GeoCache>[]);
    caches.sort((a, b) {
      final da = _distanceTo(a);
      final db = _distanceTo(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return caches;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Не удалось загрузить тайники',
        subtitle: 'Проверьте подключение и попробуйте ещё раз.',
      );
    }

    if (_caches == null) {
      return const _LoadingState();
    }

    final selected = _selectedCache();
    if (selected != null) {
      return _NavigateView(
        cache: selected,
        distanceMeters: _distanceTo(selected),
        bearingDegrees: _bearingTo(selected),
        isOpened: _isOpened(selected),
        onBack: () => setState(() => _selectedId = null),
        onOpenInAr: widget.onOpenInAr,
      );
    }

    if (_caches!.isEmpty) {
      return const _MessageState(
        icon: Icons.travel_explore_rounded,
        title: 'Поблизости тайников нет',
        subtitle: 'Спрячьте свой тайник или вернитесь позже.',
      );
    }

    return _CacheList(
      caches: _sortedCaches,
      distanceOf: _distanceTo,
      isOpenedOf: _isOpened,
      onTap: (cache) => setState(() => _selectedId = cache.id),
    );
  }

  /// Resolves the selected cache against the latest stream data so its
  /// opened-state stays fresh; returns `null` if it disappeared.
  GeoCache? _selectedCache() {
    final id = _selectedId;
    if (id == null) {
      return null;
    }
    for (final cache in _caches ?? const <GeoCache>[]) {
      if (cache.id == id) {
        return cache;
      }
    }
    return null;
  }
}

class _CacheList extends StatelessWidget {
  const _CacheList({
    required this.caches,
    required this.distanceOf,
    required this.isOpenedOf,
    required this.onTap,
  });

  final List<GeoCache> caches;
  final double? Function(GeoCache) distanceOf;
  final bool Function(GeoCache) isOpenedOf;
  final void Function(GeoCache) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: caches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cache = caches[index];
        return CacheListCard(
          cache: cache,
          distanceMeters: distanceOf(cache),
          isOpened: isOpenedOf(cache),
          onTap: () => onTap(cache),
        );
      },
    );
  }
}

/// Per-cache navigation sub-state: big distance readout, a bearing arrow that
/// rotates toward the target, and the «Открыть в AR» CTA gated by proximity.
class _NavigateView extends StatelessWidget {
  const _NavigateView({
    required this.cache,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.isOpened,
    required this.onBack,
    required this.onOpenInAr,
  });

  final GeoCache cache;
  final double? distanceMeters;
  final double? bearingDegrees;
  final bool isOpened;
  final VoidCallback onBack;
  final OpenInArCallback? onOpenInAr;

  @override
  Widget build(BuildContext context) {
    final canOpen = distanceMeters != null &&
        LocationService.isWithinOpenRadius(distanceMeters!);
    final distanceLabel =
        distanceMeters == null ? 'Поиск GPS…' : formatDistance(distanceMeters!);
    final title = cache.title.isEmpty ? 'Тайник' : cache.title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textDark,
                tooltip: 'Назад',
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.display(
                    size: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BearingArrow(bearingDegrees: bearingDegrees),
                  const SizedBox(height: 24),
                  Text(
                    'До тайника',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceLabel,
                    style: AppTextStyles.display(size: 40, color: AppColors.mint),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canOpen
                        ? 'Вы на месте — открывайте!'
                        : 'Подойдите ближе, чтобы открыть',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      size: 13,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _OpenInArButton(
            enabled: canOpen,
            onPressed: onOpenInAr == null ? null : () => onOpenInAr!(cache),
          ),
        ],
      ),
    );
  }
}

/// An arrow that points toward the target using its compass bearing.
///
/// Shows a neutral placeholder while the bearing is unknown (no GPS fix yet).
class _BearingArrow extends StatelessWidget {
  const _BearingArrow({required this.bearingDegrees});

  final double? bearingDegrees;

  @override
  Widget build(BuildContext context) {
    final radians = (bearingDegrees ?? 0) * math.pi / 180;
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.geoBg,
        border: Border.all(color: AppColors.mint, width: 3),
      ),
      alignment: Alignment.center,
      child: bearingDegrees == null
          ? Icon(Icons.gps_not_fixed_rounded,
              size: 48, color: AppColors.textLight)
          : Transform.rotate(
              angle: radians,
              child: const Icon(
                Icons.navigation_rounded,
                size: 64,
                color: AppColors.mint,
              ),
            ),
    );
  }
}

class _OpenInArButton extends StatelessWidget {
  const _OpenInArButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.camera_alt_rounded),
        label: Text(
          'Открыть в AR',
          style: AppTextStyles.body(
            size: 15,
            weight: FontWeight.w900,
            color: AppColors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          disabledBackgroundColor: const Color(0xFFB9E6DB),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.mint),
    );
  }
}

/// Themed full-view state used for both empty and error cases.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.mint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.display(size: 18, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
