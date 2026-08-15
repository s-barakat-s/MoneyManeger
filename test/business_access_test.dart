import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/business/domain/business_access.dart';
import 'package:money_manager/features/business/domain/permission.dart';
import 'package:money_manager/features/business/domain/system_business_roles.dart';

void main() {
  test('permission values have stable round-trip serialization', () {
    for (final permission in Permission.values) {
      expect(Permission.tryParse(permission.persistedValue), permission);
    }
    expect(Permission.tryParse('future.permission'), isNull);
  });

  test('owner receives the complete permission catalog', () {
    expect(SystemBusinessRoles.owner.permissions, Permission.values.toSet());
  });

  test('admin cannot manage role definitions', () {
    final access = BusinessAccess(SystemBusinessRoles.admin.permissions);
    expect(access.can(Permission.membersManage), isTrue);
    expect(access.can(Permission.rolesRead), isTrue);
    expect(access.can(Permission.rolesManage), isFalse);
    expect(access.can(Permission.activityRead), isTrue);
  });

  test('accountant has conservative finance permissions', () {
    final access = BusinessAccess(SystemBusinessRoles.accountant.permissions);
    expect(access.can(Permission.ownersRead), isTrue);
    expect(access.can(Permission.ownersCreate), isFalse);
    expect(access.can(Permission.transactionsCreate), isTrue);
    expect(access.can(Permission.transactionsArchive), isFalse);
    expect(access.can(Permission.transfersArchive), isFalse);
    expect(access.can(Permission.businessSettings), isFalse);
    expect(access.can(Permission.activityRead), isTrue);
  });

  test('viewer permissions are read-only', () {
    final access = BusinessAccess(SystemBusinessRoles.viewer.permissions);
    expect(access.can(Permission.ownersRead), isTrue);
    expect(access.can(Permission.ownersUpdate), isFalse);
    expect(access.can(Permission.reportsRead), isTrue);
    expect(access.can(Permission.transactionsCreate), isFalse);
    expect(access.can(Permission.membersManage), isFalse);
    expect(access.can(Permission.activityRead), isFalse);
  });
}
