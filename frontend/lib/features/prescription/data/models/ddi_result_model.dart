import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';

class DdiInteractionModel extends DdiInteractionEntity {
  const DdiInteractionModel({
    required super.drug1,
    required super.drug2,
    required super.description,
    super.aiExplanation,
  });

  factory DdiInteractionModel.fromJson(Map<String, dynamic> json) {
    return DdiInteractionModel(
      drug1: json['drug1'] as String,
      drug2: json['drug2'] as String,
      description: json['description'] as String,
      aiExplanation: json['ai_explanation'] as String?,
    );
  }
}

class DdiResultModel extends DdiResultEntity {
  const DdiResultModel({
    required super.drugs,
    required super.interactions,
    required super.hasInteractions,
  });

  factory DdiResultModel.fromJson(Map<String, dynamic> json) {
    return DdiResultModel(
      drugs: List<String>.from(json['drugs'] as List),
      interactions: (json['interactions'] as List)
          .map((i) => DdiInteractionModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      hasInteractions: json['has_interactions'] as bool,
    );
  }
}
