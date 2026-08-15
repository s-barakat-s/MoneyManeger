# Business-owned financial data

## Why the business owns financial records

Firebase Authentication identifies a person, while owners, transactions,
transfers, debts, receivables, payments, and assets describe a business.
Keeping those records under a Business makes sharing and roles possible later
without changing the financial models or calculations again.

This release still looks like a personal, single-business application. Every
authenticated user receives exactly one Business and is its active owner.

## Firestore structure

```text
userProfiles/{uid}
businesses/{businessId}
businesses/{businessId}/members/{uid}
businesses/{businessId}/owners/{id}
businesses/{businessId}/transactions/{id}
businesses/{businessId}/transfers/{id}
businesses/{businessId}/debts/{id}
businesses/{businessId}/receivables/{id}
businesses/{businessId}/payments/{id}
businesses/{businessId}/assets/{id}
usernames/{username}
```

Authentication and Saved Accounts remain UID-based. The user profile stores
`activeBusinessId`; it does not contain financial records.

## Initial provisioning and bootstrap

The initial Business uses the Firebase UID as its deterministic document ID.
This is an idempotency choice, not the authorization model. A Firestore
transaction reads the profile, Business, and owner membership, then creates or
repairs the missing documents and records `activeBusinessId`. Repeating the
operation reuses the same Business and never creates a second default Business.

The authenticated application waits for this transaction. It shows a branded
loading page while provisioning, a bounded error page with Retry on failure,
and creates financial routes only after a Business scope is ready. Account
switching keeps its overlay active until the selected UID's Business bootstrap
completes, so repositories cannot retain the previous account's scope.

## Data scope and repositories

`BusinessDataScope` exposes typed references rooted at
`businesses/{businessId}`. Every financial repository receives that scope and
stores only its scoped collection references; repositories do not read Firebase
Auth or build user-owned paths. Riverpod derives the scope from the current
authenticated bootstrap result. A UID change rebuilds the bootstrap, scope,
repositories, and their streams.

Business-related local preferences, such as the last selected owner, include
the Business ID. Saved Accounts metadata remains keyed by Firebase UID.

## Write attribution and future activity history

Business location and actor identity are deliberately separate dependencies.
`BusinessDataScope` chooses where a financial record is stored, while the
authenticated actor provider supplies the immutable Firebase UID responsible
for the write. Financial repositories never accept an actor UID from forms or
other UI input.

Every financial create writes `createdByUid`, `createdAt`, `updatedByUid`, and
`updatedAt`. Every update or archive changes only the updater fields and
preserves the original creator fields. Timestamps use Firestore server
timestamps. Older development documents without audit fields remain readable;
their model fields parse as null.

A future immutable history can live at:

```text
businesses/{businessId}/activityLogs/{logId}
```

An activity record may contain `entityType`, `entityId`, `action`,
`performedByUid`, `performedAt`, `changedFields`, and optional snapshots that
have been reviewed for safe storage. The full activity log, its trusted write
mechanism, and its UI are intentionally not implemented yet. Future deletion
should remain a soft-delete/archive operation or produce a trusted immutable
activity-log entry so the action is auditable.

## Security rules

Users can read and safely update only their own profile. The client may create
only the deterministic first Business owned by its authenticated UID and the
matching active owner membership. Active membership permits reads; the owner
role permits writes. Role and ownership fields cannot be escalated through
ordinary client updates. The obsolete `users/{uid}/...` tree is explicitly
denied.

This layout leaves room for later admin/editor/viewer policies: membership
roles can refine the existing read/write helper functions without moving data.
Additional businesses can later use random IDs and a server-controlled
creation/invitation flow.

Future inventory, product, and stock-movement collections will be added beneath
the same Business document. None are created by this refactor.

## Migration policy

There is no legacy migration or fallback reader. Production financial data had
not launched, so disposable documents below `users/{uid}` must be removed
manually and all new financial writes use only Business paths.
