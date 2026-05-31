import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Profile destination — shows the signed-in user and sign-out action.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '—';
    final initials = _initials(displayName, email);

    return Container(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(initials: initials, photoUrl: user?.photoURL),
                const SizedBox(height: 16),
                Text(
                  displayName?.isNotEmpty == true ? displayName! : 'Профиль',
                  style: AppTextStyles.display(size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    size: 13,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSigningOut ? null : _signOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: const BorderSide(color: AppColors.coral),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.coral,
                            ),
                          )
                        : const Icon(Icons.logout, size: 20),
                    label: Text(
                      'Выйти',
                      style: AppTextStyles.body(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.photoUrl});

  final String initials;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 42,
        backgroundColor: AppColors.coral,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.coral,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.display(size: 28, color: AppColors.white),
      ),
    );
  }
}
