import '../../domain/entities/measurement_entity.dart';

class MeasurementModel {
  final String id;
  final String clientId;
  final String loggedBy;
  final DateTime date;
  final double weightKg;
  final double heightCm;
  final double bmi;
  final double bodyFatPercentage;
  final double chestCm;
  final double waistCm;
  final double hipsCm;
  final double bicepsCm;
  final double thighsCm;
  final double calvesCm;
  final String? notes;
  final String source;
  final ProgressPhotos? photos;

  MeasurementModel({
    required this.id,
    required this.clientId,
    required this.loggedBy,
    required this.date,
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    this.bodyFatPercentage = 22.0,
    this.chestCm = 90.0,
    this.waistCm = 72.0,
    this.hipsCm = 95.0,
    this.bicepsCm = 29.0,
    this.thighsCm = 55.0,
    this.calvesCm = 36.5,
    this.notes,
    this.source = 'CLIENT',
    this.photos,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    final photosList = (json['progress_photos'] as List?)?.map((p) => p as Map<String, dynamic>).toList() ?? [];
    String? front;
    String? side;
    String? back;

    for (final p in photosList) {
      final pose = p['pose_type']?.toString().toUpperCase();
      final path = p['storage_path']?.toString();
      if (pose == 'FRONT') front = path;
      if (pose == 'SIDE') side = path;
      if (pose == 'BACK') back = path;
    }

    return MeasurementModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      loggedBy: json['logged_by']?.toString() ?? json['client_id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()).toLocal() : DateTime.now(),
      weightKg: json['weight_kg'] != null ? double.tryParse(json['weight_kg'].toString()) ?? 64.5 : 64.5,
      heightCm: json['height_cm'] != null ? double.tryParse(json['height_cm'].toString()) ?? 168.0 : 168.0,
      bmi: json['bmi'] != null ? double.tryParse(json['bmi'].toString()) ?? 22.9 : 22.9,
      bodyFatPercentage: json['body_fat_percentage'] != null ? double.tryParse(json['body_fat_percentage'].toString()) ?? 22.0 : 22.0,
      chestCm: json['chest_cm'] != null ? double.tryParse(json['chest_cm'].toString()) ?? 90.0 : 90.0,
      waistCm: json['waist_cm'] != null ? double.tryParse(json['waist_cm'].toString()) ?? 72.0 : 72.0,
      hipsCm: json['hips_cm'] != null ? double.tryParse(json['hips_cm'].toString()) ?? 95.0 : 95.0,
      bicepsCm: json['biceps_cm'] != null ? double.tryParse(json['biceps_cm'].toString()) ?? 29.0 : 29.0,
      thighsCm: json['thighs_cm'] != null ? double.tryParse(json['thighs_cm'].toString()) ?? 55.0 : 55.0,
      calvesCm: json['calves_cm'] != null ? double.tryParse(json['calves_cm'].toString()) ?? 36.5 : 36.5,
      notes: json['notes']?.toString(),
      source: json['source']?.toString() ?? 'CLIENT',
      photos: (front != null || side != null || back != null)
          ? ProgressPhotos(frontUrl: front, sideUrl: side, backUrl: back)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'logged_by': loggedBy,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'body_fat_percentage': bodyFatPercentage,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'biceps_cm': bicepsCm,
      'thighs_cm': thighsCm,
      'calves_cm': calvesCm,
      if (notes != null) 'notes': notes,
      'source': source,
    };
  }

  MeasurementEntity toEntity() {
    return MeasurementEntity(
      id: id,
      clientId: clientId,
      date: date,
      weightKg: weightKg,
      heightCm: heightCm,
      bmi: bmi,
      bodyFatPercentage: bodyFatPercentage,
      chestCm: chestCm,
      waistCm: waistCm,
      hipsCm: hipsCm,
      bicepsCm: bicepsCm,
      thighsCm: thighsCm,
      calvesCm: calvesCm,
      photos: photos,
      notes: notes,
      source: source,
    );
  }
}
