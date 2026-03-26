part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class CallForwardingRequested extends SettingsEvent {
  const CallForwardingRequested({this.currentForwarding});
  final Map<String, String>? currentForwarding;

  @override
  List<Object?> get props => [currentForwarding];
}

class CallForwardingUpdated extends SettingsEvent {
  const CallForwardingUpdated({
    required this.reason,
    required this.number,
    this.enable = true,
  });

  final String reason; // 'unconditional', 'busy', 'noAnswer', 'unreachable'
  final String number;
  final bool enable;

  @override
  List<Object?> get props => [reason, number, enable];
}

class EnableForwardingRequested extends SettingsEvent {
  const EnableForwardingRequested({
    required this.forwardingType,
    required this.forwardingNumber,
  });

  final String forwardingType; // 'unconditional', 'busy', 'noAnswer', 'unreachable'
  final String forwardingNumber;

  @override
  List<Object?> get props => [forwardingType, forwardingNumber];
}

class DisableForwardingRequested extends SettingsEvent {
  const DisableForwardingRequested({required this.forwardingType});

  final String forwardingType;

  @override
  List<Object?> get props => [forwardingType];
}

class SetDefaultDialerRequested extends SettingsEvent {
  const SetDefaultDialerRequested();
}
