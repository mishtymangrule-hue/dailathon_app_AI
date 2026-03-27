import 'package:equatable/equatable.dart';

class SimInfo extends Equatable {
  const SimInfo({
    required this.subscriptionId,
    required this.slotIndex,
    required this.displayName,
    this.iccId,
    this.isDefault = false,
  });

  factory SimInfo.fromMap(Map<String, dynamic> map) => SimInfo(
      subscriptionId: map['subscriptionId'] ?? 0,
      slotIndex: map['slotIndex'] ?? 0,
      displayName: map['displayName'] ?? 'SIM',
      iccId: map['iccId'],
      isDefault: map['isDefault'] ?? false,
    );

  final int subscriptionId;
  final int slotIndex;
  final String displayName;
  final String? iccId;
  final bool isDefault;

  @override
  List<Object?> get props => [subscriptionId, slotIndex, displayName, iccId, isDefault];
}
