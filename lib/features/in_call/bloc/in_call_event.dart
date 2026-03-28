part of 'in_call_bloc.dart';

abstract class InCallEvent extends Equatable {
  const InCallEvent();

  @override
  List<Object?> get props => [];
}

class CallStateReceived extends InCallEvent {
  const CallStateReceived(this.callInfo);
  final CallInfo callInfo;

  @override
  List<Object?> get props => [callInfo];
}

class MultiCallStateReceived extends InCallEvent {
  const MultiCallStateReceived(this.multiCallState);
  final MultiCallState multiCallState;

  @override
  List<Object?> get props => [multiCallState];
}

class MuteToggled extends InCallEvent {
  const MuteToggled(this.currentlyMuted);
  final bool currentlyMuted;

  @override
  List<Object?> get props => [currentlyMuted];
}

class SpeakerToggled extends InCallEvent {
  const SpeakerToggled(this.currentlyEnabled);
  final bool currentlyEnabled;

  @override
  List<Object?> get props => [currentlyEnabled];
}

class BluetoothToggled extends InCallEvent {
  const BluetoothToggled(this.currentlyEnabled);
  final bool currentlyEnabled;

  @override
  List<Object?> get props => [currentlyEnabled];
}

class HoldToggled extends InCallEvent {
  const HoldToggled(this.currentlyHeld);
  final bool currentlyHeld;

  @override
  List<Object?> get props => [currentlyHeld];
}

class DtmfSent extends InCallEvent {
  const DtmfSent(this.digit);
  final String digit;

  @override
  List<Object?> get props => [digit];
}

class MergeCallsRequested extends InCallEvent {
  const MergeCallsRequested();
}

class SwapCallsRequested extends InCallEvent {
  const SwapCallsRequested();
}

class CallWaitingReceived extends InCallEvent {

  const CallWaitingReceived({required this.waitingCall});
  final CallInfo waitingCall;

  @override
  List<Object?> get props => [waitingCall];
}

class AnswerWaitingCallAndHold extends InCallEvent {
  const AnswerWaitingCallAndHold();
}

class AnswerWaitingCallAndEnd extends InCallEvent {
  const AnswerWaitingCallAndEnd();
}

class DeclineWaitingCall extends InCallEvent {
  const DeclineWaitingCall();
}

class AudioRoutesUpdated extends InCallEvent {

  const AudioRoutesUpdated({required this.availableRoutes});
  final List<String> availableRoutes;

  @override
  List<Object?> get props => [availableRoutes];
}

class AudioRouteSelected extends InCallEvent {
  const AudioRouteSelected(this.route);
  final String route;

  @override
  List<Object?> get props => [route];
}

class CallEnded extends InCallEvent {
  const CallEnded({this.cause});
  final String? cause;

  @override
  List<Object?> get props => [cause];
}
