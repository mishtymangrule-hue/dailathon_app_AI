part of 'login_bloc.dart';

/// Events for LoginBloc
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}

class SessionRestored extends LoginEvent {
  const SessionRestored({required this.token});

  final String token;

  @override
  List<Object?> get props => [token];
}
