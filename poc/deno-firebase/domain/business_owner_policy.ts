import { ApiError } from "../http/api.ts";

export function assertBusinessOwnerUid(
  ownerUid: unknown,
  authenticatedUid: string,
): void {
  if (ownerUid !== authenticatedUid) {
    throw new ApiError(
      403,
      "permission-denied",
      "Only the Business owner may manage the team.",
    );
  }
}
