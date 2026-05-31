import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/geo/cache_repository.dart';
import '../core/geo/location_service.dart';
import '../core/geo/models/geo_cache.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'geo_tag/ar_find_screen.dart';
import 'geo_tag/create_cache_sheet.dart';
import 'geo_tag/nearby_caches_view.dart';

/// Geo-Tag Catch — the AR geocaching game («тайники»).
///
/// Hosted as tab index 2 inside [HomeShell]'s `IndexedStack`, so it renders
/// without its own [Scaffold] and keeps its state alive across tab switches.
///
/// Wires the feature's building blocks into one screen:
/// * default view is [NearbyCachesView] («Найти»), which streams nearby caches
///   and hands off to the AR experience;
/// * a header action opens [CreateCacheSheet] to hide a new cache («Спрятать
///   тайник») — the list auto-refreshes via the underlying Firestore stream;
/// * tapping «Открыть в AR» pushes [ArFindScreen] for the selected cache.
///
/// A single [CacheRepository] and [LocationService] are constructed here and
/// shared with every child so the whole feature reads one source of truth.
/// [cacheRepository] and [locationService] are injectable for testing and
/// default-constructed when omitted, keeping the public constructor compatible
/// with `const GeoTagScreen()`.
class GeoTagScreen extends StatefulWidget {
  const GeoTagScreen({
    super.key,
    this.cacheRepository,
    this.locationService,
  });

  final CacheRepository? cacheRepository;
  final LocationService? locationService;

  @override
  State<GeoTagScreen> createState() => _GeoTagScreenState();
}

class _GeoTagScreenState extends State<GeoTagScreen> {
  late final CacheRepository _repository =
      widget.cacheRepository ?? CacheRepository();
  late final LocationService _location =
      widget.locationService ?? const LocationService();

  void _openCreateSheet() {
    // The sheet shares this screen's repository/location instances; on success
    // it pops with `true`, but no manual refresh is needed because
    // [NearbyCachesView] listens to the live Firestore stream.
    CreateCacheSheet.show(
      context,
      cacheRepository: _repository,
      locationService: _location,
    );
  }

  void _openInAr(GeoCache cache) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArFindScreen(
          cache: cache,
          cacheRepository: _repository,
          locationService: _location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.geoBg,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
            final signedIn = user != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onHide: signedIn ? _openCreateSheet : null),
                Expanded(
                  child: signedIn
                      ? NearbyCachesView(
                          cacheRepository: _repository,
                          locationService: _location,
                          onOpenInAr: _openInAr,
                        )
                      : const _SignedOutPrompt(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Title, subtitle and the «Спрятать тайник» action.
///
/// The action is shown only when a user is signed in (`onHide != null`).
class _Header extends StatelessWidget {
  const _Header({this.onHide});

  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тайники',
                      style: AppTextStyles.display(
                        size: 26,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Прячьте тайники на карте и ищите чужие в AR — '
                      'дойдите до места и откройте находку.',
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              if (onHide != null) ...[
                const SizedBox(width: 12),
                _HideButton(onPressed: onHide!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact mint pill that opens the create-cache flow.
class _HideButton extends StatelessWidget {
  const _HideButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_location_alt_rounded,
                  color: AppColors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                'Спрятать',
                style: AppTextStyles.body(
                  size: 11,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly themed prompt shown when no user is signed in.
class _SignedOutPrompt extends StatelessWidget {
  const _SignedOutPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(color: AppColors.mint, width: 3),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 48,
                color: AppColors.mint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Войдите, чтобы играть в тайники',
              textAlign: TextAlign.center,
              style: AppTextStyles.display(size: 20, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Авторизуйтесь в профиле, чтобы прятать свои тайники и '
              'находить чужие рядом с вами.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
