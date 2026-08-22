-- ============================================================================
-- Контрольований набір для перевірки ранжування.
--
-- Скидає всі зв'язки живих акаунтів (лайки, метчі, чати, заявки), щоб можна
-- було свайпати заново, і створює сім профілів, кожен з яких перевіряє рівно
-- один сигнал ранжування. Профілі названі за своєю роллю, тож у застосунку
-- одразу видно, хто має бути де.
--
-- Запуск (можна повторювати):
--   psql "$DATABASE_URL" -f supabase/seed_ranking_test.sql
-- ============================================================================

-- --------------------------------------------------------------- очищення
-- Живі акаунти — це ті, чиї телефони не з тестових діапазонів.
CREATE OR REPLACE FUNCTION pg_temp.real_users() RETURNS SETOF uuid
LANGUAGE sql AS $$
  SELECT id FROM public.profiles
  WHERE phone IS NULL
     OR (phone NOT LIKE '+38099000%' AND phone NOT LIKE '+38099100%' AND phone NOT LIKE '+38099200%');
$$;

-- чати живих акаунтів (повідомлення та учасники приберуться каскадом)
DELETE FROM public.rooms r
WHERE EXISTS (
  SELECT 1 FROM public.room_participants rp
  WHERE rp.room_id = r.id AND rp.profile_id IN (SELECT pg_temp.real_users())
);

DELETE FROM public.likes
WHERE sender_id IN (SELECT pg_temp.real_users())
   OR receiver_id IN (SELECT pg_temp.real_users());

DELETE FROM public.event_participants WHERE user_id IN (SELECT pg_temp.real_users());
DELETE FROM public.event_likes        WHERE user_id IN (SELECT pg_temp.real_users());

-- попередній львівський набір прибираємо, щоб не заважав чистоті тесту
DELETE FROM auth.users WHERE phone LIKE '+38099100%';
DELETE FROM auth.users WHERE phone LIKE '+38099200%';


-- --------------------------------------------------------------- профілі
DO $test$
DECLARE
  -- Точка відліку — фактична позиція живого акаунта Max (Львів).
  base_lat  double precision;
  base_long double precision;

  -- 1 км ≈ 0.009° широти, 40 км ≈ 0.36°
  km1  constant double precision := 0.009;
  km40 constant double precision := 0.360;

  same_tags  text[] := ARRAY['Програмування','Фотографія','Похід з наметом','Настільні ігри'];
  other_tags text[] := ARRAY['Танці','Кулінарія','Плавання','Йога'];
  half_tags  text[] := ARRAY['Програмування','Фотографія','Танці','Йога'];

  v_id uuid;
  me   uuid;


  -- (назва, теги, зсув широти, години з останньої активності)
  specs text[][] := ARRAY[
    ARRAY['А · Ті самі хобі, поруч',        'same',  '1',  '1'],
    ARRAY['Б · Ті самі хобі, далеко',       'same',  '40', '1'],
    ARRAY['В · Інші хобі, поруч',           'other', '1',  '1'],
    ARRAY['Г · Інші хобі, далеко',          'other', '40', '1'],
    ARRAY['Д · Половина хобі, поруч',       'half',  '1',  '1'],
    ARRAY['Е · Ті самі хобі, поруч, зник',  'same',  '1',  '720'],
    ARRAY['Ж · Ті самі хобі, поруч, лайкнув','same', '1',  '1']
  ];
  spec text[];
  i int := 0;
  v_tags text[];
  v_vec text;
  v_offset double precision;
  v_hours int;
BEGIN
  SELECT id, location_point[0], location_point[1]
    INTO me, base_lat, base_long
  FROM public.profiles
  WHERE full_name = 'Max'
  LIMIT 1;

  IF me IS NULL THEN
    RAISE EXCEPTION 'не знайдено профіль Max — вкажіть інший орієнтир';
  END IF;

  -- Живим акаунтам ставимо той самий набір хобі, щоб спорідненість була
  -- передбачуваною незалежно від того, під ким увійти.
  UPDATE public.profiles SET hobbies = same_tags
  WHERE id IN (SELECT pg_temp.real_users());

  FOREACH spec SLICE 1 IN ARRAY specs LOOP
    i := i + 1;
    v_id := gen_random_uuid();

    v_tags := CASE spec[2]
                WHEN 'same'  THEN same_tags
                WHEN 'other' THEN other_tags
                ELSE half_tags
              END;
    v_offset := CASE spec[3] WHEN '1' THEN km1 ELSE km40 END;
    v_hours  := spec[4]::int;

    INSERT INTO auth.users (id, phone, instance_id, aud, role, created_at, updated_at)
    VALUES (v_id, '+38099200' || lpad(i::text, 4, '0'),
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated', now(), now());

    UPDATE public.profiles SET
      full_name      = spec[1],
      birth_date     = (now() - interval '25 years')::date,
      bio            = 'Тестовий профіль для перевірки підбору: ' || spec[1],
      location       = 'Львів',
      hobbies        = v_tags,
      -- DiceBear віддає CORS-заголовки, pravatar — ні.
      photos         = ARRAY['https://api.dicebear.com/9.x/avataaars/png?size=600&seed=' || v_id::text],
      location_point = point(base_lat + v_offset, base_long),
      last_active_at = now() - (v_hours || ' hours')::interval,
      updated_at     = now()
    WHERE id = v_id;

    -- «Ж» уже лайкнув живі акаунти — перевіряє сигнал взаємності
    IF spec[1] LIKE 'Ж%' THEN
      INSERT INTO public.likes (sender_id, receiver_id, is_like, is_accepted)
      SELECT v_id, u, true, false FROM pg_temp.real_users() u
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;

  RAISE NOTICE 'створено % тестових профілів', i;
END
$test$;

-- Ваги інтересів — матеріалізоване подання; без оновлення нові хобі мають
-- нульову вагу і спорідненість завжди виходить 0.
SELECT public.refresh_interest_weights();
