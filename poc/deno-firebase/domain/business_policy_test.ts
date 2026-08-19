import { ApiError } from "../http/api.ts";
import { assertBusinessOwnerUid } from "./business_owner_policy.ts";

Deno.test("team management requires ownership of the target Business", () => {
  assertBusinessOwnerUid("owner-a", "owner-a");
  assertApiError(
    () => assertBusinessOwnerUid("owner-b", "owner-a"),
    403,
    "permission-denied",
  );
});

function assertApiError(
  operation: () => void,
  status: number,
  code: string,
): void {
  try {
    operation();
  } catch (error) {
    if (
      error instanceof ApiError && error.status === status &&
      error.code === code
    ) return;
    throw error;
  }
  throw new Error(`Expected ApiError(${code}).`);
}
