import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../places/places_service.dart';
import 'day_plan.dart';

/// Configuration for the YandexGPT Foundation Models REST API.
///
/// The [folderId] is the Yandex Cloud folder (catalog) that owns the model and
/// is REQUIRED to build the model URI. Set it to your folder id before relying
/// on live responses — until then the service falls back to a local mock plan
/// so the feature stays demoable.
class YandexGptConfig {
  YandexGptConfig._();

  static const String apiKey =
      'AQ.Ab8RN6IOkrwz61HovJG_w4N5KCWw6o28_KuVX10Xlkj43WyY8w';

  /// TODO: replace with your Yandex Cloud folder id (e.g. `b1g...`).
  static const String folderId = 'PUT_YOUR_FOLDER_ID_HERE';

  /// `yandexgpt/latest` (most capable) or `yandexgpt-lite/latest` (cheaper).
  static const String model = 'yandexgpt-lite/latest';

  static const String endpoint =
      'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';

  static bool get isConfigured =>
      folderId.isNotEmpty && folderId != 'PUT_YOUR_FOLDER_ID_HERE';

  static String get modelUri => 'gpt://$folderId/$model';
}

/// Turns a free-text mood/company description into a day of nearby activities.
///
/// YandexGPT suggests *what* to do (with a Google Maps search query for each
/// activity); [PlacesService] then resolves each query to a real place near the
/// user so it can be plotted on the map and connected into a route.
class YandexGptService {
  YandexGptService({http.Client? client, PlacesService? placesService})
      : _client = client ?? http.Client(),
        _places = placesService ?? PlacesService();

  final http.Client _client;
  final PlacesService _places;

  static const String _systemPrompt = '''
Ты — дружелюбный планировщик летнего отдыха в приложении SummerDrift.
Пользователь описывает компанию и настроение (например: "я с детьми",
"хотим адреналина", "нас 6, бюджет 20€"). Подбери 3-5 подходящих активностей
рядом и составь маршрут на день. Для каждой активности дай поисковый запрос,
по которому её можно найти на Google Maps рядом с пользователем.

Отвечай ТОЛЬКО валидным JSON без markdown и пояснений, строго по схеме:
{
  "reply": "короткий дружелюбный ответ на русском (1-2 предложения)",
  "route_summary": "краткое описание маршрута дня на русском",
  "activities": [
    {
      "name": "название активности",
      "emoji": "один эмодзи",
      "category": "категория (например: Вода, Природа, Адреналин, С детьми)",
      "description": "1 короткое предложение",
      "approx_cost_eur": число (0 если бесплатно),
      "duration": "примерная длительность, напр. '2 ч'",
      "search_query": "поисковый запрос для Google Maps, напр. 'rafting club' или 'озеро рядом'"
    }
  ]
}
Учитывай бюджет и состав компании. Запросы делай конкретными, чтобы их можно
было найти на карте.''';

  /// Requests a plan, resolves each activity to a real Google Maps place near
  /// the user, and never throws (falls back to a local plan on any failure).
  Future<DayPlan> planDay({
    required String userMessage,
    required LatLng userLocation,
    List<ChatTurn> history = const [],
  }) async {
    final aiResult = await _suggest(userMessage, userLocation, history);
    final activities = await _resolve(aiResult.suggestions, userLocation);
    return DayPlan(
      reply: aiResult.reply,
      routeSummary: aiResult.routeSummary,
      activities: activities,
    );
  }

