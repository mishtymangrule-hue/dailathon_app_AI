import 'package:equatable/equatable.dart';
import 'call_info.dart';

/// Represents the state of multiple calls (active + held + waiting).
class MultiCallState extends Equatable {
  const MultiCallState({
    this.activeCall,
    this.heldCall,
    this.waitingCall,
  });

  factory MultiCallState.fromMap(Map<String, dynamic> map) => MultiCallState(
      activeCall: map['activeCall'] != null 
          ? CallInfo.fromMap(Map<String, dynamic>.from(map['activeCall'] as Map))
          : null,
      heldCall: map['heldCall'] != null 
          ? CallInfo.fromMap(Map<String, dynamic>.from(map['heldCall'] as Map))
          : null,
      waitingCall: map['waitingCall'] != null 
          ? CallInfo.fromMap(Map<String, dynamic>.from(map['waitingCall'] as Map))
          : null,
    );

  final CallInfo? activeCall;
  final CallInfo? heldCall;
  final CallInfo? waitingCall;

  bool get hasActiveCalls => activeCall != null || heldCall != null;
  bool get canSwap => activeCall != null && heldCall != null;
  bool get canMerge => activeCall != null && heldCall != null;
  bool get hasWaitingCall => waitingCall != null;

  @override
  List<Object?> get props => [activeCall, heldCall, waitingCall];
}
