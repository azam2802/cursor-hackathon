import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models/geo_cache.dart';

/// UI-agnostic data access for geo caches (тайники).
///
/// Reads/writes the Firestore `caches` collection and uploads cache photos to
/// Cloud Storage. [FirebaseFirestore] and [FirebaseStorage] are injected so the
/// repository is unit-testable with fakes (e.g. `fake_cloud_firestore`).
class CacheRepository {
  CacheRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static const String collectionName = 'caches';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _caches =>
      _firestore.collection(collectionName);

  /// Creates a cache document and returns its generated id.
  ///
  /// When [photo] is provided it is uploaded to
  /// `caches/{ownerId}/{cacheId}.jpg` and its download URL is stored on the
  /// doc. `createdAt` is set to [DateTime.now] and `openedBy` starts empty.
  Future<String> createCache({
    required String ownerId,
    required String ownerName,
    required double lat,
    required double lng,
    required String title,
    required String message,
    File? photo,
  }) async {
    final docRef = _caches.doc();
    final cacheId = docRef.id;

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _uploadPhoto(
        ownerId: ownerId,
        cacheId: cacheId,
        photo: photo,
      );
    }

    final cache = GeoCache(
      id: cacheId,
      ownerId: ownerId,
      ownerName: ownerName,
      lat: lat,
      lng: lng,
      title: title,
      message: message,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      openedBy: const <String>[],
    );

    await docRef.set(cache.toMap());
    return cacheId;
  }

  /// Streams all caches ordered by newest first, mapped to [GeoCache].
  ///
  /// MVP behaviour: every cache is streamed and distance filtering happens
  /// client-side. Follow-up for scale: store a geohash and query by
  /// geohash-prefix / bounding box so reads grow with nearby caches only.
  Stream<List<GeoCache>> watchCaches() {
    return _caches
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(GeoCache.fromFirestore)
            .toList(growable: false));
  }

  /// Records [uid] as having opened [cacheId]. `arrayUnion` prevents duplicates.
  Future<void> markOpened(String cacheId, String uid) {
    return _caches.doc(cacheId).update(<String, dynamic>{
      'openedBy': FieldValue.arrayUnion(<String>[uid]),
    });
  }

  /// Deletes a cache document. Intended for owner-side deletion.
  Future<void> deleteCache(String cacheId) {
    return _caches.doc(cacheId).delete();
  }

  Future<String> _uploadPhoto({
    required String ownerId,
    required String cacheId,
    required File photo,
  }) async {
    final ref = _storage.ref('$collectionName/$ownerId/$cacheId.jpg');
    final task = await ref.putFile(
      photo,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
