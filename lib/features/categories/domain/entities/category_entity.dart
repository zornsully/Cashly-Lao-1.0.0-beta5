import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import 'category_type.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final CategoryType type;
  final AppIconKey icon;
  final AppColorKey color;

  /// True for the categories Cashly seeds automatically on first login.
  /// Default categories can be archived but never deleted, so a user can
  /// never end up with zero categories to pick from.
  final bool isDefault;

  final bool isArchived;

  /// Position within its [type]'s list, lowest first. Updated in bulk when
  /// the user drags to reorder.
  final int sortOrder;

  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryEntity copyWith({
    String? name,
    CategoryType? type,
    AppIconKey? icon,
    AppColorKey? color,
    bool? isArchived,
    int? sortOrder,
  }) {
    return CategoryEntity(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    icon,
    color,
    isDefault,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}
