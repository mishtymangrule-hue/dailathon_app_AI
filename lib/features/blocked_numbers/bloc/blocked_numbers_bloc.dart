import 'package:dailathon_dialer/core/repositories/blocked_numbers_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'blocked_numbers_event.dart';
part 'blocked_numbers_state.dart';

/// BlockedNumbersBloc manages phone number blocking.
class BlockedNumbersBloc extends Bloc<BlockedNumbersEvent, BlockedNumbersState> {
  BlockedNumbersBloc(this._blockedNumbersRepository)
      : super(const BlockedNumbersLoading()) {
    on<BlockedNumbersRequested>(_onBlockedNumbersRequested);
    on<NumberBlocked>(_onNumberBlocked);
    on<NumberUnblocked>(_onNumberUnblocked);
  }

  final BlockedNumbersRepository _blockedNumbersRepository;

  Future<void> _onBlockedNumbersRequested(
    BlockedNumbersRequested event,
    Emitter<BlockedNumbersState> emit,
  ) async {
    try {
      emit(const BlockedNumbersLoading());
      final blockedNumbers = await _blockedNumbersRepository.getBlockedNumbers();
      emit(BlockedNumbersLoaded(blockedNumbers: blockedNumbers));
    } catch (e) {
      emit(BlockedNumbersError(error: e.toString()));
    }
  }

  Future<void> _onNumberBlocked(
    NumberBlocked event,
    Emitter<BlockedNumbersState> emit,
  ) async {
    try {
      await _blockedNumbersRepository.blockNumber(event.phoneNumber);
      // Refresh blocked list
      final blockedNumbers = await _blockedNumbersRepository.getBlockedNumbers();
      emit(BlockedNumbersLoaded(blockedNumbers: blockedNumbers));
    } catch (e) {
      emit(BlockedNumbersError(error: e.toString()));
    }
  }

  Future<void> _onNumberUnblocked(
    NumberUnblocked event,
    Emitter<BlockedNumbersState> emit,
  ) async {
    try {
      await _blockedNumbersRepository.unblockNumber(event.phoneNumber);
      // Refresh blocked list
      final blockedNumbers = await _blockedNumbersRepository.getBlockedNumbers();
      emit(BlockedNumbersLoaded(blockedNumbers: blockedNumbers));
    } catch (e) {
      emit(BlockedNumbersError(error: e.toString()));
    }
  }
}
