import { ApiError } from "../http/api.ts";

const maximumTransactionIds = 100;

export function requestedTransactionIds(value: unknown): string[] {
  if (!Array.isArray(value) || value.length > maximumTransactionIds) {
    invalidTransactionIds();
  }
  const ids = value.map((item) => {
    if (typeof item !== "string") invalidTransactionIds();
    const id = item.trim();
    if (id.length === 0 || id.length > 150 || id.includes("/")) {
      invalidTransactionIds();
    }
    return id;
  });
  return [...new Set(ids)];
}

function invalidTransactionIds(): never {
  throw new ApiError(
    400,
    "invalid-argument",
    "Invalid transaction identifiers.",
  );
}
