part of 'in_call_bloc.dart';

abstract class InCallState extends Equatable {
  const InCallState();

  @override
  List<Object?> get props => [];
}

class InCallIdle extends InCallState {
  const InCallIdle();
}

class InCallActive extends InCallState {
  const InCallActive({
    required this.callInfo,
    this.heldCall,
    this.waitingCall,
    this.availableAudioRoutes = const [],
  });

  final CallInfo callInfo;
  final CallInfo? heldCall;
  final CallInfo? waitingCall;  // Call waiting scenario
  final List<String> availableAudioRoutes;  // Available audio routes (earpiece, speaker, bluetooth, wired_headset)

  bool get canMerge => heldCall != null;
  bool get canSwap => heldCall != null;
  bool get hasCallWaiting => waitingCall != null;

  @override
  List<Object?> get props => [callInfo, heldCall, waitingCall, availableAudioRoutes];
}

class InCallEnded extends InCallState {
  const InCallEnded({this.cause});

  final String? cause;

  @override
  List<Object?> get props => [cause];
}
