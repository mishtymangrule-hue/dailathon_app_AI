part of 'admission_calling_bloc.dart';

abstract class AdmissionCallingState extends Equatable {
  const AdmissionCallingState();

  @override
  List<Object?> get props => [];
}

class AdmissionCallingIdle extends AdmissionCallingState {
  const AdmissionCallingIdle();
}

class AdmissionCallingPreparing extends AdmissionCallingState {
  const AdmissionCallingPreparing({required this.participantNumbers});

  final List<String> participantNumbers;

  @override
  List<Object?> get props => [participantNumbers];
}

class AdmissionCallingActive extends AdmissionCallingState {
  const AdmissionCallingActive({
    required this.participantNumbers,
    required this.activeCalls,
  });

  final List<String> participantNumbers;
  final List<CallInfo> activeCalls;

  @override
  List<Object?> get props => [participantNumbers, activeCalls];
}
