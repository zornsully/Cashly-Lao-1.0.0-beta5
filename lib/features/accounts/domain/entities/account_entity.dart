import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import 'account_type.dart';

class AccountEntity extends Equatable {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currencyCode,
    required this.icon,
    required this.color,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currencyCode;
  final AppIconKey icon;
  final AppColorKey color;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountEntity copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? currencyCode,
    AppIconKey? icon,
    AppColorKey? color,
    bool? isArchived,
  }) {
    return AccountEntity(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currencyCode,
    icon,
    color,
    isArchived,
    createdAt,
    updatedAt,
  ];
}
