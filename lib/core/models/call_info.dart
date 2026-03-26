import 'package:equatable/equatable.dart';

enum CallState {
  ringing,
  dialing,
  active,
  held,
  ended,
}

class CallInfo extends Equatable {

  factory CallInfo.fromMap(Map<String, dynamic> map) {
    return CallInfo(
      callId: map['callId'] ?? '',
      state: CallState.values.firstWhere(
        (e) => e.toString().split('.').last == (map['state'] ?? 'ringing'),
        orElse: () => CallState.ringing,
      ),
      callerNumber: map['callerNumber'] ?? map['number'] ?? '',
      callerName: map['callerName'],
      callerPhotoUri: map['callerPhotoUri'],
      durationSeconds: map['durationSeconds'] ?? (map['duration'] as int? ?? 0) ~/ 1000,
      isMuted: map['isMuted'] ?? false,
      isSpeakerOn: map['isSpeakerEnabled'] ?? false,
      isBluetoothActive: map['isBluetoothAudio'] ?? false,
      isWiredHeadsetConnected: map['isWiredHeadsetConnected'] ?? false,
      isOnHold: map['isOnHold'] ?? false,
      isConference: map['isConference'] ?? false,
      conferenceMemberIds: List<String>.from(map['conferenceParticipants'] ?? []),
      simSlot: map['simSlot'] ?? 0,
      disconnectCause: map['disconnectCause'],
      callType: map['callType'] ?? 'normal',
    );
  }
  const CallInfo({
    required this.callId,
    required this.state,
    required this.callerNumber,
    this.callerName,
    this.callerPhotoUri,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isBluetoothActive = false,
    this.isWiredHeadsetConnected = false,
    this.isOnHold = false,
    this.isConference = false,
    this.conferenceMemberIds = const [],
    this.simSlot = 0,
    this.disconnectCause,
    this.callType = 'normal',  // 'normal', 'call_waiting', 'conference'
  });

  final String callId;
  final CallState state;
  final String callerNumber;
  final String? callerName;
  final String? callerPhotoUri;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isBluetoothActive;
  final bool isWiredHeadsetConnected;
  final bool isOnHold;
  final bool isConference;
  final List<String> conferenceMemberIds;
  final int simSlot;
  final String? disconnectCause;
  final String callType;

  @override
  List<Object?> get props => [
        callId,
        state,
        callerNumber,
        callerName,
        callerPhotoUri,
        durationSeconds,
        isMuted,
        isSpeakerOn,
        isBluetoothActive,
        isWiredHeadsetConnected,
        isOnHold,
        isConference,
        conferenceMemberIds,
        simSlot,
        disconnectCause,
        callType,
      ];
}

