import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:cashly_lao/features/savings_goals/domain/usecases/create_savings_goal_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavingsGoalRepository extends Mock
    implements SavingsGoalRepository {}

void main() {
  late _MockSavingsGoalRepository repository;
  late CreateSavingsGoalUseCase useCase;

  setUp(() {
    repository = _MockSavingsGoalRepository();
    useCase = CreateSavingsGoalUseCase(repository);
  });

  final goal = SavingsGoalEntity(
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

  test('delegates to the repository and returns the created goal', () async {
    when(
      () => repository.createGoal(
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
        autoContributionAmount: null,
        autoContributionFrequency: null,
      ),
    ).thenAnswer((_) async => Right(goal));

    final result = await useCase(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    expect(result, Right<Failure, SavingsGoalEntity>(goal));
  });
}
