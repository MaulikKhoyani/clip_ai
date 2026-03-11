import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String subscriptionTier;
  final bool onboardingCompleted;
  final int totalExports;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.subscriptionTier = 'free',
    this.onboardingCompleted = false,
    this.totalExports = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      totalExports: json['total_exports'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'subscription_tier': subscriptionTier,
      'onboarding_completed': onboardingCompleted,
      'total_exports': totalExports,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      subscriptionTier: subscriptionTier,
      onboardingCompleted: onboardingCompleted,
      totalExports: totalExports,
      createdAt: createdAt,
    );
  }
}
