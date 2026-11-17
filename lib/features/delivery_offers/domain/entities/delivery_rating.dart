/// Calificación que el cliente deja al repartidor al finalizar una entrega.
class DeliveryRating {
  final int stars;
  final String comment;
  final String driverId;
  final DateTime createdAt;

  const DeliveryRating({
    required this.stars,
    this.comment = '',
    required this.driverId,
    required this.createdAt,
  }) : assert(
         stars >= 1 && stars <= 5,
         'La calificación debe estar entre 1 y 5',
       );

  String get starsLabel => '$stars/5';

  String get starsGlyphs => List.generate(stars, (_) => '★').join();

  @override
  String toString() =>
      'DeliveryRating(driver: $driverId, stars: $stars, comment: $comment)';
}
