import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/savings_goals/data/datasources/savings_goal_remote_datasource.dart';
import 'package:cashly_lao/features/savings_goals/data/models/savings_goal_model.dart';
import 'package:cashly_lao/features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavingsGoalRemoteDataSource extends Mock
    implements SavingsGoalRemoteDataSource {}

void main() {
  late _MockSavingsGoalRemoteDataSource dataSource;
  late SavingsGoalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AppIconKey.savings);
    registerFallbackValue(AppColorKey.emerald);
  });

  setUp(() {
    dataSource = _MockSavingsGoalRemoteDataSource();
    repository = SavingsGoalRepositoryImpl(dataSource);
  });

  final goal = SavingsGoalModel(
    id: 'goal-1',
    name: 'Vacation',
    targetAmount: 5000000,
    accountId: 'acc-1',
    icon: AppIconKey.savings,
    color: AppColorKey.emerald,
    isArchived: false,
    lastContributionAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('createGoal returns Right(goal) on success', () async {
    when(
      () => dataSource.createGoal(
        name: any(named: 'name'),
        targetAmount: any(named: 'targetAmount'),
        accountId: any(named: 'accountId'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
        autoContributionAmount: any(named: 'autoContributionAmount'),
        autoContributionFrequency: any(named: 'autoContributionFrequency'),
      ),
    ).thenAnswer((_) async => goal);

    final result = await repository.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    expect(result, Right(goal));
  });

  test('createGoal maps ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.createGoal(
        name: any(named: 'name'),
        targetAmount: any(named: 'targetAmount'),
        accountId: any(named: 'accountId'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
        autoContributionAmount: any(named: 'autoContributionAmount'),
        autoContributionFrequency: any(named: 'autoContributionFrequency'),
      ),
    ).thenThrow(
      const ServerException(
        'This account already backs another active savings goal.',
      ),
    );

    final result = await repository.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    expect(
      result,
      const Left<Failure, dynamic>(
        ServerFailure(
          'This account already backs another active savings goal.',
        ),
      ),
    );
  });

  test('deleteGoal returns Right(unit) on success', () async {
    when(() => dataSource.deleteGoal('goal-1')).thenAnswer((_) async {});

    final result = await repository.deleteGoal('goal-1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('watchGoals filters archived goals unless includeArchived is true', () {
    final archivedGoal = SavingsGoalModel(
      id: 'goal-2',
      name: 'Old Goal',
      targetAmount: 1000000,
      accountId: 'acc-2',
      icon: AppIconKey.savings,
      color: AppColorKey.grey,
      isArchived: true,
      lastContributionAt: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(
      () => dataSource.watchGoals(),
    ).thenAnswer((_) => Stream.value([goal, archivedGoal]));

    expect(
      repository.watchGoals(),
      emits(predicate<List<dynamic>>((goals) => goals.length == 1)),
    );
    expect(
      repository.watchGoals(includeArchived: true),
      emits(predicate<List<dynamic>>((goals) => goals.length == 2)),
    );
  });
}
