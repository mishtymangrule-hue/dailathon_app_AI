import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dailathon_dialer/core/models/call_info.dart';

part 'admission_calling_event.dart';
part 'admission_calling_state.dart';

/// AdmissionCallingBloc manages admission calling (tele-gathering) state.
/// Handles initiating conference calls with multiple participants.
class AdmissionCallingBloc extends Bloc<AdmissionCallingEvent, AdmissionCallingState> {
  AdmissionCallingBloc() : super(const AdmissionCallingIdle()) {
    on<AdmissionNumberAdded>(_onAdmissionNumberAdded);
    on<AdmissionNumberRemoved>(_onAdmissionNumberRemoved);
    on<AdmissionCallInitiated>(_onAdmissionCallInitiated);
    on<AdmissionCallEnded>(_onAdmissionCallEnded);
    on<StudentCalled>(_onStudentCalled);
  }

  Future<void> _onAdmissionNumberAdded(
    AdmissionNumberAdded event,
    Emitter<AdmissionCallingState> emit,
  ) async {
    if (state is AdmissionCallingPreparing) {
      final currentState = state as AdmissionCallingPreparing;
      if (!currentState.participantNumbers.contains(event.phoneNumber)) {
        emit(
          AdmissionCallingPreparing(
            participantNumbers: [...currentState.participantNumbers, event.phoneNumber],
          ),
        );
      }
    } else {
      emit(AdmissionCallingPreparing(participantNumbers: [event.phoneNumber]));
    }
  }

  Future<void> _onAdmissionNumberRemoved(
    AdmissionNumberRemoved event,
    Emitter<AdmissionCallingState> emit,
  ) async {
    if (state is AdmissionCallingPreparing) {
      final currentState = state as AdmissionCallingPreparing;
      final updated = currentState.participantNumbers
          .where((num) => num != event.phoneNumber)
          .toList();
      if (updated.isEmpty) {
        emit(const AdmissionCallingIdle());
      } else {
        emit(AdmissionCallingPreparing(participantNumbers: updated));
      }
    }
  }

  Future<void> _onAdmissionCallInitiated(
    AdmissionCallInitiated event,
    Emitter<AdmissionCallingState> emit,
  ) async {
    if (state is AdmissionCallingPreparing) {
      final currentState = state as AdmissionCallingPreparing;
      // TODO: Call native method to initiate conference calls
      // await _callMethodChannel.initiateConferenceCalls(currentState.participantNumbers);
      emit(
        AdmissionCallingActive(
          participantNumbers: currentState.participantNumbers,
          activeCalls: const [],
        ),
      );
    }
  }

  Future<void> _onAdmissionCallEnded(
    AdmissionCallEnded event,
    Emitter<AdmissionCallingState> emit,
  ) async {
    emit(const AdmissionCallingIdle());
  }

  Future<void> _onStudentCalled(
    StudentCalled event,
    Emitter<AdmissionCallingState> emit,
  ) async {
    // Add student to the calling queue
    final number = event.studentId; // In practice would look up phone number
    add(AdmissionNumberAdded(number));
    add(const AdmissionCallInitiated());
  }
}
