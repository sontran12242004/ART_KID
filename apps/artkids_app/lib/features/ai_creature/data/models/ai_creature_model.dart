import '../../domain/entities/ai_creature.dart';

class AiCreatureModel extends AiCreature {
  const AiCreatureModel({
    required super.id,
    required super.submissionId,
    required super.animalType,
    super.model2dUrl,
    super.model3dUrl,
    super.animationUrl,
    super.audioUrl,
    super.thumbnailUrl,
    super.status = 'pending',
    this.speciesName,
    this.funFact,
  });

  final String? speciesName;
  final String? funFact;

  factory AiCreatureModel.fromJson(Map<String, dynamic> json) {
    return AiCreatureModel(
      id: json['id'] as String,
      submissionId: json['submission_id'] as String? ?? json['submissionId'] as String? ?? '',
      animalType: json['animal_type'] as String? ?? json['animalType'] as String? ?? 'unknown',
      model2dUrl: json['model_2d_url'] as String? ?? json['model2dUrl'] as String?,
      model3dUrl: json['model_3d_url'] as String? ?? json['model3dUrl'] as String?,
      animationUrl: json['animation_url'] as String? ?? json['animationUrl'] as String?,
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      speciesName: json['species_name'] as String? ?? json['speciesName'] as String?,
      funFact: json['fun_fact'] as String? ?? json['funFact'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submission_id': submissionId,
      'animal_type': animalType,
      'model_2d_url': model2dUrl,
      'model_3d_url': model3dUrl,
      'animation_url': animationUrl,
      'audio_url': audioUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status,
      'species_name': speciesName,
      'fun_fact': funFact,
    };
  }
}
