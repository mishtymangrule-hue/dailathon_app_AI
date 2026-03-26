import 'package:equatable/equatable.dart';

class DegreeOption extends Equatable {
  const DegreeOption({required this.id, required this.name});

  factory DegreeOption.fromJson(Map<String, dynamic> json) => DegreeOption(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class ProgramOption extends Equatable {
  const ProgramOption({required this.id, required this.name, required this.degreeId});

  factory ProgramOption.fromJson(Map<String, dynamic> json) => ProgramOption(
        id: json['id'] as String,
        name: json['name'] as String,
        degreeId: json['degreeId'] as String? ?? '',
      );

  final String id;
  final String name;
  final String degreeId;

  @override
  List<Object?> get props => [id, name, degreeId];
}

class ResponseOption extends Equatable {
  const ResponseOption({required this.id, required this.label});

  factory ResponseOption.fromJson(Map<String, dynamic> json) => ResponseOption(
        id: json['id'] as String,
        label: json['label'] as String? ?? json['name'] as String? ?? '',
      );

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

class SubResponseOption extends Equatable {
  const SubResponseOption(
      {required this.id, required this.label, required this.parentId});

  factory SubResponseOption.fromJson(Map<String, dynamic> json) =>
      SubResponseOption(
        id: json['id'] as String,
        label: json['label'] as String? ?? json['name'] as String? ?? '',
        parentId: json['responseId'] as String? ?? '',
      );

  final String id;
  final String label;
  final String parentId;

  @override
  List<Object?> get props => [id, label, parentId];
}
