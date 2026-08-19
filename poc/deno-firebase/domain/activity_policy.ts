import { ApiError } from "../http/api.ts";

export const activityPageSize = 30;

export interface ActivityCursor {
  createdAtMillis: number;
  id: string;
}

export function parseActivityCursor(url: URL): ActivityCursor | null {
  const rawCreatedAt = url.searchParams.get("cursorCreatedAt");
  const rawId = url.searchParams.get("cursorId");
  if (rawCreatedAt === null && rawId === null) return null;
  if (rawCreatedAt === null || rawId === null) invalidCursor();

  const createdAtMillis = Number(rawCreatedAt);
  if (
    !Number.isSafeInteger(createdAtMillis) || createdAtMillis < 0 ||
    rawId.length === 0 || rawId.includes("/")
  ) {
    invalidCursor();
  }
  return { createdAtMillis, id: rawId };
}

export function safeActivityMetadata(
  action: unknown,
  metadata: unknown,
): Record<string, string> {
  if (action !== "member.roleChanged" || !isRecord(metadata)) return {};
  const fromRoleId = safeNonEmptyString(metadata.fromRoleId);
  const toRoleId = safeNonEmptyString(metadata.toRoleId);
  return {
    ...(fromRoleId === null ? {} : { fromRoleId }),
    ...(toRoleId === null ? {} : { toRoleId }),
  };
}

function invalidCursor(): never {
  throw new ApiError(400, "invalid-argument", "Invalid activity cursor.");
}

function safeNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length === 0 ? null : normalized;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
