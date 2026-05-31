import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/ai/day_plan.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Full-screen Google Map showing the user's location, the AI-recommended
/// activities as markers, and the day route connecting them.
class RoutePlanScreen extends StatefulWidget {
  const RoutePlanScreen({
    super.key,
    required this.plan,
    required this.userLocation,
  });

  final DayPlan plan;
  final LatLng userLocation;

  @override
  State<RoutePlanScreen> createState() => _RoutePlanScreenState();
}

class _RoutePlanScreenState extends State<RoutePlanScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  List<LatLng> get _routePoints => [
        widget.userLocation,
        ...widget.plan.activities.map((a) => a.location),
      ];

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    // Give the map a frame to lay out before fitting the route bounds.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(_routePoints), 60),
    );
  }

  Future<void> _focusActivity(int index) async {
    final controller = await _controller.future;
    final activity = widget.plan.activities[index];
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(activity.location, 14),
    );
    await controller.showMarkerInfoWindow(MarkerId('activity_$index'));
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('user'),
        position: widget.userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Вы здесь'),
      ),
      for (var i = 0; i < widget.plan.activities.length; i++)
        Marker(
          markerId: MarkerId('activity_$i'),
          position: widget.plan.activities[i].location,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${widget.plan.activities[i].name}',
            snippet: widget.plan.activities[i].distanceLabel,
          ),
        ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: AppColors.warm,
        width: 4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.moodBg,
      appBar: AppBar(
        backgroundColor: AppColors.warm,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Маршрут дня',
          style: AppTextStyles.display(size: 20, color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.userLocation,
                zoom: 12,
              ),
              onMapCreated: _onMapCreated,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          _RouteDetails(plan: widget.plan, onActivityTap: _focusActivity),
        ],
      ),
    );
  }

  /// Builds a bounding box that contains all [points].
  static LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _RouteDetails extends StatelessWidget {
  const _RouteDetails({required this.plan, required this.onActivityTap});

  final DayPlan plan;
  final ValueChanged<int> onActivityTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.moodBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('План на день', style: AppTextStyles.display(size: 18)),
            if (plan.routeSummary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.routeSummary,
                style: AppTextStyles.body(size: 13, color: AppColors.textMid),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < plan.activities.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityTile(
                  index: i + 1,
                  activity: plan.activities[i],
                  onTap: () => onActivityTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.index,
    required this.activity,
    required this.onTap,
  });

  final int index;
  final PlannedActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = activity.costLabel;
    final meta = [
      activity.distanceLabel,
      if (activity.duration != null) activity.duration!,
      if (cost != null) cost,
      if (activity.rating != null) '★ ${activity.rating!.toStringAsFixed(1)}',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.moodBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(activity.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${activity.name}',
                    style: AppTextStyles.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.body(
                      size: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.place, color: AppColors.warm, size: 20),
          ],
        ),
      ),
    );
  }
}
