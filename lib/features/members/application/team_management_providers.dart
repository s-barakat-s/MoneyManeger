import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../business/application/business_providers.dart';
import '../data/callable_invitation_repository.dart';
import '../data/callable_member_management_repository.dart';
import '../domain/assignable_role.dart';
import '../domain/business_invitation.dart';
import '../domain/member_summary.dart';
import '../domain/repositories/invitation_repository.dart';
import '../domain/repositories/member_management_repository.dart';

final memberManagementRepositoryProvider = Provider<MemberManagementRepository>(
  (ref) => CallableMemberManagementRepository(
    functions: ref.watch(firebaseFunctionsProvider),
  ),
);

final invitationRepositoryProvider = Provider<InvitationRepository>(
  (ref) => CallableInvitationRepository(
    functions: ref.watch(firebaseFunctionsProvider),
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

  Future<bool> changeRole(String targetUid, String roleId) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .changeRole(
            businessId: ref.read(activeBusinessIdProvider),
            targetUid: targetUid,
            roleId: roleId,
          ),
    );
  }

  Future<bool> suspend(String targetUid) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .suspend(
            businessId: ref.read(activeBusinessIdProvider),
            targetUid: targetUid,
          ),
    );
  }

  Future<bool> reactivate(String targetUid) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .reactivate(
            businessId: ref.read(activeBusinessIdProvider),
            targetUid: targetUid,
          ),
    );
  }

  Future<bool> remove(String targetUid) {
    return _run(
      () => ref
          .read(memberManagementRepositoryProvider)
          .remove(
            businessId: ref.read(activeBusinessIdProvider),
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

  Future<bool> create({required String email, required String roleId}) {
    return _run(
      () => ref
          .read(invitationRepositoryProvider)
          .create(
            businessId: ref.read(activeBusinessIdProvider),
            email: email,
            roleId: roleId,
          ),
      invalidateBusinessInvitations: true,
    );
  }

  Future<bool> revoke(String invitationId) {
    return _run(
      () => ref
          .read(invitationRepositoryProvider)
          .revoke(
            businessId: ref.read(activeBusinessIdProvider),
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
