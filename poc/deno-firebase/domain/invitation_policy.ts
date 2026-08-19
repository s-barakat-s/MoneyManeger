import { createHash } from "node:crypto";

import { ApiError } from "../http/api.ts";

export function normalizeInvitationEmail(value: string): string {
  const normalized = value.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
    throw new ApiError(400, "invalid-argument", "Enter a valid email address.");
  }
  return normalized;
}

export function invitationEmailIndexId(email: string): string {
  return createHash("sha256").update(email).digest("hex");
}
