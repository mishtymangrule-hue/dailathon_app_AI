import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/repositories/call_forwarding_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// SettingsBloc manages call forwarding and other dialer settings.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(
    this._callForwardingRepository,
    this._callMethodChannel,
  ) : super(const SettingsInitial()) {
    on<CallForwardingRequested>(_onCallForwardingRequested);
    on<CallForwardingUpdated>(_onCallForwardingUpdated);
    on<EnableForwardingRequested>(_onEnableForwardingRequested);
    on<DisableForwardingRequested>(_onDisableForwardingRequested);
    on<SetDefaultDialerRequested>(_onSetDefaultDialerRequested);
  }

  // ignore: unused_field
  final CallForwardingRepository _callForwardingRepository;
  final CallMethodChannel _callMethodChannel;

  Future<void> _onCallForwardingRequested(
    CallForwardingRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      // TODO: Retrieve current forwarding settings from device (MMI query)
      emit(
        SettingsLoaded(
          unconditionalForwarding: event.currentForwarding?['unconditional'] ?? '',
          busyForwarding: event.currentForwarding?['busy'] ?? '',
          noAnswerForwarding: event.currentForwarding?['noAnswer'] ?? '',
          unreachableForwarding: event.currentForwarding?['unreachable'] ?? '',
        ),
      );
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> _onCallForwardingUpdated(
    CallForwardingUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // TODO: Call native CallForwardingManager to set forwarding
      // await _callForwardingRepository.setForwarding(
      //   reason: event.reason,
      //   number: event.number,
      //   enable: event.enable,
      // );
      emit(
        SettingsLoaded(
          unconditionalForwarding: event.reason == 'unconditional' ? event.number : '',
          busyForwarding: event.reason == 'busy' ? event.number : '',
          noAnswerForwarding: event.reason == 'noAnswer' ? event.number : '',
          unreachableForwarding: event.reason == 'unreachable' ? event.number : '',
        ),
      );
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> _onEnableForwardingRequested(
    EnableForwardingRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      // TODO: Call native CallForwardingManager to enable forwarding
      await _callMethodChannel.enableCallForwarding(
        forwardingType: event.forwardingType,
        forwardingNumber: event.forwardingNumber,
      );
      
      final currentState = state;
      if (currentState is SettingsLoaded) {
        final updatedState = _updateForwarding(
          currentState,
          event.forwardingType,
          event.forwardingNumber,
          true,
        );
        emit(updatedState);
        emit(const SettingsSuccess());
      }
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> _onDisableForwardingRequested(
    DisableForwardingRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      // TODO: Call native CallForwardingManager to disable forwarding
      await _callMethodChannel.disableCallForwarding(
        forwardingType: event.forwardingType,
      );
      
      final currentState = state;
      if (currentState is SettingsLoaded) {
        final updatedState = _updateForwarding(
          currentState,
          event.forwardingType,
          '',
          false,
        );
        emit(updatedState);
        emit(const SettingsSuccess());
      }
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> _onSetDefaultDialerRequested(
    SetDefaultDialerRequested event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      await _callMethodChannel.setDefaultDialer();
      
      // Re-check default dialer status after setting
      await Future.delayed(const Duration(seconds: 1));
      
      final isDefaultDialer = await _callMethodChannel.checkDefaultDialer();
      
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(SettingsLoaded(
          unconditionalForwarding: currentState.unconditionalForwarding,
          busyForwarding: currentState.busyForwarding,
          noAnswerForwarding: currentState.noAnswerForwarding,
          unreachableForwarding: currentState.unreachableForwarding,
          unconditionalEnabled: currentState.unconditionalEnabled,
          busyEnabled: currentState.busyEnabled,
          noAnswerEnabled: currentState.noAnswerEnabled,
          unreachableEnabled: currentState.unreachableEnabled,
          isDefaultDialer: isDefaultDialer,
        ));
        emit(const SettingsSuccess());
      }
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  SettingsLoaded _updateForwarding(
    SettingsLoaded currentState,
    String forwardingType,
    String forwardingNumber,
    bool enabled,
  ) {
    switch (forwardingType) {
      case 'unconditional':
        return SettingsLoaded(
          unconditionalForwarding: forwardingNumber,
          busyForwarding: currentState.busyForwarding,
          noAnswerForwarding: currentState.noAnswerForwarding,
          unreachableForwarding: currentState.unreachableForwarding,
          unconditionalEnabled: enabled,
          busyEnabled: currentState.busyEnabled,
          noAnswerEnabled: currentState.noAnswerEnabled,
          unreachableEnabled: currentState.unreachableEnabled,
        );
      case 'busy':
        return SettingsLoaded(
          unconditionalForwarding: currentState.unconditionalForwarding,
          busyForwarding: forwardingNumber,
          noAnswerForwarding: currentState.noAnswerForwarding,
          unreachableForwarding: currentState.unreachableForwarding,
          unconditionalEnabled: currentState.unconditionalEnabled,
          busyEnabled: enabled,
          noAnswerEnabled: currentState.noAnswerEnabled,
          unreachableEnabled: currentState.unreachableEnabled,
        );
      case 'noAnswer':
        return SettingsLoaded(
          unconditionalForwarding: currentState.unconditionalForwarding,
          busyForwarding: currentState.busyForwarding,
          noAnswerForwarding: forwardingNumber,
          unreachableForwarding: currentState.unreachableForwarding,
          unconditionalEnabled: currentState.unconditionalEnabled,
          busyEnabled: currentState.busyEnabled,
          noAnswerEnabled: enabled,
          unreachableEnabled: currentState.unreachableEnabled,
        );
      case 'unreachable':
        return SettingsLoaded(
          unconditionalForwarding: currentState.unconditionalForwarding,
          busyForwarding: currentState.busyForwarding,
          noAnswerForwarding: currentState.noAnswerForwarding,
          unreachableForwarding: forwardingNumber,
          unconditionalEnabled: currentState.unconditionalEnabled,
          busyEnabled: currentState.busyEnabled,
          noAnswerEnabled: currentState.noAnswerEnabled,
          unreachableEnabled: enabled,
        );
      default:
        return currentState;
    }
  }
}
