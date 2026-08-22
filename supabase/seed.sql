-- ============================================================================
-- Seed data for development.
--
-- Not a migration: it is never applied to production by `db push`. Run it by
-- hand against a development project when you need a feed that is worth
-- looking at.
--
-- Everything is created through the same tables and constraints real users go
-- through, so the seeded rows exercise RLS, the embedding format and the
-- geo columns exactly as production data would.
--
-- Seeded accounts all carry phone numbers in +38099000xxxx and are tagged with
-- bio ending in the marker below, so they can be removed cleanly.
--
-- Usage:
--   psql "$DATABASE_URL" -f supabase/seed.sql
--   psql "$DATABASE_URL" -c "select public.seed_clear();"
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."seed_clear"()
RETURNS "text"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "auth", "pg_temp"
AS $$
DECLARE
  v_users int;
BEGIN
  DELETE FROM auth.users
  WHERE phone LIKE '+38099000%'
  RETURNING 1 INTO v_users;

  GET DIAGNOSTICS v_users = ROW_COUNT;
  RETURN format('видалено тестових акаунтів: %s', v_users);
END;
$$;

ALTER FUNCTION "public"."seed_clear"() OWNER TO "postgres";


DO $seed$
DECLARE
  -- Київ як центр; учасники розкидані навколо, щоб було що фільтрувати радіусом
  base_lat   double precision := 50.4501;
  base_long  double precision := 30.5234;

  interests text[] := ARRAY[
    'Музика','Танці','Спорт','Подорожі','Освіта','Вечірка',
    'Кава','Кіно','Мистецтво','Походи','Гори','Природа',
    'IT','Програмування','Геймінг','Фотографія','Кулінарія',
    'Йога','Фітнес','Біг'
  ];

  first_names text[] := ARRAY[
    'Олена','Андрій','Софія','Максим','Дарина','Іван','Марія','Назар',
    'Юлія','Богдан','Аліна','Тарас','Катерина','Олексій','Вікторія','Дмитро',
    'Анастасія','Сергій','Христина','Роман','Ірина','Павло','Оксана','Юрій',
    'Наталія','Володимир','Злата','Артем','Мирослава','Денис'
  ];
  last_names text[] := ARRAY[
    'Коваленко','Шевченко','Бондаренко','Ткаченко','Кравченко','Мельник',
    'Іваненко','Поліщук','Савченко','Марченко','Гриценко','Лисенко'
  ];

  bios text[] := ARRAY[
    'Шукаю компанію для ранкових пробіжок уздовж Дніпра.',
    'Кавоманка. Знаю всі спешелті-місця в центрі й готова показати.',
    'Граю в настолки щочетверга, місце за столом завжди знайдеться.',
    'Ходжу в гори кожного місяця. Карпати знаю краще за свій район.',
    'Пишу код удень, готую вечорами. Шукаю, з ким це їсти.',
    'Фотографую плівку. Гуляю містом і шукаю світло.',
    'Веган, скеледром, довгі розмови. У такому порядку.',
    'Переїхала пів року тому, знайомих майже немає — виправляю це.',
    'Люблю концерти в маленьких залах і людей, які теж їх люблять.',
    'Йога вранці, книжки ввечері. Іноді навпаки.',
    'Збираю компанію на велопрогулянки вихідними.',
    'Кіноман. Готовий сперечатися про Лінча годинами.',
    'Вчу польську, шукаю з ким практикуватись за кавою.',
    'Бігаю марафони. Повільно, але вперто.',
    'Малюю акварель у парках. Приєднуйтесь, фарби є.'
  ];

  event_titles text[] := ARRAY[
    'Ранкова пробіжка на Трухановому',
    'Настолки в антикафе',
    'Похід на Говерлу',
    'Кава і розмови про IT',
    'Велопрогулянка вздовж Дніпра',
    'Кінопоказ у дворику',
    'Йога в парку на світанку',
    'Майстерня акварелі',
    'Розмовний клуб польської',
    'Вечір настільного тенісу',
    'Фотопрогулянка старим Подолом',
    'Спільна вечеря: готуємо разом',
    'Скелелазіння для початківців',
    'Барахолка та своп одягу',
    'Джем-сейшн для музикантів',
    'Пікнік на ВДНГ',
    'Забіг 5 км для новачків',
    'Вечір гри на гітарі',
    'Прогулянка з собаками',
    'Книжковий клуб: обговорюємо Джойса'
  ];

  event_locations text[] := ARRAY[
    'Київ, Труханів острів','Київ, Поділ','Київ, Печерськ','Київ, ВДНГ',
    'Київ, Оболонь','Київ, Голосіїв','Київ, Лук''янівка','Київ, Троєщина'
  ];

  v_id        uuid;
  v_name      text;
  v_tags      text[];
  v_vec       text;
  v_lat       double precision;
  v_long      double precision;
  v_creator   uuid;
  v_event_id  uuid;
  v_room_id   uuid;
  v_seeded    uuid[] := '{}';
  i           int;
  j           int;
  k           int;
  tag_count   int;
