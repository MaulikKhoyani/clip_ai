import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String subscriptionTier;
  final bool onboardingCompleted;
  final int totalExports;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.subscriptionTier = 'free',
    this.onboardingCompleted = false,
    this.totalExports = 0,
    required this.createdAt,
  });

  bool get isPro => subscriptionTier == 'pro';

  UserEntity copyWith({
    String? displayName,
    String? avatarUrl,
    String? subscriptionTier,
    bool? onboardingCompleted,
    int? totalExports,
  }) {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      totalExports: totalExports ?? this.totalExports,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        subscriptionTier,
        onboardingCompleted,
        totalExports,
        createdAt,
      ];
}
