import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

/// HomeBloc manages home screen state including default dialer status.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._callMethodChannel) : super(const HomeInitial()) {
    on<CheckDefaultDialerRequested>(_onCheckDefaultDialerRequested);
  }

  final CallMethodChannel _callMethodChannel;

  Future<void> _onCheckDefaultDialerRequested(
    CheckDefaultDialerRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(const HomeLoading());
      final isDefaultDialer = await _callMethodChannel.checkDefaultDialer();
      emit(HomeLoaded(isDefaultDialer: isDefaultDialer));
    } catch (e) {
      emit(HomeError(error: e.toString()));
    }
  }
}
