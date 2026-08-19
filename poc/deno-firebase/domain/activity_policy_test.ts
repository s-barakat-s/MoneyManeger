import { ApiError } from "../http/api.ts";
import {
  activityPageSize,
  parseActivityCursor,
  safeActivityMetadata,
} from "./activity_policy.ts";
import { actorDisplayName } from "./actor_identity.ts";

Deno.test("activity pagination uses a bounded deterministic cursor", () => {
  assertEquals(activityPageSize, 30);
  assertEquals(
    parseActivityCursor(
      new URL("https://example.test/activity?cursorCreatedAt=123&cursorId=a"),
    ),
    { createdAtMillis: 123, id: "a" },
  );
  assertApiError(
    () =>
      parseActivityCursor(
        new URL("https://example.test/activity?cursorCreatedAt=123"),
      ),
    "invalid-argument",
  );
});

Deno.test("actor names use safe profile priority and fallback", () => {
  assertEquals(
    actorDisplayName({ displayName: " Ahmed ", username: "ahmed" }),
    "Ahmed",
  );
  assertEquals(actorDisplayName({ username: "saif" }), "saif");
  assertEquals(actorDisplayName(undefined), "Unknown member");
});

Deno.test("only presentation-safe activity metadata is returned", () => {
  assertEquals(
    safeActivityMetadata("member.roleChanged", {
      fromRoleId: "accountant",
      toRoleId: "admin",
      privateValue: "hidden",
    }),
    { fromRoleId: "accountant", toRoleId: "admin" },
  );
  assertEquals(
    safeActivityMetadata("transaction.created", { privateValue: "hidden" }),
    {},
  );
});

function assertApiError(operation: () => unknown, code: string): void {
  try {
    operation();
  } catch (error) {
    if (error instanceof ApiError && error.code === code) return;
    throw error;
  }
  throw new Error(`Expected ApiError(${code}).`);
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }.`,
    );
  }
}
