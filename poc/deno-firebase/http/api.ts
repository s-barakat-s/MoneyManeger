export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export function success(
  data: Record<string, unknown>,
  headers: HeadersInit = {},
): Response {
  return Response.json(
    { ok: true, data },
    { status: 200, headers: responseHeaders(headers) },
  );
}

export function failure(
  error: ApiError,
  headers: HeadersInit = {},
): Response {
  return Response.json(
    {
      ok: false,
      error: { code: error.code, message: error.message },
    },
    { status: error.status, headers: responseHeaders(headers) },
  );
}

export async function readJsonObject(
  request: Request,
): Promise<Record<string, unknown>> {
  try {
    const value: unknown = await request.json();
    if (isRecord(value)) return value;
  } catch {
    // Converted into a stable API error below.
  }
  throw new ApiError(400, "invalid-argument", "A JSON object is required.");
}

export function requiredString(
  data: Record<string, unknown>,
  key: string,
): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ApiError(400, "invalid-argument", `Invalid ${key}.`);
  }
  return value.trim();
}

function responseHeaders(extra: HeadersInit): Headers {
  const headers = new Headers(extra);
  headers.set("cache-control", "no-store");
  return headers;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
