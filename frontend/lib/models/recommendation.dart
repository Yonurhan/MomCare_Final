// lib/models/recommendation.dart

// Kelas dasar (abstrak)
abstract class Recommendation {
  factory Recommendation.fromJson(Map<String, dynamic> json) {
    // Kunci utama untuk membedakan adalah 'type'
    final type = json['type'];

    switch (type) {
      case 'info':
        return InfoRecommendation.fromJson(json);
      case 'food':
        return FoodRecommendation.fromJson(json);
      case 'tip':
        return TipRecommendation.fromJson(json);
      // Fallback jika ada tipe baru di masa depan
      default:
        print('--- TIPE REKOMENDASI TIDAK DIKENAL ---');
        print('Diterima tipe: $type dengan data: $json');
        print('------------------------------------');
        throw Exception('Unknown recommendation type: $type');
    }
  }
}

// Tipe 1: Info (Tidak ada perubahan struktur)
class InfoRecommendation implements Recommendation {
  final String text;
  final String type;

  InfoRecommendation({required this.text, required this.type});

  factory InfoRecommendation.fromJson(Map<String, dynamic> json) {
    return InfoRecommendation(
      text: json['text'],
      type: json['type'],
    );
  }
}

// Tipe 2: Makanan (Tidak ada perubahan struktur)
class FoodRecommendation implements Recommendation {
  final String food;
  final String servingSize;
  final List<String> tags;
  final String unit;
  final num value;

  FoodRecommendation({
    required this.food,
    required this.servingSize,
    required this.tags,
    required this.unit,
    required this.value,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      food: json['food'],
      servingSize: json['serving_size'],
      tags: List<String>.from(json['tags']),
      unit: json['unit'],
      value: json['value'],
    );
  }
}

// Tipe 3: Tip (Strukturnya sekarang mirip InfoRecommendation)
class TipRecommendation implements Recommendation {
  final String text;
  final String type;

  TipRecommendation({required this.text, required this.type});

  factory TipRecommendation.fromJson(Map<String, dynamic> json) {
    return TipRecommendation(
      text: json['text'],
      type: json['type'],
    );
  }
}
