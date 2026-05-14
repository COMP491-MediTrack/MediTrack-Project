import 'package:equatable/equatable.dart';

class DdiInteractionEntity extends Equatable {
  final String drug1;
  final String drug2;
  final String description;
  final String? aiExplanation;

  const DdiInteractionEntity({
    required this.drug1,
    required this.drug2,
    required this.description,
    this.aiExplanation,
  });

  @override
  List<Object?> get props => [drug1, drug2, description, aiExplanation];
}

class DdiResultEntity extends Equatable {
  final List<String> drugs;
  final List<DdiInteractionEntity> interactions;
  final bool hasInteractions;

  const DdiResultEntity({
    required this.drugs,
    required this.interactions,
    required this.hasInteractions,
  });

  @override
  List<Object?> get props => [drugs, interactions, hasInteractions];
}
