import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/business/domain/business_member.dart';
import 'package:money_manager/features/business/domain/business_workspace.dart';

void main() {
  test('workspace resolution may require an explicit selection', () {
    const resolution = WorkspaceResolution(
      workspaces: [
        BusinessWorkspace(
          businessId: 'business-a',
          businessName: 'Business A',
          roleId: 'owner',
          roleName: 'Owner',
          isOwner: true,
        ),
        BusinessWorkspace(
          businessId: 'business-b',
          businessName: 'Business B',
          roleId: 'accountant',
          roleName: 'Accountant',
          isOwner: false,
        ),
      ],
    );

    expect(resolution.hasSelectedBusiness, isFalse);
    expect(resolution.workspaces, hasLength(2));
  });

  test('unknown membership statuses parse safely', () {
    expect(MembershipStatus.tryParse('future-status'), isNull);
  });

  test('membership keeps role reference and lifecycle metadata', () {
    final joinedAt = DateTime.utc(2026, 1, 1);
    const member = BusinessMember(
      uid: 'user-a',
      roleId: 'owner',
      status: MembershipStatus.active,
    );
    final memberWithLifecycle = BusinessMember(
      uid: member.uid,
      roleId: member.roleId,
      status: member.status,
      joinedAt: joinedAt,
      createdAt: joinedAt,
      updatedAt: joinedAt,
    );

    expect(memberWithLifecycle.roleId, 'owner');
    expect(memberWithLifecycle.status, MembershipStatus.active);
    expect(memberWithLifecycle.joinedAt, joinedAt);
    expect(memberWithLifecycle.invitedAt, isNull);
    expect(memberWithLifecycle.invitedBy, isNull);
  });

  test('membership status supports the complete lifecycle', () {
    expect(MembershipStatus.values, [
      MembershipStatus.invited,
      MembershipStatus.active,
      MembershipStatus.suspended,
      MembershipStatus.removed,
    ]);
  });
}
