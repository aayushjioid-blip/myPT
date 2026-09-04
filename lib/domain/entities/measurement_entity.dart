class ProgressPhotos {
  final String? frontUrl;
  final String? sideUrl;
  final String? backUrl;

  const ProgressPhotos({this.frontUrl, this.sideUrl, this.backUrl});
}

class MeasurementEntity {
  final String id;
  final String clientId;
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
  final ProgressPhotos? photos;
  final String? notes;
  final String source; // 'CLIENT' or 'TRAINER'

  const MeasurementEntity({
    required this.id,
    required this.clientId,
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
    this.photos,
    this.notes,
    this.source = 'CLIENT',
  });
}
