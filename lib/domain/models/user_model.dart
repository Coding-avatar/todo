import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/enums/enums.dart';

/// User profile model stored in Firestore.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserLevel level;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.level = UserLevel.beginner,
    this.onboardingComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserLevel? level,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'level': level.toJson(),
      'onboardingComplete': onboardingComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      level: UserLevel.fromJson(json['level'] as String?),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create initial user model for new signups
  factory UserModel.newUser({
    required String id,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      level: UserLevel.beginner,
      onboardingComplete: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        level,
        onboardingComplete,
        createdAt,
        updatedAt,
      ];
}
