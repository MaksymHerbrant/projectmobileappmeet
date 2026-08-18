import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
// Використовуємо офіційну бібліотеку Google напряму з NPM!
import { JWT } from "npm:google-auth-library@9.6.3";

// Функція приймає receiver_id, а не готовий токен. Токен читається тут, під
// service_role, і ніколи не потрапляє на клієнт. Викликач мусить передати свій
// user JWT — анонімного ключа недостатньо.
// Веб-збірка ходить сюди з іншого походження, тому без preflight і заголовків
// браузер блокує виклик ще до того, як функція запуститься.
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};


// Тексти сповіщень мовою ОТРИМУВАЧА. Раніше вони формувались на пристрої
// відправника й були жорстко українськими — тобто польський користувач
// отримував українські пуші незалежно від того, як добре перекладено сам
// застосунок, бо телефон відправника не знає мови співрозмовника.
type Locale = "uk" | "en" | "es" | "pl" | "pt";

const MESSAGES: Record<string, Record<Locale, { title: string; body: string }>> = {
  match: {
    uk: { title: "Це взаємно! 🔥", body: "У тебе новий метч, мерщій зазирни в чати!" },
    en: { title: "It's a match! 🔥", body: "You have a new match — go say hello!" },
    es: { title: "¡Es mutuo! 🔥", body: "Tienes un nuevo match, ¡ve a saludar!" },
    pl: { title: "To wzajemne! 🔥", body: "Masz nowe dopasowanie — zajrzyj na czat!" },
    pt: { title: "É mútuo! 🔥", body: "Tens um novo match — vai dizer olá!" },
  },
  new_like: {
    uk: { title: "Новий інтерес! 👋", body: "Хтось хоче з тобою закентуватись. Можливо, це твій новий бро?" },
    en: { title: "Someone likes you! 👋", body: "Someone wants to get to know you. Maybe a new friend?" },
    es: { title: "¡Le gustas a alguien! 👋", body: "Alguien quiere conocerte. ¿Quizá un nuevo amigo?" },
    pl: { title: "Ktoś Cię polubił! 👋", body: "Ktoś chce Cię poznać. Może nowy znajomy?" },
    pt: { title: "Alguém gostou de ti! 👋", body: "Alguém quer conhecer-te. Talvez um novo amigo?" },
  },
  request_accepted: {
    uk: { title: "Твій запит прийнято! 🎉", body: "Тепер ви друзі. Почніть спілкування зараз!" },
    en: { title: "Your request was accepted! 🎉", body: "You're connected now — start chatting!" },
    es: { title: "¡Tu solicitud fue aceptada! 🎉", body: "Ya estáis conectados, ¡empieza a chatear!" },
    pl: { title: "Twoja prośba została przyjęta! 🎉", body: "Jesteście już połączeni — zacznij rozmowę!" },
    pt: { title: "O teu pedido foi aceite! 🎉", body: "Já estão ligados — começa a conversar!" },
  },
};

function resolve(kind: string, locale: string, fallbackTitle?: string, fallbackBody?: string) {
  const set = MESSAGES[kind];
  if (!set) return { title: fallbackTitle ?? "", body: fallbackBody ?? "" };
  const loc = (["uk", "en", "es", "pl", "pt"].includes(locale) ? locale : "uk") as Locale;
  return set[loc];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS });
  }

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

    // 2. Дані запиту. `kind` — ключ у словнику перекладів; `title`/`body`
    //    лишаються для повідомлень чату, де текст пише сама людина.
    const { receiver_id: receiverId, kind, title, body, data } = await req.json();
    if (!receiverId || (!kind && (!title || !body))) {
      return json({ error: "receiver_id and either kind or title+body are required" }, 400);
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

    // 4. Мова отримувача і кінцевий текст
    const { data: receiver } = await admin
      .from("profiles")
      .select("locale")
      .eq("id", receiverId)
      .maybeSingle();

    const text = kind
      ? resolve(kind, receiver?.locale ?? "uk", title, body)
      : { title: title as string, body: body as string };

    // 5. Токени пристроїв отримувача (у людини може бути кілька девайсів)
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
                notification: { title: text.title, body: text.body },
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
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
