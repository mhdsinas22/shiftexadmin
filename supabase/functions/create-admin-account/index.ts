import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ALLOWED_PERMISSIONS = new Set([
  "dashboard.view",
  "users.view",
  "users.approve",
  "users.reject",
  "pos.view",
  "pos.give_reward",
  "pos.verify_claim",
  "ledger.view",
  "ads.manage",
  "settings.view",
  "settings.manage",
  "streak.manage",
  "valuation.manage",
  "admins.view",
  "admins.invite",
  "admins.manage",
  "audit.view",
]);

const DEFAULT_ROLE_PERMISSIONS: Record<string, string[]> = {
  super_admin: Array.from(ALLOWED_PERMISSIONS),
  store_manager: [
    "dashboard.view",
    "pos.view",
    "pos.verify_claim",
    "users.view",
  ],
  auditor: [
    "dashboard.view",
    "ledger.view",
    "audit.view",
    "users.view",
    "users.approve",
  ],
};

function resolveRoleLabels(role: string, permissions: string[]) {
  if (role === "super_admin") {
    return {
      permission_summary: "All Permissions",
      badge_label: "Full Access",
    };
  }
  if (role === "store_manager") {
    if (
      permissions.includes("pos.give_reward") &&
      permissions.includes("pos.verify_claim")
    ) {
      return {
        permission_summary: "POS Reward & Verify",
        badge_label: "POS Operator",
      };
    }
    if (permissions.includes("pos.verify_claim")) {
      return {
        permission_summary: "Verify Claim Only",
        badge_label: "Verify Only",
      };
    }
    return {
      permission_summary: "Terminal Operations",
      badge_label: "Verify Only",
    };
  }
  // auditor
  if (permissions.includes("users.approve")) {
    return {
      permission_summary: "Read-only Ledger",
      badge_label: "KYC Verify",
    };
  }
  return {
    permission_summary: "Read-only Ledger",
    badge_label: "Audit Only",
  };
}

