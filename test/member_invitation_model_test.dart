import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/business/domain/business_member.dart';
import 'package:money_manager/features/members/domain/business_invitation.dart';
import 'package:money_manager/features/members/domain/email_normalizer.dart';
import 'package:money_manager/features/members/domain/member_summary.dart';

void main() {
  test('invitation email normalization is stable', () {
    expect(
      normalizeInvitationEmail('  Ahmed@Example.COM '),
      'ahmed@example.com',
    );
    expect(isValidInvitationEmail('ahmed@example.com'), isTrue);
    expect(isValidInvitationEmail('not-an-email'), isFalse);
  });

  test('invitation statuses round-trip without an expired placeholder', () {
    for (final status in InvitationStatus.values) {
      expect(InvitationStatus.tryParse(status.name), status);
    }
    expect(InvitationStatus.tryParse('expired'), isNull);
  });

  test('member display identity does not duplicate profile requirements', () {
    const member = MemberSummary(
      uid: 'uid-a',
      roleId: 'accountant',
      roleName: 'Accountant',
      status: MembershipStatus.active,
      isProtectedOwner: false,
      displayName: 'Ahmed',
      email: 'ahmed@example.com',
    );

    expect(member.primaryLabel, 'Ahmed');
    expect(member.secondaryLabel, 'ahmed@example.com');
  });
}
