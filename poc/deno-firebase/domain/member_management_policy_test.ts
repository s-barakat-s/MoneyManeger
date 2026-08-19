import { ApiError } from "../http/api.ts";
import { resolveMemberMutation } from "./member_management_policy.ts";

Deno.test("member status transitions preserve lifecycle rules", () => {
  assertEquals(
    resolveMemberMutation("suspend", "active", "viewer", null).action,
    "member.suspended",
  );
  assertEquals(
    resolveMemberMutation("reactivate", "suspended", "viewer", null).action,
    "member.reactivated",
  );
  assertEquals(
    resolveMemberMutation("remove", "active", "viewer", null).updates.status,
    "removed",
  );
  assertApiError(
    () => resolveMemberMutation("reactivate", "removed", "viewer", null),
    "failed-precondition",
  );
});

Deno.test("role changes retain exact activity metadata", () => {
  const mutation = resolveMemberMutation(
    "changeRole",
    "active",
    "accountant",
    "admin",
  );
  assertEquals(mutation.action, "member.roleChanged");
  assertEquals(mutation.updates.roleId, "admin");
  assertEquals(mutation.metadata.fromRoleId, "accountant");
  assertEquals(mutation.metadata.toRoleId, "admin");
});

function assertApiError(operation: () => void, code: string): void {
  try {
    operation();
  } catch (error) {
    if (error instanceof ApiError && error.code === code) return;
    throw error;
  }
  throw new Error(`Expected ApiError(${code}).`);
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(
      `Expected ${String(expected)}, received ${String(actual)}.`,
    );
  }
}
