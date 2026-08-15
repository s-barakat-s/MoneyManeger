String normalizeInvitationEmail(String value) {
  return value.trim().toLowerCase();
}

bool isValidInvitationEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
      .hasMatch(normalizeInvitationEmail(value));
}
