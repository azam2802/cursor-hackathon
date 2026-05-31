/// A randomly picked road-trip destination shown on the route screen.
class RouteDestination {
  const RouteDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.heroName,
    required this.distanceKm,
    required this.durationText,
    required this.rating,
    required this.entryFee,
  });

  final String id;
  final String title;
  final String subtitle;
  final String heroName;
  final int distanceKm;
  final String durationText;
  final double rating;
  final String entryFee;
}
