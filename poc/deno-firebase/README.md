# Money Manager Deno backend

This service uses Firebase Admin from Deno Deploy for trusted Money Manager
workspace operations. Temporary compatibility-test endpoints remain isolated
and are disabled unless explicitly enabled.

## Environment

Copy `.env.example` to `.env` locally and populate:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS` (comma-separated exact web origins; optional for native clients)
- `ENABLE_POC_ENDPOINTS` (`true` only for temporary development validation)

Never commit `.env` or service-account credentials. In Deno Deploy, add these as
application secrets/environment variables.

## Local checks

```text
deno task check
deno task --env-file=.env start
```

Endpoints:

- `GET /health` is public.
- `GET /api/workspaces` resolves the authenticated caller's workspaces.
- `POST /api/workspaces` creates a Business atomically.
- `POST /api/workspaces/select` selects an active membership.
- `GET /api/businesses/:businessId/invitations` lists pending invitations.
- `POST /api/businesses/:businessId/invitations` creates an invitation.
- `POST /api/businesses/:businessId/invitations/:invitationId/revoke` revokes
  a pending invitation.
- `GET /api/invitations/mine` discovers invitations for the verified caller.
- `POST /api/invitations/:invitationId/accept` atomically accepts an invitation.
- `GET /api/businesses/:businessId/members` lists Business members with safe
  profile display fields.
- `GET /api/businesses/:businessId/roles/assignable` lists non-owner roles.
- `POST /api/businesses/:businessId/members/:memberUid/manage` changes roles or
  performs constrained membership status transitions atomically.
- PoC test routes require authentication and `ENABLE_POC_ENDPOINTS=true`;
  they are disabled by default.

For authenticated requests, send:

```text
Authorization: Bearer <Firebase ID Token>
```

The lookup request body is:

```json
{"email":"the-caller-verified-email@example.com"}
```

## Deployment

The Deno Deploy application's working directory is `poc/deno-firebase`. From
the repository root, deploy production with:

```text
deno deploy --app moneymaneger --prod
```

Do not place secret values in command history or source files.
