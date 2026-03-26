import 'dart:async';

import 'package:dailathon_dialer/core/channels/call_event_channel.dart';
import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/models/call_info.dart';
import 'package:dailathon_dialer/core/models/multi_call_state.dart';
import 'package:dailathon_dialer/core/services/crm_reporting_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'in_call_event.dart';
part 'in_call_state.dart';

/// InCallBloc manages the active call UI state.
/// Subscribes to CallEventChannel for real-time call state updates.
class InCallBloc extends Bloc<InCallEvent, InCallState> {
  InCallBloc(
    this._callEventChannel,
    this._callMethodChannel, {
    CrmReportingService? reportingService,
  })  : _reportingService = reportingService,
        super(const InCallIdle()) {
    on<CallStateReceived>(_onCallStateReceived);
    on<MultiCallStateReceived>(_onMultiCallStateReceived);
    on<MuteToggled>(_onMuteToggled);
    on<SpeakerToggled>(_onSpeakerToggled);
    on<BluetoothToggled>(_onBluetoothToggled);
    on<HoldToggled>(_onHoldToggled);
    on<DtmfSent>(_onDtmfSent);
    on<MergeCallsRequested>(_onMergeCallsRequested);
    on<SwapCallsRequested>(_onSwapCallsRequested);
    on<CallWaitingReceived>(_onCallWaitingReceived);
    on<AnswerWaitingCallAndHold>(_onAnswerWaitingAndHold);
    on<AnswerWaitingCallAndEnd>(_onAnswerWaitingAndEnd);
    on<DeclineWaitingCall>(_onDeclineWaitingCall);
    on<CallEnded>(_onCallEnded);

    _startListeningToCallEvents();
  }

  final CallEventChannel _callEventChannel;
  final CallMethodChannel _callMethodChannel;
  final CrmReportingService? _reportingService;
  late StreamSubscription<MultiCallState> _callEventSubscription;

  // Track call timing for CRM reporting
  DateTime? _callStartedAt;
  DateTime? _ringingStartedAt;

  void _startListeningToCallEvents() {
    _callEventSubscription = _callEventChannel.multiCallStateStream.listen(
      (multiCallState) => add(MultiCallStateReceived(multiCallState)),
      onError: (error) {
        addError(error);
      },
    );
  }

  Future<void> _onCallStateReceived(
    CallStateReceived event,
    Emitter<InCallState> emit,
  ) async {
    // Record ringing start time on first event
    _ringingStartedAt ??= DateTime.now();

    if (event.callInfo.state == CallState.active) {
      _callStartedAt ??= DateTime.now();
    }

    if (event.callInfo.state == CallState.ended) {
      await _reportEndedCall(event.callInfo);
      emit(InCallEnded(cause: event.callInfo.disconnectCause));
    } else {
      emit(InCallActive(callInfo: event.callInfo));
    }
  }

  Future<void> _onMultiCallStateReceived(
    MultiCallStateReceived event,
    Emitter<InCallState> emit,
  ) async {
    final multiCallState = event.multiCallState;
    
    if (multiCallState.activeCall == null) {
      emit(const InCallIdle());
    } else if (multiCallState.activeCall!.state == CallState.ended) {
      emit(InCallEnded(cause: multiCallState.activeCall!.disconnectCause));
    } else {
      emit(InCallActive(
        callInfo: multiCallState.activeCall!,
        heldCall: multiCallState.heldCall,
        waitingCall: multiCallState.waitingCall,
      ));
    }
  }

  Future<void> _onMuteToggled(
    MuteToggled event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.mute(!event.currentlyMuted);
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onSpeakerToggled(
    SpeakerToggled event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.setSpeaker(!event.currentlyEnabled);
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onBluetoothToggled(
    BluetoothToggled event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.setBluetoothAudio(!event.currentlyEnabled);
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onHoldToggled(
    HoldToggled event,
    Emitter<InCallState> emit,
  ) async {
    try {
      if (event.currentlyHeld) {
        await _callMethodChannel.unhold();
      } else {
        await _callMethodChannel.hold();
      }
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onDtmfSent(
    DtmfSent event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.sendDtmf(event.digit);
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onMergeCallsRequested(
    MergeCallsRequested event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.mergeActiveCalls();
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onSwapCallsRequested(
    SwapCallsRequested event,
    Emitter<InCallState> emit,
  ) async {
    try {
      await _callMethodChannel.swapCalls();
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onCallWaitingReceived(
    CallWaitingReceived event,
    Emitter<InCallState> emit,
  ) async {
    if (state is InCallActive) {
      final currentState = state as InCallActive;
      emit(InCallActive(
        callInfo: currentState.callInfo,
        heldCall: currentState.heldCall,
        waitingCall: event.waitingCall,
        availableAudioRoutes: currentState.availableAudioRoutes,
      ));
    }
  }

  Future<void> _onAnswerWaitingAndHold(
    AnswerWaitingCallAndHold event,
    Emitter<InCallState> emit,
  ) async {
    try {
      // Hold current call and answer waiting call
      await _callMethodChannel.hold();
      await _callMethodChannel.answer();
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onAnswerWaitingAndEnd(
    AnswerWaitingCallAndEnd event,
    Emitter<InCallState> emit,
  ) async {
    try {
      // End current call and answer waiting call
      await _callMethodChannel.hangUp();
      await _callMethodChannel.answer();
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onDeclineWaitingCall(
    DeclineWaitingCall event,
    Emitter<InCallState> emit,
  ) async {
    try {
      // Decline/reject the waiting call
      await _callMethodChannel.rejectCall();
    } catch (e) {
      addError(e);
    }
  }

  Future<void> _onCallEnded(
    CallEnded event,
    Emitter<InCallState> emit,
  ) async {
    // Derive callInfo from current state for reporting
    if (state is InCallActive) {
      final callInfo = (state as InCallActive).callInfo;
      await _reportEndedCall(callInfo, cause: event.cause);
    }
    emit(InCallEnded(cause: event.cause));
  }

  Future<void> _reportEndedCall(CallInfo callInfo, {String? cause}) async {
    if (_reportingService == null) return;
    final now = DateTime.now();
    final start = _ringingStartedAt ?? now;
    final activeStart = _callStartedAt ?? now;
    final ringing = activeStart.difference(start).inSeconds;
    final active = now.difference(activeStart).inSeconds;

    final status = (active > 0) ? 'completed'
        : (cause?.toLowerCase().contains('reject') == true) ? 'declined'
        : 'missed';

    await _reportingService?.reportCallEnd({
      'callId': callInfo.callId,
      'phoneNumber': callInfo.callerNumber,
      'direction': 'outbound',
      'status': status,
      'startedAt': start,
      'endedAt': now,
      'ringingDurationSeconds': ringing.clamp(0, 3600),
      'activeDurationSeconds': active.clamp(0, 86400),
      'simSlot': callInfo.simSlot,
    });

    // Reset timers
    _ringingStartedAt = null;
    _callStartedAt = null;
  }

  @override
  Future<void> close() {
    _callEventSubscription.cancel();
    return super.close();
  }
}
