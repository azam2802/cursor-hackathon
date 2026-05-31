import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summer_activity/core/geo/models/geo_cache.dart';

void main() {
  GeoCache sampleCache() => GeoCache(
        id: 'cache-1',
        ownerId: 'owner-1',
        ownerName: 'Алиса',
        lat: 55.751244,
        lng: 37.618423,
        title: 'У фонтана',
        message: 'Загляни под скамейку',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.utc(2026, 5, 31, 12, 30, 45),
        openedBy: const <String>['user-a', 'user-b'],
      );

  group('GeoCache.location / lat / lng', () {
    test('exposes coordinates as a GeoPoint', () {
      final cache = sampleCache();
      expect(cache.location, isA<GeoPoint>());
      expect(cache.location.latitude, cache.lat);
      expect(cache.location.longitude, cache.lng);
    });
  });

  group('GeoCache.isOpenedBy', () {
    test('is true for a uid present in openedBy', () {
      expect(sampleCache().isOpenedBy('user-a'), isTrue);
    });

    test('is false for a uid not present in openedBy', () {
      expect(sampleCache().isOpenedBy('stranger'), isFalse);
    });
  });

  group('GeoCache.copyWith', () {
    test('overrides only the provided fields', () {
      final updated = sampleCache().copyWith(
        title: 'Новое название',
        openedBy: const <String>['user-a', 'user-b', 'user-c'],
      );
      expect(updated.title, 'Новое название');
      expect(updated.openedBy, contains('user-c'));
      // Untouched fields are preserved.
      expect(updated.id, 'cache-1');
      expect(updated.ownerId, 'owner-1');
      expect(updated.message, 'Загляни под скамейку');
    });

    test('returns an equivalent value when no overrides are given', () {
      final original = sampleCache();
      final clone = original.copyWith();
      expect(clone.id, original.id);
      expect(clone.lat, original.lat);
      expect(clone.lng, original.lng);
      expect(clone.createdAt, original.createdAt);
      expect(clone.openedBy, original.openedBy);
    });
  });

  group('GeoCache Firestore round-trip', () {
    test('toMap then fromFirestore preserves all data', () async {
      final firestore = FakeFirebaseFirestore();
      final original = sampleCache();

      await firestore
          .collection('caches')
          .doc(original.id)
          .set(original.toMap());

      final snapshot =
          await firestore.collection('caches').doc(original.id).get();
      final restored = GeoCache.fromFirestore(snapshot);

      expect(restored.id, original.id);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.lat, closeTo(original.lat, 1e-9));
      expect(restored.lng, closeTo(original.lng, 1e-9));
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.photoUrl, original.photoUrl);
      // Firestore Timestamps round-trip through UTC, so compare the instant
      // rather than the (local vs UTC) DateTime representation.
      expect(restored.createdAt.isAtSameMomentAs(original.createdAt), isTrue);
      expect(restored.openedBy, original.openedBy);
    });

    test('reads coordinates from the GeoPoint location field', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('caches').doc('geo').set(<String, dynamic>{
        'ownerId': 'o',
        'ownerName': 'n',
        'location': const GeoPoint(12.34, 56.78),
        'title': 't',
        'message': 'm',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'openedBy': <String>[],
      });

      final snapshot =
          await firestore.collection('caches').doc('geo').get();
      final cache = GeoCache.fromFirestore(snapshot);

      expect(cache.lat, closeTo(12.34, 1e-9));
      expect(cache.lng, closeTo(56.78, 1e-9));
    });

    test('defends against missing/malformed fields without crashing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('caches').doc('bad').set(<String, dynamic>{
        // No location/lat/lng, no title, openedBy is the wrong type.
        'openedBy': 'not-a-list',
      });

      final snapshot =
          await firestore.collection('caches').doc('bad').get();
      final cache = GeoCache.fromFirestore(snapshot);

      expect(cache.id, 'bad');
      expect(cache.ownerId, '');
      expect(cache.ownerName, '');
      expect(cache.lat, 0);
      expect(cache.lng, 0);
      expect(cache.title, '');
      expect(cache.photoUrl, isNull);
      expect(cache.openedBy, isEmpty);
    });

    test('treats an empty photoUrl as null', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('caches').doc('nophoto').set(<String, dynamic>{
        'ownerId': 'o',
        'ownerName': 'n',
        'location': const GeoPoint(0, 0),
        'title': 't',
        'message': 'm',
        'photoUrl': '',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'openedBy': <String>[],
      });

      final snapshot =
          await firestore.collection('caches').doc('nophoto').get();
      final cache = GeoCache.fromFirestore(snapshot);

      expect(cache.photoUrl, isNull);
    });
  });
}
