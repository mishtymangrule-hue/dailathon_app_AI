part of 'contacts_bloc.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class ContactsRequested extends ContactsEvent {
  const ContactsRequested();
}

class ContactSearched extends ContactsEvent {
  const ContactSearched(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ContactsFavoritesToggled extends ContactsEvent {
  const ContactsFavoritesToggled({required this.contactId, required this.isFavorite});
  final String contactId;
  final bool isFavorite;

  @override
  List<Object?> get props => [contactId, isFavorite];
}
