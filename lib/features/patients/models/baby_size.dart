/// Reference data for a single gestational week from
/// `GET /api/v1/health/baby-size/{week}/` (or the list endpoint).
class BabySizeReference {
  final int week;
  final String sizeComparison;
  final String lengthCm;
  final String weightGrams;
  final String description;

  const BabySizeReference({
    this.week = 0,
    this.sizeComparison = '',
    this.lengthCm = '',
    this.weightGrams = '',
    this.description = '',
  });

  factory BabySizeReference.fromJson(Map<String, dynamic> json) =>
      BabySizeReference(
        week: json['week'] ?? 0,
        sizeComparison: json['size_comparison'] ?? '',
        lengthCm: json['length_cm']?.toString() ?? '',
        weightGrams: json['weight_grams']?.toString() ?? '',
        description: json['description'] ?? '',
      );
}
