import 'business_role.dart';
import 'permission.dart';

abstract final class SystemBusinessRoles {
  static const ownerId = 'owner';
  static const adminId = 'admin';
  static const accountantId = 'accountant';
  static const viewerId = 'viewer';

  static final owner = BusinessRole(
    id: ownerId,
    name: 'Owner',
    permissions: Permission.values.toSet(),
    isSystem: true,
  );

  static final admin = BusinessRole(
    id: adminId,
    name: 'Admin',
    permissions: {
      Permission.membersRead,
      Permission.membersManage,
      Permission.rolesRead,
      Permission.ownersRead,
      Permission.ownersCreate,
      Permission.ownersUpdate,
      Permission.ownersArchive,
      Permission.transactionsRead,
      Permission.transactionsCreate,
      Permission.transactionsUpdate,
      Permission.transactionsArchive,
      Permission.transfersRead,
      Permission.transfersCreate,
      Permission.transfersCorrect,
      Permission.transfersArchive,
      Permission.debtsRead,
      Permission.debtsCreate,
      Permission.debtsUpdate,
      Permission.debtsArchive,
      Permission.receivablesRead,
      Permission.receivablesCreate,
      Permission.receivablesUpdate,
      Permission.receivablesArchive,
      Permission.assetsRead,
      Permission.assetsCreate,
      Permission.assetsUpdate,
      Permission.assetsArchive,
      Permission.reportsRead,
      Permission.activityRead,
      Permission.businessSettings,
    },
    isSystem: true,
  );

  static final accountant = BusinessRole(
    id: accountantId,
    name: 'Accountant',
    permissions: {
      Permission.ownersRead,
      Permission.transactionsRead,
      Permission.transactionsCreate,
      Permission.transactionsUpdate,
      Permission.transfersRead,
      Permission.transfersCreate,
      Permission.debtsRead,
      Permission.debtsCreate,
      Permission.debtsUpdate,
      Permission.receivablesRead,
      Permission.receivablesCreate,
      Permission.receivablesUpdate,
      Permission.assetsRead,
      Permission.reportsRead,
      Permission.activityRead,
    },
    isSystem: true,
  );

  static final viewer = BusinessRole(
    id: viewerId,
    name: 'Viewer',
    permissions: {
      Permission.membersRead,
      Permission.ownersRead,
      Permission.transactionsRead,
      Permission.transfersRead,
      Permission.debtsRead,
      Permission.receivablesRead,
      Permission.assetsRead,
      Permission.reportsRead,
    },
    isSystem: true,
  );

  static List<BusinessRole> get values => [owner, admin, accountant, viewer];
}
