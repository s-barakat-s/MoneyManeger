import {
  invitationEmailIndexId,
  normalizeInvitationEmail,
} from "./invitation_policy.ts";

Deno.test("invitation email normalization matches the callable contract", () => {
  assertEquals(
    normalizeInvitationEmail("  Ahmed@Example.COM "),
    "ahmed@example.com",
  );
  let threw = false;
  try {
    normalizeInvitationEmail("not-an-email");
  } catch {
    threw = true;
  }
  assertEquals(threw, true);
});

Deno.test("invitation email index remains a stable SHA-256 hex ID", () => {
  assertEquals(
    invitationEmailIndexId("ahmed@example.com"),
    "632bb9bf1171c9a5791a52c340c53d9b71d2a342cd884579c799cefbf5de262b",
  );
});

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(
      `Expected ${String(expected)}, received ${String(actual)}.`,
    );
  }
}
