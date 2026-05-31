import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/geo/cache_repository.dart';
import '../../core/geo/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/photo_picker_tile.dart';

/// Maximum horizontal accuracy (in meters) we accept before allowing a save.
///
/// GPS under tree cover drifts; requiring a reasonable fix avoids hiding a
/// cache at a wildly wrong spot. Beyond this the UI shows «Уточняем
/// местоположение…» and blocks saving.
const double _kMaxAccuracyMeters = 50;

/// Image compression target passed to [ImagePicker] to keep uploads small.
const int _kPhotoQuality = 70;
const double _kPhotoMaxWidth = 1280;

/// Discrete states of the one-shot location acquisition flow.
enum _LocationState {
  loading,
  ready,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

/// Bottom sheet for hiding a new cache («Спрятать тайник»).
///
/// Captures the device's current GPS position, collects a title plus a message
/// and/or photo, and writes the cache via [CacheRepository.createCache]. Pops
/// with `true` on success so the caller can refresh its list.
///
/// [cacheRepository] and [locationService] are injectable for testability and
/// default-constructed when omitted.
class CreateCacheSheet extends StatefulWidget {
  const CreateCacheSheet({
    super.key,
    this.cacheRepository,
    this.locationService,
    this.onCreated,
  });

  final CacheRepository? cacheRepository;
  final LocationService? locationService;

  /// Optional callback invoked with the new cache id on success, in addition
  /// to popping the route with `true`.
  final ValueChanged<String>? onCreated;

  /// Presents the sheet as a scrollable modal bottom sheet and resolves to
  /// `true` when a cache was created.
  static Future<bool?> show(
    BuildContext context, {
    CacheRepository? cacheRepository,
    LocationService? locationService,
    ValueChanged<String>? onCreated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCacheSheet(
        cacheRepository: cacheRepository,
        locationService: locationService,
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<CreateCacheSheet> createState() => _CreateCacheSheetState();
}

class _CreateCacheSheetState extends State<CreateCacheSheet> {
  late final CacheRepository _repository =
      widget.cacheRepository ?? CacheRepository();
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  _LocationState _locationState = _LocationState.loading;
  Position? _position;
  File? _photo;
  bool _submitting = false;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFormChanged);
    _messageController.addListener(_onFormChanged);
    _acquireLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  Future<void> _acquireLocation() async {
    setState(() {
      _locationState = _LocationState.loading;
      _position = null;
    });

    final status = await _locationService.ensurePermission();
    if (!mounted) return;

    switch (status) {
      case LocationPermissionStatus.denied:
        setState(() => _locationState = _LocationState.denied);
        return;
      case LocationPermissionStatus.deniedForever:
        setState(() => _locationState = _LocationState.deniedForever);
        return;
      case LocationPermissionStatus.serviceDisabled:
        setState(() => _locationState = _LocationState.serviceDisabled);
        return;
      case LocationPermissionStatus.granted:
        break;
    }

    try {
      final position = await _locationService.currentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationState = _LocationState.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationState = _LocationState.error);
    }
  }

  bool get _hasValidFix {
    final position = _position;
    return position != null && position.accuracy <= _kMaxAccuracyMeters;
  }

  bool get _titleValid => _titleController.text.trim().isNotEmpty;

  bool get _contentValid =>
      _messageController.text.trim().isNotEmpty || _photo != null;

  bool get _canSave =>
      !_submitting && _hasValidFix && _titleValid && _contentValid;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: _kPhotoQuality,
        maxWidth: _kPhotoMaxWidth,
      );
      if (picked == null || !mounted) return;
      setState(() => _photo = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      _showError('Не удалось получить фото');
    }
  }

  void _removePhoto() => setState(() => _photo = null);

  Future<void> _save() async {
    setState(() => _showValidation = true);
    if (!_canSave) return;

    final position = _position;
    final user = FirebaseAuth.instance.currentUser;
    if (position == null) {
      _showError('Нет данных о местоположении');
      return;
    }
    if (user == null) {
      _showError('Войдите, чтобы спрятать тайник');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    try {
      final cacheId = await _repository.createCache(
        ownerId: user.uid,
        ownerName: _resolveOwnerName(user),
        lat: position.latitude,
        lng: position.longitude,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        photo: _photo,
      );
      if (!mounted) return;
      widget.onCreated?.call(cacheId);
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось спрятать тайник. Попробуйте ещё раз')),
      );
    }
  }

