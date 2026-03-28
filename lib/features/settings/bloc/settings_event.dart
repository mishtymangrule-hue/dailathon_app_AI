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

class CallWaitingToggled extends SettingsEvent {
  const CallWaitingToggled({required this.enabled});
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class PowerButtonEndCallToggled extends SettingsEvent {
  const PowerButtonEndCallToggled({required this.enabled});
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class VolumeButtonBehaviorChanged extends SettingsEvent {
  const VolumeButtonBehaviorChanged({required this.behavior});
  final String behavior; // 'mute', 'decline', 'nothing'

  @override
  List<Object?> get props => [behavior];
}

class ThemeModeChanged extends SettingsEvent {
  const ThemeModeChanged({required this.themeMode});
  final String themeMode; // 'light', 'dark', 'system'

  @override
  List<Object?> get props => [themeMode];
}

class BlockedNumberAdded extends SettingsEvent {
  const BlockedNumberAdded({required this.number});
  final String number;

  @override
  List<Object?> get props => [number];
}

class BlockedNumberRemoved extends SettingsEvent {
  const BlockedNumberRemoved({required this.number});
  final String number;

  @override
  List<Object?> get props => [number];
}
