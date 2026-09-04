class ReviewEntity {
  final String id;
  final String trainerId;
  final String clientId;
  final String clientName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
