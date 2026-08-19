import { ApiError } from "../http/api.ts";
import { requestedTransactionIds } from "./transaction_actor_policy.ts";

Deno.test("transaction actor resolution identifiers are bounded and unique", () => {
  assertEquals(requestedTransactionIds(["a", "b", "a"]), ["a", "b"]);
  assertApiError(() => requestedTransactionIds(["bad/id"]));
  assertApiError(() =>
    requestedTransactionIds(
      Array.from({ length: 101 }, (_, index) => `transaction-${index}`),
    )
  );
});

function assertApiError(operation: () => unknown): void {
  try {
    operation();
  } catch (error) {
    if (error instanceof ApiError && error.code === "invalid-argument") return;
    throw error;
  }
  throw new Error("Expected invalid-argument.");
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