function isStrongPassword(password: string): boolean {
  if (password.length < 8 || password.length > 128) return false;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumberOrSymbol = /[0-9!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]/.test(
    password,
  );
  return hasUpper && hasLower && hasNumberOrSymbol;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "METHOD_NOT_ALLOWED: Use POST." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(
      { error: "SERVER_MISCONFIGURED: Missing Supabase service configuration." },
      500,
    );
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const accessToken = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!accessToken) {
    return jsonResponse(
      { error: "UNAUTHENTICATED: Missing Authorization bearer token." },
      401,
    );
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  // 1. Verify caller's authenticated identity
  const {
    data: { user: callerUser },
    error: callerAuthError,
  } = await supabaseAdmin.auth.getUser(accessToken);

  if (callerAuthError || !callerUser) {
    return jsonResponse(
      { error: "UNAUTHENTICATED: Invalid or expired admin session." },
      401,
    );
  }

  // 2. Verify caller is an active Super Admin in public.admin_users
  const { data: callerAdmin, error: callerRoleError } = await supabaseAdmin
    .from("admin_users")
    .select(
      "user_id, email, full_name, role, status, is_key_master, permissions",
    )
    .eq("user_id", callerUser.id)
    .maybeSingle();

  if (callerRoleError || !callerAdmin) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: Ordinary customer or non-admin accounts cannot create Admin accounts.",
      },
      403,
    );
  }

  const callerStatus = String(callerAdmin.status ?? "active").toLowerCase();
  const callerRole = String(callerAdmin.role ?? "").toLowerCase();
  const callerIsKeyMaster = Boolean(callerAdmin.is_key_master);
  const callerPerms: string[] = Array.isArray(callerAdmin.permissions)
    ? callerAdmin.permissions.map((p: unknown) => String(p))
    : [];

  const isAuthorizedSuperAdmin =
    callerStatus === "active" &&
    (callerIsKeyMaster ||
      callerRole === "super_admin" ||
      callerPerms.includes("admins.manage"));

  if (!isAuthorizedSuperAdmin) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: Only active Super Admins are authorized to create Admin accounts.",
      },
      403,
    );
  }

  // 3. Parse & validate request payload
  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: "INVALID_PAYLOAD: Invalid JSON body." }, 400);
  }

  const fullName = String(payload.full_name ?? "").trim();
  const email = String(payload.email ?? "")
    .trim()
    .toLowerCase();
  const password = String(payload.password ?? "");
  const role = String(payload.role ?? "store_manager")
    .trim()
    .toLowerCase();
  const rawTerminal = String(payload.terminal_assignment ?? "").trim();
  const rawPermissions = Array.isArray(payload.permissions)
    ? payload.permissions.map((p: unknown) => String(p).trim())
    : [];

  if (fullName.length < 2 || fullName.length > 100) {
    return jsonResponse(
      { error: "INVALID_NAME: Full name must be between 2 and 100 characters." },
      400,
    );
  }

  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  if (!emailRegex.test(email)) {
    return jsonResponse(
      { error: "INVALID_EMAIL: Please enter a valid email address." },
      400,
    );
  }

  if (!isStrongPassword(password)) {
    return jsonResponse(
      {
        error:
          "INVALID_PASSWORD: Password must be at least 8 characters and include uppercase, lowercase, and a number or symbol.",
      },
      400,
    );
  }

  if (!["super_admin", "store_manager", "auditor"].includes(role)) {
    return jsonResponse(
      {
        error:
          "INVALID_ROLE: Role must be super_admin, store_manager, or auditor.",
      },
      400,
    );
  }

  // Prevent privilege escalation: only Super Admins (role=super_admin or is_key_master) can create another Super Admin
  if (
    role === "super_admin" &&
    callerRole !== "super_admin" &&
    !callerIsKeyMaster
  ) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: Only a Super Admin can create another Super Admin account.",
      },
      403,
    );
  }

  const sanitizedPermissions = rawPermissions.filter((p) =>
    ALLOWED_PERMISSIONS.has(p),
  );
  const finalPermissions =
    sanitizedPermissions.length > 0
      ? Array.from(new Set(sanitizedPermissions))
      : DEFAULT_ROLE_PERMISSIONS[role];

  const defaultTerminal =
    role === "super_admin"
      ? "ShiftEx Central Control"
      : role === "store_manager"
        ? "Term #02"
        : "Read-only Ledger";
  const terminalAssignment =
    rawTerminal.length > 0 ? rawTerminal : defaultTerminal;

  // 4. Verify email uniqueness in public.admin_users
  const { data: existingAdmin } = await supabaseAdmin
    .from("admin_users")
    .select("user_id, email")
    .ilike("email", email)
    .maybeSingle();

  if (existingAdmin) {
    return jsonResponse(
      {
        error: `DUPLICATE_EMAIL: An admin account with email ${email} already exists.`,
      },
      409,
    );
  }

  // 5. Create Supabase Auth user with email_confirm = true (no email verification needed)
  const { data: createdAuth, error: createAuthError } =
    await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
      },
      app_metadata: {
        is_admin_account: true,
        admin_role: role,
      },
    });

  if (createAuthError || !createdAuth?.user) {
    const errMsg = createAuthError?.message ?? "Failed to create Auth user.";
    const isDuplicate =
      errMsg.toLowerCase().includes("already") ||
      errMsg.toLowerCase().includes("exists") ||
      errMsg.toLowerCase().includes("registered");
    return jsonResponse(
      {
        error: isDuplicate
          ? `DUPLICATE_EMAIL: An account with email ${email} is already registered.`
          : `AUTH_CREATE_FAILED: ${errMsg}`,
      },
      isDuplicate ? 409 : 400,
    );
  }

  const newUserId = createdAuth.user.id;
  const labels = resolveRoleLabels(role, finalPermissions);
  const nowIso = new Date().toISOString();

  // 6. Insert admin_users profile with safe rollback if profile creation fails
  try {
    const { data: insertedAdmin, error: insertAdminError } =
      await supabaseAdmin
        .from("admin_users")
        .upsert(
          {
            user_id: newUserId,
            full_name: fullName,
            email,
            role,
            terminal_assignment: terminalAssignment,
            permission_summary: labels.permission_summary,
            badge_label: labels.badge_label,
            is_key_master: false,
            status: "active",
            permissions: finalPermissions,
            created_by: callerUser.id,
            invited_by: callerUser.id,
            updated_at: nowIso,
          },
          { onConflict: "user_id" },
        )
        .select("*")
        .single();

    if (insertAdminError || !insertedAdmin) {
      throw new Error(
        insertAdminError?.message ?? "Failed to insert admin_users record.",
      );
    }

    // Remove any accidental customer profile row if created
    await supabaseAdmin.from("profiles").delete().eq("id", newUserId);

    // 7. Write immutable audit log entry
    await supabaseAdmin.from("admin_access_audit_logs").insert({
      actor_user_id: callerUser.id,
      actor_email: callerUser.email ?? callerAdmin.email ?? "super_admin",
      target_user_id: newUserId,
      target_email: email,
      action: "CREATE_ADMIN_ACCOUNT",
      new_role: role,
      new_permissions: finalPermissions,
      note: `Created admin account for ${fullName} (${role} • ${terminalAssignment})`,
    });

    return jsonResponse(
      {
        user_id: insertedAdmin.user_id,
        full_name: insertedAdmin.full_name,
        email: insertedAdmin.email,
        role: insertedAdmin.role,
        terminal_assignment: insertedAdmin.terminal_assignment,
        permission_summary: insertedAdmin.permission_summary,
        badge_label: insertedAdmin.badge_label,
        is_key_master: insertedAdmin.is_key_master,
        is_current_user: false,
        status: insertedAdmin.status,
        permissions: insertedAdmin.permissions,
        created_by: insertedAdmin.created_by,
        created_at: insertedAdmin.created_at,
        updated_at: insertedAdmin.updated_at,
      },
      201,
    );
  } catch (profileErr) {
    // Safe cleanup: delete the newly created Auth user so orphaned Auth accounts cannot exist
    await supabaseAdmin.auth.admin.deleteUser(newUserId);
    const message =
      profileErr instanceof Error
        ? profileErr.message
        : "Failed to provision admin profile.";
    return jsonResponse(
      { error: `PROFILE_CREATION_FAILED: ${message}` },
      500,
    );
  }
});
