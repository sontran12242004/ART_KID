import 'package:equatable/equatable.dart';

class ParentUser extends Equatable {
  const ParentUser({
    required this.id,
    required this.email,
    this.fullName = '',
    this.displayName = '',
    this.phoneNumber,
    this.hasActiveSubscription = false,
    this.hasCompletedCoppaConsent = false,
    this.parentalConsentAt,
    this.role = 'parent',
  });

  final String id;
  final String email;
  final String fullName;
  final String displayName;
  final String? phoneNumber;
  final bool hasActiveSubscription;
  final bool hasCompletedCoppaConsent;
  final DateTime? parentalConsentAt;
  final String role;

  String get name => fullName.isNotEmpty ? fullName : displayName;

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    displayName,
    phoneNumber,
    hasActiveSubscription,
    hasCompletedCoppaConsent,
    parentalConsentAt,
  ];
}
