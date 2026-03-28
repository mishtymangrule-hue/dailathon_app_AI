part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.unconditionalForwarding,
    required this.busyForwarding,
    required this.noAnswerForwarding,
    required this.unreachableForwarding,
    this.unconditionalEnabled = false,
    this.busyEnabled = false,
    this.noAnswerEnabled = false,
    this.unreachableEnabled = false,
    this.isDefaultDialer = false,
    this.callWaitingEnabled = false,
    this.powerButtonEndCall = false,
    this.volumeButtonBehavior = 'mute',
    this.themeMode = 'system',
    this.blockedNumbers = const [],
  });

  final String unconditionalForwarding;
  final String busyForwarding;
  final String noAnswerForwarding;
  final String unreachableForwarding;
  final bool unconditionalEnabled;
  final bool busyEnabled;
  final bool noAnswerEnabled;
  final bool unreachableEnabled;
  final bool isDefaultDialer;
  final bool callWaitingEnabled;
  final bool powerButtonEndCall;
  final String volumeButtonBehavior;
  final String themeMode;
  final List<String> blockedNumbers;

  bool getForwardingEnabled(String type) {
    switch (type) {
      case 'unconditional':
        return unconditionalEnabled;
      case 'busy':
        return busyEnabled;
      case 'noAnswer':
        return noAnswerEnabled;
      case 'unreachable':
        return unreachableEnabled;
      default:
        return false;
    }
  }

  String? getForwardingNumber(String type) {
    switch (type) {
      case 'unconditional':
        return unconditionalForwarding.isEmpty ? null : unconditionalForwarding;
      case 'busy':
        return busyForwarding.isEmpty ? null : busyForwarding;
      case 'noAnswer':
        return noAnswerForwarding.isEmpty ? null : noAnswerForwarding;
      case 'unreachable':
        return unreachableForwarding.isEmpty ? null : unreachableForwarding;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
    unconditionalForwarding,
    busyForwarding,
    noAnswerForwarding,
    unreachableForwarding,
    unconditionalEnabled,
    busyEnabled,
    noAnswerEnabled,
    unreachableEnabled,
    isDefaultDialer,
    callWaitingEnabled,
    powerButtonEndCall,
    volumeButtonBehavior,
    themeMode,
    blockedNumbers,
  ];
}

class SettingsError extends SettingsState {
  const SettingsError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}

class SettingsSuccess extends SettingsState {
  const SettingsSuccess();
}
