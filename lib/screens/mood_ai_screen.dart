import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../core/ai/day_plan.dart';
import '../core/ai/yandex_gpt_service.dart';
import '../core/location/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'route_plan_screen.dart';

/// AI Mood Planner — the user describes their mood/company and the AI suggests
/// nearby activities and builds a day route shown on a map.
class MoodAiScreen extends StatefulWidget {
  const MoodAiScreen({
    super.key,
    this.aiService,
    this.locationService,
  });

  final YandexGptService? aiService;
  final LocationService? locationService;

  @override
  State<MoodAiScreen> createState() => _MoodAiScreenState();
}

class _MoodAiScreenState extends State<MoodAiScreen> {
  static const List<_MoodChip> _moods = [
    _MoodChip('С детьми', Color(0xFFFFDED0), Color(0xFF8B2500)),
    _MoodChip('Природа', Color(0xFFD4F5E9), Color(0xFF005C38)),
    _MoodChip('Вода', Color(0xFFD8EEFF), Color(0xFF003C6E)),
    _MoodChip('Бюджетно', Color(0xFFFFE9C7), Color(0xFF7A4500)),
    _MoodChip('Адреналин!', AppColors.warm, AppColors.white),
  ];

  late final YandexGptService _ai;
  late final LocationService _location;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_Message> _messages = [
    const _Message(
      'Привет! Опиши свою компанию и настроение — подберу активности рядом '
      'и построю маршрут на день. 🌞',
      fromUser: false,
    ),
  ];

  LatLng? _userLocation;
  DayPlan? _plan;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ai = widget.aiService ?? YandexGptService();
    _location = widget.locationService ?? LocationService();
    _resolveLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    final location = await _location.getCurrentLocation();
    if (mounted) setState(() => _userLocation = location);
  }

  void _onChipTap(String label) {
    final text = _controller.text.trim();
    _controller.text = text.isEmpty ? label : '$text, $label';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final history = [
      for (final m in _messages) ChatTurn(fromUser: m.fromUser, text: m.text),
    ];

    setState(() {
      _messages.add(_Message(text, fromUser: true));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    final location = _userLocation ?? await _location.getCurrentLocation();
    final plan = await _ai.planDay(
      userMessage: text,
      userLocation: location,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _userLocation = location;
      _plan = plan;
      _messages.add(_Message(plan.reply, fromUser: false));
      if (plan.routeSummary.isNotEmpty) {
        _messages.add(_Message(plan.routeSummary, fromUser: false));
      }
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openMap() {
    final plan = _plan;
    final location = _userLocation;
    if (plan == null || location == null || !plan.hasActivities) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePlanScreen(plan: plan, userLocation: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.moodBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            _MoodChipsRow(moods: _moods, onTap: _onChipTap),
            Expanded(
              child: _MessageList(
                controller: _scrollController,
                messages: _messages,
                isLoading: _isSending,
              ),
            ),
            if (_plan?.hasActivities ?? false)
              _ActivityRow(activities: _plan!.activities, onTap: _openMap),
            if (_plan?.hasActivities ?? false)
              _ShowMapButton(onPressed: _openMap),
            _InputBar(
              controller: _controller,
              enabled: !_isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Планировщик', style: AppTextStyles.display(size: 22)),
                const SizedBox(height: 2),
                Text(
                  'Что ты хочешь сегодня?',
                  style: AppTextStyles.body(
                    size: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.warm,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip {
  const _MoodChip(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;
}

class _MoodChipsRow extends StatelessWidget {
  const _MoodChipsRow({required this.moods, required this.onTap});

  final List<_MoodChip> moods;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final mood in moods)
            GestureDetector(
              onTap: () => onTap(mood.label),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: mood.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mood.label,
                  style: AppTextStyles.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: mood.foreground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message {
  const _Message(this.text, {required this.fromUser});

  final String text;
  final bool fromUser;
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.isLoading,
  });

  final ScrollController controller;
  final List<_Message> messages;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= messages.length) return const _TypingBubble();
        return _Bubble(message: messages[index]);
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fromUser ? AppColors.warm : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(fromUser ? 16 : 4),
              bottomRight: Radius.circular(fromUser ? 4 : 16),
            ),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.body(
              size: 13,
              height: 1.45,
              color: fromUser ? AppColors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warm,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Подбираю маршрут...',
              style: AppTextStyles.body(size: 12, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activities, required this.onTap});

  final List<PlannedActivity> activities;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final activity = activities[index];
          final isFirst = index == 0;
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 92,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFirst ? AppColors.warm : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(activity.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    activity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    activity.distanceLabel,
                    style: AppTextStyles.body(
                      size: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShowMapButton extends StatelessWidget {
  const _ShowMapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warm,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.map, size: 20),
          label: Text(
            'Показать маршрут на карте',
            style: AppTextStyles.display(size: 14, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD4B8), width: 2),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: AppTextStyles.body(size: 13, color: AppColors.textDark),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  border: InputBorder.none,
                  hintText: 'Опиши компанию и настроение...',
                  hintStyle: AppTextStyles.body(
                    size: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? AppColors.warm : AppColors.navInactive,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 17, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
