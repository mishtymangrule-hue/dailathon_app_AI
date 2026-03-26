part of 'contact_detail_bloc.dart';

abstract class ContactDetailState extends Equatable {
  const ContactDetailState();

  @override
  List<Object?> get props => [];
}

class ContactDetailInitial extends ContactDetailState {
  const ContactDetailInitial();
}

class ContactDetailLoading extends ContactDetailState {
  const ContactDetailLoading();
}

class ContactDetailLoaded extends ContactDetailState {

  const ContactDetailLoaded({required this.contact});
  final ContactDetail contact;

  @override
  List<Object?> get props => [contact];
}

class ContactDetailError extends ContactDetailState {

  const ContactDetailError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
