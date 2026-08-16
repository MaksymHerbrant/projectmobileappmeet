import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
// Використовуємо офіційну бібліотеку Google напряму з NPM!
import { JWT } from "npm:google-auth-library@9.6.3";

// Функція приймає receiver_id, а не готовий токен. Токен читається тут, під
// service_role, і ніколи не потрапляє на клієнт. Викликач мусить передати свій
// user JWT — анонімного ключа недостатньо.
serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    // 1. Хто викликає. Bearer має бути JWT живого користувача, а не anon key.
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "Missing Authorization header" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY");
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: caller, error: callerError } = await admin.auth.getUser(jwt);
    if (callerError || !caller?.user) {
      return json({ error: "Unauthorized" }, 401);
    }
    const senderId = caller.user.id;

    // 2. Дані запиту
    const { receiver_id: receiverId, title, body, data } = await req.json();
    if (!receiverId || !title || !body) {
      return json({ error: "receiver_id, title and body are required" }, 400);
    }

    // 3. Чи має цей користувач взагалі право писати тому користувачу.
    //    Без цієї перевірки функція — відкритий релей: знаєш чужий id, шлеш що завгодно.
    const { data: allowed, error: allowedError } = await admin.rpc("can_notify", {
      p_sender: senderId,
      p_receiver: receiverId,
    });
    if (allowedError) throw allowedError;
    if (allowed !== true) {
      return json({ error: "Forbidden" }, 403);
    }

    // 4. Токени пристроїв отримувача (у людини може бути кілька девайсів)
    const { data: devices, error: devicesError } = await admin
      .from("user_devices")
      .select("fcm_token")
      .eq("profile_id", receiverId);
    if (devicesError) throw devicesError;

    const tokens = (devices ?? [])
      .map((d: { fcm_token: string }) => d.fcm_token)
      .filter(Boolean);
    if (tokens.length === 0) {
      return json({ skipped: "no registered devices" }, 200);
    }

    // 5. Отримуємо секрет і access_token для FCM
    const rawSa = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!rawSa) throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON");
    const sa = JSON.parse(rawSa);

    const jwtClient = new JWT({
      email: sa.client_email,
      key: sa.private_key, // Бібліотека сама обробить всі \n
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const authRes = await jwtClient.getAccessToken();
    const accessToken = authRes.token;
    if (!accessToken) throw new Error("Не вдалося отримати access_token від Google");

    // 6. Відправляємо пуш на кожен девайс. Мертві токени прибираємо з бази,
    //    інакше вони накопичуються і кожен пуш марно ходить у FCM.
    const results = await Promise.all(
      tokens.map(async (token: string) => {
        const fcmRes = await fetch(
          `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body },
                data: data || {},
                android: { priority: "high" },
              },
            }),
          },
        );

        if (fcmRes.ok) return { token, ok: true };

        const error = await fcmRes.json().catch(() => ({}));
        const code = error?.error?.details?.[0]?.errorCode ?? error?.error?.status;
        if (code === "UNREGISTERED" || code === "INVALID_ARGUMENT") {
          await admin.from("user_devices").delete().eq("fcm_token", token);
        }
        return { token, ok: false, code };
      }),
    );

    return json({ sent: results.filter((r) => r.ok).length, results }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ error: message }, 500);
  }
});

function json(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
