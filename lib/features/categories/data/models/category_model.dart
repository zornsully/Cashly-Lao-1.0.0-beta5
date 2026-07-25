import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    required super.icon,
    required super.color,
    required super.isDefault,
    required super.isArchived,
    required super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String,
      type: CategoryType.values.byName(data['type'] as String),
      icon: AppIconKey.values.byName(data['icon'] as String),
      color: AppColorKey.values.byName(data['color'] as String),
      isDefault: data['isDefault'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toFirestoreUpdate() {
    return {
      'name': name,
      'type': type.name,
      'icon': icon.name,
      'color': color.name,
      'isDefault': isDefault,
      'isArchived': isArchived,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
