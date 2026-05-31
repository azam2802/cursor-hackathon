import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// AI Mood Planner screen — chat-style planner that turns a mood/description
/// into a day of activities.
///
/// Static UI only. The mood chips, message list, send field and activity
/// cards are placeholders ready to be wired to real state/AI later.
class MoodAiScreen extends StatelessWidget {
  const MoodAiScreen({super.key});

  static const List<_MoodChip> _moods = [
    _MoodChip('С детьми', Color(0xFFFFDED0), Color(0xFF8B2500)),
    _MoodChip('Природа', Color(0xFFD4F5E9), Color(0xFF005C38)),
    _MoodChip('Вода', Color(0xFFD8EEFF), Color(0xFF003C6E)),
    _MoodChip('Бюджетно', Color(0xFFFFE9C7), Color(0xFF7A4500)),
    _MoodChip('Адреналин!', AppColors.warm, AppColors.white),
  ];

  static const List<_Message> _messages = [
    _Message('Нас 6, бюджет 20€, хотим адреналина!', fromUser: true),
    _Message(
      'Нашёл рафтинг + скалолазание + zip-line — всё вписывается в бюджет. '
      'Маршрут на 8 часов готов!',
      fromUser: false,
    ),
    _Message('Покажи активности', fromUser: true),
    _Message(
      'Вот топ-3 для вашей группы — рафтинг ближе всего, старт в 10:00',
      fromUser: false,
    ),
  ];

  static const List<_Activity> _activities = [
    _Activity('🚣', 'Рафтинг', '3.2 км', hot: true),
    _Activity('🧗', 'Скалы', '7.1 км'),
    _Activity('🪂', 'Zip-line', '12 км'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.moodBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            _MoodChipsRow(moods: _moods),
            Expanded(child: _MessageList(messages: _messages)),
            _ActivityRow(activities: _activities),
            const _InputBar(),
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
  const _MoodChipsRow({required this.moods});

  final List<_MoodChip> moods;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final mood in moods)
            // TODO: select/deselect mood to filter AI suggestions.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
  const _MessageList({required this.messages});

  final List<_Message> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _Bubble(message: messages[index]),
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

class _Activity {
  const _Activity(this.icon, this.name, this.distance, {this.hot = false});

  final String icon;
  final String name;
  final String distance;
  final bool hot;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activities});

  final List<_Activity> activities;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Container(
            width: 86,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activity.hot ? AppColors.warm : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(activity.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  activity.name,
                  style: AppTextStyles.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  activity.distance,
                  style: AppTextStyles.body(
                    size: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD4B8), width: 2),
              ),
              // TODO: replace with a TextField wired to the AI request flow.
              child: Text(
                'Опиши компанию и настроение...',
                style: AppTextStyles.body(
                  size: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // TODO: send the composed prompt to the planner.
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.warm,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, size: 16, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
