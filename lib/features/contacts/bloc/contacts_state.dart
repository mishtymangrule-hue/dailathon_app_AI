part of 'contacts_bloc.dart';

abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  const ContactsLoaded({required this.contacts});
  final List<Contact> contacts;

  @override
  List<Object?> get props => [contacts];
}

class ContactsError extends ContactsState {
  const ContactsError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
