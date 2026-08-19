import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/business/application/business_providers.dart';

const administrativeContextChangedMessage =
    'The active Account or Business changed. Close this action and start again.';

class AccountMutationScope {
  AccountMutationScope.capture(WidgetRef ref) : uid = ref.read(currentUidProvider);

  final String? uid;

  bool isCurrent(WidgetRef ref) =>
      uid != null && ref.read(currentUidProvider) == uid;
}

class BusinessAdminMutationScope {
  BusinessAdminMutationScope.capture(WidgetRef ref)
    : uid = ref.read(currentUidProvider),
      businessId = ref.read(activeBusinessIdProvider);

  final String? uid;
  final String businessId;

  bool isCurrent(WidgetRef ref) {
    if (uid == null || ref.read(currentUidProvider) != uid) return false;
    try {
      return ref.read(activeBusinessIdProvider) == businessId;
    } on MissingActiveBusinessException {
      return false;
    }
  }
}