BEGIN
  -- ---------------------------------------------------------------- профілі
  FOR i IN 1..30 LOOP
    v_id := gen_random_uuid();

    INSERT INTO auth.users (id, phone, instance_id, aud, role, created_at, updated_at)
    VALUES (
      v_id,
      '+38099000' || lpad(i::text, 4, '0'),
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', now(), now()
    );

    -- 2-5 інтересів на людину, щоб схожість була нерівномірною
    tag_count := 2 + (i % 4);
    v_tags := '{}';
    FOR j IN 1..tag_count LOOP
      v_tags := array_append(v_tags, interests[1 + ((i * 7 + j * 3) % array_length(interests, 1))]);
    END LOOP;
    v_tags := ARRAY(SELECT DISTINCT unnest(v_tags));

    -- Той самий формат вектора, що будує клієнт: одиниця на позиції інтересу
    v_vec := '[' || array_to_string(ARRAY(
      SELECT CASE WHEN interests[p] = ANY(v_tags) THEN 1 ELSE 0 END
      FROM generate_series(1, 384) AS p
      WHERE p <= 384
    ), ',') || ']';

    -- Розкидані в межах приблизно 25 км від центру
    v_lat  := base_lat  + ((i % 11) - 5) * 0.022;
    v_long := base_long + ((i % 7)  - 3) * 0.031;

    v_name := first_names[1 + ((i - 1) % array_length(first_names, 1))]
              || ' ' || last_names[1 + ((i * 5) % array_length(last_names, 1))];

    UPDATE profiles SET
      full_name      = v_name,
      birth_date     = (now() - ((20 + (i % 15)) || ' years')::interval)::date,
      bio            = bios[1 + ((i - 1) % array_length(bios, 1))],
      location       = 'Київ',
      hobbies        = v_tags,
      photos         = ARRAY[
                         -- DiceBear, а не pravatar: той віддає зображення без CORS-заголовків,
                       -- і браузер відмовляється їх декодувати на вебі.
                       'https://api.dicebear.com/9.x/avataaars/png?size=600&seed=' || v_id::text
                       ],
      embedding      = v_vec::vector,
      location_point = point(v_lat, v_long),
      updated_at     = now()
    WHERE id = v_id;

    v_seeded := array_append(v_seeded, v_id);
  END LOOP;

  -- ------------------------------------------------------------------ події
  FOR i IN 1..array_length(event_titles, 1) LOOP
    v_creator := v_seeded[1 + ((i * 3) % array_length(v_seeded, 1))];

    tag_count := 2 + (i % 3);
    v_tags := '{}';
    FOR j IN 1..tag_count LOOP
      v_tags := array_append(v_tags, interests[1 + ((i * 5 + j * 2) % array_length(interests, 1))]);
    END LOOP;
    v_tags := ARRAY(SELECT DISTINCT unnest(v_tags));

    v_vec := '[' || array_to_string(ARRAY(
      SELECT CASE WHEN interests[p] = ANY(v_tags) THEN 1 ELSE 0 END
      FROM generate_series(1, 384) AS p
    ), ',') || ']';

    v_lat  := base_lat  + ((i % 9) - 4) * 0.019;
    v_long := base_long + ((i % 5) - 2) * 0.027;

    INSERT INTO events (
      creator_id, title, description, location, event_date, photos, tags,
      participants_count, is_private, embedding, location_point
    )
    VALUES (
      v_creator,
      event_titles[i],
      'Збираємось невеликою компанією. Новачкам раді — досвід не потрібен, '
        || 'головне гарний настрій.',
      event_locations[1 + ((i - 1) % array_length(event_locations, 1))],
      now() + ((i * 2) || ' days')::interval + interval '18 hours',
      ARRAY['https://api.dicebear.com/9.x/shapes/png?size=600&seed=event' || i::text],
      v_tags,
      4 + (i % 12),
      (i % 6 = 0),          -- кожна шоста подія приватна
      v_vec::vector,
      point(v_lat, v_long)
    )
    RETURNING id INTO v_event_id;

    -- Груповий чат, як його створює create_event_with_chat
    INSERT INTO rooms (is_group, type, name, avatar_url, event_id, last_message, last_message_time)
    VALUES (true, 'group', event_titles[i],
            'https://api.dicebear.com/9.x/shapes/png?size=600&seed=event' || i::text,
            v_event_id, 'Груповий чат створено 🥳', now())
    RETURNING id INTO v_room_id;

    INSERT INTO room_participants (room_id, profile_id) VALUES (v_room_id, v_creator);

    -- Кілька заявок на подію, щоб екран заявок не був порожній
    FOR k IN 1..(2 + (i % 3)) LOOP
      INSERT INTO event_participants (event_id, user_id, status, message)
      SELECT v_event_id,
             v_seeded[1 + ((i * 7 + k * 11) % array_length(v_seeded, 1))],
             CASE WHEN k = 1 THEN 'accepted' ELSE 'pending' END,
             CASE WHEN k = 2 THEN 'Привіт! Можна приєднатись?' ELSE NULL END
      WHERE v_seeded[1 + ((i * 7 + k * 11) % array_length(v_seeded, 1))] <> v_creator
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'створено: % профілів, % подій',
    array_length(v_seeded, 1), array_length(event_titles, 1);
END
$seed$;