  Future<_AiResult> _suggest(
    String userMessage,
    LatLng userLocation,
    List<ChatTurn> history,
  ) async {
    if (!YandexGptConfig.isConfigured) {
      return _fallbackSuggestions(userMessage);
    }

    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'text': _systemPrompt},
        for (final turn in history)
          {'role': turn.fromUser ? 'user' : 'assistant', 'text': turn.text},
        {
          'role': 'user',
          'text': 'Геопозиция пользователя: '
              '${userLocation.latitude}, ${userLocation.longitude}.\n'
              'Запрос: $userMessage',
        },
      ];

      final response = await _client
          .post(
            Uri.parse(YandexGptConfig.endpoint),
            headers: {
              'Authorization': 'Api-Key ${YandexGptConfig.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'modelUri': YandexGptConfig.modelUri,
              'completionOptions': {
                'stream': false,
                'temperature': 0.6,
                'maxTokens': 2000,
              },
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return _fallbackSuggestions(userMessage);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final text = decoded['result']?['alternatives']?[0]?['message']?['text']
          as String?;
      if (text == null || text.isEmpty) {
        return _fallbackSuggestions(userMessage);
      }

      return _parse(text) ?? _fallbackSuggestions(userMessage);
    } catch (_) {
      return _fallbackSuggestions(userMessage);
    }
  }

  _AiResult? _parse(String raw) {
    try {
      final jsonText = _extractJson(raw);
      if (jsonText == null) return null;
      final map = jsonDecode(jsonText) as Map<String, dynamic>;

      final activitiesJson = (map['activities'] as List?) ?? const [];
      final suggestions = <_Suggestion>[];
      for (final item in activitiesJson) {
        final a = item as Map<String, dynamic>;
        suggestions.add(
          _Suggestion(
            name: (a['name'] as String?)?.trim() ?? 'Активность',
            emoji: (a['emoji'] as String?)?.trim() ?? '📍',
            category: (a['category'] as String?)?.trim() ?? '',
            description: (a['description'] as String?)?.trim() ?? '',
            duration: (a['duration'] as String?)?.trim(),
            cost: _toDouble(a['approx_cost_eur']),
            searchQuery: (a['search_query'] as String?)?.trim() ??
                (a['name'] as String?)?.trim() ??
                '',
          ),
        );
      }

      if (suggestions.isEmpty) return null;

      return _AiResult(
        reply:
            (map['reply'] as String?)?.trim() ?? 'Вот что я подобрал для вас!',
        routeSummary: (map['route_summary'] as String?)?.trim() ?? '',
        suggestions: suggestions,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves each suggestion to a real Google Maps place. If Places isn't
  /// configured or returns nothing, falls back to a deterministic offset so the
  /// activity still appears on the route.
  Future<List<PlannedActivity>> _resolve(
    List<_Suggestion> suggestions,
    LatLng origin,
  ) async {
    final activities = <PlannedActivity>[];
    for (var i = 0; i < suggestions.length; i++) {
      final s = suggestions[i];
      final place = s.searchQuery.isEmpty
          ? null
          : await _places.searchText(s.searchQuery, near: origin);

      final location =
          place?.location ?? _offset(origin, 1.5 + i * 2.0, i * 70.0);
      final distanceMeters = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        location.latitude,
        location.longitude,
      );

      activities.add(
        PlannedActivity(
          name: s.name,
          emoji: s.emoji,
          category: s.category,
          description: s.description,
          location: location,
          distanceKm: distanceMeters / 1000.0,
          duration: s.duration,
          approxCostEur: s.cost,
          address: place?.address,
          rating: place?.rating,
        ),
      );
    }
    return activities;
  }

  /// Extracts the first balanced JSON object from a model response that may be
  /// wrapped in markdown fences or surrounded by prose.
  String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  /// Computes a coordinate [distanceKm] away from [origin] along [bearingDeg],
  /// using a simple equirectangular approximation (used only as a fallback).
  static LatLng _offset(LatLng origin, double distanceKm, double bearingDeg) {
    const kmPerDegLat = 111.0;
    final bearing = bearingDeg * math.pi / 180.0;
    final dLat = distanceKm / kmPerDegLat * math.cos(bearing);
    final dLon = distanceKm /
        (kmPerDegLat * math.cos(origin.latitude * math.pi / 180.0)) *
        math.sin(bearing);
    return LatLng(origin.latitude + dLat, origin.longitude + dLon);
  }

  /// Local, keyword-based suggestions used when the AI isn't configured/fails.
  _AiResult _fallbackSuggestions(String userMessage) {
    final lower = userMessage.toLowerCase();
    final wantsKids = lower.contains('дет') || lower.contains('ребен');
    final wantsAdrenaline =
        lower.contains('адренал') || lower.contains('экстрим');
    final wantsWater = lower.contains('вод') || lower.contains('пляж');

    final List<_Suggestion> suggestions;
    if (wantsAdrenaline) {
      suggestions = const [
        _Suggestion(name: 'Рафтинг', emoji: '🚣', category: 'Адреналин', description: 'Сплав по реке для драйва.', duration: '2 ч', cost: 15, searchQuery: 'rafting'),
        _Suggestion(name: 'Скалолазание', emoji: '🧗', category: 'Адреналин', description: 'Скалодром или виа феррата.', duration: '3 ч', cost: 20, searchQuery: 'climbing gym'),
        _Suggestion(name: 'Zip-line', emoji: '🪂', category: 'Адреналин', description: 'Полёт над каньоном.', duration: '1 ч', cost: 18, searchQuery: 'zipline adventure park'),
      ];
    } else if (wantsKids) {
      suggestions = const [
        _Suggestion(name: 'Парк аттракционов', emoji: '🎡', category: 'С детьми', description: 'Веселье для всей семьи.', duration: '3 ч', cost: 12, searchQuery: 'amusement park'),
        _Suggestion(name: 'Зоопарк', emoji: '🦙', category: 'С детьми', description: 'Контактный зоопарк рядом.', duration: '1.5 ч', cost: 8, searchQuery: 'petting zoo'),
        _Suggestion(name: 'Пикник в парке', emoji: '🧺', category: 'Природа', description: 'Отдых на траве у воды.', duration: '2 ч', cost: 0, searchQuery: 'park'),
      ];
    } else if (wantsWater) {
      suggestions = const [
        _Suggestion(name: 'Пляж', emoji: '🏖️', category: 'Вода', description: 'Городской пляж у воды.', duration: '3 ч', cost: 0, searchQuery: 'beach'),
        _Suggestion(name: 'Прокат сапов', emoji: '🏄', category: 'Вода', description: 'SUP-борды на озере.', duration: '1.5 ч', cost: 14, searchQuery: 'paddle board rental'),
        _Suggestion(name: 'Каякинг', emoji: '🛶', category: 'Вода', description: 'Каяки по заливу.', duration: '2 ч', cost: 16, searchQuery: 'kayak rental'),
      ];
    } else {
      suggestions = const [
        _Suggestion(name: 'Парк', emoji: '🌳', category: 'Природа', description: 'Зелёная прогулка рядом.', duration: '1.5 ч', cost: 0, searchQuery: 'park'),
        _Suggestion(name: 'Смотровая площадка', emoji: '🌄', category: 'Природа', description: 'Лучшие виды на город.', duration: '1 ч', cost: 0, searchQuery: 'viewpoint'),
        _Suggestion(name: 'Летнее кафе', emoji: '☕', category: 'Еда', description: 'Уютная терраса.', duration: '1 ч', cost: 10, searchQuery: 'cafe'),
        _Suggestion(name: 'Велопрогулка', emoji: '🚴', category: 'Активность', description: 'Прокат велосипедов.', duration: '2 ч', cost: 6, searchQuery: 'bike rental'),
      ];
    }

    return _AiResult(
      reply: YandexGptConfig.isConfigured
          ? 'Не удалось связаться с AI, показываю подборку по вашему запросу.'
          : 'Собрал маршрут под ваш запрос! (демо-режим — добавьте folderId для живого AI)',
      routeSummary:
          'Маршрут на день: ${suggestions.map((s) => s.name).join(' → ')}.',
      suggestions: suggestions,
    );
  }
}

class _AiResult {
  const _AiResult({
    required this.reply,
    required this.routeSummary,
    required this.suggestions,
  });

  final String reply;
  final String routeSummary;
  final List<_Suggestion> suggestions;
}

class _Suggestion {
  const _Suggestion({
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
    required this.searchQuery,
    this.duration,
    this.cost,
  });

  final String name;
  final String emoji;
  final String category;
  final String description;
  final String searchQuery;
  final String? duration;
  final double? cost;
}
