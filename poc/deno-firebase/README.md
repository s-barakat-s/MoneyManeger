# Deno Deploy Firebase compatibility PoC

This isolated service verifies that Deno can use Firebase Admin for token
verification, Firestore access, transactions, and Auth user lookup. It does not
contain or replace any Money Manager backend operation.

## Environment

Copy `.env.example` to `.env` locally and populate:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS` (comma-separated exact web origins; optional for native clients)

Never commit `.env` or service-account credentials. In Deno Deploy, add these as
application secrets/environment variables.

## Local checks

```text
deno task check
deno task --env-file=.env start
```

Endpoints:

- `GET /health` is public.
- `GET /auth-check` requires a Firebase bearer ID token.
- `GET /firestore-read-test` reads only `userProfiles/{verified uid}`.
- `POST /firestore-write-test` transacts only `_backendPoc/{verified uid}`.
- `POST /auth-user-lookup-test` only looks up the caller's own verified email.

For authenticated requests, send:

```text
Authorization: Bearer <Firebase ID Token>
```

The lookup request body is:

```json
{"email":"the-caller-verified-email@example.com"}
```

## Deployment

Authenticate the Deno CLI, create/select a Deno Deploy application, configure
the four environment variables, then deploy this directory's `main.ts` only.
Do not place secret values in command history or source files.
