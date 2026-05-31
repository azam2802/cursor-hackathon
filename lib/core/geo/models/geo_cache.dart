import 'package:cloud_firestore/cloud_firestore.dart';

/// A virtual "cache" (тайник) hidden at real-world GPS coordinates.
///
/// Persisted in the Firestore `caches` collection. Coordinates are stored as a
/// Firestore [GeoPoint] under the `location` field; [lat]/[lng] are convenience
/// accessors. [createdAt] is stored as a Firestore [Timestamp].
class GeoCache {
  const GeoCache({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.lat,
    required this.lng,
    required this.title,
    required this.message,
    required this.createdAt,
    this.photoUrl,
    this.openedBy = const <String>[],
  });

  /// Builds a [GeoCache] from a Firestore document, defending against missing
  /// or malformed fields so a single bad doc never crashes the stream.
  factory GeoCache.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    final location = data['location'];
    double lat = 0;
    double lng = 0;
    if (location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    } else {
      lat = _toDouble(data['lat']);
      lng = _toDouble(data['lng']);
    }

    final createdAtRaw = data['createdAt'];
    final createdAt =
        createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now();

    final openedByRaw = data['openedBy'];
    final openedBy = openedByRaw is List
        ? openedByRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    final photoUrl = data['photoUrl'];

    return GeoCache(
      id: doc.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      lat: lat,
      lng: lng,
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      photoUrl: photoUrl is String && photoUrl.isNotEmpty ? photoUrl : null,
      createdAt: createdAt,
      openedBy: openedBy,
    );
  }

  final String id;
  final String ownerId;
  final String ownerName;
  final double lat;
  final double lng;
  final String title;
  final String message;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> openedBy;

  /// Coordinates as a Firestore [GeoPoint] for the `location` field.
  GeoPoint get location => GeoPoint(lat, lng);

  /// Whether [uid] has already opened this cache.
  bool isOpenedBy(String uid) => openedBy.contains(uid);

  /// Serializes to a Firestore-writable map. [createdAt] is written as a
  /// [Timestamp] and coordinates as a [GeoPoint] under `location`.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'location': GeoPoint(lat, lng),
      'lat': lat,
      'lng': lng,
      'title': title,
      'message': message,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'openedBy': openedBy,
    };
  }

  GeoCache copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    double? lat,
    double? lng,
    String? title,
    String? message,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? openedBy,
  }) {
    return GeoCache(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      title: title ?? this.title,
      message: message ?? this.message,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      openedBy: openedBy ?? this.openedBy,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
