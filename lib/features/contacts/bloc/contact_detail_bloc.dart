import 'package:dailathon_dialer/core/channels/contacts_method_channel.dart';
import 'package:dailathon_dialer/core/models/contact_detail.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'contact_detail_event.dart';
part 'contact_detail_state.dart';

/// BLoC for loading detailed contact information.
class ContactDetailBloc extends Bloc<ContactDetailEvent, ContactDetailState> {

  ContactDetailBloc(this._contactsChannel) : super(const ContactDetailInitial()) {
    on<ContactDetailRequested>(_onContactDetailRequested);
  }
  // ignore: unused_field
  final ContactsMethodChannel _contactsChannel;

  Future<void> _onContactDetailRequested(
    ContactDetailRequested event,
    Emitter<ContactDetailState> emit,
  ) async {
    try {
      emit(const ContactDetailLoading());

      // TODO: Call _contactsChannel.getContactDetail(event.contactId)
      // final detail = await _contactsChannel.getContactDetail(event.contactId);
      
      emit(const ContactDetailLoading()); // Placeholder
    } catch (e) {
      emit(ContactDetailError(error: e.toString()));
    }
  }
}
