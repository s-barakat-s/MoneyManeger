import { systemRoles } from "./system_roles.ts";

Deno.test("only the owner system role carries team-management authority", () => {
  assertEquals(systemRoles.owner.permissions.includes("members.manage"), true);
  assertEquals(systemRoles.owner.permissions.includes("roles.manage"), true);
  assertEquals(systemRoles.admin.permissions.includes("members.manage"), false);
  assertEquals(systemRoles.admin.permissions.includes("roles.manage"), false);
  assertEquals(
    systemRoles.admin.permissions.includes("transactions.create"),
    true,
  );
});

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(
      `Expected ${String(expected)}, received ${String(actual)}.`,
    );
  }
}
