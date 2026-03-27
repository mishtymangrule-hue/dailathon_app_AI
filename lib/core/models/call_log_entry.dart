import 'package:equatable/equatable.dart';

/// Represents a single call log entry.
class CallLogEntry extends Equatable {
  const CallLogEntry({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.timestamp,
    required this.duration,
    required this.type,
  });

  /// Create CallLogEntry from a map (from native code)
  factory CallLogEntry.fromMap(Map<String, dynamic> map) => CallLogEntry(
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['number'] ?? '',
      name: map['name'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      duration: map['duration'] ?? 0,
      type: map['type'] ?? 0,
    );

  /// Unique identifier for the call log entry
  final String id;

  /// Phone number involved in the call
  final String phoneNumber;

  /// Contact name or phone number if name unavailable
  final String name;

  /// Timestamp when the call occurred (milliseconds since epoch)
  final int timestamp;

  /// Call duration in seconds
  final int duration;

  /// Call type: 1 = incoming, 2 = outgoing, 3 = missed
  /// Matches Android CallLog.Calls constants
  final int type;

  /// Get the call type as a human-readable string
  String get typeLabel {
    switch (type) {
      case 1:
        return 'Incoming';
      case 2:
        return 'Outgoing';
      case 3:
        return 'Missed';
      default:
        return 'Unknown';
    }
  }

  /// Check if this is an incoming call
  bool get isIncoming => type == 1;

  /// Check if this is an outgoing call
  bool get isOutgoing => type == 2;

  /// Check if this is a missed call
  bool get isMissed => type == 3;

  /// Get a formatted duration string
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Convert CallLogEntry to map
  Map<String, dynamic> toMap() => {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'timestamp': timestamp,
      'duration': duration,
      'type': type,
    };

  @override
  List<Object?> get props => [id, phoneNumber, name, timestamp, duration, type];

  @override
  String toString() =>
      'CallLogEntry(id: $id, number: $phoneNumber, name: $name, type: $typeLabel, duration: $durationFormatted)';
}
