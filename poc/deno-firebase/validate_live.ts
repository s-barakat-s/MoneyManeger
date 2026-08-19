const token = requiredEnv("FIREBASE_ID_TOKEN");
const baseUrl = new URL(
  requiredEnv("DENO_BASE_URL").replace(/\/+$/, "") + "/",
);
const authorization = { authorization: `Bearer ${token}` };

type Check = { name: string; passed: boolean; note: string };
const checks: Check[] = [];

const health = await request("health", { method: "GET" });
checks.push(result("Health", health.status === 200, health.status));

const auth = await request("auth-check", {
  method: "GET",
  headers: authorization,
});
const authBody = await safeJson(auth);
const email = objectString(authBody, "email");
checks.push(result(
  "Auth verification",
  auth.status === 200 && Boolean(objectString(authBody, "uid")) && Boolean(email),
  auth.status,
));

const read = await request("firestore-read-test", {
  method: "GET",
  headers: authorization,
});
checks.push(result("Firestore read", read.status === 200, read.status));

const write = await request("firestore-write-test", {
  method: "POST",
  headers: authorization,
});
const writeBody = await safeJson(write);
checks.push(result(
  "Firestore isolated write",
  write.status === 200 && writeBody?.ok === true &&
    typeof writeBody.attemptCount === "number",
  write.status,
));

let lookupPassed = false;
let lookupStatus = 0;
if (email) {
  const lookup = await request("auth-user-lookup-test", {
    method: "POST",
    headers: { ...authorization, "content-type": "application/json" },
    body: JSON.stringify({ email }),
  });
  lookupStatus = lookup.status;
  const lookupBody = await safeJson(lookup);
  lookupPassed = lookup.status === 200 && lookupBody?.uidMatchesCaller === true;
}
checks.push(result("Auth getUserByEmail", lookupPassed, lookupStatus));

const missingToken = await request("auth-check", { method: "GET" });
checks.push(result(
  "Missing-token rejection",
  missingToken.status === 401,
  missingToken.status,
));

for (const check of checks) {
  console.log(`${check.name}: ${check.passed ? "PASS" : "FAIL"} (${check.note})`);
}

if (checks.some((check) => !check.passed)) Deno.exit(1);

function request(path: string, init: RequestInit): Promise<Response> {
  return fetch(new URL(path, baseUrl), init);
}

async function safeJson(response: Response): Promise<Record<string, unknown> | null> {
  try {
    const value: unknown = await response.json();
    return isRecord(value) ? value : null;
  } catch {
    return null;
  }
}

function result(name: string, passed: boolean, status: number): Check {
  return { name, passed, note: `HTTP ${status || "not called"}` };
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    console.error(`Missing ${name} in .env.validation.local.`);
    Deno.exit(2);
  }
  return value;
}

function objectString(
  value: Record<string, unknown> | null,
  key: string,
): string | undefined {
  if (!value) return undefined;
  const item = value[key];
  return typeof item === "string" && item.length > 0 ? item : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
