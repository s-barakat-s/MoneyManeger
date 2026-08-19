import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/authenticated_backend_client.dart';
import '../../../core/data/data_scope.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/http_business_workspace_repository.dart';
import '../domain/business_workspace.dart';
import '../domain/repositories/business_workspace_repository.dart';

final businessWorkspaceRepositoryProvider =
    Provider<BusinessWorkspaceRepository>(
      (ref) => HttpBusinessWorkspaceRepository(
        backend: ref.watch(authenticatedBackendClientProvider),
      ),
    );

final workspaceResolutionProvider = FutureProvider<WorkspaceResolution>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) throw StateError('Authentication is required.');
  return ref
      .watch(businessWorkspaceRepositoryProvider)
      .resolve()
      .timeout(const Duration(seconds: 15));
});

final activeBusinessIdProvider = Provider<String>((ref) {
  final resolution = ref.watch(workspaceResolutionProvider);
  if (resolution case AsyncData(:final value)) {
    final businessId = value.selectedBusinessId;
    if (businessId != null) return businessId;
  }
  throw const MissingActiveBusinessException();
});

final currentWorkspaceProvider = Provider<BusinessWorkspace?>((ref) {
  return ref.watch(workspaceResolutionProvider).value?.selectedWorkspace;
});

final isBusinessOwnerProvider = Provider<bool>((ref) {
  return ref.watch(currentWorkspaceProvider)?.isOwner == true;
});

final workspaceMutationControllerProvider =
    NotifierProvider<WorkspaceMutationController, AsyncValue<void>>(
      WorkspaceMutationController.new,
    );

class WorkspaceMutationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> create(String name) => _run(
    () => ref.read(businessWorkspaceRepositoryProvider).create(name: name),
  );

  Future<bool> select(String businessId) => _run(
    () => ref
        .read(businessWorkspaceRepositoryProvider)
        .select(businessId: businessId),
  );

  Future<bool> _run(Future<String> Function() operation) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await operation();
      ref.invalidate(workspaceResolutionProvider);
      await ref.read(workspaceResolutionProvider.future);
    });
    return !state.hasError;
  }
}

final currentDataScopeProvider = Provider<DataScope>((ref) {
  return BusinessDataScope(
    firestore: ref.watch(firebaseFirestoreProvider),
    businessId: ref.watch(activeBusinessIdProvider),
  );
});

class MissingActiveBusinessException implements Exception {
  const MissingActiveBusinessException();
}
