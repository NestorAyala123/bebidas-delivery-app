/// Entidad de dominio que representa la calificación de una entrega de
/// delivery realizada por el cliente a favor del repartidor asignado.
///
/// 100% pure Dart, independiente de Flutter y Firebase.
/// La entidad es inmutable y valida sus invariantes:
/// - La puntuación debe ser un entero entre 1 y 5 estrellas.
/// - El comentario es opcional y con longitud máxima de 500 caracteres.
/// - Un usuario no puede calificar su propia entrega.
/// - El identificador de la solicitud de delivery no puede estar vacío.
class Rating {
  /// Puntuación mínima permitida en una calificación.
  static const int minScore = 1;

  /// Puntuación máxima permitida en una calificación.
  static const int maxScore = 5;

  /// Longitud máxima permitida para el comentario de una calificación.
  static const int maxCommentLength = 500;

  final String id;
  final String deliveryRequestId;
  final String customerId;
  final String driverId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.deliveryRequestId,
    required this.customerId,
    required this.driverId,
    required this.score,
    this.comment,
    required this.createdAt,
  }) {
    assert(
      id.trim().isNotEmpty,
      'El id de la calificación no puede estar vacío',
    );
    assert(
      deliveryRequestId.trim().isNotEmpty,
      'El id de la solicitud de delivery no puede estar vacío',
    );
    assert(
      customerId.trim().isNotEmpty,
      'El id del cliente no puede estar vacío',
    );
    assert(
      driverId.trim().isNotEmpty,
      'El id del repartidor no puede estar vacío',
    );
    assert(
      score >= minScore && score <= maxScore,
      'La calificación debe estar entre 1 y 5 estrellas',
    );
    assert(
      customerId != driverId,
      'RN-RATING: Un usuario no puede calificar su propia entrega',
    );
  }

  /// Indica si la calificación incluye un comentario con contenido utilizable.
  bool get hasComment => comment != null && comment!.trim().isNotEmpty;

  /// Normaliza el comentario, dejándolo nulo cuando está vacío.
  String? get normalizedComment => comment == null
      ? null
      : (comment!.trim().isEmpty ? null : comment!.trim());
}
