part of 'dialer_bloc.dart';

abstract class DialerEvent extends Equatable {
  const DialerEvent();

  @override
  List<Object?> get props => [];
}

class NumberInput extends DialerEvent {
  const NumberInput(this.digit);
  final String digit;

  @override
  List<Object?> get props => [digit];
}

class BackspacePressed extends DialerEvent {
  const BackspacePressed();
}

class ClearPressed extends DialerEvent {
  const ClearPressed();
}

class CallInitiated extends DialerEvent {
  const CallInitiated({required this.number, required this.simSlot});
  final String number;
  final int simSlot;

  @override
  List<Object?> get props => [number, simSlot];
}

class SimSelected extends DialerEvent {
  const SimSelected({required this.slot});
  final int slot;

  @override
  List<Object?> get props => [slot];
}

class NumberChanged extends DialerEvent {
  const NumberChanged({required this.number});
  final String number;

  @override
  List<Object?> get props => [number];
}

class SimSlotSelected extends DialerEvent {
  const SimSlotSelected(this.simSlot);
  final int simSlot;

  @override
  List<Object?> get props => [simSlot];
}

class T9SearchPerformed extends DialerEvent {
  const T9SearchPerformed(this.suggestions);
  final List<Contact> suggestions;

  @override
  List<Object?> get props => [suggestions];
}

class SpeedDialAssigned extends DialerEvent {
  const SpeedDialAssigned({
    required this.position,
    required this.contactId,
    required this.displayName,
    required this.phoneNumber,
  });
  final int position;
  final String contactId;
  final String displayName;
  final String phoneNumber;

  @override
  List<Object?> get props => [position, contactId, displayName, phoneNumber];
}

class SpeedDialRemoved extends DialerEvent {
  const SpeedDialRemoved({required this.position});
  final int position;

  @override
  List<Object?> get props => [position];
}

class SpeedDialLongPress extends DialerEvent {
  const SpeedDialLongPress({required this.position});
  final int position;

  @override
  List<Object?> get props => [position];
}
