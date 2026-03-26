import 'package:equatable/equatable.dart';

class Contact extends Equatable {

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      photoUri: map['photoUri'],
      isBlocked: map['isBlocked'] ?? false,
    );
  }
  const Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photoUri,
    this.isBlocked = false,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? photoUri;
  final bool isBlocked;

  @override
  List<Object?> get props => [id, name, phoneNumber, photoUri, isBlocked];
}

class CallLogEntry extends Equatable {

  factory CallLogEntry.fromMap(Map<String, dynamic> map) {
    return CallLogEntry(
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      duration: map['duration'] ?? 0,
      type: map['type'] ?? 'incoming',
    );
  }
  const CallLogEntry({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.timestamp,
    required this.duration,
    required this.type, // incoming, outgoing, missed
  });

  final String id;
  final String phoneNumber;
  final String name;
  final DateTime timestamp;
  final int duration;
  final String type;

  @override
  List<Object?> get props => [id, phoneNumber, name, timestamp, duration, type];
}
