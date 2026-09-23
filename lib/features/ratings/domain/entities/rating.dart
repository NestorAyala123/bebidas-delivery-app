class Rating {
  final String id;
  final String orderId;
  final String authorId;
  final String targetUserId; // driver or store
  final int score; // 1 to 5
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.targetUserId,
    required this.score,
    this.comment,
    required this.createdAt,
  }) : assert(score >= 1 && score <= 5, 'La calificación debe estar entre 1 y 5 estrellas');
}
