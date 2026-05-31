import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/geo/compass_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/ar_overlay.dart';

/// Internal lifecycle state of the camera preview.
enum _CameraStatus { initializing, ready, unavailable }

/// Reusable AR camera view: a live back-camera preview filling the viewport
/// with a directional [ArOverlay] (arrow + cache pin + crosshair + distance
/// badge) painted on top.
///
/// The view owns the [CameraController] lifecycle (init/dispose + app
/// pause/resume) and the compass subscription via [CompassService]. When the
/// camera is unavailable or permission is denied it renders a styled gradient
/// fallback instead of crashing.
class ArCameraView extends StatefulWidget {
  const ArCameraView({
    super.key,
    required this.targetBearing,
    required this.distanceMeters,
    this.openable = false,
    this.cacheLabel = 'Тайник',
    this.compassService = const CompassService(),
    this.child,
  });

  /// Bearing from the user to the cache in degrees (0..360).
  final double targetBearing;

  /// Live distance to the cache in meters (drives the distance badge).
  final double distanceMeters;

  /// Whether the user is within the open radius (emphasizes the pin).
  final bool openable;

  /// Short label shown inside the cache bubble.
  final String cacheLabel;

  /// Compass source; injectable for testing.
  final CompassService compassService;

  /// Optional extra overlay rendered above the AR overlay (e.g. an open CTA).
  final Widget? child;

  @override
  State<ArCameraView> createState() => _ArCameraViewState();
}

class _ArCameraViewState extends State<ArCameraView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraStatus _status = _CameraStatus.initializing;
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setUnavailable();
        return;
      }
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _status = _CameraStatus.ready;
      });
    } on CameraException {
      // Permission denied, in use elsewhere, or other camera failure.
      _setUnavailable();
    } catch (_) {
      // No camera plugin support / platform without cameras.
      _setUnavailable();
    }
  }

  void _setUnavailable() {
    if (!mounted) {
      return;
    }
    setState(() => _status = _CameraStatus.unavailable);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreview(),
        StreamBuilder<double?>(
          stream: widget.compassService.headingStream(),
          builder: (context, snapshot) {
            return ArOverlay(
              heading: snapshot.data,
              targetBearing: widget.targetBearing,
              distanceMeters: widget.distanceMeters,
              openable: widget.openable,
              cacheLabel: widget.cacheLabel,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _buildPreview() {
    final controller = _controller;
    if (_status == _CameraStatus.ready &&
        controller != null &&
        controller.value.isInitialized) {
      final previewSize = controller.value.previewSize;
      if (previewSize == null) {
        return const _CameraFallback();
      }
      // previewSize is in sensor orientation (landscape); swap to fill a
      // portrait viewport with BoxFit.cover.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      );
    }
    if (_status == _CameraStatus.unavailable) {
      return const _CameraFallback();
    }
    return const _CameraLoading();
  }
}

/// Styled gradient placeholder shown while the camera initializes.
class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC7EDFF), AppColors.geoBg],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.mint),
          ),
        ),
      ),
    );
  }
}

/// Styled fallback shown when the camera is unavailable or denied.
class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC7EDFF), Color(0xFFB8EBD8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.white,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text(
              'Камера недоступна',
              style: AppTextStyles.display(size: 16, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
