import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
// Використовуємо офіційну бібліотеку Google напряму з NPM!
import { JWT } from "npm:google-auth-library@9.6.3";

serve(async (req) => {
  try {
    // 1. Отримуємо секрет
    const rawSa = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!rawSa) throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON");
    const sa = JSON.parse(rawSa);

    // 2. Читаємо дані з додатку
    const { token, title, body, data } = await req.json();

    // 3. Google Auth Library сама робить всю магію з JWT та ключами
    const jwtClient = new JWT({
      email: sa.client_email,
      key: sa.private_key, // Бібліотека сама обробить всі \n
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const authRes = await jwtClient.getAccessToken();
    const accessToken = authRes.token;

    if (!accessToken) throw new Error("Не вдалося отримати access_token від Google");

    // 4. Відправляємо пуш
    const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
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
          android: { priority: "high" }
        },
      }),
    });

    const result = await fcmRes.json();
    
    // Якщо Google FCM повернув помилку (наприклад, токен девайса невалідний)
    if (!fcmRes.ok) {
        throw new Error(`FCM Error: ${JSON.stringify(result)}`);
    }

    return new Response(JSON.stringify(result), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});