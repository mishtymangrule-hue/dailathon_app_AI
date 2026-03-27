import 'package:dailathon_dialer/core/channels/contacts_method_channel.dart';
import 'package:dailathon_dialer/core/models/contact.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'contacts_event.dart';
part 'contacts_state.dart';

/// ContactsBloc manages contact list, search, and T9 matching.
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(this._contactsMethodChannel) : super(const ContactsLoading()) {
    on<ContactsRequested>(_onContactsRequested);
    on<ContactSearched>(_onContactSearched);
    on<ContactsFavoritesToggled>(_onContactsFavoritesToggled);
  }

  final ContactsMethodChannel _contactsMethodChannel;

  Future<void> _onContactsRequested(
    ContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      emit(const ContactsLoading());
      final contacts = await _contactsMethodChannel.getContacts();
      emit(ContactsLoaded(contacts: contacts));
    } catch (e) {
      emit(ContactsError(error: e.toString()));
    }
  }

  Future<void> _onContactSearched(
    ContactSearched event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      if (event.query.isEmpty) {
        // Reset to full list
        final contacts = await _contactsMethodChannel.getContacts();
        emit(ContactsLoaded(contacts: contacts));
      } else {
        // Perform search
        final results = await _contactsMethodChannel.searchContacts(event.query);
        emit(ContactsLoaded(contacts: results));
      }
    } catch (e) {
      emit(ContactsError(error: e.toString()));
    }
  }

  Future<void> _onContactsFavoritesToggled(
    ContactsFavoritesToggled event,
    Emitter<ContactsState> emit,
  ) async {
    // TODO: Implement favorites persistence (SharedPreferences)
    // Update local state and persist to SharedPreferences
  }
}
