import {
  requireIdentity,
  requireVerifiedIdentity,
} from "./auth/firebase_auth.ts";
import { ApiError, failure, success } from "./http/api.ts";
import {
  handlePocRoute,
  isPocPath,
  pocEndpointsEnabled,
} from "./routes/poc.ts";
import {
  createWorkspace,
  resolveWorkspaces,
  selectWorkspace,
} from "./routes/workspace.ts";
import { handleInvitationRoute } from "./routes/invitations.ts";
import { handleMemberRoute } from "./routes/members.ts";
import { handleActivityRoute } from "./routes/activity.ts";
import { handleTransactionActorRoute } from "./routes/transaction_actors.ts";
import { handleActorNamesRoute } from "./routes/actor_names.ts";

const allowedOrigins = new Set(
  (Deno.env.get("ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
);

Deno.serve(async (request) => {
  const origin = request.headers.get("origin");
  if (origin && !allowedOrigins.has(origin)) {
    return failure(
      new ApiError(403, "permission-denied", "Origin is not allowed."),
    );
  }
  const corsHeaders: Record<string, string> = origin
    ? {
      "access-control-allow-origin": origin,
      "access-control-allow-headers": "authorization, content-type",
      "access-control-allow-methods": "GET, POST, OPTIONS",
      vary: "Origin",
    }
    : {};
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const { pathname } = new URL(request.url);
    if (request.method === "GET" && pathname === "/health") {
      return Response.json(
        { ok: true, runtime: "deno" },
        {
          status: 200,
          headers: { ...corsHeaders, "cache-control": "no-store" },
        },
      );
    }

    if (isPocPath(pathname)) {
      if (!pocEndpointsEnabled()) {
        throw new ApiError(404, "not-found", "Not found.");
      }
      const identity = await requireIdentity(request);
      return success(
        await handlePocRoute(request, pathname, identity),
        corsHeaders,
      );
    }

    const identity = await requireIdentity(request);
    requireVerifiedIdentity(identity);
    if (request.method === "GET" && pathname === "/api/workspaces") {
      return success(await resolveWorkspaces(identity), corsHeaders);
    }
    if (request.method === "POST" && pathname === "/api/workspaces/select") {
      return success(await selectWorkspace(request, identity), corsHeaders);
    }
    if (request.method === "POST" && pathname === "/api/workspaces") {
      return success(await createWorkspace(request, identity), corsHeaders);
    }
    const invitationResult = await handleInvitationRoute(
      request,
      pathname,
      identity,
    );
    if (invitationResult !== null) {
      return success(invitationResult, corsHeaders);
    }
    const memberResult = await handleMemberRoute(request, pathname, identity);
    if (memberResult !== null) {
      return success(memberResult, corsHeaders);
    }
    const activityResult = await handleActivityRoute(
      request,
      pathname,
      identity,
    );
    if (activityResult !== null) {
      return success(activityResult, corsHeaders);
    }
    const transactionActorResult = await handleTransactionActorRoute(
      request,
      pathname,
      identity,
    );
    if (transactionActorResult !== null) {
      return success(transactionActorResult, corsHeaders);
    }
    const actorNamesResult = await handleActorNamesRoute(
      request,
      pathname,
      identity,
    );
    if (actorNamesResult !== null) {
      return success(actorNamesResult, corsHeaders);
    }
    throw new ApiError(404, "not-found", "Not found.");
  } catch (error) {
    if (error instanceof ApiError) return failure(error, corsHeaders);
    console.error("Backend request failed", error);
    return failure(
      new ApiError(500, "internal", "The backend request failed."),
      corsHeaders,
    );
  }
});
