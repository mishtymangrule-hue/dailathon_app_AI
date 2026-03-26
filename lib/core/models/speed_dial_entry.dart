import 'package:equatable/equatable.dart';

/// Speed dial entry for positions 1-9 on the dialpad.
/// Position 1 is reserved for voicemail.
/// Positions 2-9 can be assigned to contacts for quick dialing.
class SpeedDialEntry extends Equatable {

  factory SpeedDialEntry.fromMap(Map<String, dynamic> map) {
    return SpeedDialEntry(
      position: map['position'] as int,
      contactId: map['contactId'] as String,
      displayName: map['displayName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      photoUri: map['photoUri'] as String?,
      createdAt: map['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null,
      updatedAt: map['updatedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
        : null,
    );
  }
  const SpeedDialEntry({
    required this.position,      // 1-9
    required this.contactId,
    required this.displayName,
    required this.phoneNumber,
    this.photoUri,
    this.createdAt,
    this.updatedAt,
  });

  final int position;         // 1-9 (1 = voicemail)
  final String contactId;      // Contact ID from system
  final String displayName;    // Contact name
  final String phoneNumber;    // Number to dial
  final String? photoUri;      // Optional contact photo
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVoicemail => position == 1;

  Map<String, dynamic> toMap() => {
      'position': position,
      'contactId': contactId,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUri': photoUri,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };

  SpeedDialEntry copyWith({
    int? position,
    String? contactId,
    String? displayName,
    String? phoneNumber,
    String? photoUri,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SpeedDialEntry(
      position: position ?? this.position,
      contactId: contactId ?? this.contactId,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUri: photoUri ?? this.photoUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  @override
  List<Object?> get props => [
    position,
    contactId,
    displayName,
    phoneNumber,
    photoUri,
    createdAt,
    updatedAt,
  ];
}

/// Contact marked as favorite.
class ContactFavorite extends Equatable {

  factory ContactFavorite.fromMap(Map<String, dynamic> map) {
    return ContactFavorite(
      contactId: map['contactId'] as String,
      displayName: map['displayName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      photoUri: map['photoUri'] as String?,
      createdAt: map['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null,
    );
  }
  const ContactFavorite({
    required this.contactId,
    required this.displayName,
    required this.phoneNumber,
    this.photoUri,
    this.createdAt,
  });

  final String contactId;
  final String displayName;
  final String phoneNumber;
  final String? photoUri;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [contactId, displayName, phoneNumber, photoUri, createdAt];
}
