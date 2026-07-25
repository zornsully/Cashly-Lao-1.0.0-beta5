import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.balance,
    required super.currencyCode,
    required super.icon,
    required super.color,
    required super.isArchived,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AccountModel(
      id: doc.id,
      name: data['name'] as String,
      type: AccountType.values.byName(data['type'] as String),
      balance: (data['balance'] as num).toDouble(),
      currencyCode: data['currencyCode'] as String,
      icon: AppIconKey.values.byName(data['icon'] as String),
      color: AppColorKey.values.byName(data['color'] as String),
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toFirestoreUpdate() {
    return {
      'name': name,
      'type': type.name,
      'balance': balance,
      'currencyCode': currencyCode,
      'icon': icon.name,
      'color': color.name,
      'isArchived': isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
