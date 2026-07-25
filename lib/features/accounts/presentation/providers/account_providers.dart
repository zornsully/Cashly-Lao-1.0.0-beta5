import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/archive_account_usecase.dart';
import '../../domain/usecases/create_account_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/unarchive_account_usecase.dart';
import '../../domain/usecases/update_account_usecase.dart';

final accountRemoteDataSourceProvider = Provider<AccountRemoteDataSource>((
  ref,
) {
  return FirestoreAccountRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(accountRemoteDataSourceProvider));
});

/// The list of accounts for the signed-in user, live-updating from
/// Firestore. `includeArchived: true` is used by the "show archived"
/// toggle on the accounts list.
final accountsProvider = StreamProvider.family<List<AccountEntity>, bool>((
  ref,
  includeArchived,
) {
  return ref
      .watch(accountRepositoryProvider)
      .watchAccounts(includeArchived: includeArchived);
});

/// Whether the accounts list is currently showing archived accounts too.
/// Lives per-screen (autoDispose) so it always resets to "hidden" when the
/// user leaves and comes back to the accounts tab.
class ShowArchivedAccounts extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final showArchivedAccountsProvider =
    NotifierProvider.autoDispose<ShowArchivedAccounts, bool>(
      ShowArchivedAccounts.new,
    );

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  return CreateAccountUseCase(ref.watch(accountRepositoryProvider));
});

final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>((ref) {
  return UpdateAccountUseCase(ref.watch(accountRepositoryProvider));
});

final archiveAccountUseCaseProvider = Provider<ArchiveAccountUseCase>((ref) {
  return ArchiveAccountUseCase(ref.watch(accountRepositoryProvider));
});

final unarchiveAccountUseCaseProvider = Provider<UnarchiveAccountUseCase>((
  ref,
) {
  return UnarchiveAccountUseCase(ref.watch(accountRepositoryProvider));
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(accountRepositoryProvider));
});
