import 'package:equatable/equatable.dart';

class ContactDetail extends Equatable {

  const ContactDetail({
    required this.contactId,
    required this.displayName,
    required this.phoneNumbers, this.photoUri,
    this.organization,
  });
  final String contactId;
  final String displayName;
  final String? photoUri;
  final String? organization;
  final List<PhoneEntry> phoneNumbers;

  @override
  List<Object?> get props => [
    contactId,
    displayName,
    photoUri,
    organization,
    phoneNumbers,
  ];
}

class PhoneEntry extends Equatable {

  const PhoneEntry({
    required this.number,
    required this.type,
    this.isPrimary = false,
  });
  final String number;
  final String type;  // "Mobile", "Work", "Home", "Other"
  final bool isPrimary;

  @override
  List<Object?> get props => [number, type, isPrimary];
}
