import 'package:equatable/equatable.dart';

class AiCreature extends Equatable {
  const AiCreature({
    required this.id,
    required this.submissionId,
    required this.animalType,
    this.model2dUrl,
    this.model3dUrl,
    this.animationUrl,
    this.audioUrl,
    this.thumbnailUrl,
    this.status = 'pending',
  });

  final String id;
  final String submissionId;
  final String animalType;
  final String? model2dUrl;
  final String? model3dUrl;
  final String? animationUrl;
  final String? audioUrl;
  final String? thumbnailUrl;
  final String status;

  @override
  List<Object?> get props => [
        id,
        submissionId,
        animalType,
        model2dUrl,
        model3dUrl,
        animationUrl,
        audioUrl,
        thumbnailUrl,
        status,
      ];
}
