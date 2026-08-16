# Dating App (Meet)

Сучасний додаток для знайомств з подіями, матчингом та чатами. Flutter + Supabase + Firebase (FCM).

---

## Що потрібно для запуску

- Flutter SDK (stable)
- Обліковий запис [Supabase](https://supabase.com) та проект з налаштованими таблицями (див. нижче)
- Firebase проект для пуш-сповіщень (опційно)

---

## Локальний запуск

```bash
# Залежності
flutter pub get

# Запуск (дефолтні URL/ключі з коду)
flutter run
```

З власним Supabase (без зміни коду):

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## Розгортання «в світ»

### 1. Секрети та конфіг

- Скопіюй **`.env.example`** у **`.env`** (локально) і заповни значення. Файл **`.env` не комітити** (він уже в `.gitignore`).
- Для збірки (CI або локально) використовуй **`--dart-define`**:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` — обов’язково для production, якщо не хочеш залишати дефолти в коді.
  - `PHONE_PREFIX`, `PLACEHOLDER_AVATAR_URL` — опційно.

### 2. Supabase

- Виконай у Supabase SQL Editor скрипт створення таблиць, RLS, тригерів і storage (якщо ще не виконував) — див. окрему інструкцію з SQL.
- Для пушів: створи Edge Function **`send-push`** і задай секрет з Firebase Service Account. Деталі в **`docs/DEPLOY.md`**.

### 3. Firebase

- Перегенеруй конфіг під production: `flutterfire configure`.
- У Firebase Console додай домени (для web) та пакети (Android/iOS) у налаштуваннях.

### 4. Збірка подіб до production

**Android:**

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

**iOS:**

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

**Web (для деплою на хостинг або в Docker):**

```bash
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### 5. Docker (Web)

Збірка образу та запуск контейнера:

```bash
# Збірка (опційно з аргументами)
docker build -t dating-app .

# Запуск на порту 8080
docker run -p 8080:80 dating-app
```

Відкрий `http://localhost:8080`. Для production передай `SUPABASE_URL` та `SUPABASE_ANON_KEY` через `--build-arg` під час `docker build`.

---

## Структура проєкту

- `lib/config/app_config.dart` — URL та ключі (з `--dart-define` або дефолти).
- `lib/service/` — auth, matches, chat, notifications.
- `lib/screens/` — екрани додатку.
- `lib/providers/` — стан (наприклад, locale, app state).
- `docs/DEPLOY.md` — детальний аудит безпеки, продуктивності та інструкції по Edge Function для пушів.

---

## Документація по деплою та безпеці

Повний опис:

- що винесено в .env / dart-define,
- обробка помилок,
- Docker,
- вразливості та рекомендації з безпеки й продуктивності,
- налаштування Edge Function для FCM,

див. ** [docs/DEPLOY.md](docs/DEPLOY.md) **.
