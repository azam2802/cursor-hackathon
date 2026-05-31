import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summer_activity/core/geo/cache_repository.dart';
import 'package:summer_activity/core/geo/models/geo_cache.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CacheRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    // A mock storage is injected so the constructor never touches the real
    // FirebaseStorage.instance (which needs Firebase.initializeApp). Every test
    // below uses the no-photo path, so storage is constructed but never called.
    repository =
        CacheRepository(firestore: firestore, storage: MockFirebaseStorage());
  });

  group('createCache (without photo)', () {
    test('writes a doc with the provided fields and returns its id', () async {
      final id = await repository.createCache(
        ownerId: 'owner-1',
        ownerName: 'Алиса',
        lat: 55.751244,
        lng: 37.618423,
        title: 'У фонтана',
        message: 'Загляни под скамейку',
      );

      expect(id, isNotEmpty);

      final snapshot = await firestore
          .collection(CacheRepository.collectionName)
          .doc(id)
          .get();
      expect(snapshot.exists, isTrue);

      final cache = GeoCache.fromFirestore(snapshot);
      expect(cache.id, id);
      expect(cache.ownerId, 'owner-1');
      expect(cache.ownerName, 'Алиса');
      expect(cache.lat, closeTo(55.751244, 1e-9));
      expect(cache.lng, closeTo(37.618423, 1e-9));
      expect(cache.title, 'У фонтана');
      expect(cache.message, 'Загляни под скамейку');
      expect(cache.photoUrl, isNull);
      expect(cache.openedBy, isEmpty);
    });
  });

  group('watchCaches', () {
    test('emits caches ordered newest first', () async {
      final older = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 1,
        lng: 1,
        title: 'older',
        message: 'm',
      );
      // Force a strictly later createdAt by writing the second doc afterwards.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final newer = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 2,
        lng: 2,
        title: 'newer',
        message: 'm',
      );

      final caches = await repository.watchCaches().first;

      expect(caches.map((c) => c.id), containsAll(<String>[older, newer]));
      expect(caches.first.id, newer,
          reason: 'watchCaches orders by createdAt descending');
    });

    test('reflects a newly created cache', () async {
      final stream = repository.watchCaches();
      final id = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 1,
        lng: 1,
        title: 'fresh',
        message: 'm',
      );

      final caches = await stream.firstWhere((list) => list.isNotEmpty);
      expect(caches.any((c) => c.id == id && c.title == 'fresh'), isTrue);
    });
  });

  group('markOpened', () {
    test('adds the uid to openedBy', () async {
      final id = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 1,
        lng: 1,
        title: 't',
        message: 'm',
      );

      await repository.markOpened(id, 'user-x');

      final cache = GeoCache.fromFirestore(await firestore
          .collection(CacheRepository.collectionName)
          .doc(id)
          .get());
      expect(cache.openedBy, contains('user-x'));
    });

    test('does not duplicate a uid when called repeatedly (arrayUnion)',
        () async {
      final id = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 1,
        lng: 1,
        title: 't',
        message: 'm',
      );

      await repository.markOpened(id, 'user-x');
      await repository.markOpened(id, 'user-x');

      final cache = GeoCache.fromFirestore(await firestore
          .collection(CacheRepository.collectionName)
          .doc(id)
          .get());
      expect(cache.openedBy.where((u) => u == 'user-x').length, 1);
    });
  });

  group('deleteCache', () {
    test('removes the document', () async {
      final id = await repository.createCache(
        ownerId: 'o',
        ownerName: 'n',
        lat: 1,
        lng: 1,
        title: 't',
        message: 'm',
      );

      await repository.deleteCache(id);

      final snapshot = await firestore
          .collection(CacheRepository.collectionName)
          .doc(id)
          .get();
      expect(snapshot.exists, isFalse);
    });
  });
}
