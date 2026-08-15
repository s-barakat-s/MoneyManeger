import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/business_access.dart';
import '../domain/business_member.dart';
import '../domain/business_role.dart';
import '../domain/permission.dart';
import '../domain/repositories/business_access_repository.dart';

final businessAccessRepositoryProvider = Provider<BusinessAccessRepository>((
  ref,
) {
  throw UnimplementedError('BusinessAccessRepository is not configured.');
});

final currentBusinessMemberProvider =
    StreamProvider.autoDispose<BusinessMember?>((ref) {
      final uid = ref.watch(authenticatedActorUidProvider);
      return ref.watch(businessAccessRepositoryProvider).watchMember(uid);
    });

final businessRoleProvider = StreamProvider.autoDispose
    .family<BusinessRole?, String>((ref, roleId) {
      return ref.watch(businessAccessRepositoryProvider).watchRole(roleId);
    });

final currentBusinessRoleProvider =
    Provider.autoDispose<AsyncValue<BusinessRole?>>((ref) {
      return ref.watch(currentBusinessMemberProvider).when(
        data: (member) {
          if (member == null || member.status != MembershipStatus.active) {
            return const AsyncData(null);
          }
          return ref.watch(businessRoleProvider(member.roleId));
        },
        error: (error, stackTrace) => AsyncError(error, stackTrace),
        loading: () => const AsyncLoading(),
      );
    });

final currentBusinessAccessProvider =
    Provider.autoDispose<AsyncValue<BusinessAccess>>((ref) {
      return ref.watch(currentBusinessRoleProvider).whenData((role) {
        return role == null
            ? BusinessAccess.denied
            : BusinessAccess(role.permissions);
      });
    });

final canProvider = Provider.autoDispose
    .family<AsyncValue<bool>, Permission>((ref, permission) {
      return ref
          .watch(currentBusinessAccessProvider)
          .whenData((access) => access.can(permission));
    });
