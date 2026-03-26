part of 'contact_detail_bloc.dart';

abstract class ContactDetailEvent extends Equatable {
  const ContactDetailEvent();

  @override
  List<Object?> get props => [];
}

class ContactDetailRequested extends ContactDetailEvent {

  const ContactDetailRequested({required this.contactId});
  final String contactId;

  @override
  List<Object?> get props => [contactId];
}
