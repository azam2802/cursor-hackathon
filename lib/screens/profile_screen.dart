import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Profile destination — shows the signed-in user and their summer checklist
/// (a "summer bucket list" of things to do, with progress persisted locally).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _prefsKey = 'summer_checklist_done';

  /// The default summer to-do items.
  static const List<_ChecklistItem> _items = [
    _ChecklistItem('🏊', 'Искупаться в озере'),
    _ChecklistItem('🥾', 'Сходить в поход'),
    _ChecklistItem('🧺', 'Устроить пикник на природе'),
    _ChecklistItem('🌅', 'Встретить рассвет'),
    _ChecklistItem('📍', 'Найти 10 тайников'),
    _ChecklistItem('🚣', 'Прокатиться на байдарке'),
    _ChecklistItem('🎪', 'Сходить на фестиваль'),
    _ChecklistItem('🔥', 'Пожарить зефир на костре'),
    _ChecklistItem('🚴', 'Покататься на велосипеде'),
    _ChecklistItem('🤿', 'Поплавать с маской'),
  ];

  late final AuthService _authService;
  final Set<int> _done = {};
  bool _isSigningOut = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _done
        ..clear()
        ..addAll(stored.map(int.tryParse).whereType<int>());
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_done.contains(index)) {
        _done.remove(index);
      } else {
        _done.add(index);
      }
    });
    _prefs?.setStringList(
      _prefsKey,
      _done.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '—';
    final progress = _items.isEmpty ? 0.0 : _done.length / _items.length;

    return Container(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProfileHeader(
              initials: _initials(displayName, email),
              photoUrl: user?.photoURL,
              name: displayName?.isNotEmpty == true ? displayName! : 'Профиль',
              email: email,
              isSigningOut: _isSigningOut,
              onSignOut: _isSigningOut ? null : _signOut,
            ),
            const SizedBox(height: 24),
            _ChecklistHeader(done: _done.length, total: _items.length, progress: progress),
            const SizedBox(height: 12),
            for (var i = 0; i < _items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChecklistTile(
                  item: _items[i],
                  checked: _done.contains(i),
                  onTap: () => _toggle(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String? displayName, String email) {
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    if (email.isNotEmpty && email != '—') {
      return email[0].toUpperCase();
    }
    return '?';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.isSigningOut,
    required this.onSignOut,
    this.photoUrl,
  });

  final String initials;
  final String name;
  final String email;
  final bool isSigningOut;
  final VoidCallback? onSignOut;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(initials: initials, photoUrl: photoUrl),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.display(size: 20),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(size: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSignOut,
          tooltip: 'Выйти',
          icon: isSigningOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.coral,
                  ),
                )
              : const Icon(Icons.logout, color: AppColors.coral),
        ),
      ],
    );
  }
}

class _ChecklistHeader extends StatelessWidget {
  const _ChecklistHeader({
    required this.done,
    required this.total,
    required this.progress,
  });

  final int done;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Летний чек-лист ☀️', style: AppTextStyles.display(size: 18)),
            Text(
              '$done / $total',
              style: AppTextStyles.display(size: 14, color: AppColors.coral),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.sand,
            valueColor: const AlwaysStoppedAnimation(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem(this.emoji, this.title);

  final String emoji;
  final String title;
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final _ChecklistItem item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked ? AppColors.coral : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: checked ? AppColors.textLight : AppColors.textDark,
                  height: 1.2,
                ).copyWith(
                  decoration:
                      checked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
            _CheckCircle(checked: checked),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? AppColors.coral : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? AppColors.coral : AppColors.navInactive,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: AppColors.white)
          : null,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.photoUrl});

  final String initials;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.coral,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.coral,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.display(size: 22, color: AppColors.white),
      ),
    );
  }
}
