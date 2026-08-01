import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../providers/category_controller.dart';
import '../providers/category_providers.dart';
import '../widgets/category_tile.dart';

class CategoriesListScreen extends ConsumerStatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  ConsumerState<CategoriesListScreen> createState() =>
      _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default-category seeding is triggered once at login by
    // HomeShellScreen, not here — see ensureDefaultCategoriesProvider.
    final showArchived = ref.watch(showArchivedCategoriesProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton(
            tooltip: showArchived
                ? l10n.hideArchivedTooltip
                : l10n.showArchivedTooltip,
            icon: Icon(
              AppSymbols.archive,
              color: showArchived
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () =>
                ref.read(showArchivedCategoriesProvider.notifier).toggle(),
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.categoryNew,
                  extra: _tabController.index == 0
                      ? CategoryType.expense
                      : CategoryType.income,
                ),
                icon: const Icon(AppSymbols.addRounded),
                label: Text(l10n.addCategoryButton),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.expenseLabel),
            Tab(text: l10n.incomeLabel),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryTypeList(type: CategoryType.expense),
          _CategoryTypeList(type: CategoryType.income),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final type = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          return FloatingActionButton(
            // See the same fix's comment in accounts_list_screen.dart --
            // every shell tab's FAB otherwise shares Flutter's implicit
            // default hero tag, since the shell keeps all branches mounted
            // simultaneously. The key gives integration tests an
            // unambiguous target too.
            key: const ValueKey('categories-fab'),
            heroTag: 'categories-fab',
            onPressed: () => context.push(AppRoutes.categoryNew, extra: type),
            child: const Icon(AppSymbols.addRounded),
          );
        },
      ),
    );
  }
}

class _CategoryTypeList extends ConsumerWidget {
  const _CategoryTypeList({required this.type});

  final CategoryType type;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteCategoryTitle,
      message: l10n.deleteCategoryMessage(category.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .deleteCategory(category.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(categoryControllerProvider.notifier).failure?.message ??
          l10n.deleteCategoryFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _toggleArchived(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(categoryControllerProvider.notifier);
    final success = category.isArchived
        ? await notifier.unarchiveCategory(category.id)
        : await notifier.archiveCategory(category.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          notifier.failure?.message ?? l10n.updateCategoryFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<CategoryEntity> categories,
    int oldIndex,
    int newIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reordered = [...categories];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .reorderCategories(reordered.map((c) => c.id).toList());

    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(categoryControllerProvider.notifier).failure?.message ??
          l10n.reorderCategoriesFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedCategoriesProvider);
    final categoriesAsync = ref.watch(
      categoriesProvider((type: type, includeArchived: showArchived)),
    );
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveCenter(
      child: categoriesAsync.when(
        loading: () => const AppSkeletonList(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState(
              icon: AppSymbols.category,
              title: type == CategoryType.expense
                  ? l10n.noExpenseCategoriesYetTitle
                  : l10n.noIncomeCategoriesYetTitle,
              message: l10n.addCategoryToStartMessage,
              action: FilledButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.categoryNew, extra: type),
                icon: const Icon(AppSymbols.addRounded),
                label: Text(l10n.addCategoryButton),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: categories.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorder(context, ref, categories, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryTile(
                key: ValueKey(category.id),
                category: category,
                reorderIndex: index,
                onTap: () => context.push(
                  AppRoutes.categoryEditPath(category.id),
                  extra: category,
                ),
                trailingMenu: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'archive':
                        _toggleArchived(context, ref, category);
                      case 'delete':
                        _confirmDelete(context, ref, category);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        category.isArchived
                            ? l10n.unarchiveMenuItem
                            : l10n.archiveMenuItem,
                      ),
                    ),
                    if (!category.isDefault)
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
