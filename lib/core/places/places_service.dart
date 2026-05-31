import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/google_maps_config.dart';

/// A real-world place resolved from the Google Places API (New).
class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.location,
    this.address,
    this.rating,
  });

  final String name;
  final LatLng location;
  final String? address;
  final double? rating;
}

/// Looks up real locations on Google Maps for AI-suggested activities, using
/// the Places API (New) Text Search endpoint biased to the user's area.
class PlacesService {
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchText';

  /// Finds the best matching place for [query] near [near] within [radiusMeters].
  /// Returns `null` if the API isn't configured, the request fails, or there are
  /// no results.
  Future<PlaceResult?> searchText(
    String query, {
    required LatLng near,
    double radiusMeters = 30000,
  }) async {
    if (!GoogleMapsConfig.isConfigured) return null;

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              'X-Goog-FieldMask':
                  'places.displayName,places.location,places.formattedAddress,places.rating',
            },
            body: jsonEncode({
              'textQuery': query,
              'maxResultCount': 1,
              'languageCode': 'ru',
              'locationBias': {
                'circle': {
                  'center': {
                    'latitude': near.latitude,
                    'longitude': near.longitude,
                  },
                  'radius': radiusMeters,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final places = decoded['places'] as List?;
      if (places == null || places.isEmpty) return null;

      final place = places.first as Map<String, dynamic>;
      final location = place['location'] as Map<String, dynamic>?;
      final lat = (location?['latitude'] as num?)?.toDouble();
      final lng = (location?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return PlaceResult(
        name: (place['displayName']?['text'] as String?)?.trim() ?? query,
        location: LatLng(lat, lng),
        address: (place['formattedAddress'] as String?)?.trim(),
        rating: (place['rating'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