  String _resolveOwnerName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'Аноним';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 12),
                Text(
                  'Спрятать тайник',
                  style: AppTextStyles.display(size: 20, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Оставьте сообщение или фото на этом месте',
                  style: AppTextStyles.body(size: 12, color: AppColors.textMid),
                ),
                const SizedBox(height: 16),
                _LocationCard(
                  state: _locationState,
                  position: _position,
                  hasValidFix: _hasValidFix,
                  onRetry: _acquireLocation,
                  onOpenSettings: _locationService.openLocationSettings,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Название тайника'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: _inputDecoration(
                    hint: 'Например, «Под старым дубом»',
                    errorText: _showValidation && !_titleValid
                        ? 'Введите название'
                        : null,
                  ),
                  style: AppTextStyles.body(size: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                _FieldLabel('Сообщение'),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  enabled: !_submitting,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 280,
                  decoration: _inputDecoration(
                    hint: 'Подсказка, поздравление или загадка…',
                  ),
                  style: AppTextStyles.body(size: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                PhotoPickerTile(
                  photo: _photo,
                  enabled: !_submitting,
                  onPickCamera: () => _pickPhoto(ImageSource.camera),
                  onPickGallery: () => _pickPhoto(ImageSource.gallery),
                  onRemove: _removePhoto,
                ),
                if (_showValidation && !_contentValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте сообщение или фото',
                    style: AppTextStyles.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.coral,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _SaveButton(
                  enabled: _canSave,
                  submitting: _submitting,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body(size: 13, color: AppColors.textLight),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      counterText: '',
      enabledBorder: border(const Color(0xFFD0F5EC)),
      focusedBorder: border(AppColors.mint),
      disabledBorder: border(const Color(0xFFE5E5E5)),
      errorBorder: border(AppColors.coral),
      focusedErrorBorder: border(AppColors.coral),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.navInactive,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body(
        size: 13,
        weight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }
}

/// Renders the location acquisition state: loading, the captured coordinates +
/// accuracy, or an actionable error (with retry / open-settings).
class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.state,
    required this.position,
    required this.hasValidFix,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final _LocationState state;
  final Position? position;
  final bool hasValidFix;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.geoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint, width: 1.5),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (state) {
      case _LocationState.loading:
        return _statusRow(
          icon: Icons.my_location,
          title: 'Определяем местоположение…',
          subtitle: 'Подождите немного',
          showSpinner: true,
        );
      case _LocationState.denied:
        return _errorBody(
          title: 'Нет доступа к геолокации',
          subtitle: 'Разрешите доступ, чтобы спрятать тайник здесь',
          actionLabel: 'Повторить',
          onAction: onRetry,
        );
      case _LocationState.deniedForever:
        return _errorBody(
          title: 'Доступ к геолокации запрещён',
          subtitle: 'Включите доступ в настройках устройства',
          actionLabel: 'Открыть настройки',
          onAction: () => onOpenSettings(),
        );
      case _LocationState.serviceDisabled:
        return _errorBody(
          title: 'Геолокация выключена',
          subtitle: 'Включите GPS на устройстве и повторите',
          actionLabel: 'Повторить',
          onAction: onRetry,
        );
      case _LocationState.error:
        return _errorBody(
          title: 'Не удалось определить местоположение',
          subtitle: 'Попробуйте ещё раз',
          actionLabel: 'Повторить',
          onAction: onRetry,
        );
      case _LocationState.ready:
        return _readyBody();
    }
  }

  Widget _readyBody() {
    final fix = position;
    if (fix == null) {
      return _statusRow(
        icon: Icons.my_location,
        title: 'Уточняем местоположение…',
        subtitle: 'Подождите немного',
        showSpinner: true,
      );
    }
    final coords =
        '${fix.latitude.toStringAsFixed(5)}, ${fix.longitude.toStringAsFixed(5)}';
    final accuracy = 'Точность: ±${fix.accuracy.toStringAsFixed(0)} м';
    if (!hasValidFix) {
      return _statusRow(
        icon: Icons.gps_not_fixed,
        title: 'Уточняем местоположение…',
        subtitle: '$coords  •  $accuracy',
        showSpinner: true,
      );
    }
    return _statusRow(
      icon: Icons.place,
      title: coords,
      subtitle: accuracy,
      showSpinner: false,
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showSpinner,
  }) {
    return Row(
      children: [
        if (showSpinner)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.mint),
            ),
          )
        else
          Icon(icon, color: AppColors.mint, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.body(size: 12, color: AppColors.textMid),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorBody({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusRow(
          icon: Icons.location_off,
          title: title,
          subtitle: subtitle,
          showSpinner: false,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mint,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              actionLabel,
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.mint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          disabledBackgroundColor: const Color(0xFFB8E6DC),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Text(
                'Спрятать тайник',
                style: AppTextStyles.display(size: 16, color: AppColors.white),
              ),
      ),
    );
  }
}
