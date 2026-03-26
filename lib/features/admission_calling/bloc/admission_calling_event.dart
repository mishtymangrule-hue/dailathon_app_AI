part of 'admission_calling_bloc.dart';

abstract class AdmissionCallingEvent extends Equatable {
  const AdmissionCallingEvent();

  @override
  List<Object?> get props => [];
}

class AdmissionNumberAdded extends AdmissionCallingEvent {
  const AdmissionNumberAdded(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AdmissionNumberRemoved extends AdmissionCallingEvent {
  const AdmissionNumberRemoved(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AdmissionCallInitiated extends AdmissionCallingEvent {
  const AdmissionCallInitiated();
}

class AdmissionCallEnded extends AdmissionCallingEvent {
  const AdmissionCallEnded();
}
