import 'package:dailathon_dialer/core/models/contact.dart';
import 'package:dailathon_dialer/core/repositories/contacts_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'contacts_event.dart';
part 'contacts_state.dart';

/// ContactsBloc manages contact list, search, and T9 matching.
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(this._contactsRepository) : super(const ContactsLoading()) {
    on<ContactsRequested>(_onContactsRequested);
    on<ContactSearched>(_onContactSearched);
    on<ContactsFavoritesToggled>(_onContactsFavoritesToggled);
  }

  final ContactsRepository _contactsRepository;

  Future<void> _onContactsRequested(
    ContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      emit(const ContactsLoading());
      final contacts = await _contactsRepository.getAllContacts();
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
        final contacts = await _contactsRepository.getAllContacts();
        emit(ContactsLoaded(contacts: contacts));
      } else {
        // Perform T9/fuzzy search
        final results = await _contactsRepository.searchByQuery(event.query);
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
