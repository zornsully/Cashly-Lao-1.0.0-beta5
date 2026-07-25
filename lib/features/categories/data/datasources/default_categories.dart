import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../domain/entities/category_type.dart';

/// One entry of the curated starter category set seeded the first time a
/// user reaches Categories. `sortOrder` is implicit — each list's index is
/// its default position within its [type].
class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String name;
  final CategoryType type;
  final AppIconKey icon;
  final AppColorKey color;
}

const List<DefaultCategorySeed> defaultCategorySeeds = [
  DefaultCategorySeed(
    name: 'Salary',
    type: CategoryType.income,
    icon: AppIconKey.work,
    color: AppColorKey.green,
  ),
  DefaultCategorySeed(
    name: 'Business',
    type: CategoryType.income,
    icon: AppIconKey.business,
    color: AppColorKey.teal,
  ),
  DefaultCategorySeed(
    name: 'Gifts',
    type: CategoryType.income,
    icon: AppIconKey.gift,
    color: AppColorKey.pink,
  ),
  DefaultCategorySeed(
    name: 'Investments',
    type: CategoryType.income,
    icon: AppIconKey.investment,
    color: AppColorKey.indigo,
  ),
  DefaultCategorySeed(
    name: 'Other Income',
    type: CategoryType.income,
    icon: AppIconKey.other,
    color: AppColorKey.blueGrey,
  ),
  DefaultCategorySeed(
    name: 'Food & Dining',
    type: CategoryType.expense,
    icon: AppIconKey.food,
    color: AppColorKey.orange,
  ),
  DefaultCategorySeed(
    name: 'Groceries',
    type: CategoryType.expense,
    icon: AppIconKey.groceries,
    color: AppColorKey.amber,
  ),
  DefaultCategorySeed(
    name: 'Transportation',
    type: CategoryType.expense,
    icon: AppIconKey.transport,
    color: AppColorKey.blue,
  ),
  DefaultCategorySeed(
    name: 'Housing',
    type: CategoryType.expense,
    icon: AppIconKey.home,
    color: AppColorKey.brown,
  ),
  DefaultCategorySeed(
    name: 'Utilities',
    type: CategoryType.expense,
    icon: AppIconKey.bills,
    color: AppColorKey.cyan,
  ),
  DefaultCategorySeed(
    name: 'Shopping',
    type: CategoryType.expense,
    icon: AppIconKey.shopping,
    color: AppColorKey.purple,
  ),
  DefaultCategorySeed(
    name: 'Entertainment',
    type: CategoryType.expense,
    icon: AppIconKey.entertainment,
    color: AppColorKey.red,
  ),
  DefaultCategorySeed(
    name: 'Health',
    type: CategoryType.expense,
    icon: AppIconKey.health,
    color: AppColorKey.emerald,
  ),
  DefaultCategorySeed(
    name: 'Education',
    type: CategoryType.expense,
    icon: AppIconKey.education,
    color: AppColorKey.grey,
  ),
  DefaultCategorySeed(
    name: 'Other Expense',
    type: CategoryType.expense,
    icon: AppIconKey.other,
    color: AppColorKey.blueGrey,
  ),
];
