import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single activity suggested by the AI planner and resolved to a real place
/// on Google Maps.
class PlannedActivity {
  const PlannedActivity({
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
    required this.location,
    required this.distanceKm,
    this.duration,
    this.approxCostEur,
    this.address,
    this.rating,
  });

  final String name;
  final String emoji;
  final String category;
  final String description;
  final LatLng location;
  final double distanceKm;
  final String? duration;
  final double? approxCostEur;
  final String? address;
  final double? rating;

  /// Compact, human-readable distance label, e.g. `3.2 км` or `800 м`.
  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} м';
    }
    return '${distanceKm.toStringAsFixed(1)} км';
  }

  String? get costLabel {
    if (approxCostEur == null) return null;
    if (approxCostEur == 0) return 'бесплатно';
    return '≈${approxCostEur!.round()}€';
  }
}

/// The full result of an AI planning request: a chat reply, a short route
/// summary and the ordered list of activities making up the day.
class DayPlan {
  const DayPlan({
    required this.reply,
    required this.routeSummary,
    required this.activities,
  });

  final String reply;
  final String routeSummary;
  final List<PlannedActivity> activities;

  bool get hasActivities => activities.isNotEmpty;
}

/// A single turn in the chat history sent back to the model for context.
class ChatTurn {
  const ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}
