import '../../domain/entities/parent_user.dart';

class ParentUserModel extends ParentUser {
  const ParentUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phoneNumber,
    super.hasActiveSubscription = false,
    super.hasCompletedCoppaConsent = false,
  });

  factory ParentUserModel.fromJson(Map<String, dynamic> json) {
    return ParentUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      hasActiveSubscription: json['has_active_subscription'] as bool? ?? false,
      hasCompletedCoppaConsent: json['has_completed_coppa_consent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'has_active_subscription': hasActiveSubscription,
      'has_completed_coppa_consent': hasCompletedCoppaConsent,
    };
  }
}
