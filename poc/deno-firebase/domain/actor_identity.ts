export function actorDisplayName(
  profile: Record<string, unknown> | undefined,
): string {
  return safeNonEmptyString(profile?.displayName) ??
    safeNonEmptyString(profile?.username) ??
    "Unknown member";
}

function safeNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length === 0 ? null : normalized;
}
