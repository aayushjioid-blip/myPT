import '../../domain/entities/review_entity.dart';

class ReviewModel {
  final String id;
  final String trainerId;
  final String clientId;
  final String clientName;
  final int rating;
  final String comment;
  final bool isVisible;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    this.isVisible = true,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final client = json['users'] is Map<String, dynamic> ? json['users'] as Map<String, dynamic> : <String, dynamic>{};

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      trainerId: json['trainer_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      clientName: client['name']?.toString() ?? json['client_name']?.toString() ?? 'Client',
      rating: json['rating'] != null ? int.tryParse(json['rating'].toString()) ?? 5 : 5,
      comment: json['comment']?.toString() ?? '',
      isVisible: json['is_visible'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'rating': rating,
      'comment': comment,
      'is_visible': isVisible,
    };
  }

  ReviewEntity toEntity() {
    return ReviewEntity(
      id: id,
      trainerId: trainerId,
      clientId: clientId,
      clientName: clientName,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}
