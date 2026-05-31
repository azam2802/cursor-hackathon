import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summer_activity/core/geo/models/geo_cache.dart';
import 'package:summer_activity/screens/geo_tag/widgets/cache_list_card.dart';

void main() {
  group('formatDistance', () {
    test('renders whole meters under 1 km', () {
      expect(formatDistance(0), '0 м');
      expect(formatDistance(38), '38 м');
      expect(formatDistance(38.4), '38 м');
      expect(formatDistance(38.6), '39 м');
      expect(formatDistance(999), '999 м');
    });

    test('switches to kilometers at and above 1 km', () {
      expect(formatDistance(1000), '1.0 км');
      expect(formatDistance(1200), '1.2 км');
      expect(formatDistance(15340), '15.3 км');
    });

    test('clamps negative input to zero', () {
      expect(formatDistance(-5), '0 м');
    });
  });

  group('CacheListCard widget', () {
    GeoCache cache({String title = 'У фонтана', String ownerName = 'Алиса'}) =>
        GeoCache(
          id: 'c1',
          ownerId: 'o1',
          ownerName: ownerName,
          lat: 0,
          lng: 0,
          title: title,
          message: 'm',
          createdAt: DateTime.utc(2026, 1, 1),
        );

    Future<void> pumpCard(WidgetTester tester, CacheListCard card) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: card)),
      );
      await tester.pump();
    }

    testWidgets('renders title, owner label and distance', (tester) async {
      await pumpCard(
        tester,
        CacheListCard(cache: cache(), distanceMeters: 1200),
      );

      expect(find.text('У фонтана'), findsOneWidget);
      expect(find.text('от Алиса'), findsOneWidget);
      expect(find.text('1.2 км'), findsOneWidget);
      expect(find.text('новый'), findsOneWidget);
    });

    testWidgets('shows placeholder distance when distance is null',
        (tester) async {
      await pumpCard(tester, CacheListCard(cache: cache()));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows opened badge when isOpened is true', (tester) async {
      await pumpCard(
        tester,
        CacheListCard(cache: cache(), isOpened: true, distanceMeters: 10),
      );
      expect(find.text('открыт'), findsOneWidget);
    });

    testWidgets('falls back to defaults for empty title/owner', (tester) async {
      await pumpCard(
        tester,
        CacheListCard(cache: cache(title: '', ownerName: '')),
      );
      expect(find.text('Тайник'), findsOneWidget);
      expect(find.text('Аноним'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await pumpCard(
        tester,
        CacheListCard(
          cache: cache(),
          distanceMeters: 10,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(CacheListCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
