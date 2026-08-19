const validationEnvUrl = new URL("./.env.validation.local", import.meta.url);
const googleServicesUrl = new URL(
  "../../android/app/google-services.json",
  import.meta.url,
);

const email = requiredEnv("FIREBASE_TEST_EMAIL");
const password = requiredEnv("FIREBASE_TEST_PASSWORD");
const apiKey = await readFirebaseWebApiKey();

const response = await fetch(
  `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
  {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  },
);

const payload: unknown = await response.json();
if (!response.ok) {
  const code = firebaseErrorCode(payload);
  console.error(`Firebase client sign-in failed (HTTP ${response.status}, ${code}).`);
  Deno.exit(1);
}

const idToken = objectString(payload, "idToken");
if (!idToken) {
  console.error("Firebase client sign-in succeeded without returning an ID token.");
  Deno.exit(1);
}

const current = await Deno.readTextFile(validationEnvUrl);
const tokenLine = `FIREBASE_ID_TOKEN=${idToken}`;
let tokenWritten = false;
const updatedLines = current.split(/\r?\n/).flatMap((line) => {
  if (!/^\s*FIREBASE_ID_TOKEN\s*=/.test(line)) return [line];
  if (tokenWritten) return [];
  tokenWritten = true;
  return [tokenLine];
});
if (!tokenWritten) updatedLines.push(tokenLine);
const updated = `${updatedLines.join("\n").trimEnd()}\n`;
await Deno.writeTextFile(validationEnvUrl, updated);

console.log("Firebase client sign-in succeeded; the ID token was stored locally (redacted). ");

async function readFirebaseWebApiKey(): Promise<string> {
  const config: unknown = JSON.parse(await Deno.readTextFile(googleServicesUrl));
  if (!isRecord(config) || !Array.isArray(config.client)) {
    throw new Error("Android Firebase configuration has no client entries.");
  }
  for (const client of config.client) {
    if (!isRecord(client) || !Array.isArray(client.api_key)) continue;
    for (const entry of client.api_key) {
      const key = objectString(entry, "current_key");
      if (key) return key;
    }
  }
  throw new Error("Android Firebase configuration has no Web API key.");
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    console.error(`Set ${name} in .env.validation.local and retry.`);
    Deno.exit(2);
  }
  return value;
}

function firebaseErrorCode(value: unknown): string {
  if (!isRecord(value) || !isRecord(value.error)) return "UNKNOWN_ERROR";
  return objectString(value.error, "message") ?? "UNKNOWN_ERROR";
}

function objectString(value: unknown, key: string): string | undefined {
  if (!isRecord(value)) return undefined;
  const item = value[key];
  return typeof item === "string" && item.length > 0 ? item : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
