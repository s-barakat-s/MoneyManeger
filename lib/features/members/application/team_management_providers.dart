import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/authenticated_backend_client.dart';
import '../../business/application/business_providers.dart';
import '../data/http_invitation_repository.dart';
import '../data/http_member_management_repository.dart';
import '../domain/assignable_role.dart';
import '../domain/business_invitation.dart';
import '../domain/member_summary.dart';
import '../domain/repositories/invitation_repository.dart';
import '../domain/repositories/member_management_repository.dart';

final memberManagementRepositoryProvider = Provider<MemberManagementRepository>(
  (ref) => HttpMemberManagementRepository(
    backend: ref.watch(authenticatedBackendClientProvider),
  ),
);

final invitationRepositoryProvider = Provider<InvitationRepository>(
  (ref) => HttpInvitationRepository(
    backend: ref.watch(authenticatedBackendClientProvider),
  ),
);

final businessMembersProvider = FutureProvider.autoDispose<List<MemberSummary>>(
  (ref) {
    return ref
        .watch(memberManagementRepositoryProvider)
        .listMembers(ref.watch(activeBusinessIdProvider));
  },
);

final assignableRolesProvider =
    FutureProvider.autoDispose<List<AssignableRole>>((ref) {
      return ref
          .watch(memberManagementRepositoryProvider)
          .listAssignableRoles(ref.watch(activeBusinessIdProvider));
    });

final businessInvitationsProvider =
    FutureProvider.autoDispose<List<BusinessInvitation>>((ref) {
      return ref
          .watch(invitationRepositoryProvider)
          .listBusinessInvitations(ref.watch(activeBusinessIdProvider));
    });

final myInvitationOffersProvider =
    FutureProvider.autoDispose<List<InvitationOffer>>((ref) {
      return ref.watch(invitationRepositoryProvider).discoverMine();
    });

final memberMutationControllerProvider =
    NotifierProvider<MemberMutationController, AsyncValue<void>>(
      MemberMutationController.new,
    );

class MemberMutationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> changeRole({
    required String businessId,
    required String targetUid,
    required String roleId,
  }) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .changeRole(
            businessId: businessId,
            targetUid: targetUid,
            roleId: roleId,
          ),
    );
  }

  Future<bool> suspend({required String businessId, required String targetUid}) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .suspend(
            businessId: businessId,
            targetUid: targetUid,
          ),
    );
  }

  Future<bool> reactivate({
    required String businessId,
    required String targetUid,
  }) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .reactivate(
            businessId: businessId,
            targetUid: targetUid,
          ),
    );
  }

  Future<bool> remove({required String businessId, required String targetUid}) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .remove(
            businessId: businessId,
            targetUid: targetUid,
          ),
    );
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(operation);
    if (!state.hasError) ref.invalidate(businessMembersProvider);
    return !state.hasError;
  }
}

final invitationMutationControllerProvider =
    NotifierProvider<InvitationMutationController, AsyncValue<void>>(
      InvitationMutationController.new,
    );

class InvitationMutationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> create({
    required String businessId,
    required String email,
    required String roleId,
  }) {
    return _run(
      () => ref
          .read(invitationRepositoryProvider)
          .create(
            businessId: businessId,
            email: email,
            roleId: roleId,
          ),
      invalidateBusinessInvitations: true,
    );
  }

  Future<bool> revoke({
    required String businessId,
    required String invitationId,
  }) {
    return _run(
      () => ref
          .read(invitationRepositoryProvider)
          .revoke(
            businessId: businessId,
            invitationId: invitationId,
          ),
      invalidateBusinessInvitations: true,
    );
  }

  Future<bool> accept(InvitationOffer offer) async {
    final accepted = await _run(
      () => ref
          .read(invitationRepositoryProvider)
          .accept(businessId: offer.businessId, invitationId: offer.id),
      invalidateMyInvitations: true,
    );
    if (accepted) {
      ref.invalidate(workspaceResolutionProvider);
      await ref.read(workspaceResolutionProvider.future);
      ref.invalidate(businessMembersProvider);
    }
    return accepted;
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    bool invalidateBusinessInvitations = false,
    bool invalidateMyInvitations = false,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(operation);
    if (!state.hasError) {
      if (invalidateBusinessInvitations) {
        ref.invalidate(businessInvitationsProvider);
      }
      if (invalidateMyInvitations) ref.invalidate(myInvitationOffersProvider);
    }
    return !state.hasError;
  }
}
