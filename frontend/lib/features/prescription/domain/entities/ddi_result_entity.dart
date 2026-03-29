import 'package:equatable/equatable.dart';

class DdiInteractionEntity extends Equatable {
  final String drug1;
  final String drug2;
  final String description;

  const DdiInteractionEntity({
    required this.drug1,
    required this.drug2,
    required this.description,
  });

  @override
  List<Object?> get props => [drug1, drug2, description];
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
