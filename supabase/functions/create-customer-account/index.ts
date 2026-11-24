import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ALLOWED_APPROVAL_STATUSES = new Set(["approved", "pending"]);
const ALLOWED_TIERS = new Set([
  "Pebble Black Member",
  "Gold Tier",
  "Elite Tier",
]);

function normalizeMobile(raw: string): string {
  const cleaned = raw.trim().replace(/[^0-9+]/g, "");
  if (!cleaned) return "";
  if (cleaned.startsWith("+")) return cleaned;
  if (cleaned.length === 10) return `+91${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith("91")) return `+${cleaned}`;
  return `+${cleaned}`;
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

  // 2. Verify caller is an active admin in public.admin_users
  const { data: callerAdmin, error: callerRoleError } = await supabaseAdmin
    .from("admin_users")
    .select("user_id, email, full_name, role, status, is_key_master, permissions")
    .eq("user_id", callerUser.id)
    .maybeSingle();

  if (callerRoleError || !callerAdmin) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: Only active administrators can add customer accounts.",
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

  const isActiveAdmin = callerStatus === "active";
  const hasSuperOrApproveAccess =
    callerIsKeyMaster ||
    callerRole === "super_admin" ||
    callerPerms.includes("users.approve");
  const hasUsersView = callerPerms.includes("users.view");

  if (!isActiveAdmin || (!hasSuperOrApproveAccess && !hasUsersView)) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: You do not have permission to create customer accounts.",
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
  const rawMobile = String(payload.mobile_number ?? "").trim();
  const normalizedMobile = normalizeMobile(rawMobile);
  const password = String(payload.password ?? "");
  const requestedStatus = String(payload.approval_status ?? "approved")
    .trim()
    .toLowerCase();
  const requestedTier = String(
    payload.membership_tier ?? "Pebble Black Member",
  ).trim();
  const rawInitialPoints = Number(payload.initial_points ?? 0);
  const initialPoints = Number.isFinite(rawInitialPoints)
    ? Math.trunc(rawInitialPoints)
    : 0;

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

  const digitsOnly = normalizedMobile.replace(/[^0-9]/g, "");
  if (digitsOnly.length < 10 || digitsOnly.length > 15) {
    return jsonResponse(
      {
        error:
          "INVALID_MOBILE: Please enter a valid 10 to 15 digit mobile number.",
      },
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

  if (!ALLOWED_APPROVAL_STATUSES.has(requestedStatus)) {
    return jsonResponse(
      {
        error: "INVALID_STATUS: Initial status must be approved or pending.",
      },
      400,
    );
  }

  if (requestedStatus === "approved" && !hasSuperOrApproveAccess) {
    return jsonResponse(
      {
        error:
          "UNAUTHORIZED: Only admins with KYC Approve permission can create pre-approved customers.",
      },
      403,
    );
  }

  const membershipTier = ALLOWED_TIERS.has(requestedTier)
    ? requestedTier
    : "Pebble Black Member";

  if (initialPoints < 0 || initialPoints > 100000) {
    return jsonResponse(
      {
        error:
          "INVALID_POINTS: Initial welcome points must be between 0 and 100,000.",
      },
      400,
    );
  }

  // 4. Verify email and mobile uniqueness across existing profiles and admins
  const { data: existingAdmin } = await supabaseAdmin
    .from("admin_users")
    .select("user_id")
    .ilike("email", email)
    .maybeSingle();

  if (existingAdmin) {
    return jsonResponse(
      {
        error:
          `DUPLICATE_EMAIL: The email ${email} belongs to an admin account.`,
      },
      409,
    );
  }

  const { data: existingEmailProfile } = await supabaseAdmin
    .from("profiles")
    .select("id")
    .ilike("email", email)
    .maybeSingle();

  if (existingEmailProfile) {
    return jsonResponse(
      {
        error:
          `DUPLICATE_EMAIL: A customer account with email ${email} already exists.`,
      },
      409,
    );
  }

  const { data: existingMobileProfile } = await supabaseAdmin
    .from("profiles")
    .select("id")
    .eq("mobile_number", normalizedMobile)
    .maybeSingle();

  if (existingMobileProfile) {
    return jsonResponse(
      {
        error:
          `DUPLICATE_MOBILE: A customer account with mobile ${normalizedMobile} already exists.`,
      },
      409,
    );
  }

  // 5. Create Supabase Auth user with email_confirm = true
  const { data: createdAuth, error: createAuthError } =
    await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        mobile_number: normalizedMobile,
      },
    });

  if (createAuthError || !createdAuth?.user) {
    const errMsg = createAuthError?.message ?? "Failed to create Auth user.";
    const lower = errMsg.toLowerCase();
    const isDuplicate =
      lower.includes("already") ||
      lower.includes("exists") ||
      lower.includes("registered") ||
      lower.includes("mobile_already_registered");
    return jsonResponse(
      {
        error: isDuplicate
          ? `DUPLICATE_ACCOUNT: ${errMsg}`
          : `AUTH_CREATE_FAILED: ${errMsg}`,
      },
      isDuplicate ? 409 : 400,
    );
  }

  const newUserId = createdAuth.user.id;
  const nowIso = new Date().toISOString();

  // 6. Provision profile, wallet, optional welcome points, and audit log with rollback
  try {
    const profilePayload = {
      id: newUserId,
      full_name: fullName,
      email,
      mobile_number: normalizedMobile,
      approval_status: requestedStatus,
      approved_by: requestedStatus === "approved" ? callerUser.id : null,
      approved_at: requestedStatus === "approved" ? nowIso : null,
      rejection_reason: null,
      updated_at: nowIso,
    };

    const { data: savedProfile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .upsert(profilePayload, { onConflict: "id" })
      .select("*")
      .single();

    if (profileError || !savedProfile) {
      throw new Error(
        profileError?.message ?? "Failed to save customer profile.",
      );
    }

    let customerCode = `SHFT-${newUserId.replace(/-/g, "").slice(0, 4).toUpperCase()}`;
    const { data: codeConflict } = await supabaseAdmin
      .from("customer_wallets")
      .select("user_id")
      .eq("customer_code", customerCode)
      .neq("user_id", newUserId)
      .maybeSingle();
    if (codeConflict) {
      customerCode = `SHFT-${newUserId.replace(/-/g, "").slice(0, 6).toUpperCase()}`;
    }

    const { data: savedWallet, error: walletError } = await supabaseAdmin
      .from("customer_wallets")
      .upsert(
        {
          user_id: newUserId,
          customer_code: customerCode,
          membership_tier: membershipTier,
          available_points: initialPoints,
          locked_points: 0,
          reserved_points: 0,
          lifetime_earned_points: initialPoints,
          lifetime_redeemed_points: 0,
          updated_at: nowIso,
        },
        { onConflict: "user_id" },
      )
      .select("*")
      .single();

    if (walletError || !savedWallet) {
      throw new Error(
        walletError?.message ?? "Failed to initialize customer wallet.",
      );
    }

    // Fetch global rate config for consistent ledger snapshot metadata
    let ptsPerRupee = 10;
    let ratePerPt = 0.1;
    let currencyCode = "INR";
    const { data: settingsRow } = await supabaseAdmin
      .from("reward_settings")
      .select("points_per_rupee, points_to_inr_rate, currency_code")
      .eq("singleton_key", "global")
      .maybeSingle();

    if (settingsRow) {
      const parsedPts = Number(settingsRow.points_per_rupee ?? 10);
      if (Number.isFinite(parsedPts) && parsedPts > 0) {
        ptsPerRupee = Math.round(parsedPts);
      }
      const parsedRate = Number(settingsRow.points_to_inr_rate ?? 0.1);
      if (Number.isFinite(parsedRate) && parsedRate > 0) {
        ratePerPt = parsedRate;
      }
      if (settingsRow.currency_code) {
        currencyCode = String(settingsRow.currency_code);
      }
    }

    if (initialPoints > 0) {
      const cashVal = Number((initialPoints * ratePerPt).toFixed(2));
      const { error: txError } = await supabaseAdmin
        .from("point_transactions")
        .insert({
          user_id: newUserId,
          transaction_type: "point_adjustment",
          title: "Welcome Points Bonus",
          description: `Initial ${initialPoints} pts credited by Admin during onboarding`,
          points_delta: initialPoints,
          is_locked_allocation: false,
          points_per_rupee: ptsPerRupee,
          points_per_currency_unit: ptsPerRupee,
          points_to_inr_rate: ratePerPt,
          cash_value: cashVal,
          currency_code: currencyCode,
          metadata: {
            created_by_admin: callerUser.id,
            source: "admin_add_user",
          },
        });

      if (txError) {
        throw new Error(
          `Failed to record initial points ledger entry: ${txError.message}`,
        );
      }
    }

    await supabaseAdmin.from("admin_access_audit_logs").insert({
      actor_user_id: callerUser.id,
      actor_email: callerUser.email ?? callerAdmin.email ?? "admin",
      target_user_id: newUserId,
      target_email: email,
      action: "CREATE_CUSTOMER_ACCOUNT",
      new_role: requestedStatus,
      note:
        `Added customer ${fullName} (${customerCode}, tier: ${membershipTier}, initial_points: ${initialPoints})`,
    });

    return jsonResponse(
      {
        id: savedProfile.id,
        full_name: savedProfile.full_name,
        email: savedProfile.email,
        mobile_number: savedProfile.mobile_number,
        approval_status: savedProfile.approval_status,
        approved_by: savedProfile.approved_by,
        approved_at: savedProfile.approved_at,
        rejection_reason: savedProfile.rejection_reason,
        created_at: savedProfile.created_at,
        updated_at: savedProfile.updated_at,
        customer_code: savedWallet.customer_code,
        membership_tier: savedWallet.membership_tier,
        points_per_rupee: ptsPerRupee,
        instant_points: savedWallet.available_points,
        future_points: savedWallet.locked_points,
        lifetime_earned_points: savedWallet.lifetime_earned_points,
      },
      201,
    );
  } catch (provisionErr) {
    await supabaseAdmin.auth.admin.deleteUser(newUserId);
    const message =
      provisionErr instanceof Error
        ? provisionErr.message
        : "Failed to provision customer profile and wallet.";
    return jsonResponse(
      { error: `CUSTOMER_PROVISION_FAILED: ${message}` },
      500,
    );
  }
});
