part of 'login_bloc.dart';

/// States for LoginBloc
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess({required this.token, this.username});

  final String token;
  final String? username;

  @override
  List<Object?> get props => [token, username];
}

class LoginFailure extends LoginState {
  const LoginFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
