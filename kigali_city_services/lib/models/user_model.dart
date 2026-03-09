import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final DateTime createdAt;
  final bool notificationsEnabled;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    required this.createdAt,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Factory constructor to create a UserModel from Firestore data
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}
