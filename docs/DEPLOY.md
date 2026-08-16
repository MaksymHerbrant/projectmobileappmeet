# Підготовка до деплою та аудит

## 1. Hard-coded значення та секрети (.env)

Винесено в конфіг / dart-define:

| Що | Де було | Як задати тепер |
|----|--------|------------------|
| **SUPABASE_URL** | `main.dart` | `AppConfig.supabaseUrl` (default у коді) або `--dart-define=SUPABASE_URL=...` |
| **SUPABASE_ANON_KEY** | `main.dart` | `AppConfig.supabaseAnonKey` або `--dart-define=SUPABASE_ANON_KEY=...` |
| **PHONE_PREFIX** | `auth_service.dart` (+380) | `AppConfig.phonePrefix` / dart-define `PHONE_PREFIX` |
| **Placeholder avatar** | Різні екрани | `AppConfig.placeholderAvatarUrl` |
| **Firebase** | `firebase_options.dart` | Залишається з FlutterFire; для production перегенеруй `flutterfire configure` або задай через CI. |
| **FCM (пуші)** | ~~приватний ключ у `notification_service.dart`~~ | **Видалено з коду.** Пуші відправляються через Supabase Edge Function `send-push` (ключ тільки в секретах Edge Function). |

Файл **`.env.example`** в корені містить список змінних для довідки. Для Flutter збірки використовуй `--dart-define` або CI (наприклад GitHub Secrets → dart-define).

---

## 2. Обробка помилок (що зроблено)

- **AuthService:** використання `AuthException` / `PostgrestException` де доречно, `debugPrint` замість `print`, виправлено відступи й структуру класу (`signOut`, `updateFcmToken`).
- **MatchesService:** усі методи перевіряють `_userId`; при відсутності користувача повертають порожні списки або виходять без падіння.
- **NotificationService:** пуші через Edge Function; обробка `FunctionException` та загальний `catch`.
- **Рекомендація:** у UI показувати користувачу зрозумілі повідомлення (наприклад "Немає з’єднання", "Спробуйте пізніше") замість сирого `e.toString()`.

---

## 3. Docker (продакшн)

- **Dockerfile:** двосекційний: збірка Flutter Web (`flutter build web`), подача через **nginx**.
- **Запуск:**
  ```bash
  docker build -t dating-app .
  docker run -p 8080:80 dating-app
  ```
- Опційно передати конфіг на збірку:
  ```bash
  docker build --build-arg SUPABASE_URL=https://xxx.supabase.co --build-arg SUPABASE_ANON_KEY=eyJ... -t dating-app .
  ```
- Якщо додаток під сабшлях (наприклад `https://domain.com/app/`), потрібен `flutter build web --base-href /app/` і відповідний `root`/`location` в `nginx.conf`.

---

## 4. Вразливості та ризики

| Ризик | Статус / дія |
|------|------------------|
| **Приватний ключ Firebase в репозиторії** | Усунено: ключ прибрано з коду, пуші тільки через Edge Function. |
| **Supabase anon key в клієнті** | Нормально для публічного клієнта; RLS захищає дані. Не використовуй `service_role` у клієнті. |
| **Firebase API keys у `firebase_options.dart`** | Публічні ключі; обмеження через Firebase Console (домени/пакети). Не комітити `google-services.json` з приватним вмістом. |
| **Логовані токени/номери** | У production прибрати або обмежити `debugPrint` з FCM token / phone. |
| **SQL injection** | Supabase клієнт використовує параметризовані запити; ризик низький. |
| **CORS / домени** | Для Web: додай домен у Supabase (Authentication → URL Configuration) та у Firebase (Authorized domains). |

---

## 5. Продуктивність

- **Ліміти запитів:** у `getPotentialMatches` / `getSmartMatches` вже є `.limit(20)` — добре.
- **N+1:** `getEventLikes()` у циклі робить запит на кожну подію; при зрості даних варто один запит з join або RPC.
- **Realtime:** підписки на канали (чат, presence) — при виході з екрану варто відписатися (`unsubscribeFromPresence` тощо).
- **Векторний пошук:** при відсутності `embedding` використовується fallback на звичайний список — стабільно.
- **Кеш:** для списків профілів/подій можна додати простий in-memory кеш з TTL, щоб не тягнути одне й те саме при кожному поверненні на екран.

---

## 6. Edge Function для пушів

Реалізація: **`supabase/functions/send-push/index.ts`**.

- **Безпечний парсинг:** `FIREBASE_SERVICE_ACCOUNT_JSON` парситься в try/catch; перевіряються наявність і тип полів `project_id`, `private_key`, `client_email`. При помилці повертається 500 без витоку вмісту.
- **Access token:** OAuth2 JWT з Service Account; кеш в пам’яті з оновленням за ~60 сек до expiry, щоб не робити запит за токеном на кожен пуш.
- **Тіло запиту:** `{ "token": "<fcm_token>", "title": "...", "body": "...", "data": {} }`. Валідація типів; при відсутності полів — 400.

Деплой:

1. Секрет у Supabase: Project → Edge Functions → Secrets → `FIREBASE_SERVICE_ACCOUNT_JSON` = рядок JSON з Firebase Console (Service Account key).
2. З CLI: `supabase functions deploy send-push --no-verify-jwt` (або з verify, якщо викликає лише авторизований клієнт).
