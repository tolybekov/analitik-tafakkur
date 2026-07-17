-- Analitik Tafakkur Supabase setup
-- Run this whole file once in Supabase Dashboard -> SQL Editor.
-- Change the professor invite code below before inviting real teachers.

create extension if not exists pgcrypto;

create table if not exists public.app_config (
  id boolean primary key default true check (id),
  professor_invite_code text not null default 'ustoz-2026',
  updated_at timestamptz not null default now()
);

insert into public.app_config (id, professor_invite_code)
values (true, 'ustoz-2026')
on conflict (id) do nothing;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('student', 'professor')),
  full_name text not null,
  school text not null,
  grade integer check (grade between 5 and 9),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id text primary key,
  grade integer not null check (grade between 5 and 9),
  subject text not null,
  style text not null check (style in ('case', 'swot', 'fishbone', 'insert', 'venn', 'debate', 'disney', 'reflexive')),
  title text not null,
  topic text not null,
  context text not null,
  question text not null,
  steps jsonb not null default '[]'::jsonb,
  rubric jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  task_id text not null references public.tasks(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  status text not null default 'waiting' check (status in ('waiting', 'graded')),
  score integer check (score between 0 and 100),
  feedback text not null default '',
  submitted_at timestamptz not null default now(),
  graded_at timestamptz,
  graded_by uuid references public.profiles(id) on delete set null
);


create table if not exists public.demo_scoreboard_records (
  id text primary key,
  anonymous_id text not null unique,
  grade integer not null check (grade between 5 and 9),
  task_title text not null,
  score integer not null check (score between 0 and 100),
  submitted_at timestamptz not null default now(),
  graded_at timestamptz not null default now()
);

create or replace function public.is_professor(user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = user_id
      and role = 'professor'
  );
$$;

create or replace function public.complete_profile(
  p_full_name text,
  p_school text,
  p_grade integer,
  p_role text,
  p_professor_code text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to complete a profile.';
  end if;

  if p_role not in ('student', 'professor') then
    raise exception 'Unsupported role.';
  end if;

  if length(trim(coalesce(p_full_name, ''))) < 2 then
    raise exception 'Full name is required.';
  end if;

  if length(trim(coalesce(p_school, ''))) < 2 then
    raise exception 'School or organization is required.';
  end if;

  if p_role = 'student' and (p_grade is null or p_grade not between 5 and 9) then
    raise exception 'Students must select grade 5, 6, 7, 8, or 9.';
  end if;

  if p_role = 'professor' and not exists (
    select 1
    from public.app_config
    where id = true
      and professor_invite_code = coalesce(p_professor_code, '')
  ) then
    raise exception 'Professor invite code is incorrect.';
  end if;

  insert into public.profiles (id, role, full_name, school, grade, updated_at)
  values (
    auth.uid(),
    p_role,
    trim(p_full_name),
    trim(p_school),
    case when p_role = 'student' then p_grade else null end,
    now()
  )
  on conflict (id) do update set
    role = excluded.role,
    full_name = excluded.full_name,
    school = excluded.school,
    grade = excluded.grade,
    updated_at = now()
  returning * into v_profile;

  return v_profile;
end;
$$;

alter table public.app_config enable row level security;
alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.submissions enable row level security;

alter table public.demo_scoreboard_records enable row level security;


drop policy if exists "profiles_read_own_or_professor" on public.profiles;
drop policy if exists "tasks_public_read_active" on public.tasks;
drop policy if exists "tasks_professor_manage" on public.tasks;
drop policy if exists "submissions_read_own_or_professor" on public.submissions;
drop policy if exists "submissions_student_insert" on public.submissions;
drop policy if exists "submissions_professor_update" on public.submissions;

drop policy if exists "demo_scoreboard_public_read" on public.demo_scoreboard_records;


create policy "profiles_read_own_or_professor"
on public.profiles
for select
to authenticated
using (id = auth.uid() or public.is_professor(auth.uid()));

create policy "tasks_public_read_active"
on public.tasks
for select
to anon, authenticated
using (is_active = true);

create policy "tasks_professor_manage"
on public.tasks
for all
to authenticated
using (public.is_professor(auth.uid()))
with check (public.is_professor(auth.uid()));

create policy "submissions_read_own_or_professor"
on public.submissions
for select
to authenticated
using (student_id = auth.uid() or public.is_professor(auth.uid()));

create policy "submissions_student_insert"
on public.submissions
for insert
to authenticated
with check (
  student_id = auth.uid()
  and exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'student'
  )
);

create policy "submissions_professor_update"
on public.submissions
for update
to authenticated
using (public.is_professor(auth.uid()))
with check (public.is_professor(auth.uid()));


create policy "demo_scoreboard_public_read"
on public.demo_scoreboard_records
for select
using (true);

grant usage on schema public to anon, authenticated;
grant select on public.tasks to anon, authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update on public.submissions to authenticated;
grant insert, update, delete on public.tasks to authenticated;
grant execute on function public.complete_profile(text, text, integer, text, text) to authenticated;
grant execute on function public.is_professor(uuid) to authenticated;

grant select on public.demo_scoreboard_records to anon, authenticated;


insert into public.tasks (id, grade, subject, style, title, topic, context, question, steps, rubric, is_active)
values
(
  'task-5-case-temur',
  5,
  'Tarix',
  'case',
  $$Amir Temur tuzuklari: adolatli qaror$$,
  $$Davlat boshqaruvi va mas'uliyat$$,
  $$Sinf kengashida ikki guruh bir xil kutubxona vaqtini so'ramoqda. Bir guruh tarix loyihasini yakunlashi kerak, ikkinchisi esa tarbiya darsidagi taqdimotga tayyorlanmoqda. Amir Temur tuzuklaridagi adolat, tartib va mas'uliyat g'oyalariga tayanib qaror qabul qiling.$$,
  $$Sinf sardori sifatida qaysi qarorni tanlaysiz va uni tarixiy tamoyillar bilan qanday asoslay olasiz?$$,
  jsonb_build_array($$Vaziyatdagi asosiy muammoni belgilang.$$, $$Har bir guruh manfaatini va mas'uliyatini yozing.$$, $$Kamida ikki yechim taklif qiling.$$, $$Eng adolatli qarorni dalillar bilan himoya qiling.$$),
  jsonb_build_array($$Tarixiy tushuncha vaziyat bilan bog'langan.$$, $$Dalillar aniq va izchil keltirilgan.$$, $$Qaror ikki tomon manfaatini hisobga oladi.$$, $$Xulosa mas'uliyatli harakat rejasini beradi.$$),
  true
),
(
  'task-5-insert-silk-road',
  5,
  'Tarix',
  'insert',
  $$Buyuk ipak yo'li va shaharlardagi bilim almashinuvi$$,
  $$Samarqand, Buxoro va Xiva$$,
  $$Buyuk ipak yo'li savdo, hunarmandchilik, ilm va madaniyat almashinuviga xizmat qilgan. O'zbekiston hududidagi qadimiy shaharlar turli xalqlar uchrashgan markaz bo'lgan.$$,
  $$Matndagi ma'lumotlarni INSERT usulida tahlil qiling: qaysi fikrlarni oldindan bilardingiz, qaysilari yangi, qaysi fikrlar savol tug'diradi?$$,
  jsonb_build_array($$V belgisi ostiga avval bilgan ma'lumotlaringizni yozing.$$, $$+ belgisi ostiga yangi ma'lumotlarni kiriting.$$, $$- belgisi ostiga sizni o'ylantirgan yoki boshqacha ko'ringan fikrni yozing.$$, $$? belgisi ostiga qo'shimcha izlanish savolini yozing.$$),
  jsonb_build_array($$Har bir belgi mazmunli to'ldirilgan.$$, $$Savollar mavzuga mos va izlanishga undaydi.$$, $$Fikrlar tarixiy tushuncha bilan bog'langan.$$, $$Yakuniy kuzatuv aniq yozilgan.$$),
  true
),
(
  'task-6-venn-sogd-bactria',
  6,
  'Tarix',
  'venn',
  $$So'g'd va Baqtriya: o'xshashlik va farqlar$$,
  $$Qadimgi davlatlar$$,
  $$So'g'd va Baqtriya qadimgi O'rta Osiyo tarixida muhim o'rin egallagan. Ikkalasida ham shahar madaniyati, savdo aloqalari va boshqaruv shakllari rivojlangan, ammo ularning geografik joylashuvi va tashqi aloqalari turlicha bo'lgan.$$,
  $$Venn diagramma orqali So'g'd va Baqtriyaning farqli va umumiy jihatlarini tahlil qiling.$$,
  jsonb_build_array($$So'g'dga xos uchta jihatni yozing.$$, $$Baqtriyaga xos uchta jihatni yozing.$$, $$Ikkalasiga umumiy bo'lgan kamida uchta jihatni belgilang.$$, $$Qaysi umumiy jihat tarixiy rivojlanishda eng muhim bo'lganini tushuntiring.$$),
  jsonb_build_array($$Farqlar va o'xshashliklar ajratilgan.$$, $$Geografiya, savdo va madaniyat hisobga olingan.$$, $$Xulosa sabab-oqibat aloqasini ko'rsatadi.$$, $$Tushunchalar aniq va tartibli yozilgan.$$),
  true
),
(
  'task-6-fishbone-zarafshan',
  6,
  'Tarix',
  'fishbone',
  $$Zarafshon vohasida shaharlarning rivojlanishi$$,
  $$Sabab va oqibat$$,
  $$Vohalarda suv manbalari, savdo yo'llari, hunarmandchilik va dehqonchilik shaharlar paydo bo'lishiga ta'sir qilgan. Har bir omil boshqa omillar bilan bog'liq bo'lgan.$$,
  $$Fishbone usulida shaharlarning rivojlanishiga olib kelgan asosiy sabablarni guruhlang.$$,
  jsonb_build_array($$Asosiy oqibatni yozing: shaharlarning rivojlanishi.$$, $$Tabiiy sharoit, inson omili, savdo va boshqaruv sabablarini ajrating.$$, $$Har bir sababga bitta tarixiy izoh qo'shing.$$, $$Eng kuchli sababni tanlab, nima uchunligini yozing.$$),
  jsonb_build_array($$Sabablar to'g'ri guruhlangan.$$, $$Har bir sabab oqibat bilan bog'langan.$$, $$Tarixiy izohlar mavzuga mos.$$, $$Eng muhim sabab asoslangan.$$),
  true
),
(
  'task-7-swot-khorezmshah',
  7,
  'Tarix',
  'swot',
  $$Xorazmshohlar davlati: imkoniyat va xatarlar$$,
  $$O'rta asrlar boshqaruvi$$,
  $$Xorazmshohlar davlati keng hudud, savdo yo'llari va harbiy salohiyatga ega bo'lgan. Shu bilan birga ichki nizolar, diplomatik xatolar va tashqi bosim davlat barqarorligiga ta'sir ko'rsatgan.$$,
  $$SWOT tahlil yordamida Xorazmshohlar davlatining kuchli va zaif tomonlarini, imkoniyat va xatarlarini ko'rsating.$$,
  jsonb_build_array($$Kuchli tomonlarni tarixiy dalillar bilan yozing.$$, $$Zaif tomonlarni boshqaruv va birlik nuqtai nazaridan ko'rsating.$$, $$Mavjud imkoniyatlarni savdo va diplomatiya bilan bog'lang.$$, $$Xatarlarni tashqi va ichki omillarga ajrating.$$),
  jsonb_build_array($$SWOT bo'limlari to'liq to'ldirilgan.$$, $$Tarixiy dalillar mavzuga mos.$$, $$Ichki va tashqi omillar farqlangan.$$, $$Xulosa strategik fikrni ko'rsatadi.$$),
  true
),
(
  'task-7-debate-navoiy',
  7,
  'Tarbiya',
  'debate',
  $$Alisher Navoiy qarashlari: bilim va odob$$,
  $$Ma'naviyat va ta'lim$$,
  $$Alisher Navoiy asarlarida ilm, odob, mehnat va insoniylik qadri ulug'lanadi. Bugungi maktab hayotida ham bilim va odob bir-birini to'ldiradi.$$,
  $$Debat shaklida fikr bildiring: 'Bilim kuchli bo'lishi uchun odob va mas'uliyat zarur'. Ushbu fikrni yoqlang yoki unga qarshi asosli munosabat bildiring.$$,
  jsonb_build_array($$O'z pozitsiyangizni aniq tanlang.$$, $$Kamida ikki dalil yozing.$$, $$Qarshi fikr bo'lishi mumkin bo'lgan nuqtani ko'rsating.$$, $$Qarshi fikrga javob va yakuniy xulosa yozing.$$),
  jsonb_build_array($$Pozitsiya ravshan bildirilgan.$$, $$Dalillar tarbiya va adabiy meros bilan bog'langan.$$, $$Qarshi fikr hurmat bilan tahlil qilingan.$$, $$Xulosa amaliy hayotga ulanadi.$$),
  true
),
(
  'task-8-disney-jadid-school',
  8,
  'Tarix',
  'disney',
  $$Jadid maktabi uchun islohot rejasi$$,
  $$Jadidchilik va ta'lim$$,
  $$Jadidlar yangi usul maktablari orqali savodxonlik, dunyoviy fanlar va milliy uyg'onish g'oyalarini kuchaytirishga harakat qilgan. Har bir islohot orzu, real imkoniyat va tanqidiy bahoni talab qiladi.$$,
  $$Walt Disney strategiyasi orqali jadid maktabini rivojlantirish rejasini tuzing.$$,
  jsonb_build_array($$Orzuchi sifatida ideal maktab qanday bo'lishini tasvirlang.$$, $$Realist sifatida mavjud resurslar va birinchi qadamlarni yozing.$$, $$Tanqidchi sifatida xavf va to'siqlarni belgilang.$$, $$Uch rolni birlashtirib aniq harakat rejasini tuzing.$$),
  jsonb_build_array($$Uch rol alohida va mazmunli ishlatilgan.$$, $$Reja tarixiy sharoitga mos.$$, $$Xavflar real ko'rsatilgan.$$, $$Harakat rejasi aniq va bajariladigan.$$),
  true
),
(
  'task-8-case-khanate',
  8,
  'Tarix',
  'case',
  $$Qo'qon xonligida mahalliy boshqaruv$$,
  $$Boshqaruv va ijtimoiy hayot$$,
  $$Mahalliy boshqaruvda soliq, xavfsizlik, savdo va aholi ehtiyojlari muvozanatda turishi kerak. Agar bozorda tartib buzilsa, aholi va savdogarlar ishonchi pasayadi.$$,
  $$Qo'qon xonligi davridagi mahalliy hokim sifatida bozordagi nizoni qanday hal qilgan bo'lardingiz?$$,
  jsonb_build_array($$Nizoning iqtisodiy va ijtimoiy sabablarini yozing.$$, $$Aholi, savdogar va boshqaruv manfaatlarini ajrating.$$, $$Adolatli tartib uchun ikki taklif bering.$$, $$Qaroringizning mumkin bo'lgan oqibatini baholang.$$),
  jsonb_build_array($$Muammo tarixiy sharoitda ko'rib chiqilgan.$$, $$Manfaatdor tomonlar ajratilgan.$$, $$Takliflar amaliy va adolatli.$$, $$Oqibatlar tahlil qilingan.$$),
  true
),
(
  'task-9-fishbone-independence',
  9,
  'Tarbiya',
  'fishbone',
  $$Mustaqillikdan keyingi ta'lim islohotlari$$,
  $$Ta'lim va fuqarolik mas'uliyati$$,
  $$Mustaqillikdan keyingi davrda ta'lim tizimi milliy qadriyatlar, zamonaviy bilim, kadrlar tayyorlash va fuqarolik mas'uliyatini uyg'unlashtirishga intildi.$$,
  $$Fishbone orqali ta'lim islohotlariga ta'sir qilgan asosiy omillarni tahlil qiling.$$,
  jsonb_build_array($$Asosiy oqibatni yozing: ta'lim sifatini oshirish zarurati.$$, $$Qonunchilik, jamiyat ehtiyoji, iqtisodiy talab va texnologiya omillarini ajrating.$$, $$Har bir omilga misol yozing.$$, $$Qaysi omil eng tez ta'sir qilganini asoslang.$$),
  jsonb_build_array($$Omillar aniq guruhlangan.$$, $$Har bir omil misol bilan tushuntirilgan.$$, $$Sabab-oqibat aloqasi bor.$$, $$Xulosa mustaqil fikrni ko'rsatadi.$$),
  true
),
(
  'task-9-reflective-citizen',
  9,
  'Tarbiya',
  'reflexive',
  $$Faol fuqaro va maktab jamoasi$$,
  $$Fuqarolik pozitsiyasi$$,
  $$Faol fuqaro o'z huquqini biladi, majburiyatini bajaradi va jamoa muammolariga befarq bo'lmaydi. Maktabdagi kichik tashabbuslar ham fuqarolik madaniyatini shakllantiradi.$$,
  $$Refleksiv savollar orqali o'zingizning fuqarolik pozitsiyangizni baholang.$$,
  jsonb_build_array($$Mavzudan nimani o'rganganingizni yozing.$$, $$Sizni o'ylantirgan yoki hayratlantirgan jihatni belgilang.$$, $$Maktab jamoasida bajarishingiz mumkin bo'lgan bitta tashabbusni yozing.$$, $$Tashabbus qanday natija berishini taxmin qiling.$$),
  jsonb_build_array($$Shaxsiy xulosa samimiy va aniq.$$, $$Fuqarolik mas'uliyati tushuntirilgan.$$, $$Tashabbus real va foydali.$$, $$Natija taxmini asoslangan.$$),
  true
)
on conflict (id) do update set
  grade = excluded.grade,
  subject = excluded.subject,
  style = excluded.style,
  title = excluded.title,
  topic = excluded.topic,
  context = excluded.context,
  question = excluded.question,
  steps = excluded.steps,
  rubric = excluded.rubric,
  is_active = excluded.is_active,
  updated_at = now();



with pasted_tasks as (
  select *
  from jsonb_to_recordset($tasks$[
  {
    "id": "task-5-case-nil-daryosi-toshqini-va-birinchi-kalendar",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "case",
    "title": "Nil daryosi toshqini va birinchi kalendar",
    "topic": "Nil daryosi toshqini va birinchi kalendar",
    "context": "Qadimgi Misrda odamlar hayoti Nil daryosining toshishiga bog'liq edi. Ular daryo toshishidan oldin to'g'onlarni ochib, kanallarni tozalashlari kerak edi. Daryo toshqinlari orasidagi vaqt 365 kunni tashkil etishini kuzatgan misrliklar o'zlarining ilk kalendarlarini yaratdilar. Biroq, ularning hisob-kitobida har 4 yilda 1 kunlik xatolik yuzaga kelardi.",
    "question": "Nima sababdan Qadimgi Misrda kalendar yaratish ehtiyoji aynan dehqonchilik va daryo toshqini bilan bog'liq bo'ldi? Ularning kalendaridagi 1 kunlik xatolikning asl sababi nimada edi?",
    "steps": [
      "Odamlarning dehqonchilik va tabiat hodisalariga (Nil daryosiga) qaramligini ko'rsating.",
      "365 kun 12 oyga bo'lingani va oxirgi 5 kun bayram qilinganini tushuntiring.",
      "Yil aslida 365 kun emas, balki undan 6 soat ko'proq ekanligi (shuning hisobiga har 4 yilda 1 kun yig'ilishi) haqida xulosa yozing."
    ],
    "rubric": [
      "Kalendar va insoniyatning xo'jalik ehtiyoji o'rtasidagi bog'liqlik aniq ochib berilgan.",
      "Misr kalendarining tuzilishi (30 kundan 12 oy + 5 kun) to'g'ri ta'riflangan.",
      "6 soatlik farq qanday qilib xatoga olib kelgani mantiqiy xulosalangan."
    ]
  },
  {
    "id": "task-5-case-avesto-va-moddiy-manbalarning-topilishi",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "case",
    "title": "\"Avesto\" va moddiy manbalarning topilishi",
    "topic": "\"Avesto\" va moddiy manbalarning topilishi",
    "context": "Arxeologlar qadimgi odamlar yashagan manzilgohlarni qazib, mehnat qurollari, tangalar va qoldiqlar topishadi (moddiy manbalar). Shu bilan birga, olimlar \"Avesto\" kitobidek qadimiy qo'lyozmalarni ham o'rganadilar (yozma manbalar). Bu orqali qadimgi o'tmishimiz to'liq tiklanadi.",
    "question": "Agar siz O'zbekiston tarixini o'rganayotgan tadqiqotchi bo'lsangiz, o'tmishni tiklash uchun moddiy manbalarga ko'proq tayanarmidingiz yoki yozma manbalarga? Har ikkisining o'rnini tahlil qiling.",
    "steps": [
      "Moddiy manbalar (tangalar, qurollar) voqeaning aniq isboti ekanligini yozing.",
      "Yozma manbalar (Avesto) insonlarning ismlari, qonunlari va dinlari haqida gapirib berishini tahlil qiling.",
      "Yozuvi bo'lmagan qadimiy davrlarni faqat moddiy manbalar orqali o'rganish mumkinligini tushuntiring."
    ],
    "rubric": [
      "Moddiy va yozma manbalarning vazifalari aniq farqlangan.",
      "\"Avesto\"ning o'zbek davlatchiligidagi o'rni to'g'ri tasvirlangan.",
      "Har ikki manba turining bir-birini to'ldirishi mantiqiy isbotlangan.",
      "2.",
      "SWOT TAHLIL (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-swot-yozma-manbalar-kitoblar-qolyozmalar-arxividagi-hujjatlar",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "swot",
    "title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "topic": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "context": "Insoniyat 5 ming yil oldin yozuvni ixtiro qildi. Ular tosh, daraxt po'stlog'i, teri va nihoyat qog'ozga yoza boshladilar. Bu tarixni o'rganishda katta yengillik yaratdi.",
    "question": "SWOT tahlili yordamida yozma manbalarning tarixni saqlashdagi kuchli va zaif tomonlarini baholang.",
    "steps": [
      "Kuchli tomonlarga tarixiy ismlar, sanalar va qonunlarni aniq yozib qoldirish imkoniyatini yozing.",
      "Zaif tomonlarga qog'oz va terining vaqt o'tishi bilan chirishi yoki yonib ketishi tezligini ko'rsating.",
      "Imkoniyatlarga kelajak avlodga arxivlar orqali katta hajmdagi bilimlarni yetkazishni yozing.",
      "Xavflarga yozuvni bilmagan odam o'qiy olmasligi va kitoblarning urushlarda yo'q qilinishi xavfini kiriting."
    ],
    "rubric": [
      "Yozma manbalarning tarix fani uchun ahamiyati ko'rsatilgan.",
      "Qog'oz va teri ashyolarining moddiy xususiyatlari (zaifligi) to'g'ri baholangan.",
      "Kuchli tomonlar / Zaif tomonlar / Imkoniyatlar / Xavflar jadvali to'liq to'ldirilgan."
    ]
  },
  {
    "id": "task-5-swot-yuliy-kalendari",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "swot",
    "title": "Yuliy kalendari",
    "topic": "Yuliy kalendari",
    "context": "Rim imperatori Yuliy Sezar miloddan avvalgi 46-yilda Misr kalendaridagi xatoni to'g'rilab, har 4 yilda fevral oyini 29 kun deb belgilagan yangi kalendar joriy etdi.",
    "question": "SWOT tahlil yordamida Yuliy kalendarining kuchli va zaif tomonlarini tahlil qiling.",
    "steps": [
      "Kuchli tomonlarga kabisa yilini (366 kun) kiritish orqali 6 soatlik farqni yo'qotganini yozing.",
      "Zaif tomonlarga 1582-yilga kelib bu kalendarda ham 10 kunlik xatolik yig'ilib qolganini ko'rsating.",
      "Imkoniyatlarga Yevropa xalqlari uchun tartibli yil hisobini (1-yanvardan boshlanishini) joriy qilganini yozing.",
      "Xavflarga bahorgi tengkunlik (Navro'z) 21-martdan 11-martga siljib qolishi xavfini kiriting."
    ],
    "rubric": [
      "Kalendar islohotining asl maqsadi to'g'ri tushuntirilgan.",
      "10 kunlik xatolik yuzaga kelish sababi to'g'ri joylashtirilgan.",
      "3.",
      "FISHBONE (BALIQ SKELETI) (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-fishbone-tarixiy-manbalarning-turlari-va-ahamiyati",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "fishbone",
    "title": "Tarixiy manbalarning turlari va ahamiyati",
    "topic": "Tarixiy manbalarning turlari va ahamiyati",
    "context": "Tarix fani faqat taxminlar bilan emas, balki aniq tarixiy manbalar (moddiy va yozma) asosida yoziladi.",
    "question": "Fishbone tahlilidan foydalanib, tarixchi olimlarga o'tmishni o'rganishda xizmat qiladigan manbalar turlarini (yuqori suyaklar) va ularga misollarni (quyi suyaklar) ko'rsating, so'ng xulosa chiqaring.",
    "steps": [
      "Bosh (Natija): Tarix fanini yaratish.",
      "1-sabab (Moddiy): Arxeologik topilmalar — tafsilot: tangalar, mehnat qurollari, xarobalar.",
      "2-sabab (Yozma): Qadimiy yozuvlar — tafsilot: \"Avesto\" , g'or devoridagi xatlar, kitoblar.",
      "3-sabab (Arxivlar): Tarixiy hujjatlar — tafsilot: davlat muhrlari va shartnomalar.",
      "4-sabab (Og'zaki - agar o'tilgan bo'lsa): Afsona va dostonlar — tafsilot: avloddan-avlodga o'tgan ertak va rivoyatlar."
    ],
    "rubric": [
      "Moddiy va yozma manbalar turlari to'g'ri tasniflangan.",
      "Har bir manbaga darslikka asoslangan aniq misollar (tangalar, Avesto) yozilgan."
    ]
  },
  {
    "id": "task-5-fishbone-kalendarlar-rivojlanishidagi-xatolar-va-ularning-yechimlari",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "fishbone",
    "title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "topic": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "context": "Insoniyat yilni to'g'ri hisoblash uchun turli davrlarda 3 ta asosiy kalendarga tayanib islohotlar qildi.",
    "question": "Fishbone tahlili orqali kalendarlarning takomillashib borish bosqichlari va ulardagi o'zgarishlarni tahlil qiling.",
    "steps": [
      "Bosh (Muammo/Natija): Mukammal yil hisobini (kalendar) yaratish.",
      "1-omil (Misr kalendari): Asos yaratilishi — tafsilot: 365 kun, 12 oy, ammo har 4 yilda 1 kunlik xato.",
      "2-omil (Yuliy kalendari): Kabisa yilining joriy qilinishi — tafsilot: har 4 yilda fevralni 29 kun qilib xatoni to'g'rilash (Sezar islohoti).",
      "3-omil (Grigoriy kalendari): 10 kunlik xatoning yo'qotilishi — tafsilot: 1582-yilda papa Grigoriy XIII tomonidan yil hisobining to'g'rilanishi.",
      "4-omil (Hijriy yil hisobi): Muqobil o'lchov — tafsilot: 622-yilda Payg'ambarimizning Makkadan Madinaga ko'chishi asosidagi taqvim."
    ],
    "rubric": [
      "Kalendarlarning 3 ta tarixiy bosqichi aniq ko'rsatilgan.",
      "Islohotlar sababi (matematik xatolar) to'g'ri keltirilgan.",
      "4.",
      "INSERT METODI (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-insert-era-va-xronologiya-tushunchasi",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "insert",
    "title": "Era va Xronologiya tushunchasi",
    "topic": "Era va Xronologiya tushunchasi",
    "context": "Bizning eramiz xronologiyasi Iso payg'ambar tug'ilgan yildan boshlab hisoblanadi. Undan oldin yuz bergan voqealar «miloddan avvalgi» yoki «eragacha» deb yuritiladi. Xronologiya (vaqt fani) voqealarning qachon sodir bo'lganini ko'rsatib, tarixni to'g'ri tushunishga yordam beradi. O'tmishda asrlar Rim raqamlari (masalan, I, V, X) bilan belgilangan. ",
    "question": "INSERT metodi orqali yuqoridagi matnni o'rganib chiqing va yil hisobi (era) hamda Rim raqamlarining ma'nosini tahlil qiling.",
    "steps": [
      "(V): Hozirgi yilimiz 2000-yillardan o'tganini bilardim. (+): \"Era\" so'zining asl ma'nosi arablardan emas, lotincha \"boshlang'ich san'at\" yoki \"tug'ilish\" ma'nosini bildirishini bilib oldim.",
      "Asrlar Rim raqamida yozilishi yangilik bo'ldi. (-): Barcha xalqlar yilni faqat 1-yanvardan hisoblagan deb o'ylardim (aslida xalqlar turlicha hisoblagan: yunonlar olimpiadadan, rimliklar shahar qurilishidan). (?): Nima uchun butun dunyo asrlarni yozishda faqat Rim raqamlaridan foydalanadi?"
    ],
    "rubric": [
      "Era va Xronologiya so'zlarining tub ma'nosi to'g'ri tushunilgan.",
      "Rim raqamlarining tarix fani xronologiyasidagi o'rni qayd etilgan."
    ]
  },
  {
    "id": "task-5-insert-vatan-tushunchasi-va-tarix",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "insert",
    "title": "Vatan tushunchasi va tarix",
    "topic": "Vatan tushunchasi va tarix",
    "context": "Vatan – biz tug'ilgan makon, kindik qonimiz tomgan tuproqdir. Tarixiy o'tmishsiz kelajak yo'q. Biror xalqni tobe qilmoqchi bo'lganlar birinchi bo'lib uning tarixini yashirishga va unuttirishga urinadilar. Tarix fani o'zligimizni, ajdodlarimiz kim bo'lganligini anglashga yordam beradi. ",
    "question": "Matnni INSERT usulida o'qing va tarix fanining nega faqat sanalarni yodlash emas, balki Vatan tuyg'usini shakllantiruvchi fan ekanligini izohlang.",
    "steps": [
      "(V): Vatanning muqaddas ekanligi va uni sevish kerakligini bilardim. (+): Dushmanlar millatni yengish uchun birinchi uning tarixini esdan chiqarishga urinishini anglab yetdim. (-): Tarix darsida faqat o'tgan janglar va shohlarning ismlari o'qitiladi deb o'ylardim. (?): Qadimiy ajdodlarimiz (To'maris, Spitamen) tarixi mening bugungi qahramonligimga qanday yordam berishi mumkin?"
    ],
    "rubric": [
      "\"O'tmishsiz kelajak yo'q\" g'oyasining mantig'i chuqur o'ylangan.",
      "Tarix fanining tarbiyaviy mohiyati to'g'ri ajratilgan.",
      "5.",
      "VENN DIAGRAMMA (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-venn-moddiy-manbalar-va-yozma-manbalar",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "venn",
    "title": "Moddiy manbalar va Yozma manbalar",
    "topic": "Moddiy manbalar va Yozma manbalar",
    "context": "Tarixiy o'tmishni olimlar (arxeologlar va tarixchilar) qadimiy buyumlar va qadimiy xatlar orqali tiklaydilar.",
    "question": "Venn diagrammasidan foydalanib, tarixiy manbalarning ikki asosiy turi: moddiy va yozma manbalarni qiyoslang.",
    "steps": [
      "Chap doira (Moddiy manbalar): Mehnat qurollari, tangalar, kiyimlar, qasr xarobalari, inson suyaklari; ularni asosan arxeologlar yer ostidan qazib oladilar.",
      "O'ng doira (Yozma manbalar): G'or devoridagi yozuvlar, qog'oz va kitoblar, arxiv hujjatlari (masalan, \"Avesto\"); arxivariuslar va tarixchilar tahlil qiladi.",
      "Kesishuv (O'xshashlik): Har ikkisi ham tarixiy o'tmishdan guvohlik beradi, muzeylarda saqlanadi, ajdodlar hayotini o'rganishda yordam beradi."
    ],
    "rubric": [
      "Manba turlarining o'ziga xos misollari to'g'ri joylashtirilgan.",
      "O'xshashlik qismida fanga qo'shadigan umumiy hissasi aniq yozilgan."
    ]
  },
  {
    "id": "task-5-venn-yuliy-kalendari-va-grigoriy-kalendari",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "venn",
    "title": "Yuliy kalendari va Grigoriy kalendari",
    "topic": "Yuliy kalendari va Grigoriy kalendari",
    "context": "Hozirgi biz foydalanayotgan kalendar (Grigoriy) aslida uzoq o'tmishdagi kalendarning (Yuliy) takomillashgan shaklidir.",
    "question": "Venn diagrammasi orqali Yuliy Sezar joriy qilgan kalendar va Rim papasi Grigoriy XIII kiritgan kalendardagi o'zgarishlarni taqqoslang.",
    "steps": [
      "Chap doira (Yuliy): Miloddan avvalgi 46-yilda joriy qilingan, kabisa yilida fevral 29 kun bo'lishini kiritgan, lekin asta-sekin yil davomida 10 kun orqada qolib ketgan.",
      "O'ng doira (Grigoriy): 1582-yilda qabul qilingan, yig'ilib qolgan 10 kunni o'rtadan olib tashlagan (4-oktabrdan birdan 15-oktabrga o'tilgan).",
      "Kesishuv (O'xshashlik): Ikkisi ham asosan 365 kunlik yilga suyanadi, yangi yil 1-yanvardan boshlanadi, birining xatosini ikkinchisi to'ldiradi."
    ],
    "rubric": [
      "10 kunlik farq tarixi (1582-yil voqeasi) aniq ajratilgan.",
      "Yuliyning kabisa (29 kun) kashfiyoti to'g'ri ifodalangan.",
      "6.",
      "DEBAT (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-debate-qaysi-manba-turi-ishonchliroq-yozmami-yoki-moddiy",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "debate",
    "title": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "topic": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "context": "Tarixchi kitobda yozilgan (yozma manba) xabarni haqiqat deb bilishi mumkin, lekin kimdir ataylab yolg'on yozib qoldirgan bo'lishi ham ehtimol. Arxeolog esa yer ostidan bitta idish parchasini topadi (moddiy manba) va u so'zlamasada, yoshi aniq bilinadi.",
    "question": "Debat shaklida fikr bildiring: 'Tarixiy o'tmishni o'rganishda arxeologik moddiy manbalar yozma manbalarga qaraganda ishonchliroq va haqqoniydir, chunki ularni soxtalashtirib bo'lmaydi. '",
    "steps": [
      "Pozitsiya: Moddiy manbalarni yoqlash yoki yozma bilimlarni ustun qo'yish.",
      "Dalil: Yozma manbalar inson hissiyoti va e'tiqodi ta'sirida o'zgarib ketishi mumkinligini (shohlar maqtalishi), moddiy manba (qozon, nayza) esa fakt ekanini dalillang.",
      "Qarshi fikrga javob: \"Moddiy manba aniq bo'lsa-da, u tilga kirmaydi va sirlarni (masalan, kishining ismi yoki urush sababini) aytib bera olmaydi, buning uchun baribir yozuv kerak\" deb raddiya bering."
    ],
    "rubric": [
      "Moddiy ashyo va hujjatning yutuq-kamchiliklari adolatli ko'rsatilgan.",
      "Beshinchi sinf o'quvchisi darajasidagi mantiqiy xulosa va isbot keltirilgan."
    ]
  },
  {
    "id": "task-5-debate-otmishni-organmasdan-ham-baxtli-yashash-mumkinmi",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "debate",
    "title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "topic": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "context": "Darslikning birinchi sahifasida \"Tarixiy o'tmishsiz kelajak yo'q\" deb yozilgan.",
    "question": "Debat shaklida fikr bildiring: 'Hozirgi zamon kompyuter va texnikalar davri. Uzoq o'tmishdagi qadimgi odamlarning suyaklari va eskirgan kalendarlarni o'rganish bizning zamonaviy hayotimizga hech qanday amaliy foyda keltirmaydi. ' Ushbu fikrni yoqlang yoki asosiylik bilan qoralang.",
    "steps": [
      "Pozitsiya: \"Tarixiy o'tmishsiz kelajak yo'q\" tushunchasi asosida tarixni yoqlash.",
      "Dalil: Bugungi zamonaviy davlatimiz va erkinligimiz o'sha ajdodlar xatolaridan to'g'ri xulosa qilingani uchun borligini tushuntiring.",
      "Qarshi fikrga javob: Texnika rivojlangan bo'lsa ham, texnikani boshqaruvchi inson o'z vatanini va qadriyatini bilmasa, boshqa xalqlarga oson tobe bo'lib qolishini asoslang."
    ],
    "rubric": [
      "Vatanga muhabbat va kelajak uchun tarixning o'rni dalillangan.",
      "O'quvchi shaxsiy mulohazasini erkin tushuntira olgan.",
      "7.",
      "WALT DISNEY STRATEGIYASI (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-disney-bizning-sinf-tarixiy-muzeyi-ni-yaratish",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "disney",
    "title": "Bizning sinf \"Tarixiy muzeyi\"ni yaratish",
    "topic": "Bizning sinf \"Tarixiy muzeyi\"ni yaratish",
    "context": "Tarixiy manbalar (moddiy va yozma) odatda muzeylar va arxivlarda saqlanadi.",
    "question": "Walt Disney strategiyasidan foydalanib (Xayolparast, Realist, Tanqidchi), maktabingizdagi bo'sh xonada \"O'zbekistonning eng qadimiy manbalari muzeyi\"ni yaratish loyihasini baholang.",
    "steps": [
      "Xayolparast sifatida: Qadimiy Misr toshqinlari ko'rinishidagi maketlar, \"Avesto\" ning ulkan nusxasi, devoriy g'or yozuvlari tushirilgan sirli muzey yaratishni tasavvur qiling.",
      "Realist sifatida: O'quvchilar va ustozlar yordamida uydagi eski buyumlar (kashtalar, eski tangalar, bobolarning eski xatlari) yig'ib kelib ko'rgazma tayyorlashni ko'rsating.",
      "Tanqidchi sifatida: Haqiqiy qadimiy (arxeologik) qimmatbaho manbalarni maktabga olib kelish mumkin emasligi, ularni davlat qat'iy nazorat qilishini va xavfsizlik choralarini yozing."
    ],
    "rubric": [
      "Uchta rolning shartlariga to'laqonli va ijodiy yondashilgan.",
      "Muzey manbalarini yig'ish (moddiy va yozma) tushunchalari ishtirok etgan."
    ]
  },
  {
    "id": "task-5-disney-yoshlar-uchun-yangi-va-mukammal-kalendar-yaratish-loyihasi",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "disney",
    "title": "Yoshlar uchun yangi va mukammal Kalendar yaratish loyihasi",
    "topic": "Yoshlar uchun yangi va mukammal Kalendar yaratish loyihasi",
    "context": "Insoniyat Misr, Yuliy va Grigoriy kalendarlarida turli xatolar qilib, ularni takomillashtirdi.",
    "question": "Walt Disney strategiyasidan foydalanib, butunlay xatosiz va barcha davlatlar (jumladan tabiat fasllari) uchun qulay bo'lgan mutlaqo yangi \"Kelajak kalendari\"ni ishlab chiqish loyihasini tahlil qiling.",
    "steps": [
      "Xayolparast sifatida: Barcha oylar bir xil (masalan 30 kundan), qolib ketgan kunlar esa butun sayyora aholisi uchun bayram sifatida (oy nomisiz) nishonlanadigan qiziqarli va mutlaq aniq taqvim chizing.",
      "Realist sifatida: Yerni Quyosh atrofida aylanishi amalda matematik ravishda 365 kun, 5 soat, 48 minut va 46 soniya ekanligiga asoslanib, olimlar bilan soniyalarni ham to'g'ri hisoblaydigan formula tuzishni yozing.",
      "Tanqidchi sifatida: Odamlar va kompyuterlar yuz yillar davomida Grigoriy kalendariga (yanvar-dekabr) o'rganib qolgani, yangi kalendarga o'tish global chalkashlik (ayniqsa xronologiyada) keltirib chiqarishini asoslang."
    ],
    "rubric": [
      "Yil hisobining osmon jismlari bilan aloqasi to'g'ri e'tiborga olingan.",
      "Loyihadagi qarama-qarshiliklar (Realist vs Tanqidchi) mantiqan yoritilgan.",
      "8.",
      "REFLEKSIYA (5-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-5-reflexive-vatan-tarixi-mening-ozligim",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "reflexive",
    "title": "Vatan tarixi — mening o'zligim",
    "topic": "Vatan tarixi — mening o'zligim",
    "context": "Tarixiy o'tmishsiz kelajak yo'q\" . Insonning qalbi, orzu-umidlari, quvonchlari va kelajagi Vatan bilan chambarchas bog'liq.",
    "question": "Men 5-sinfda tarix fanini o'rganishni boshlar ekanman, ajdodlarim yashagan Vatan va uning o'tmishidagi qanday qahramonliklar men uchun ibrat bo'ladi va kelajakdagi orzularimga qanday qanot bag'ishlaydi? Shaxsiy xulosangizni yozing.",
    "steps": [
      "Vatan (ota-bobolarimiz izlari qolgan muqaddas tuproq) tushunchasi sizning hayotingizda qanday ma'no anglatishini bayon qiling.",
      "Necha ming yillardan buyon ajdodlarimiz O'zbekistonni jahonga tanitgani kabi, bugungi kunda yaxshi o'qishingiz bilan qanday hissa qo'shishingizni yozing.",
      "\"Hech kimga tobe bo'lmaslik uchun tarixni bilish kerak\" g'oyasini o'z xulosangizga joylashtiring."
    ],
    "rubric": [
      "O'quvchining vatanparvarlik va tarixdan g'ururlanish hissi yorqin ifodalangan.",
      "Darslikdagi kirish mavzusi mazmuni hayotiy xulosalarga to'g'ri bog'langan."
    ]
  },
  {
    "id": "task-5-reflexive-men-ham-tarix-guvohiman",
    "grade": 5,
    "subject": "Tarixdan hikoyalar",
    "style": "reflexive",
    "title": "Men ham tarix guvohiman",
    "topic": "Men ham tarix guvohiman",
    "context": "Ming yillar avvalgi odamlarning qoldirgan yozuvlari va tangalari bugungi bizlar uchun \"Tarixiy manba\" hisoblanadi. Demak, biz bugun yaratayotgan narsalar ertaga kelajak avlod uchun manbaga aylanadi.",
    "question": "Bugungi davrimizda internet, kompyuter va har xil telefonlar bor. Yana yuz yillardan so'ng, olimlar bizning asrimizni (XXI asrni) o'rganayotganda bizdan qanday qiziqarli \"moddiy\" va \"yozma\" (yoki elektron) manbalarni topishadi deb o'ylaysiz? Bu orqali qanday farzand sifatida tarixda qolishni istardingiz?",
    "steps": [
      "Hozirgi biz foydalanayotgan texnikalar asrlar o'tib eng zo'r arxeologik topilmalarga (moddiy manba) aylanishini qiziqarli tasavvur bilan yozing.",
      "Barcha yozma bilimlar elektron xotiralarda saqlanib qolayotgani va olimlar buni kelajakda qanday o'qib bilishlarini ifodalang.",
      "Siz yaratgan shaxsiy kashfiyot kelajak avlod tarix kitobidan qanday o'rin olishi haqida xulosangizni bayon qiling."
    ],
    "rubric": [
      "Tarixiy davriylik (era va vaqt davomiyligi) tushunchasi o'quvchida anglab yetilgan.",
      "Yosh yigit-qizning mas'uliyat hissi va ijodiy yondashuvi aks etgan."
    ]
  },
  {
    "id": "task-6-case-bobil-podshosi-xammurapi-qonunlari",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "case",
    "title": "Bobil podshosi Xammurapi qonunlari",
    "topic": "Bobil podshosi Xammurapi qonunlari",
    "context": "Qadimgi Bobil podshosi Xammurapi (mil. avv. 1792-1750-yillar) o'z davlatida tartib o'rnatish uchun mashhur qonunlar to'plamini yaratdi. Bu qonunlarda \"Kimgadir qanday ziyon yetkazilsa, uning o'ziga ham xuddi shunday ziyon yetkaziladi\" (ko'zga ko'z, tishga tish) tamoyili mavjud edi. Biroq, qullar va boylarga nisbatan jazo turlicha bo'lgan.",
    "question": "Nima sababdan Xammurapi o'z qonunlarini tosh ustunlarga yozdirib, shaharning markaziga o'rnatgan? Uning qonunlaridagi sinfiy (boy va kambag'al o'rtasidagi) farqlarni adolat nuqtai nazaridan qanday tahlil qilasiz?",
    "steps": [
      "Qonunlarning barcha ko'rishi va bilishi uchun ochiq e'lon qilinishining ahamiyatini yozing.",
      "\"Ko'zga ko'z\" tamoyilining ijobiy (jinoyatni to'xtatuvchi) va salbiy (shafqatsiz) tomonlarini ko'rsating.",
      "Jamiyatdagi tengsizlik qonunlarda qanday o'z aksini topganini tushuntiring."
    ],
    "rubric": [
      "Qadimgi sharq jamiyatida huquqiy davlat tushunchasi ochib berilgan.",
      "Xammurapi qonunlaridagi ijtimoiy tabaqalanish to'g'ri izohlangan."
    ]
  },
  {
    "id": "task-6-case-garbiy-rim-imperiyasining-qulashi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "case",
    "title": "G'arbiy Rim imperiyasining qulashi",
    "topic": "G'arbiy Rim imperiyasining qulashi",
    "context": "Qadimgi dunyoning eng qudratli davlati bo'lgan Rim imperiyasi asrlar o'tib zaiflashdi. 410-yilda Alarix boshchiligidagi gotlar Rimni qulatdi, 452-yilda Attila boshchiligidagi xunnlar Italiyaga bastirib kirdi. 455-yilda vandallar Rimni talon-toroj qildi. Nihoyat, 476-yilda G'arbiy Rim imperiyasi butunlay quladi.",
    "question": "Qanday qilib butun O'rta dengiz bo'yini o'ziga bo'ysundirgan qudratli Rim armiyasi \"varvarlar\" (yovvoyi qabilalar) hujumiga bardosh bera olmadi? Muammoning ichki (iqtisodiy) va tashqi sabablarini tahlil qiling.",
    "steps": [
      "Qullar mehnatiga asoslangan iqtisodiyotning inqirozga uchrashini yozing.",
      "Rim armiyasining yollanma askarlarga (germanlarga) tayanib qolgani oqibatlarini tushuntiring.",
      "Xalqlar buyuk ko'chishining Rimga ko'rsatgan ta'sirini baholang."
    ],
    "rubric": [
      "Davlatning qulashidagi ichki zaiflik aniq isbotlangan.",
      "Gotlar, xunnlar va vandallarning tarixiy ketma-ketligi to'g'ri tahlil qilingan.",
      "2.",
      "SWOT TAHLIL (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-swot-afina-va-spartaning-siyosiy-tuzumi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "swot",
    "title": "Afina va Spartaning siyosiy tuzumi",
    "topic": "Afina va Spartaning siyosiy tuzumi",
    "context": "Qadimgi Yunonistonda ikkita kuchli polis (shahar-davlat) mavjud bo'lib, Afinada xalq boshqaruvi (demokratiya), Spartada esa harbiy tartib va zodagonlar boshqaruvi (oligarxiya) o'rnatilgan edi.",
    "question": "SWOT tahlil yordamida Qadimgi Sparta harbiy davlatining salohiyatini baholang.",
    "steps": [
      "Kuchli tomonlarga Spartaning yengilmas piyoda qo'shini va qat'iy intizomini yozing.",
      "Zaif tomonlarga savdo-sotiq, ilm-fan va san'atning rivojlanmaganini ko'rsating.",
      "Imkoniyatlarga butun Peloponnes yarimorolini o'ziga bo'ysundirishini yozing.",
      "Xavflarga qullar (ilotlar)ning doimiy qo'zg'olon ko'tarish xavfi va Afinaning kuchayishini kiriting."
    ],
    "rubric": [
      "Sparta harbiy tuzumining foydasi va zarari aniq ko'rsatilgan.",
      "Madaniyatning orqada qolishi zaif tomon sifatida isbotlangan.",
      "Kuchli tomonlar / Zaif tomonlar / Imkoniyatlar / Xavflar to'g'ri to'ldirilgan."
    ]
  },
  {
    "id": "task-6-swot-iskandar-maqduniy-aleksandr-makedonskiy-imperiyasi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "swot",
    "title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "topic": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "context": "Iskandar Maqduniy qisqa vaqt ichida Yunonistondan to Hindistongacha bo'lgan ulkan hududlarni bosib olib, tarixdagi eng yirik imperiyalardan birini tuzdi. Biroq u vafot etgach, imperiya tezda parchalanib ketdi.",
    "question": "SWOT tahlili orqali Iskandar Maqduniy tuzgan ulkan davlatning qudrati va inqiroz omillarini tahlil qiling.",
    "steps": [
      "Kuchli tomonlarga Iskandarning mukammal harbiy taktikasi va yunon madaniyatining tarqalishini yozing.",
      "Zaif tomonlarga davlatning faqat qurol kuchi bilan ushlab turilgani va yagona iqtisodiy tizimning yo'qligini ko'rsating.",
      "Imkoniyatlarga Sharq va G'arb o'rtasida Buyuk Ipak yo'li orqali savdo va madaniy aloqalar o'rnatishni yozing.",
      "Xavflarga bo'ysundirilgan xalqlarning qo'zg'olonlari (masalan, Spitamen qo'zg'oloni) va sarkardalar o'rtasidagi taxt talashishni kiriting."
    ],
    "rubric": [
      "Imperiyaning hududiy kattaligi va ichki beqarorligi to'g'ri baholangan.",
      "Sharq va G'arb madaniyatining uyg'unlashuvi imkoniyat sifatida ko'rsatilgan.",
      "3.",
      "FISHBONE (BALIQ SKELETI) (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-fishbone-qadimgi-misrda-ehromlarning-piramidalarning-qurilishi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "fishbone",
    "title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "topic": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "context": "Fir'avnlar hayotlik chog'idayoq o'zlari uchun ulkan tosh ehromlar qurdira boshlashgan. Ularni qurishda yuz minglab qullar va dehqonlar yillab mehnat qilgan.",
    "question": "Fishbone tahlilidan foydalanib, Misr ehromlarining qurilishiga majbur qilgan diniy-siyosiy sabablarni va buning amaliy tafsilotlarini tahlil qiling.",
    "steps": [
      "Bosh (Natija/Muammo): Ulkan tosh piramidalarning bunyod etilishi (masalan, Xeops ehromi).",
      "1-sabab (Diniy): Narigi dunyoga ishonch — tafsilot: fir'avnning vafotidan so'ng jasadini mo'miyolab saqlash zarurati.",
      "2-sabab (Siyosiy): Fir'avnning qudrati — tafsilot: xalqqa fir'avnni xudo darajasida ko'rsatish va uning buyukligini isbotlash.",
      "3-sabab (Muhandislik): Aniq hisob-kitob — tafsilot: toshlarni kesish, yetkazib kelish uchun matematika va astronomiyaning rivojlangani.",
      "4-sabab (Ijtimoiy): Arzon ishchi kuchi — tafsilot: urush asirlari (qullar) va daryo toshqini paytida ishsiz qolgan dehqonlar mehnati."
    ],
    "rubric": [
      "Qadimgi misrliklarning diniy qarashlari piramidalar bilan to'g'ri bog'langan.",
      "Har bir sababning tarixiy isboti mantiqiy asoslangan."
    ]
  },
  {
    "id": "task-6-fishbone-xalqlarning-buyuk-kochishi-va-uning-oqibatlari",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "fishbone",
    "title": "Xalqlarning buyuk ko'chishi va uning oqibatlari",
    "topic": "Xalqlarning buyuk ko'chishi va uning oqibatlari",
    "context": "IV-VII asrlarda Osiyo va Yevropa qit'alarida ulkan ko'chishlar yuz berdi. Xunnlarning g'arbga yurishi boshqa qabilalarni ham o'z joylaridan siljitib yubordi.",
    "question": "Fishbone tahlili orqali \"Xalqlarning buyuk ko'chishi\" sabablari va uning antik dunyoga ko'rsatgan oqibatlarini ko'rsating.",
    "steps": [
      "Bosh (Natija): Xalqlarning buyuk ko'chishi (Antik davrning yakunlanishi).",
      "1-sabab (Iqlimiy): Iqlimning o'zgarishi — tafsilot: dashtlarda qurg'oqchilik sababli ko'chmanchilarning yangi yaylovlar qidirishi.",
      "2-sabab (Demografik): Aholining ko'payishi — tafsilot: qabilalarning ko'payib, oziq-ovqat yetishmovchiligi yuzaga kelishi.",
      "3-oqibat (Siyosiy): Rimning qulashi — tafsilot: 476-yilda yovvoyi qabilalar (germanlar) zarbidan G'arbiy Rimning yo'q bo'lishi.",
      "4-oqibat (Ijtimoiy-madaniy): Yangi xalqlarning paydo bo'lishi — tafsilot: qabilalarning aralashishi natijasida hozirgi Yevropa xalqlarining shakllanishi."
    ],
    "rubric": [
      "Ko'chishning iqtisodiy-iqlimiy sabablari to'g'ri ochilgan.",
      "Rim imperiyasi inqirozi ushbu ko'chishga mantiqan bog'langan.",
      "4.",
      "INSERT METODI (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-insert-qadimgi-hindistonda-kasta-tizimi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "insert",
    "title": "Qadimgi Hindistonda kasta tizimi",
    "topic": "Qadimgi Hindistonda kasta tizimi",
    "context": "Qadimgi Hindistonda jamiyat qat'iy toifalarga – kastalarga bo'lingan. Afsonaga ko'ra, xudo Braxma o'zining og'zidan kohinlarni (brahmanlarni), qo'lidan jangchilarni (kshatriylarni), sonidan dehqonlarni (vayshiylarni) va tovonidan xizmatkorlarni (shudralarni) yaratgan. Bir kastadan ikkinchisiga o'tish qat'iyan man etilgan. Eng og'ir ishlarni esa \"tegib bo'lmaydiganlar\" bajargan, ular bilan gaplashish ham taqiqlangan. ",
    "question": "Matnni INSERT usulida o'qing va jamiyatdagi sun'iy bo'linish (kasta)ning inson huquqlariga ta'sirini tahlil qiling.",
    "steps": [
      "(V): Qadimgi Hindiston jamiyatida boylar va kambag'allar bo'lganini bilardim. (+): Tabaqalar xudoning a'zolariga qarab bo'lingani va kastalar nomini o'rgandim. (-): Inson mehnati orqali qashshoqlikdan boylikka ko'tarilishi mumkin deb o'ylardim (Hindistonda kastadan kastaga o'tish taqiqlangan ekan). (?): \"Tegib bo'lmaydiganlar\"ning bunday shafqatsiz hayotga rozi bo'lib yashashiga nima majbur qilgan?",
      "Ularning dini shunday qismatni uqtirganmi?"
    ],
    "rubric": [
      "Tabaqalanishning (kasta) adolatsiz ekanligi to'g'ri his etilgan.",
      "INSERT belgilariga qo'yilgan ma'lumotlar aniq isbotlangan."
    ]
  },
  {
    "id": "task-6-insert-qadimgi-olimpiya-oyinlari",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "insert",
    "title": "Qadimgi Olimpiya o'yinlari",
    "topic": "Qadimgi Olimpiya o'yinlari",
    "context": "Yunonistonda har 4 yilda Zevs sharafiga Olimpiya o'yinlari o'tkazilgan. O'yinlar paytida barcha polislar (shaharlar) o'rtasidagi urushlar to'xtatilgan va muqaddas tinchlik e'lon qilingan. Faqat erkin yunon erkaklarigina musobaqalarda qatnashish huquqiga ega bo'lgan. G'oliblarga zaytun daraxti shoxidan yasalgan toj kiydirilgan, shaharda ular qahramon sifatida hurmat qilingan. ",
    "question": "Matnni INSERT jadvali orqali o'rganib, sport o'yinlarining qadimgi dunyoda tinchlik o'rnatishdagi rolini izohlang.",
    "steps": [
      "(V): Olimpiya o'yinlari Qadimgi Yunonistonda boshlanganini bilardim. (+): O'yinlar vaqtida barcha urushlar to'xtatilishini va g'olibga faqat zaytun shoxidan toj berilishini (oltin emasligini) bilib oldim. (-): Olimpiadada hamma xalqlar qatnashadi deb o'ylardim (lekin qullar va ayollar qatnashmagan ekan). (?): Nima uchun musobaqa aynan xudo Zevs sharafiga va aynan Olimpiya tog'ida o'tkazilgan?"
    ],
    "rubric": [
      "Olimpiya o'yinlarining siyosiy ahamiyati (tinchlik) tushunib yetilgan.",
      "Barcha 4 ta belgi o'z o'rnida to'g'ri ishlatilgan.",
      "5.",
      "VENN DIAGRAMMA (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-venn-qadimgi-misr-va-qadimgi-ikki-daryo-oraligi-mesopotamiya",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "venn",
    "title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "topic": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "context": "Insoniyat sivilizatsiyasi dastlab yirik daryolar bo'yida – Misrda Nil daryosi atrofida va Osiyoda Dajla va Furot daryolari oralig'ida vujudga keldi.",
    "question": "Venn diagrammasi yordamida Qadimgi Misr va Mesopotamiya davlatlarining jo'g'rofiyasi, yozuvi va madaniyatini taqqoslang.",
    "steps": [
      "Chap doira (Misr): Shimoliy Afrikada, Nil daryosi bo'yida joylashgan.",
      "Yozuvi ieroglif (rasmli yozuv).",
      "Davlat boshlig'i – fir'avn.",
      "Qog'oz sifatida papirusdan foydalanilgan.",
      "O'ng doira (Mesopotamiya): G'arbiy Osiyoda, Dajla va Furot daryolari oralig'ida.",
      "Yozuvi mixxat.",
      "Davlat shahar-davlatlardan (Ur, Uruk, Bobil) iborat bo'lgan.",
      "Loy loyqalardan pishitilgan g'ishtga yozishgan.",
      "Kesishuv (O'xshashlik): Ikkisi ham dehqonchilikka ixtisoslashgan ilk sivilizatsiya, quldorlik tuzumi, ko'pxudolik (butparastlik) diniga e'tiqod qilgan."
    ],
    "rubric": [
      "Daryolarning sivilizatsiya yaratishdagi o'xshash roli aniq ta'riflangan.",
      "Yozuv turlari (ieroglif va mixxat) to'g'ri farqlangan."
    ]
  },
  {
    "id": "task-6-venn-qadimgi-yunoniston-madaniyati-va-rim-madaniyati",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "venn",
    "title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "topic": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "context": "Rim o'zining qudrati bilan Yunonistonni bosib olgan bo'lsa-da, madaniyat bobida \"Yunoniston Rimni o'ziga bo'ysundirdi\" , degan tarixiy naql bor.",
    "question": "Rim va Yunon madaniyatining o'xshash va farqli tomonlarini Venn diagrammasida ko'rsating.",
    "steps": [
      "Chap doira (Yunoniston): Teatr (fajia va komediya) ixtiro qilingan, falsafa o'chog'i (Sokrat, Platon), haykaltaroshlikda inson go'zalligi madh etilgan.",
      "O'ng doira (Rim): Muhandislik va qurilish kuchli rivojlangan (akveduklar - suv quvurlari, Kolizey, beton ixtirosi), huquq va qonunshunoslik an'analari (Rim huquqi), gladiatorlar jangi.",
      "Kesishuv (O'xshashlik): Rimliklar yunon xudolarini o'zlashtirgan (Zevs -> Yupiter), ikkisi ham Qadimgi Yevropa sivilizatsiyasi poydevori, lotin va yunon tillari fan tiliga aylangan."
    ],
    "rubric": [
      "Rimning muhandisligi va Yunonistonning san'ati farqi ochiq ko'rsatilgan.",
      "Diniy va madaniy o'xshashlik tarixiy jihatdan tasdiqlangan.",
      "6.",
      "DEBAT (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-debate-gladiatorlar-jangi-tomoshami-yoki-inson-huquqining-toptalishimi",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "debate",
    "title": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "topic": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "context": "Qadimgi Rimda Kolizey kabi ulkan amfiteatrlarda qullar (gladiatorlar) o'zaro yoki yovvoyi hayvonlar bilan o'limgacha jang qilgan. Yuz minglab rimliklar buni zavq bilan tomosha qilishgan.",
    "question": "Debat shaklida fikr bildiring: 'Gladiatorlar jangi Qadimgi Rim jamiyatining shafqatsizligi va qullarni qadr-qimmatsiz buyum deb bilishining eng fojiali ko'rinishi edi, uni hech qanday sport yoki tomosha deya oqlab bo'lmaydi. '",
    "steps": [
      "Pozitsiya: Ushbu tomoshalarning vahshiyligini yoqlash (qoralash).",
      "Dalil: Inson hayoti tomoshabinlar ermagi emasligini (Spartak qo'zg'olonini eslang) asoslang.",
      "Qarshi fikrga javob: \"Ular jang qilib ozodlik olishi mumkin edi\" deydiganlarga nisbatan, baribir bu yagona yo'l emasligi va inson hayoti arzon tutilishini yozing."
    ],
    "rubric": [
      "Quldorlik davrining psixologiyasi insoniylik bilan solishtirilgan.",
      "O'quvchi tomonidan adolatli xulosa chiqarilgan."
    ]
  },
  {
    "id": "task-6-debate-makedoniyalik-iskandarning-sharqqa-yurishi-sivilizatsiyalar-toqn",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "debate",
    "title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "topic": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "context": "Iskandar Maqduniy Sharqni bosib olar ekan, yunonlarni sharqlik qizlarga uylantirgan, o'zi ham sharqona kiyinib, shohona odatlarni joriy qilgan. Natijada \"Ellinizm\" (Yunon-Sharq madaniyati) vujudga kelgan.",
    "question": "Debat shaklida fikr bildiring: 'Makedoniyalik Iskandarning yurishlari qonli qirg'inlar bilan kechgan bo'lsa-da, natijada G'arb va Sharq madaniyati uyg'unlashib, butun dunyo tamaddunining yuksalishiga sabab bo'ldi. '",
    "steps": [
      "Pozitsiya: Ellinizm madaniyatining ijobiy tomonini yoqlash yoki bosqinchilik siyosatini qoralash.",
      "Dalil: Iskandariya (Aleksandriya) kabi o'nlab shaharlarning qurilishi, kutubxonalar va ilm-fanning sharqda gullab-yashnashini dalil sifatida keltiring.",
      "Qarshi fikrga javob: Tinchlik buzilgan bo'lsa-da, shaharsozlik va savdo yo'llarining rivoji (Buyuk Ipak yo'liga poydevor) umuminsoniy taraqqiyotga xizmat qilganini asoslang."
    ],
    "rubric": [
      "Harbiy hujum va madaniy almashinuv tushunchalari muvozanatli baholangan.",
      "\"Ellinizm\" davri mohiyati ochib berilgan.",
      "7.",
      "WALT DISNEY STRATEGIYASI (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-disney-qadimgi-rimda-toza-suv-tarmogi-va-yollar-qurilishi-muhandislik-l",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "disney",
    "title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "topic": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "context": "Qadimgi Rim sivilizatsiyasining eng katta yutug'i — akveduklar (ko'prik orqali suv o'tkazgichlar) va tekis \"Rim yo'llari\" hisoblanadi. Bu shaharlarning tozaligi va armiyaning tez harakatlanishini ta'minlagan.",
    "question": "Siz Qadimgi Rimning bosh muhandisisiz. Walt Disney strategiyasidan foydalanib, yangi bosib olingan Galliya (hozirgi Fransiya) hududida yangi rimcha shahar barpo etish va u yerga toza suv olib kelish loyihasini baholang.",
    "steps": [
      "Xayolparast sifatida: Yuzlab chaqirim uzoqdan tog'dagi toza buloq suvini ulkan ko'priklar (akveduklar) orqali shaharga olib kelib, hammomlar va favvoralar qurishni chizing.",
      "Realist sifatida: Qullar mehnatidan foydalanib toshlarni kesish, beton qorishmasidan foydalanish va suvni ma'lum qiyalikda oqizib kelishning amaliy hisob-kitobini yozing.",
      "Tanqidchi sifatida: Akveduklarning tez-tez buzilishi xavfi, ko'chmanchilar hujum qilsa suv yo'lini kesib qo'yishi va qullar isyoni xavfini ko'rsating."
    ],
    "rubric": [
      "Rim muhandisligining afzalliklari va murakkabligi yaxshi tasvirlangan.",
      "Xayolparast va tanqidchi rollari o'rtasida ziddiyat mantiqiy keltirilgan."
    ]
  },
  {
    "id": "task-6-disney-iskandariya-aleksandriya-kutubxonasini-saqlab-qolish",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "disney",
    "title": "Iskandariya (Aleksandriya) kutubxonasini saqlab qolish",
    "topic": "Iskandariya (Aleksandriya) kutubxonasini saqlab qolish",
    "context": "Qadimgi Misrda barpo etilgan Iskandariya kutubxonasi qadimgi dunyoning eng katta ilm markazi edi, u yerda 700 mingdan ortiq papirus o'ramlari saqlangan. Biroq turli urushlar sababli u yonib, vayron bo'lgan.",
    "question": "Walt Disney strategiyasidan foydalanib, qadimgi dunyoning eng katta axborot bazasi – Iskandariya kutubxonasidagi bilimlarni asrab qolish va ularni kelajak avlodga yetkazish loyihasini ko'rib chiqing.",
    "steps": [
      "Xayolparast sifatida: Kutubxonani yer ostida, olov va urushlardan himoyalangan maxfiy shahar ichida qurib, dunyodagi barcha bilimlarni yig'ish loyihasini tuzing.",
      "Realist sifatida: Barcha papiruslarni yuzlab xattotlarga ko'chirtirish (nusxalash) va boshqa shaharlarga (Pergam kabi) tarqatib yuborish orqali asrab qolish chorasini yozing.",
      "Tanqidchi sifatida: Antik davrda qog'oz (papirus va pergament) juda qimmatligi va hamma bilimlarni ko'chirib chiqish uchun yillar hamda katta xazina kerakligini baholang."
    ],
    "rubric": [
      "Kutubxonaning qadimgi ilmdagi tutgan o'rni his qilingan.",
      "Real va utopik g'oyalar to'g'ri ifodalangan.",
      "8.",
      "REFLEKSIYA (6-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-6-reflexive-spartak-qozgoloni-ozodlik-yolidagi-fidoiylik",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "reflexive",
    "title": "Spartak qo'zg'oloni — ozodlik yo'lidagi fidoiylik",
    "topic": "Spartak qo'zg'oloni — ozodlik yo'lidagi fidoiylik",
    "context": "Qadimgi Rimda qullarning ahvoli shu qadar ayanchli ediki, ularni \"gapiruvchi qurol\" deyishgan. Miloddan avvalgi 74-71-yillarda gladiator Spartak boshchiligida qullar ozodlik uchun qo'zg'olon ko'tardi. Ular mag'lub bo'lsalar-da, tarixda qahramon bo'lib qoldilar.",
    "question": "Agar men qadimgi zamonda yashaganimda, Spartakning qilmishini qo'llab-quvvatlagan bo'larmidim? Insonning erkinligi va uning qadri tushunchasi bugungi kunda men uchun qanday ahamiyat kasb etadi? Shaxsiy xulosangizni yozing.",
    "steps": [
      "Hech bir inson qul qilib yaratilmagani, erkinlik insonning eng oliy huquqi ekanligi haqida falsafiy o'ylaringizni yozing.",
      "Spartakning g'alabaga ishonchi kam bo'lsa-da, qullikda o'lishdan ko'ra ozodlikda jang qilib o'lishni tanlaganidan olgan ibratingizni bayon qiling.",
      "Bugungi tinch va erkin hayotingizga shukronalik bilan qarashga bog'lang."
    ],
    "rubric": [
      "Quldorlik davrining fojiasi va ozodlikning qadri his qilingan.",
      "O'quvchi o'ziga tarbiyaviy xulosa chiqargan."
    ]
  },
  {
    "id": "task-6-reflexive-qadimgi-yunon-faylasuflari-va-mening-dunyoqarashim",
    "grade": 6,
    "subject": "Qadimgi dunyo tarixi",
    "style": "reflexive",
    "title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "topic": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "context": "Qadimgi Yunoniston \"falsafa vatani\" hisoblanadi. Sokrat, Platon va Aristotel kabi mutafakkirlar olamning tuzilishi, yaxshilik va yomonlik, adolat nima ekanligi haqida bahs yuritganlar.",
    "question": "Qadimgi faylasuflarning \"O'z-o'zingni anglab yet\" degan o'gitidan qanday xulosa chiqardingiz? Tarixni o'rganish sizga jamiyatda to'g'ri va noto'g'ri narsalarni farqlashda (ya'ni o'z dunyoqarashingizni shakllantirishda) qanday yordam bermoqda?",
    "steps": [
      "Falsafa faqat osmondagi yulduzlarni o'rganish emas, balki inson o'zining kamchiliklari va qobiliyatlarini bilishi ekanligini yozing.",
      "Tarix faqat urushlardan iborat emasligi, unda qadimgi olimlarning aql-zakovati ham borligini e'tirof eting.",
      "O'z oldingizga qo'ygan hozirgi maqsadingizni shakllantirishda tarixiy shaxslarning fikri turtki bo'lganini tushuntiring."
    ],
    "rubric": [
      "Insonning o'zini anglash jarayoni tarix faniga bog'langan.",
      "Tafakkur va mantiqiy fikrlash erkinligi ta'minlangan."
    ]
  },
  {
    "id": "task-7-case-rim-imperiyasi-va-germanlar",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "case",
    "title": "Rim imperiyasi va germanlar",
    "topic": "Rim imperiyasi va germanlar",
    "context": "IV-V asrlarda Rim imperiyasining qo'shinlari yaxshi qurollangan bo'lsa-da, german qabilalari (vestgotlar, vandallar) bosqinlariga bardosh bera olmadi va 410-yili Alarix boshchiligida Rim shahri egallab, talandi.",
    "question": "Nima sababdan qudratli Rim imperiyasi o'zidan harbiy jihatdan oddiyroq bo'lgan german qabilalari bosqiniga qarshi tura olmadi? Muammoning iqtisodiy va ijtimoiy yechimlarini tahlil qiling.",
    "steps": [
      "Qullar mehnati unumdorligining pasayishini ko'rsating.",
      "Soliqlarning yildan-yilga oshishi oddiy xalq noroziligiga sabab bo'lganini yozing.",
      "Imperiyaning 395-yili ikkiga bo'linib ketishi ta'sirini tushuntiring.",
      "Hukmdor sifatida vaziyatni o'nglash uchun qanday islohotlar qilgan bo'lardingiz — xulosa yozing."
    ],
    "rubric": [
      "Qullar mehnati va iqtisodiy inqiroz bog'lanishi aniq ochilgan.",
      "Siyosiy bo'linishning harbiy zaiflikka ta'siri ko'rsatilgan.",
      "Hukmdor nuqtai nazaridan berilgan taklif amaliy va mantiqiy."
    ]
  },
  {
    "id": "task-7-case-ilk-orta-asrlarda-suv-inshootlari-va-tabaqalanish",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "case",
    "title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "topic": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "context": "IV-VII asrlarda Turon zaminida suv tegirmoni, chig'ir va charxpalak kabi inshootlarning kashf etilishi qishloq xo'jaligi va hunarmandchilikni keskin rivojlantirdi. Biroq bu yer va suvning qabila boshliqlari — dehqonlar qo'liga o'tishiga sabab bo'ldi.",
    "question": "Suv inshootlarining takomillashuvi qanday qilib jamiyatda dehqonlar, kashovarzlar, kadivarlar va chokarlar kabi tabaqalarning paydo bo'lishiga olib keldi?",
    "steps": [
      "Suv va unumdor yerlar nazoratining o'zgarishini tahlil qiling.",
      "Kashovarz va kadivarlarning iqtisodiy holatidagi farqni yozing.",
      "Nima uchun dehqonlarga harbiy posbonlar — chokarlar kerak bo'lganini tushuntiring."
    ],
    "rubric": [
      "Iqtisodiy taraqqiyot va ijtimoiy tabaqalanish o'rtasidagi bog'liqlik ko'rsatilgan.",
      "Barcha 4 ta tabaqaning vazifalari to'g'ri ta'riflangan.",
      "Tarixiy jarayon mantiqiy xulosalangan.",
      "2.",
      "SWOT TAHLIL (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-swot-qadimgi-german-qabilalarining-xojaligi-va-jamiyati",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "swot",
    "title": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "topic": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "context": "IV-VI asrlarda german qabilalari jamoa yer egaligiga asoslangan xo'jalikka ega bo'lib, temir plug va almashlab ekishga o'tdi, biroq ular siyosiy tarqoq urug'chilik bosqichida edi.",
    "question": "SWOT tahlil yordamida german qabilalarining xo'jalik, harbiy va siyosiy salohiyatini baholang.",
    "steps": [
      "Kuchli tomonlarga temir qazib olish, qurolsozlik va jangovarlikni yozing.",
      "Zaif tomonlarga mustahkam shaharlarning yo'qligi va urug'chilik tizimini ko'rsating.",
      "Imkoniyatlarga Rim bilan savdo-sotiq va xristianlikni qabul qilishni yozing.",
      "Xavflarga xunnlar bosqini va qabilalararo o'zaro urushlarni kiriting."
    ],
    "rubric": [
      "Germanlarning xo'jalik yutuqlari (temir plug) ko'rsatilgan.",
      "Rim imperiyasi va xunnlar omili to'g'ri joylashtirilgan.",
      "Kuchli tomonlar Zaif tomonlar Imkoniyatlar Xavflar"
    ]
  },
  {
    "id": "task-7-swot-iv-vii-asrlarda-xorazm-vohasining-geografik-va-xojalik-imkoniyat",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "swot",
    "title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "topic": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "context": "Xorazm vohasi Qoraqum va Qorako'l ko'ligacha cho'zilgan qumliklar orasida joylashgan bo'lib, Amudaryoning loyqa va tez oqadigan suvidan foydalangan holda dehqonchilikni rivojlantirgan.",
    "question": "SWOT tahlil yordamida IV-VII asrlarda Xorazm vohasida dehqonchilik va savdo-sotiqni rivojlantirishning omillarini baholang.",
    "steps": [
      "Kuchli tomonlarga Amudaryoning minerallarga boy loyqa suvi va unumdor tuproqni yozing.",
      "Zaif tomonlarga daryoning juda tez va hayqirib oqishini hamda irmoqsiz jazirama sahro ichidan o'tishini ko'rsating.",
      "Imkoniyatlarga qum tepaliklari orasidan karvon yo'llari o'tkazishni va suv inshootlarini (chig'ir, charxpalak) yozing.",
      "Xavflarga sahro qum bo'ronlarining ekinzorlarni ko'mib tashlashini va ko'chmanchilar hujumini kiriting."
    ],
    "rubric": [
      "Geografik muhit (Amudaryo, Qoraqum) to'g'ri tahlil qilingan.",
      "Suv inshootlarining o'rni imkoniyat sifatida ko'rsatilgan.",
      "Kuchli tomonlar Zaif tomonlar Imkoniyatlar Xavflar 3.",
      "FISHBONE (BALIQ SKELETI) (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-fishbone-garbiy-rim-imperiyasining-qulashi",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "fishbone",
    "title": "G'arbiy Rim imperiyasining qulashi",
    "topic": "G'arbiy Rim imperiyasining qulashi",
    "context": "476-yildan Yevropada o'rta asrlar boshlanishi bilan G'arbiy Rim imperiyasi batamom quladi. Bu bitta sabab emas, balki bir necha omillar yig'indisi edi.",
    "question": "Fishbone tahlili orqali G'arbiy Rim imperiyasi inqirozi va qulashining asosiy sabablarini (yuqori suyaklar) va ularning tafsilotlarini (quyi suyaklar) aniqlang, so'ng yakuniy xulosa chiqaring.",
    "steps": [
      "Bosh (Muammo): G'arbiy Rim imperiyasining qulashi.",
      "1-sabab (Iqtisodiy): Qullar mehnati — tafsilot: unumdorlik pasayishi, yangi qullar kelmasligi.",
      "2-sabab (Ijtimoiy): Soliqlarning ortishi — tafsilot: dehqonlar va shaharliklar noroziligi.",
      "3-sabab (Siyosiy): Imperiyaning bo'linishi — tafsilot: 395-yili G'arbiy va Sharqiy qismlarga ajralishi.",
      "4-sabab (Tashqi): Varvarlar bosqini — tafsilot: Xunnlar bosgami, vestgotlar (Alarix) hujumi."
    ],
    "rubric": [
      "Sabablar 4 ta aniq kategoriyaga ajratilgan.",
      "Har bir sababni dalillovchi tarixiy faktlar (sana, nomlar) yozilgan."
    ]
  },
  {
    "id": "task-7-fishbone-ozbekiston-hududida-orta-asrlarning-boshlanishi",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "fishbone",
    "title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "topic": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "context": "Yevropadan farqli ravishda, Turonda o'rta asrlar V asr oxirida emas, IV asr oxiri va V asr o'rtalaridan, yer-mulk munosabatlarining o'zgarishi bilan boshlangan.",
    "question": "Fishbone tahlili orqali Turonda ilk o'rta asrlar boshlanishi va mulkdorlar tabaqasi shakllanishining omillarini tahlil qiling.",
    "steps": [
      "Bosh (Muammo): Turonda ilk o'rta asrlar va feodal tabaqalanishning boshlanishi.",
      "1-sabab (Texnik): Suv inshootlari — tafsilot: chig'ir, charxpalak, suv tegirmoni ixtirosi.",
      "2-sabab (Iqtisodiy): Yer egaligi — tafsilot: jamoa yerlarining hokimlar qaramog'iga o'tishi.",
      "3-sabab (Ijtimoiy): Tabaqalanish — tafsilot: dehqon, kashovar, kadivar va chokarlarning paydo bo'lishi.",
      "4-sabab (Etnik-siyosiy): Yangi uyushmalar — tafsilot: xioniylar, kidariylar, eftaliylar kirib kelishi."
    ],
    "rubric": [
      "Turon va Yevropa o'rta asrlarining davriy farqi asoslangan.",
      "Atamalar (dehqon, kadivar) omillarga to'g'ri bog'langan.",
      "4.",
      "INSERT METODI (7-sinf, 2 ta topshiriq) (Matnni o'qishda belgilar: (V) - bilardim; (+) - men uchun yangi; (-) - o'ylaganimga zid; (?) - tushunarsiz / savolim bor)."
    ]
  },
  {
    "id": "task-7-insert-germanlarning-kundalik-hayoti-va-xojaligi",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "insert",
    "title": "Germanlarning kundalik hayoti va xo'jaligi",
    "topic": "Germanlarning kundalik hayoti va xo'jaligi",
    "context": "Germanlarning mustahkam hamda bir-biriga yaqin qurilgan qishloqlari bo'lmagan. Ular nondan ko'ra sut, pishloq va go'shtni ko'proq iste'mol qilganlar. Almashlab ekish usuli hamda omochdan temir plugga o'tilishi mehnat unumdorligini oshirdi. Rimliklar bilan savdoda qullar, chorva mollari va qahrabo yetkazib berishgan.",
    "question": "Yuqoridagi matnni INSERT usulida tahlil qiling va o'zingiz uchun yangi (+) va o'ylaganingizga zid (-) bo'lgan ma'lumotlarni izohlang.",
    "steps": [
      "(V): Germanlarning chorvachilik va ovchilik bilan shug'ullangani. (+): Nondan ko'ra sut va pishloq ko'p yeyilishi, temir plugga o'tish. (-): Ularning mustahkam shaharlari yoki yaqin qishloqlari bo'lmaganligi (yoki Rimga qahrabo sotishi). (?): \"Qahrabo\" nimaga ishlatilgan va u qayerdan qazib olingan?"
    ],
    "rubric": [
      "4 ta belgi bo'yicha ma'lumotlar to'g'ri taqsimlangan.",
      "Xo'jalik va savdo aloqalariga oid yangi bilimlar ajratib ko'rsatilgan."
    ]
  },
  {
    "id": "task-7-insert-ilk-orta-asrlarda-orta-osiyodagi-tabaqalar",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "insert",
    "title": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "topic": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "context": "VI asrda unumdor yerlar va suv taqsimoti qishloq hokimlari — dehqonlar nazoratiga o'tdi. Yer va suvdan iborat umumiy mulkka ega erkin ziroatchilar — kashovarzlar, erkidan ayrilganlar esa — kadivarlar deb ataldi. Dehqonlarning xo'jaligini qo'riqlovchi maxsus askariy guruhi — chokarlari bo'lgan.",
    "question": "Matnni INSERT jadvali orqali o'qing va qadimiy ijtimoiy atamalar (dehqon, kadivar, chokar) bo'yicha tahlilingizni yozing.",
    "steps": [
      "(V): O'rta asrlarda aholi boylar va kambag'allarga bo'lingani. (+): \"Dehqon\" so'zi hozirgidagidek oddiy yer chopuvchi emas, balki mulkdor hokim bo'lgani. (-): Kadivarlarning o'z yerlaridan butunlay ayrilib, qaram bo'lib qolgani. (?): Chokarlarning hokimiyatni saqlashdagi siyosiy roli qanchalik kuchli bo'lgan?"
    ],
    "rubric": [
      "\"Dehqon\" atamasining tarixiy va zamonaviy ma'nosidagi farq ochib berilgan.",
      "Barcha tabaqalarga oid ma'lumotlar to'g'ri tasniflangan.",
      "5.",
      "VENN DIAGRAMMA (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-venn-garbiy-va-sharqiy-rim-imperiyalari-395-yildan-song",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "venn",
    "title": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "topic": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "context": "395-yili Rim imperiyasi ikkiga bo'lindi. G'arbiy Rim 476-yildan inqirozga uchrab quladi, Sharqiy Rim (Vizantiya) esa 1453-yilgacha yashadi.",
    "question": "Venn diagrammasi yordamida G'arbiy Rim va Sharqiy Rim imperiyalarining iqtisodiy, harbiy va siyosiy holatidagi o'xshashlik hamda farqlarni ko'rsating.",
    "steps": [
      "Chap doira (G'arbiy Rim): Qullar mehnatining inqirozi, german va xunnlar bosqiniga o'ralib qulashi (410-y.",
      "Alarix), poytaxti Rim.",
      "O'ng doira (Sharqiy Rim): Savdo yo'llarida joylashgani, markazlashgan davlat, poytaxti Konstantinopol, uzoq yillar yashab qolishi.",
      "Kesishuv (O'xshashlik): Ikkisi ham Qadimgi Rim merosxo'ri, xristian dinining tarqalish hududlari, quldorlik an'analari mavjudligi."
    ],
    "rubric": [
      "Har bir imperiyaning o'ziga xos taqdiri faktlar bilan yozilgan.",
      "Umumiy o'xshashliklar aniq va to'g'ri ko'rsatilgan."
    ]
  },
  {
    "id": "task-7-venn-orta-asrlarda-yevropa-va-turondagi-ijtimoiy-tabaqalar",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "venn",
    "title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "topic": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "context": "O'rta asrlarda Yevropada \"feodal va qaram dehqon\" tabaqalari shakllangan bo'lsa, Turonda \"dehqon (qishloq hokimi), kashovarz, kadivar va chokar\" tabaqalari yuzaga keldi.",
    "question": "Yevropa feodali va Turon dehqoni (hokimi) hamda ularga qaram aholining huquq va majburiyatlarini Venn diagrammasida qiyoslang.",
    "steps": [
      "Chap doira (Yevropa): Qirol in'om etgan yerlar hisobiga mulkdor bo'lishi, siyosiy tarqoqlikka olib kelishi.",
      "O'ng doira (Turon): Suv taqsimoti va chig'irlar nazorati orqali boyishi, maxsus chokar (harbiy posbon) saqlashi, qishloq jamoa yerlari mavjudligi.",
      "Kesishuv (O'xshashlik): Ikkisi ham katta yer va mulk egasi bo'lib, oddiy aholini (kadivar / qaram dehqon) o'ziga tobe qilgani."
    ],
    "rubric": [
      "Turon \"dehqon\"i va Yevropa feodali o'rtasidagi bog'liqlik tushuntirilgan.",
      "Suv inshootlari omili Turon uchun alohida ajratilgan.",
      "6.",
      "DEBAT (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-debate-germanlarning-rimni-bosib-olishi-vayronagarchilikmi-yoki-yangi-s",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "debate",
    "title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "topic": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "context": "410-yili vestgotlar Rimni egallab, 3 kun taladilar, keyinchalik Galliya, Ispaniya va Italiyada varvar qirolliklarini tuzdilar. Bu esa Yevropada o'n asr davom etgan O'rta asrlar sivilizatsiyasining boshlanishiga olib keldi.",
    "question": "Debat shaklida fikr bildiring: 'Germanlarning Rim imperiyasini bosib olishi faqat madaniy vayronagarchilik emas, balki Yevropada yangi, yosh sivilizatsiya va markazlashgan davlatlar paydo bo'lishiga zamin yaratgan zaruriy tarixiy jarayon edi.' Ushbu fikrni yoqlang yoki unga qarshi asosli munosabat bildiring.",
    "steps": [
      "Varvarlar bosqini qullar mehnatiga asoslangan inqirozli tuzumga chek qo'yib, feodalizmga yo'l ochganini ko'rsating.",
      "Rimning qadimiy muzeylari, saroy va ibodatxonalari talanganini, ammo bu xalqlarning uyg'unlashuvi yangi davlatlarni yaratganini tushuntiring.",
      "O'z pozitsiyangizni aniq yoritib, qarshi fikrga asosli raddiya yozing."
    ],
    "rubric": [
      "Rimning inqirozi va germanlarning roli adolatli tahlil qilingan.",
      "O'rta asrlar sivilizatsiyasi tushunchasi bilan bog'langan.",
      "Pozitsiya Dalil Qarshi fikrga javob Xulosa"
    ]
  },
  {
    "id": "task-7-debate-suv-inshootlari-xalq-farovonligi-omilimi-yoki-tabaqalanish-qurol",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "debate",
    "title": "Suv inshootlari — xalq farovonligi omilimi yoki tabaqalanish qurolimi?",
    "topic": "Suv inshootlari — xalq farovonligi omilimi yoki tabaqalanish qurolimi?",
    "context": "IV-VII asrlarda Turonda chig'ir, charxpalak va suv tegirmonining ixtiro qilinishi ekin maydonlarini kengaytirdi. Biroq bu suv taqsimotini nazorat qiluvchi dehqonlar (hokimlar) tabaqasi kuchayib, oddiy aholining kadivarlarga aylanib qolishiga ham sabab bo'ldi.",
    "question": "Debat shaklida fikr bildiring: 'Texnik kashfiyotlar (chig'ir, tegirmon) jamiyatda unumdorlikni oshirgani bilan, insonlar o'rtasida mulkiy tengsizlik va qaramlikni kuchaytiruvchi asosiy omilga aylandi.' Ushbu fikrga nisbatan o'z pozitsiyangizni yozing.",
    "steps": [
      "Ixtirolar shaharlar obodligi va savdo-sotiqni o'stirganini dalil sifatida keltiring.",
      "Suv nazoratini qo'lga olgan dehqonlar chokarlar yordamida ziroatchilarni o'ziga tobe qilinganini tahlil qiling.",
      "Tengsizlik oshgan bo'lsa-da, suv inshootlarisiz o'troq dehqonchilik vohalari Orol va Qoraqum qumliklari orasida yashab qola olmasligini tushuntiring."
    ],
    "rubric": [
      "Chig'ir va tegirmonning xo'jalikdagi ahamiyati ochilgan.",
      "Dehqonlar va kadivarlar o'rtasidagi munosabatlar tahlil qilingan.",
      "Pozitsiya Dalil Qarshi fikrga javob Xulosa 7.",
      "WALT DISNEY STRATEGIYASI (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-disney-rim-imperiyasini-inqirozdan-saqlab-qolish",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "disney",
    "title": "Rim imperiyasini inqirozdan saqlab qolish",
    "topic": "Rim imperiyasini inqirozdan saqlab qolish",
    "context": "IV asr oxirida Rim imperiyasi qullar mehnati unumdorligining pasayishi, soliqlarning ortishi va germanlarning doimiy bosqinlari tufayli halokat arafasida edi.",
    "question": "Siz 395-yildagi Rim imperiyasi hukmdorisiz. Walt Disney strategiyasidan foydalanib (Xayolparast, Realist va Tanqidchi niqoblarida) imperiyani inqirozdan saqlab qolish loyihasini ishlab chiqing.",
    "steps": [
      "Xayolparast sifatida: Qullarni erkin yer egalariga aylantirish va germanlarni imperiya himoyachilariga yollash orqali chegarani butunlay tinchitish g'oyasini yozing.",
      "Realist sifatida: Soliq tizimini o'zgartirish, yerlarni bo'lib berish va chegara qo'shinlarini boshqarishning amaliy qadamlarini ko'rsating.",
      "Tanqidchi sifatida: Quldor zodagonlar isyoni va german harbiy boshliqlarining xiyonat qilish xavfini tahlil qiling."
    ],
    "rubric": [
      "Har uchala rol (Xayolparast, Realist, Tanqidchi) nuqtai nazari to'liq ochilgan.",
      "Qullar mehnati va german bosqiniga oid tarixiy yechimlar mantiqiy berilgan.",
      "Xayolparast (Bunyodkor) Realist (Amaliyotchi) Tanqidchi (Xavfni ko'ruvchi)"
    ]
  },
  {
    "id": "task-7-disney-iv-vii-asrlarda-xorazm-vohasida-qishloq-xojaligini-rivojlantiris",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "disney",
    "title": "IV-VII asrlarda Xorazm vohasida qishloq xo'jaligini rivojlantirish",
    "topic": "IV-VII asrlarda Xorazm vohasida qishloq xo'jaligini rivojlantirish",
    "context": "Xorazm vohasi Qoraqum va Qorako'l ko'ligacha cho'zilgan qumliklar orasida joylashgan bo'lib, Amudaryoning loyqa, tez oqadigan suvidan foydalanar edi.",
    "question": "Walt Disney strategiyasidan foydalanib, Xorazmning sahro qumliklari orasida yangi savdo yo'llari o'tkazish va suv inshootlarini (chig'ir, charxpalak) ko'paytirish loyihasini 3 xil nuqtai nazardan baholang.",
    "steps": [
      "Xayolparast sifatida: Barcha qum tepaliklaridan karvon yo'llari o'tkazish va Amudaryo suvida ulkan chig'irlar qurib, cho'lni butunlay bo'stonga aylantirish loyihasini chizing.",
      "Realist sifatida: Miroblar rahbarligida kanallar qazish, quduqlar ochish va kashovarzlar mehnatini tashkil qilishning amaliy choralarini yozing.",
      "Tanqidchi sifatida: Amudaryoning tez oqishi va qum bo'ronlari kanallarni ko'mib tashlash xavfini hamda ko'chmanchilar hujumini ko'rsating."
    ],
    "rubric": [
      "Xorazmning geografik sharoiti (Amudaryo, Qoraqum) to'g'ri hisobga olingan.",
      "Texnik ixtiro va xavflar o'rtasidagi muvozanat realist va tanqidchi rollarida ochib berilgan.",
      "Xayolparast (Bunyodkor) Realist (Amaliyotchi) Tanqidchi (Xavfni ko'ruvchi) 8.",
      "REFLEKSIYA (7-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-7-reflexive-vatan-tarixidan-kelajak-sari-shaxsiy-xulosa",
    "grade": 7,
    "subject": "O'zbekiston tarixi",
    "style": "reflexive",
    "title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "topic": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "context": "Darsliklarda ta'kidlanishicha, tariximizdagi g'alabalar bizga kuch va iftixor bersa, yo'qotishlarga boy mag'lubiyatlar to'g'ri saboq olishga, komillikka va najot faqat ilmda ekanligini anglashga o'rgatadi.",
    "question": "Turon zaminida kechgan o'rta asrlar tarixi va buyuk ajdodlarimizdan olgan darslarim bugungi shiddatli dunyoda mening shaxsiy rivojlanishimga qanday yordam beradi?",
    "steps": [
      "Turon zaminida yashagan qardosh xalqlarning (o'zbek, qozoq, tojik, qoraqalpoq va b.) umumiy madaniy merosidan faxrlanish tuyg'usini bayon qiling.",
      "Nima uchun bugungi kun va kelajagingiz uchun \"yakka-yu yagona najot — ilm\" ekanligini amaliy hayotingizga bog'lab tushuntiring.",
      "O'zingizning kelajakdagi maqsadlaringizni ajdodlar merosiga bog'lab xulosa yozing."
    ],
    "rubric": [
      "Tarixning tarbiyaviy va amaliy ahamiyati o'quvchi shaxsiy fikrida aks etgan.",
      "\"Najot — ilmda\" g'oyasi chuqur mantiqiy asoslangan.",
      "Mening shaxsiy xulosam (Refleksiya)"
    ]
  },
  {
    "id": "task-7-reflexive-german-jangchilari-va-tarixiy-manbalar-qadri",
    "grade": 7,
    "subject": "Jahon tarixi",
    "style": "reflexive",
    "title": "German jangchilari va tarixiy manbalar qadri",
    "topic": "German jangchilari va tarixiy manbalar qadri",
    "context": "O'rta asrlar tarixini biz muzeylardagi moddiy manbalar (qurollar, tangalar) hamda Yuliy Sezar va Tatsitning yozma asarlari orqali o'rganamiz.",
    "question": "Agar siz uzoq o'rta asrlardan qolgan bitta moddiy qurolni (masalan, german jangchisining temir boltasi yoki Rim tangasini) topib olgan tadqiqotchi bo'lsangiz, o'sha davr insonlarining mashaqqatli hayoti haqida qanday o'y-xayollarga borardingiz?",
    "steps": [
      "Kitob bosish dastgohlari yo'q davrda barcha hujjatlarni xattotlar qo'lda bitganini va mehnat qadrini his qilib yozing.",
      "German jangchilarining tabiatsiz, ov va urush bilan o'tgan hayotiy qiyinchiliklarini tasavvur qiling.",
      "Moddiy va yozma manbalarni asrab-avaylashning bugungi avlod ma'naviyati uchun ahamiyatini bayon qiling."
    ],
    "rubric": [
      "Moddiy va yozma manbalar mohiyati to'g'ri anglashilgan.",
      "Tarixiy faktlarga nisbatan o'quvchining hissiy va mantiqiy yondashuvi shakllangan.",
      "Mening shaxsiy xulosam (Refleksiya) 8-SINF UCHUN TOPSHIRIQLAR 1.",
      "KEYS METODI (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-case-fransiyani-birlashtirishdagi-tosiqlar",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "case",
    "title": "Fransiyani birlashtirishdagi to'siqlar",
    "topic": "Fransiyani birlashtirishdagi to'siqlar",
    "context": "Qirol Lyudovik VI va Lyudovik VII davrida Fransiyani birlashtirish jarayoni boshlandi. Bunga eng katta to'siq — Angliyaning Fransiyadagi ulkan yer mulklari edi.",
    "question": "Qirol Lyudovik VII bu siyosiy to'siqni yengish uchun qanday diplomatik yo'l tutdi va uning o'g'li Filipp II Avgust qaysi hududlarni Fransiyaga qaytardi?",
    "steps": [
      "Lyudovik VII ning Akvitaniya malikasi Eleonoraga uylanish sababini yozing.",
      "Filipp II ning Normandiya va Men hududlarini tortib olish usullarini tahlil qiling.",
      "Atlantika va La Manshga chiqishning Fransiya savdosiga ta'sirini baholang."
    ],
    "rubric": [
      "Diplomatik nikohning siyosiy ahamiyati to'g'ri tushuntirilgan.",
      "Filipp II Avgustning harbiy va hududiy yutuqlari sanab o'tilgan.",
      "Geografik joylashuvning iqtisodiy foydasi asoslangan."
    ]
  },
  {
    "id": "task-8-case-papalarning-avinyon-tutqunligi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "case",
    "title": "Papalarning Avinyon tutqunligi",
    "topic": "Papalarning Avinyon tutqunligi",
    "context": "Fransiya qiroli Filipp IV va Rim papasi Bonifatsiy VIII o'rtasida cherkovdan soliq olish masalasida jiddiy nizo kelib chiqdi. Bu voqea 1309-1377-yillarda \"papalarning Avinyon tutqunligi\"ga olib keldi.",
    "question": "Nima uchun qirol cherkovdan soliq talab qildi va bu nizo qanday qilib papalarning 70 yil davomida Avinyonda qolib ketishiga sabab bo'ldi?",
    "steps": [
      "Qirol xazinasining bo'shab qolish sabablarini (urushlar, amaldorlar xarajati) ko'rsating.",
      "Papaning \"anafema\" e'lon qilishiga qirolning javobini tahlil qiling.",
      "Yangi papa Kliment V ning Avinyonga ko'chish sababini tushuntiring."
    ],
    "rubric": [
      "Soliq nizosining iqtisodiy ildizi aniq yoritilgan.",
      "Diniy va dunyoviy hokimiyat kurashida qirolning ustunlik omillari tushuntirilgan.",
      "\"Avinyon tutqunligi\" atamasining mohiyati ochilgan.",
      "2.",
      "SWOT TAHLIL (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-swot-sulton-muhammad-xorazmshoh-saltanati",
    "grade": 8,
    "subject": "O'zbekiston tarixi",
    "style": "swot",
    "title": "Sulton Muhammad Xorazmshoh saltanati",
    "topic": "Sulton Muhammad Xorazmshoh saltanati",
    "context": "Sulton Muhammad Xorazmshoh Movarounnahrdan to Hindistongacha bo'lgan ulkan hududni egalladi, biroq Bag'dod xalifaligi bilan adolatli aloqalarni buzib, mo'g'ullar bilan to'qnashuv arafasida qoldi.",
    "question": "SWOT tahlil yordamida Sulton Muhammad Xorazmshoh imperiyasining kuchli va zaif tomonlarini, imkoniyat va xavflarini ko'rsating.",
    "steps": [
      "Kuchli tomonlarga hududiy kengayish va qo'shin salohiyatini yozing.",
      "Zaif tomonlarga ichki nizolar va Bag'dod xalifasi bilan dushmanlikni ko'rsating.",
      "Imkoniyatlarga savdo yo'llari va yangi yerlarni nazorat qilishni bog'lang.",
      "Xavflarga Chingizxon istilosi va xalifaning mo'g'ullar bilan yashirin kelishuvini yozing."
    ],
    "rubric": [
      "SWOT bo'limlari to'liq va tarixiy dalillar bilan to'ldirilgan.",
      "Tashqi diplomatiyadagi xatolar aniq ko'rsatilgan.",
      "Kuchli tomonlar Zaif tomonlar Imkoniyatlar Xavflar"
    ]
  },
  {
    "id": "task-8-swot-moskva-knyazligining-yuksalishi-ivan-kalita-va-dmitriy-donskoy",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "swot",
    "title": "Moskva knyazligining yuksalishi (Ivan Kalita va Dmitriy Donskoy)",
    "topic": "Moskva knyazligining yuksalishi (Ivan Kalita va Dmitriy Donskoy)",
    "context": "XIV asrda Moskva knyazi Ivan Kalita Oltin O'rdadan soliq yig'ish huquqini oldi, Dmitriy Donskoy esa 1380-yili Kulikovo jangida Mamay qo'shinini yengdi.",
    "question": "SWOT tahlil yordamida Moskva knyazligining rus yerlarini birlashtirishdagi strategiyasini tahlil qiling.",
    "steps": [
      "Kuchli tomonlarga iqtisodiy yuksalish va pravoslav cherkov markazining Moskvaga ko'chishini yozing.",
      "Zaif tomonlarga Tver kabi raqib knyazliklar bilan ichki ziddiyatlarni ko'rsating.",
      "Imkoniyatlarga rus yerlarini yagona bayroq ostida birlashtirishni yozing.",
      "Xavflarga Oltin O'rda xoni To'xtamishning 1382-yildagi qasos hujumini kiriting."
    ],
    "rubric": [
      "Diniy (Pyotrning ko'chishi) va iqtisodiy (soliq) omillar yoritilgan.",
      "Kulikovo jangi va To'xtamish hujumi o'rtasidagi bog'liqlik ochilgan.",
      "Kuchli tomonlar Zaif tomonlar Imkoniyatlar Xavflar 3.",
      "FISHBONE (BALIQ SKELETI) (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-fishbone-aleksandr-nevskiyning-galaba-omillari",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "fishbone",
    "title": "Aleksandr Nevskiyning g'alaba omillari",
    "topic": "Aleksandr Nevskiyning g'alaba omillari",
    "context": "1240-yilda Neva bo'yida shvedlar, 1242-yilda esa Chud ko'li ustida nemis Livoniya ritsarlari ustidan g'alaba qozonildi.",
    "question": "Fishbone tahlilidan foydalanib, Aleksandr Nevskiyning \"Muz ustidagi jang\" va Neva jangida g'alaba qozonishini ta'minlagan omillarni ko'rsating.",
    "steps": [
      "Bosh (Natija): Shved va nemis ritsarlari ustidan g'alaba.",
      "1-omil (Harbiy taktika): Strategik mahorat — tafsilot: ko'lining muzlagan sirtidan foydalanish.",
      "2-omil (Qo'shin birligi): Armiya to'ldirilishi — tafsilot: Vladimir-Suzdal askarlari va xalq qo'shini.",
      "3-omil (Siyosiy iroda): Xalqning qo'llab-quvvatlashi — tafsilot: zodagonlar qarshiligiga qaramay xalq talabi bilan qaytishi.",
      "4-omil (Qat'iyat): Tezkor harakat — tafsilot: Pskov va Izborskni qisqa muddatda ozod qilishi."
    ],
    "rubric": [
      "Lashkarboshi taktikasi va geografik sharoitdan foydalanishi ochilgan.",
      "Xalq qo'shinining ahamiyati ko'rsatilgan."
    ]
  },
  {
    "id": "task-8-fishbone-rus-yerlarining-mogullar-zulmidan-ozod-bolishi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "fishbone",
    "title": "Rus yerlarining mo'g'ullar zulmidan ozod bo'lishi",
    "topic": "Rus yerlarining mo'g'ullar zulmidan ozod bo'lishi",
    "context": "1480-yilda ruslar Oltin O'rdaga soliq to'lashni butunlay to'xtatdi va ikki asrlik qaramlik tugadi.",
    "question": "Fishbone tahlili orqali rus yerlari mo'g'ul istibdodidan xalos bo'lishiga olib kelgan ichki va tashqi omillarni tahlil qiling.",
    "steps": [
      "Bosh (Natija): Oltin O'rda qaramligining barham topishi (1480-y.).",
      "1-omil (Markazlashuv): Moskvaning kuchayishi — tafsilot: Ivan Kalitaning soliq huquqini olishi.",
      "2-omil (Harbiy g'alaba): Kulikovo jangi — tafsilot: 1380-yili Dmitriy Donskoyning Mamayni yengishi.",
      "3-omil (Tashqi yordam / Amir Temur omili): Amir Temur yurishlari — tafsilot: 1395-yili Tarak daryosi bo'yida To'xtamishning tor-mor etilishi.",
      "4-omil (Siyosiy birlashuv): Ivan III faoliyati — tafsilot: Novgorod, Tver kabi yerlarning Moskvaga qo'shilishi."
    ],
    "rubric": [
      "Amir Temurning g'alabasi rus yerlari ozodligini tezlashtirgani aniq faktlar bilan ko'rsatilgan.",
      "Kulikovo jangi va markazlashuv jarayoni to'g'ri bog'langan.",
      "4.",
      "INSERT METODI (8-sinf, 2 ta topshiriq) (Matnni o'qishda belgilar: (V) - bilardim; (+) - men uchun yangi; (-) - o'ylaganimga zid; (?) - tushunarsiz / savolim bor)."
    ]
  },
  {
    "id": "task-8-insert-filipp-iv-ning-cherkovga-qarshi-siyosati",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "insert",
    "title": "Filipp IV ning cherkovga qarshi siyosati",
    "topic": "Filipp IV ning cherkovga qarshi siyosati",
    "context": "Qirol Filipp IV urushlar tufayli bo'shab qolgan xazinani to'ldirish uchun cherkovdan ham soliq to'lashni talab qildi. Papa Bonifatsiy VIII qirolga nisbatan anafema e'lon qildi. Qirol yollanma askarlar bilan papani tahqirladi, yangi saylangan papa Kliment V esa Rimdan Avinyon shahriga ko'chib o'tdi.",
    "question": "INSERT metodi orqali qirol va papa o'rtasidagi ziddiyat matnini o'rganib, Yevropadagi diniy va dunyoviy hokimiyat munosabatlarini baholang.",
    "steps": [
      "(V): O'rta asrlarda cherkov va qirollar o'rtasida hokimiyat talashilgani. (+): Papalarning Rimni tashlab, 70 yil davomida Avinyonda yashashga majbur bo'lishi. (-): Qirolning papadan soliq talab qilishi va yollanma askarlar bilan papaga hujum qilishi. (?): \"Anafema\" jazosi oddiy xalq va qirolga qanday huquqiy-diniy ta'sir ko'rsatgan?"
    ],
    "rubric": [
      "Cherkovning soliq to'lashga majburlanishi to'g'ri tahlil qilingan.",
      "\"Avinyon tutqunligi\" bo'yicha mantiqiy savol qo'yilgan."
    ]
  },
  {
    "id": "task-8-insert-amir-temurning-rus-yerlari-ozodligidagi-orni",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "insert",
    "title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "topic": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "context": "Amir Temur va To'xtamishxon o'rtasida 1389, 1391 va 1395-yillarda uch marotaba jang bo'ldi. 1395-yil Tarak daryosi bo'yida To'xtamish to'liq tor-mor etildi. Bu ruslarning mo'g'ullar zulmidan xalos bo'lishini tezlashtirdi va 1480-yilda ruslar soliq to'lashni butunlay to'xtatdi.",
    "question": "Matnni INSERT usulida o'qing va Amir Temur harbiy yurishlarining Yevropa va Rossiya tarixiga ko'rsatgan ta'sirini izohlang.",
    "steps": [
      "(V): Amir Temur va To'xtamish o'rtasida janglar bo'lganligi. (+): Tarak daryosi bo'yidagi jang sanasi (1395-y.) va uning ruslar uchun \"xolis xizmat\" bo'lgani. (-): Oltin O'rdaning qulashi faqat rus knyazlarining emas, balki Amir Temur zarbalarining natijasi bo'lganligi. (?): To'xtamishxon mag'lub bo'lmaganda rus yerlarining mo'g'ullarga qaramligi yana qancha davom etar edi?"
    ],
    "rubric": [
      "Tarak jangi va 1480-yilgi ozodlik o'rtasidagi sabab-oqibat bog'lanishi ochirilgan.",
      "Tarixiy voqeaning xalqaro ahamiyati baholangan.",
      "5.",
      "VENN DIAGRAMMA (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-venn-novgorod-respublikasi-va-vladimir-suzdal-knyazligi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "venn",
    "title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "topic": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "context": "Kiyev Rusi parchalanib ketgach, shimoli-g'arbda Novgorod respublikasi, shimoli-sharqda esa Vladimir-Suzdal knyazligi (monarxiya) vujudga keldi.",
    "question": "Venn diagrammasidan foydalanib, ushbu ikki rus o'lkasining boshqaruv shakli, iqtisodiyoti va ijtimoiy tuzilishini taqqoslang.",
    "steps": [
      "Chap doira (Novgorod): Zodagonlar respublikasi, veche qaror qabul qilishi, knyazning vakolati cheklangani, savdo markazi.",
      "O'ng doira (Vladimir-Suzdal): Knyaz hokimiyati kuchli bo'lgan monarxiya, poytaxtlarning ko'chirilishi (Rostov -> Suzdal -> Vladimir), yangi shaharlarga (Moskva) asos solinishi.",
      "Kesishuv (O'xshashlik): Ikkisi ham Kiyev Rusi bo'linishidan yuzaga kelgani, pravoslav cherkovi mavjudligi, tashqi dushmanlarga (shved, nemis) qarshi kurashda askar to'plashda hamkorlik qilgani."
    ],
    "rubric": [
      "Boshqaruvdagi tub farqlar (Veche vs Knyaz) ochib berilgan.",
      "Aleksandr Nevskiy davridagi harbiy hamkorlik ko'rsatilgan."
    ]
  },
  {
    "id": "task-8-venn-neva-jangi-1240-y-va-chud-kolidagi-jang-1242-y",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "venn",
    "title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "topic": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "context": "Aleksandr Nevskiy boshchiligidagi rus qo'shinlari 1240-yilda Neva daryosida shvedlarni, 1242-yilda esa Chud ko'lida nemis Livoniya ritsarlarini tor-mor etdi.",
    "question": "Venn diagrammasi orqali ushbu ikkita tarixiy jangning dushmanlari, taktikasi va oqibatlarini taqqoslang.",
    "steps": [
      "Chap doira (Neva jangi): 1240-yil, shved qo'shinlariga qarshi, Neva daryosi bo'yida, Aleksandrga \"Nevskiy\" unvonini keltirgani.",
      "O'ng doira (Chud ko'li jangi): 1242-yil 5-aprel, nemis Livoniya ritsarlariga qarshi, muzlagan ko'l ustida (\"Muz ustidagi jang\"), Izborsk va Pskovning ozod etilishi.",
      "Kesishuv (O'xshashlik): Ikkisiga ham Aleksandr Nevskiy qo'mondonlik qilgani, Novgorod va Pskov erkinligini saqlab qolgani, g'arbiy tahdidni qaytargani."
    ],
    "rubric": [
      "Janglarning strategik taktikasi (muz ustidagi jang) farqlangan.",
      "Mo'g'ullar zulmi davrida bu g'alabalarning siyosiy ahamiyati yozilgan.",
      "6.",
      "DEBAT (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-debate-cherkovdan-soliq-olish-qirolning-adolatli-huquqimi-yoki-dindorla",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "debate",
    "title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "topic": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "context": "Fransiya qiroli Filipp IV mamlakat xazinasini to'ldirish va armiyani mustahkamlash uchun birinchi bo'lib ruhoniylar (cherkov) tabaqasidan soliq talab qildi. Bu esa papa bilan tarixiy nizoga olib keldi.",
    "question": "Debat shaklida fikr bildiring: 'Markazlashgan kuchli davlat qurish yo'lida qirolning imtiyozli cherkov mulkidan ham soliq talab qilishi — adolatli va davlatparvarlik karamidir.' Ushbu fikrni yoqlang yoki unga qarshi munosabat bildiring.",
    "steps": [
      "Urushlar va amaldorlar xarajati barcha fuqarolar, jumladan, eng boy yer egasi bo'lgan cherkov tomonidan ham qoplanishi lozimligini dalillang.",
      "Papaning \"anafema\" e'lon qilishi va qirolning poytaxtga askar tortib borishi cherkov an'analarini buzgan bo'lsa-da, bu Fransiya monarxiyasi qudratini o'rnatganini ko'rsating.",
      "Davlat manfaati har qanday toifa imtiyozidan ustun turishini xulosangizda izohlang."
    ],
    "rubric": [
      "Qirol xazinasining muammolari va armiya ehtiyoji asoslangan.",
      "Papalarning Avinyon tutqunligi oqibatlari ko'rsatilgan.",
      "Pozitsiya Dalil Qarshi fikrga javob Xulosa"
    ]
  },
  {
    "id": "task-8-debate-amir-temurning-toxtamishga-zarbasi-rus-yerlarini-xalos-etishdagi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "debate",
    "title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "topic": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "context": "1395-yili Tarak daryosi bo'yida Amir Temur Oltin O'rda xoni To'xtamishni tor-mor etdi. Darslikda bu voqea \"rus yerlarining mo'g'ullar zulmidan xalos bo'lishini tezlashtirdi\" deb baholangan.",
    "question": "Debat shaklida fikr bildiring: 'Rus knyazliklarining ikki asrlik mo'g'ul qaramligidan xalos bo'lishida Moskva knyazlarining o'zaro harakatlaridan ko'ra, Amir Temurning To'xtamishxon ustidan qozongan g'alabasi hal qiluvchi rol o'ynagan.' Ushbu fikrni yoqlang yoki unga qarshi asosli munosabat bildiring.",
    "steps": [
      "Kulikovo jangidagi (1380-y.) g'alabaga qaramay, 1382-yili To'xtamish Moskvani yoqib, soliqni qayta tiklaganini tahlil qiling.",
      "Amir Temurning 1395-yilgi zarbasi Oltin O'rdaning harbiy-iqtisodiy qudratini butunlay sindirganini ko'rsating.",
      "Moskva knyazlarining (Ivan Kalita, Ivan III) ichki birlashuv harakatlarisiz bu g'alaba to'liq samara berishi mumkinligini baholang.",
      "Yakuniy xulosa va qarshi fikrga raddiya yozing."
    ],
    "rubric": [
      "Kulikovo jangi, To'xtamish hujumi va Tarak jangi sanalari to'g'ri bog'langan.",
      "Sohibqironning xalqaro tarixiy o'rni adolatli baholangan.",
      "Pozitsiya Dalil Qarshi fikrga javob Xulosa 7.",
      "WALT DISNEY STRATEGIYASI (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-disney-filipp-ii-avgustning-normandiyani-qoshib-olish-loyihasi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "disney",
    "title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "topic": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "context": "Angliya qirolligi Fransiyaning Normandiya, Men va Anju kabi eng unumli yerlarini ko'p yillar nazorat qilib, mamlakat birlashishiga to'sqinlik qilib kelgan.",
    "question": "Walt Disney strategiyasi yordamida Filipp II Avgustning ushbu yerlarni Fransiyaga qo'shib olish va ularni 20 ta viloyatga bo'lib boshqarish loyihasini tahlil qiling.",
    "steps": [
      "Xayolparast sifatida: Barcha ingliz mulklarini bir varakayiga qaytarib olib, Atlantika okeaniga chiquvchi yagona va qudratli Fransiya saroyini qurish g'oyasini ilgari suring.",
      "Realist sifatida: Hududlarni birin-ketin harbiy kuch va ma'muriy islohot (20 viloyat hokimlari) orqali bo'ysundirish choralarini ko'rsating.",
      "Tanqidchi sifatida: Angliya qirolining qasos urushi va yangi hududlarda soliq yig'ishdagi o'zboshimchalik xavflarini sanab o'ting."
    ],
    "rubric": [
      "Fransiyaning Atlantika va La Manshga chiqishining strategik ahamiyati yoritilgan.",
      "Ma'muriy islohotning realist va tanqidchi tomonlari mantiqiy asoslangan.",
      "Xayolparast (Bunyodkor) Realist (Amaliyotchi) Tanqidchi (Xavfni ko'ruvchi)"
    ]
  },
  {
    "id": "task-8-disney-moskva-knyazi-ivan-kalitaning-markazlashtirish-loyihasi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "disney",
    "title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "topic": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "context": "1327-yilda Ivan Kalita Oltin O'rda hukmdoridan rus yerlarida soliq yig'ish huquqini oldi va Moskva knyazligining siyosiy hamda iqtisodiy yuksalishini boshlab berdi.",
    "question": "Walt Disney strategiyasidan foydalanib, Ivan Kalitaning Oltin O'rda yordamida rus yerlarini Moskva atrofida birlashtirish va cherkov markazini ko'chirish loyihasini baholang.",
    "steps": [
      "Xayolparast sifatida: Moskvani barcha rus o'lkalarining yagona, muqaddas va qudratli poytaxtiga aylantirish hamda xonlikdan to'liq ozod bo'lish oliy maqsadini belgilang.",
      "Realist sifatida: Soliqni o'z vaqtida to'lab xon ishonchini qozonish, yig'ilgan pulga yangi yerlar sotib olish va bosh ruhoniy Pyotrni ko'chirish choralarini yozing.",
      "Tanqidchi sifatida: Tver kabi raqib knyazliklarning O'rdaga chaqimchilik qilishi va xalqning og'ir soliqlar tufayli isyon ko'tarish xavfini baholang."
    ],
    "rubric": [
      "\"Kalita\" (pul xaltasi) lakabining iqtisodiy-siyosiy mohiyati ochilgan.",
      "Diniy markaz va iqtisodiy omil rollarga to'g'ri taqsimlangan.",
      "Xayolparast (Bunyodkor) Realist (Amaliyotchi) Tanqidchi (Xavfni ko'ruvchi) 8.",
      "REFLEKSIYA (8-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-8-reflexive-fransiyadagi-tabaqaviy-tengsizlik-va-adolat-mezonlari",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "reflexive",
    "title": "Fransiyadagi tabaqaviy tengsizlik va adolat mezonlari",
    "topic": "Fransiyadagi tabaqaviy tengsizlik va adolat mezonlari",
    "context": "O'rta asrlar Fransiyasida butun aholi huquqlari otadan bolaga meros bo'lib o'tadigan uch toifaga bo'lingan. Ruhoniylar va zodagonlar soliqdan ozod edi, uchinchi toifa (dehqon, hunarmand va b.) esa barcha yukni tortgan.",
    "question": "O'rta asrlar Fransiyasidagi ushbu tabaqaviy tizimni va insonlarning huquqiy tengsizligini bugungi kunning adolat mezonlari va qonun ustuvorligi prinsiplari bilan qiyoslab, qanday fikrlarni bildirasiz?",
    "steps": [
      "Otadan bolaga meros bo'lib o'tadigan imtiyozlarning jamiyat taraqqiyotiga to'sqinlik qiluvchi salbiy tomonlarini yozing.",
      "Nima uchun uchinchi tabaqaning faqat \"boy shaharliklari\" qirol majlislariga chaqirilganini ijtimoiy nuqtai nazardan izohlang.",
      "Bugungi kunda barcha fuqarolarning qonun va davlat oldidagi teng huquqliligining qadrini baholang."
    ],
    "rubric": [
      "Uchta tabaqaning huquqiy holati darslik asosida to'g'ri tushunilgan.",
      "Tarixiy voqelik zamonaviy huquqiy qadriyatlar prizmasida chuqur tahlil qilingan.",
      "Mening shaxsiy xulosam (Refleksiya)"
    ]
  },
  {
    "id": "task-8-reflexive-kulikovo-jangi-va-qorquv-ustidan-galaba-ozodligi",
    "grade": 8,
    "subject": "Jahon tarixi",
    "style": "reflexive",
    "title": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "topic": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "context": "1380-yili Dmitriy Donskoy boshchiligidagi rus qo'shinlari Oltin O'rda tumanboshisi Mamay ustidan Kulikovo maydonida g'alaba qozondi. Bu g'alaba rus yerlarining mo'g'ullar zulmidan to'liq va darhol ozod bo'lishini ta'minlamagan bo'lsa-da, xalq ruhiyatida ozodlikka bo'lgan ulkan ishonchni uyg'otdi.",
    "question": "Kulikovo maydonidagi g'alaba xalq ruhiyatida qanday burilish yasaganini tahlil qiling va inson hayotidagi eng katta g'alaba — o'z qo'rquv va to'siqlari ustidan qozonilgan g'alaba ekanligi haqida mulohaza yuriting.",
    "steps": [
      "G'alabadan keyin 1382-yili To'xtamishxon kelib Moskvani yoqib, soliqni qayta tiklagan bo'lsa-da, nega bu voqea rus xalqi ruhiyatidagi ozodlik ishonchini so'ndira olmaganini izohlang.",
      "Inson hayotidagi qiyinchiliklar, vaqtinchalik mag'lubiyatlar va ruhiy sinovlar uni qanday qilib buyuk maqsadlar sari yanada qat'iyatli qilishi mumkinligini yozing.",
      "Shaxsiy hayotingizdagi to'siqlarni (masalan, o'quv jarayonidagi qiyinchiliklar, ikkilanishlar yoki qo'rquvni) yengishda ushbu tarixiy matonatdan qanday namuna olasiz?"
    ],
    "rubric": [
      "Kulikovo jangining siyosiy va ruhiy ahamiyati darslik asosida to'g'ri baholangan.",
      "Tarixiy voqelikdan shaxsiy hayotiy motivatsiya va matonat sabog'i chiqarilgan.",
      "O'quvchining o'z-o'zini tahlil qilish (refleksiya) qobiliyati va mustaqil fikri aniq ifodalangan."
    ]
  },
  {
    "id": "task-9-case-birinchi-jahon-urushining-boshlanishi-va-harbiy-bloklar",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "case",
    "title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "topic": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "context": "XIX asr oxiri – XX asr boshlarida dunyoni qayta bo'lib olish maqsadida yirik davlatlar o'rtasida ziddiyatlar kuchaydi. Natijada Yevropada ikkita yirik harbiy-siyosiy blok: \"Uchlar ittifoqi\" va \"Antanta\" shakllandi. 1914-yil Sarayevodagi qotillik esa insoniyat tarixidagi eng dahshatli urushning boshlanishiga turtki bo'ldi.",
    "question": "Nima sababdan sanoati rivojlangan yirik davlatlar muammolarni tinchlik yo'li bilan emas, balki harbiy bloklarga birlashib, qonli urush orqali hal qilishni tanladilar? Muammoning iqtisodiy va geosiyosiy sabablarini tahlil qiling.",
    "steps": [
      "Sanoat inqilobi natijasida xomashyo va bozorga bo'lgan ehtiyojning ortishini ko'rsating.",
      "Imperiyalar (Buyuk Britaniya, Fransiya, Germaniya) o'rtasidagi mustamlakalar uchun kurashni yozing.",
      "Avstro-Vengriya va Rossiya imperiyalarining Bolqon yarimorolidagi manfaatlari to'qnashuvini tushuntiring.",
      "Agar siz o'sha davrdagi tinchlikparvar siyosatchi bo'lganingizda, urushning oldini olish uchun qanday kelishuvni taklif qilgan bo'lardingiz — xulosa yozing."
    ],
    "rubric": [
      "Urushning iqtisodiy sabablari (bozor va xomashyo) aniq ochib berilgan.",
      "Harbiy bloklarning maqsadlari va ziddiyatlari ko'rsatilgan.",
      "Tinchlikni saqlash bo'yicha berilgan taklif amaliy va mantiqiy."
    ]
  },
  {
    "id": "task-9-case-turkistonda-paxta-yakkahokimligi-ning-ornatilishi",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "case",
    "title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "topic": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "context": "Chor Rossiyasi Turkistonni bosib olgach, mintaqani o'zining xomashyo bazasiga aylantirishga kirishdi. AQShdagi fuqarolar urushi tufayli to'xtab qolgan paxta ta'minoti o'rnini to'ldirish uchun O'rta Osiyoda g'alla ekinlari qisqartirilib, paxta maydonlari keskin kengaytirildi.",
    "question": "Chor Rossiyasining Turkistonda faqat paxta yetishtirishga ixtisoslashgan \"paxta yakkahokimligi\" siyosati o'lkadagi iqtisodiy va ijtimoiy vaziyatga qanday salbiy ta'sir ko'rsatdi?",
    "steps": [
      "G'alla maydonlarining qisqarishi oqibatida oziq-ovqat narxining oshishini tahlil qiling.",
      "Mahalliy dehqonlarning sudxo'r va boylarga qaram bo'lib qolish sabablarini yozing.",
      "Temiryo'llar qurilishi (masalan, Kaspiybo'yi temiryo'li) faqat paxta tashishga xizmat qilganini tushuntiring."
    ],
    "rubric": [
      "Iqtisodiy qaramlik va oziq-ovqat tanqisligi o'rtasidagi bog'liqlik ko'rsatilgan.",
      "Dehqonlarning ijtimoiy ahvoli yomonlashuvi to'g'ri ta'riflangan.",
      "Chorizmning mustamlakachilik maqsadi mantiqiy xulosalangan.",
      "2.",
      "SWOT TAHLIL (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-swot-yaponiyadagi-meydzi-islohotlari",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "swot",
    "title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "topic": "Yaponiyadagi \"Meydzi islohotlari\"",
    "context": "1868-yilda Yaponiyada syogunat ag'darilib, imperator Mutsuhito hokimiyatni o'z qo'liga oldi. Meydzi (Ma'rifatli boshqaruv) davrida Yaponiya o'zini g'arb sivilizatsiyasi uchun ochdi va tezkor modernizatsiya yo'liga o'tdi.",
    "question": "SWOT tahlil yordamida Yaponiyaning Meydzi islohotlari davridagi iqtisodiy, harbiy va siyosiy salohiyatini baholang.",
    "steps": [
      "Kuchli tomonlarga ta'lim tizimidagi g'arb andozalari, sanoatlashish va kuchli milliy armiyani yozing.",
      "Zaif tomonlarga yer va tabiiy resurslarning kamligini ko'rsating.",
      "Imkoniyatlarga Osiyoda yagona qudratli imperiyaga aylanish va tashqi bozorlarga chiqishni yozing.",
      "Xavflarga G'arb davlatlari bilan to'qnashuvlar va Xitoy/Rossiya kabi qo'shnilar bilan urushlarni kiriting."
    ],
    "rubric": [
      "Meydzi islohotlarining ta'lim va sanoatdagi yutuqlari ko'rsatilgan.",
      "Yaponiyaning geografik holati (zaif tomoni) to'g'ri joylashtirilgan.",
      "Kuchli tomonlar / Zaif tomonlar / Imkoniyatlar / Xavflar to'g'ri to'ldirilgan."
    ]
  },
  {
    "id": "task-9-swot-turkistondagi-jadidchilik-harakati",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "swot",
    "title": "Turkistondagi Jadidchilik harakati",
    "topic": "Turkistondagi Jadidchilik harakati",
    "context": "XIX asr oxiri — XX asr boshlarida Mahmudxo'ja Behbudiy, Munavvarqori, Abdulla Avloniy kabi ziyolilar millatni asriy qoloqlikdan qutqarish uchun \"Usuli savtiya\" (yangi usul) maktablari ochib, teatr va matbuotni rivojlantirishga kirishdilar.",
    "question": "SWOT tahlil yordamida Turkistondagi Jadidchilik harakatining ma'rifiy, ijtimoiy va siyosiy imkoniyatlarini baholang.",
    "steps": [
      "Kuchli tomonlarga savodxonlikni oshirish, zamonaviy darsliklar (masalan, \"Birinchi muallim\") yozilishini kiriting.",
      "Zaif tomonlarga harakatning moddiy tomondan qiynalgani va ba'zi ulamolar tomonidan qo'llab-quvvatlanmaganini ko'rsating.",
      "Imkoniyatlarga yoshlarni xorijga (Turkiya, Rossiya, Yevropa) o'qishga yuborish va milliy ongni uyg'otishni yozing.",
      "Xavflarga Chor hukumati qatag'onlari, mutaassib qadimchilarning qarshiligi va maktablarning yopilishini kiriting."
    ],
    "rubric": [
      "Jadidlarning ta'lim va matbuotdagi roli to'g'ri tahlil qilingan.",
      "Siyosiy va ijtimoiy xavflar (chorizm va qadimchilar) to'g'ri ko'rsatilgan.",
      "Kuchli tomonlar / Zaif tomonlar / Imkoniyatlar / Xavflar jadvali to'liq.",
      "3.",
      "FISHBONE (BALIQ SKELETI) (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-fishbone-aqshning-fuqarolar-urushidan-keyingi-iqtisodiy-yuksalishi",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "fishbone",
    "title": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "topic": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "context": "1861-1865-yillardagi Fuqarolar urushida shimolning g'alabasi va qullikning bekor qilinishi AQSh iqtisodiyotining misli ko'rilmagan darajada o'sishiga zamin yaratdi. XIX asr oxiriga kelib AQSh dunyodagi eng qudratli sanoat davlatiga aylandi.",
    "question": "Fishbone tahlili orqali AQShning iqtisodiy gegemonga aylanishi sabablarini (yuqori suyaklar) va ularning tafsilotlarini (quyi suyaklar) aniqlang, so'ng yakuniy xulosa chiqaring.",
    "steps": [
      "Bosh (Natija): AQShning jahon iqtisodiy yetakchisiga aylanishi.",
      "1-sabab (Siyosiy-huquqiy): Qullikning bekor qilinishi — tafsilot: erkin ishchi kuchi bozorining yaratilishi.",
      "2-sabab (Agrotexnik): Gomshtedlar to'g'risidagi qonun (Homestead Act) — tafsilot: G'arbdagi bo'sh yerlarning fermerlarga tekinga berilishi.",
      "3-sabab (Demografik): Immigratsiya — tafsilot: Yevropadan millionlab arzon ishchilar va mutaxassislarning ko'chib kelishi.",
      "4-sabab (Infratuzilma): Temiryo'llar — tafsilot: Transkontinental temiryo'llarning qurilishi va ichki bozorning birlashishi."
    ],
    "rubric": [
      "Sabablar 4 ta aniq omilga (ishchi kuchi, yer, immigratsiya, transport) ajratilgan.",
      "Har bir sababni dalillovchi tarixiy faktlar to'g'ri yozilgan."
    ]
  },
  {
    "id": "task-9-fishbone-1898-yilgi-andijon-qozgoloni-sabablari",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "fishbone",
    "title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "topic": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "context": "Chorizmning shafqatsiz mustamlakachilik siyosati, og'ir soliqlar va milliy-diniy kamsitishlar 1898-yilda Dukchi Eshon (Muhammadali inshon) rahbarligida Andijonda xalq qo'zg'olonining kelib chiqishiga sabab bo'ldi.",
    "question": "Fishbone tahlili orqali Andijon qo'zg'olonining kelib chiqishiga sabab bo'lgan omillarni va uning mag'lubiyat sabablarini tahlil qiling.",
    "steps": [
      "Bosh (Muammo): 1898-yilgi Andijon qo'zg'oloni.",
      "1-sabab (Iqtisodiy): Soliqlarning oshishi — tafsilot: yer va suv soliqlari, paxta yakkahokimligining og'ir oqibatlari.",
      "2-sabab (Siyosiy-ma'naviy): Milliy kamsitish — tafsilot: mahalliy aholining huquqsizligi va dinning toptalishi.",
      "3-sabab (Mag'lubiyat omili 1): Harbiy tayyorgarlikning pastligi — tafsilot: faqat tayoq va sovuq qurollar bilan qurollangani.",
      "4-sabab (Mag'lubiyat omili 2): Stixiyali va tarqoq harakat — tafsilot: qo'zg'olonning puxta rejaga ega emasligi va umummilliy tus olmagani."
    ],
    "rubric": [
      "Mustamlakachilik siyosatining iqtisodiy va ma'naviy zarari asoslangan.",
      "Qo'zg'olon mag'lubiyati omillari aniq va mantiqiy keltirilgan.",
      "4.",
      "INSERT METODI (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-insert-sanoat-inqilobi-va-monopoliyalarning-vujudga-kelishi",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "insert",
    "title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "topic": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "context": "XIX asrning oxiriga kelib, yirik zavod va fabrikalar ishlab chiqarishni o'z qo'lida to'play boshladi. O'zaro raqobatda yengib chiqish uchun korxonalar birlashib, monopoliyalarni (kartel, sindikat, trest) tashkil qildi. Bu davrda bank kapitali bilan sanoat kapitali birlashib, moliyaviy oligarxiya vujudga keldi. Davlat siyosatini endi shu moliya magnatlari belgilay boshladi. ",
    "question": "Yuqoridagi matnni INSERT usulida tahlil qiling va o'zingiz uchun yangi (+) hamda tushunarsiz (?) bo'lgan atamalarni izohlang.",
    "steps": [
      "(V): Sanoat inqilobi natijasida zavod va fabrikalar ko'paygani. (+): Kartel, sindikat va trest kabi monopoliya shakllarining paydo bo'lishi. (-): Davlat siyosatini qirollar emas, balki bankirlar (moliyaviy oligarxiya) hal qila boshlagani. (?): \"Moliyaviy oligarxiya\" jamiyatning oddiy ishchilariga qanday ta'sir ko'rsatgan?"
    ],
    "rubric": [
      "4 ta belgi bo'yicha ma'lumotlar to'g'ri taqsimlangan.",
      "Iqtisodiy atamalar ustida tahliliy fikr yuritilgan."
    ]
  },
  {
    "id": "task-9-insert-1916-yilgi-mardikorlikka-olish-farmoni",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "insert",
    "title": "1916-yilgi Mardikorlikka olish farmoni",
    "topic": "1916-yilgi Mardikorlikka olish farmoni",
    "context": "1916-yil 25-iyunda imperator Nikolay II ning Turkiston aholisini urush olisidagi front orqasidagi qora ishlarga (mardikorlikka) safarbar etish to'g'risidagi farmoni e'lon qilindi. Unga ko'ra 19 yoshdan 43 yoshgacha bo'lgan erkaklar olinishi kerak edi. Bu adolatsizlikka qarshi Jizzax, Toshkent va Farg'ona vodiysida ommaviy qo'zg'olonlar ko'tarildi. Jadidlar xalqni qurbon bermaslik uchun mardikorlikka borishga chaqirdilar, ammo xalq ularni tushunmadi. ",
    "question": "Matnni INSERT jadvali orqali o'qing va tarixiy vaziyatni, jumladan, jadidlarning pozitsiyasini tahlil qiling.",
    "steps": [
      "(V): 1916-yilda O'rta Osiyoda chorizmga qarshi qo'zg'olon bo'lgani. (+): Mardikorlikka yosh chegarasi 19 dan 43 yoshgacha etib belgilangani. (-): Jadidlarning xalq qo'zg'olonini qo'llab-quvvatlamay, qora ishga borishni maslahat bergani. (?): Nima uchun jadidlar kabi vatanparvar ziyolilar bunday qarorga kelishgan edi? (Javobni topishga harakat qiling)."
    ],
    "rubric": [
      "Jadidlarning qirg'inni oldini olish niyatidagi \"zid\" ko'ringan harakati to'g'ri ilg'ab olingan.",
      "Barcha faktlar bo'yicha mantiqiy savol-javob qo'yilgan.",
      "5.",
      "VENN DIAGRAMMA (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-venn-xix-asr-oxirida-buyuk-britaniya-va-germaniya-iqtisodiyoti",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "venn",
    "title": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "topic": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "context": "XIX asrning o'rtalarida Buyuk Britaniya \"dunyohing ustaxonasi\" edi. Biroq XIX asr oxiri – XX asr boshlariga kelib yosh va tajovuzkor Germaniya iqtisodiy jihatdan jadal o'sib, Britaniyani ortda qoldira boshladi.",
    "question": "Venn diagrammasi yordamida Buyuk Britaniya va Germaniyaning XIX asr oxiridagi iqtisodiy va siyosiy holatidagi o'xshashlik hamda farqlarni ko'rsating.",
    "steps": [
      "Chap doira (Buyuk Britaniya): Eng ko'p mustamlakaga ega davlat, sanoat asbob-uskunalari eskirgan, sarmoyani asosan xorijiy mustamlakalarga sarflagan.",
      "O'ng doira (Germaniya): Mustamlakalari kam, hududi birlashgandan so'ng yangi texnologiyalarga asoslangan eng zamonaviy zavodlar qurgan, militarizatsiyalashgan (harbiylashgan) iqtisodiyot.",
      "Kesishuv (O'xshashlik): Ikkisi ham kapitalistik monopoliya bosqichida bo'lgan, jahon bozorida o'zaro raqobatchi, kuchli dengiz va quruqlik armiyasiga ega."
    ],
    "rubric": [
      "Iqtisodiy o'sishdagi farqlar (texnologik yangilanish darajasi) aniq ko'rsatilgan.",
      "Imperiyalarning umumiy xususiyatlari mantiqiy asoslangan."
    ]
  },
  {
    "id": "task-9-venn-qadimchilar-va-jadidlar-qarashlari",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "venn",
    "title": "Qadimchilar va Jadidlar qarashlari",
    "topic": "Qadimchilar va Jadidlar qarashlari",
    "context": "XX asr boshlarida Turkistonda jamiyat qoloqlikdan chiqishi kerakligini hamma anglar edi. Biroq bu yo'lda ulamolarning bir qismi (qadimchilar) an'analar va eski maktabni saqlab qolishni, jadidlar esa yangicha ta'lim va zamonaviy ilm-fanni yoqlab chiqdilar.",
    "question": "Turkiston kelajagi borasidagi Jadidlar va Qadimchilarning ma'rifiy va ijtimoiy qarashlarini Venn diagrammasida qiyoslang.",
    "steps": [
      "Chap doira (Qadimchilar): Faqat diniy bilimlarni o'qitish kerakligi, G'arb madaniyati va texnikasini rad etish, maktablarda quruq yodlatish usulini qoldirish.",
      "O'ng doira (Jadidlar): Dunyoviy fanlar (geografiya, matematika) o'qitilishini talab qilish, \"Usuli savtiya\" (tovush usuli) joriy etish, teatr va gazeta chiqarish.",
      "Kesishuv (O'xshashlik): Ikkala guruh ham Islom diniga e'tiqod qilgan, Turkistonning mustamlaka holatidan xavotirda bo'lgan va o'z tushunchasi bo'yicha xalq g'amini yegan."
    ],
    "rubric": [
      "Ta'lim metodlaridagi (diniy va dunyoviy) tub farqlar ochib berilgan.",
      "Ikkala guruhning maqsadi va umumiy tomoni adolatli yozilgan.",
      "6.",
      "DEBAT (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-debate-imperializm-va-mustamlakachilik-sivilizatsiya-tarqatishmi-yoki-z",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "debate",
    "title": "Imperializm va Mustamlakachilik — sivilizatsiya tarqatishmi yoki zulm?",
    "topic": "Imperializm va Mustamlakachilik — sivilizatsiya tarqatishmi yoki zulm?",
    "context": "XIX asrda Yevropa davlatlari Afrika, Osiyo va Lotin Amerikasini bo'lib olishdi. Mustamlakachilar bu ishlarini \"qoloq xalqlarga zamonaviy texnologiya, tibbiyot va madaniyat (sivilizatsiya) olib kirish\" deb oqlashar edi.",
    "question": "Debat shaklida fikr bildiring: 'Yevropa davlatlarining mustamlakachilik siyosati qoloq mintaqalarga sivilizatsiya, poyezdlar, zamonaviy tibbiyot va ta'lim olib kirgan ijobiy jarayon edi. ' Ushbu fikrni yoqlang yoki unga qarshi asosli munosabat (raddiya) bildiring.",
    "steps": [
      "Pozitsiya: Mustamlakachilikning asl maqsadi hududlarni talash ekanligini ko'rsatish (yoki infratuzilma yutuqlarini tan olish).",
      "Dalil: Yevropaliklar qurgan temiryo'llar faqat resurslarni (paxta, olmos, oltin) tashib ketish uchun qurilganini asoslang.",
      "Qarshi fikrga javob: \"Ular tibbiyot va maktab olib keldi\" deganlarga nisbatan mahalliy xalq madaniyatining yo'q qilingani va qullik sharoitini ko'rsating."
    ],
    "rubric": [
      "Imperializmning asl iqtisodiy maqsadi adolatli tahlil qilingan.",
      "Pozitsiya va qarshi fikrga javob qismi ishonchli faktlar bilan yozilgan."
    ]
  },
  {
    "id": "task-9-debate-1916-yilgi-qozgolonda-jadidlarning-yondashuvi-adolatli-edimi",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "debate",
    "title": "1916-yilgi qo'zg'olonda Jadidlarning yondashuvi adolatli edimi?",
    "topic": "1916-yilgi qo'zg'olonda Jadidlarning yondashuvi adolatli edimi?",
    "context": "1916-yili Chor hukumati mardikor olganda, xalq qo'zg'olon ko'tardi. Jadid bobolarimiz esa qurolsiz xalq muntazam va shafqatsiz rus armiyasi tomonidan qirib tashlanishini bilib, ochiq isyon ko'tarmaslikka, mardikorlikka borib G'arb sanoati bilan tanishib qaytishga chaqirdilar.",
    "question": "Debat shaklida fikr bildiring: '1916-yilgi milliy ozodlik harakatida Jadidlarning xalqni qo'zg'olondan qaytarish va mardikorlikka ko'nish siyosati — qo'rqoqlik emas, balki millatni qirg'indan asrab qolish uchun qilingan donishmandlik edi. '",
    "steps": [
      "Pozitsiya: Jadidlarning qarorini yoqlash yoki qoralash.",
      "Dalil: Qurolsiz dehqonlarning to'plar va pulemyotlar oldida qanday ojizligini (Jizzax fojeasi misolida) tushuntiring.",
      "Qarshi fikrga javob: \"Ular xalq bilan birga jang qilishi kerak edi\" degan fikrga raddiya sifatida jadidlar qurolli kurash uchun millat hali tayyor emasligi va ziyolilar halok bo'lsa xalq yolg'iz qolishini bilishganini yozing."
    ],
    "rubric": [
      "Tarixiy voqeaga faqat hissiyot emas, balki chuqur siyosiy aql bilan baho berilgan.",
      "Pozitsiya, dalil va xulosa uzviy bog'langan.",
      "7.",
      "WALT DISNEY STRATEGIYASI (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-disney-xitoyni-ochiq-eshiklar-siyosatidan-qutqarish-loyihasi",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "disney",
    "title": "Xitoyni \"Ochiq eshiklar\" siyosatidan qutqarish loyihasi",
    "topic": "Xitoyni \"Ochiq eshiklar\" siyosatidan qutqarish loyihasi",
    "context": "XIX asr oxirida Xitoy G'arb davlatlari (Angliya, Fransiya, Germaniya, Rossiya, keyinchalik AQSh) tomonidan yarim mustamlakaga aylantirilib, ta'sir doiralarga bo'lib olingan edi (Opium urushlaridan keyingi ahvol).",
    "question": "Siz 1900-yillardagi Xitoy imperatori (yoki islohotchi vaziri)siz. Walt Disney strategiyasidan foydalanib (Xayolparast, Realist va Tanqidchi niqoblarida) Xitoyni qaramlikdan saqlab qolish va modernizatsiya qilish loyihasini ishlab chiqing.",
    "steps": [
      "Xayolparast sifatida: Yaponiyadagi kabi tezkor sanoat inqilobi qilib, barcha chet elliklarni haydab chiqarish va jahondagi eng qudratli Ipak yo'li tarmog'ini tiklashni yozing.",
      "Realist sifatida: Yevropa bilan texnologiya ayirboshlash shartnomasi tuzish, talabalarni xorijga yuborish va zamonaviy Xitoy armiyasini tuzishning amaliy qadamlarini ko'rsating.",
      "Tanqidchi sifatida: Mahalliy korrupsiyalashgan amaldorlarning qarshiligi, chet el elchixonalari bosimi (\"Ihetuanlar\" tajribasi) va mablag' yetishmasligini ko'rsating."
    ],
    "rubric": [
      "Har uchala rol (Xayolparast, Realist, Tanqidchi) nuqtai nazari to'liq ochilgan.",
      "Yapon va Xitoy tajribasi qiyosan mantiqiy berilgan."
    ]
  },
  {
    "id": "task-9-disney-turkistonda-jadid-maktablari-tarmogini-kengaytirish",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "disney",
    "title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "topic": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "context": "XX asr boshida Jadidlar yangi usul (\"Usuli savtiya\") maktablarini ochib, yoshlarga dunyoviy ilmlarni o'rgata boshlashdi, biroq mablag' va kadrlarning yetishmasligi, hamda Chor hokimiyatining to'sqinligi jiddiy muammo edi.",
    "question": "Walt Disney strategiyasidan foydalanib, butun Turkiston bo'ylab 1000 ta jadid maktabi, universitetlar va Yevropa andozasidagi nashriyotlar ochish loyihasini 3 xil nuqtai nazardan baholang.",
    "steps": [
      "Xayolparast sifatida: Har bir qishloqda shisha oynali yorug' maktablar, bepul darsliklar, chet eldan keltirilgan mikroskoplar va O'rta Osiyodagi birinchi milliy Universitet g'oyasini chizing.",
      "Realist sifatida: Boy savdogarlardan (homiylardan) mablag' yig'ish uchu \"Jamiyati xayriya\"lar tuzish, dastlab o'qituvchilar tayyorlash kurslarini ochish va mahalliy ma'murlardan ruxsat olish choralarini yozing.",
      "Tanqidchi sifatida: Mutaassib mullalarning \"Kofir maktab\" deya xalqni gijgijlashi, Chor ayg'oqchilarining qamoqqa olish xavfi va xalqning o'ta qashshoqligini hisobga oling."
    ],
    "rubric": [
      "Jadidlarning ma'rifatparvarlik orzulari va o'sha davr realligi to'g'ri bog'langan.",
      "Tanqidchi va Realist rollari tarixiy faktlar asosida yoritilgan.",
      "8.",
      "REFLEKSIYA (9-sinf, 2 ta topshiriq)"
    ]
  },
  {
    "id": "task-9-reflexive-tarix-xatolaridan-togri-xulosa-birinchi-jahon-urushi-sabogi",
    "grade": 9,
    "subject": "Jahon tarixi",
    "style": "reflexive",
    "title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "topic": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "context": "Birinchi jahon urushi (1914-1918) 10 millionga yaqin insonning yostig'ini quritdi, hududlarni vayron qildi va 4 ta ulkan imperiyaning (Rossiya, Usmoniy, Avstro-Vengriya, Germaniya) qulashiga olib keldi. Urush sababi — faqat kibr, boylikka hirs va ta'sir doiralarni bo'lib olish edi.",
    "question": "Bugungi kunda ham yirik davlatlar o'rtasida ziddiyatlar mavjud. I-Jahon urushi oqibatlari haqida o'rgangan tarixiy bilimlarim, hozirgi kunda yosh avlod sifatida tinchlikning qadriga yetishim va kelajakdagi xulosalarimga qanday ta'sir qiladi?",
    "steps": [
      "Siyosatchilarning manfaati deb millionlab oddiy insonlarning qurbon bo'lishi fojiasini bayon qiling.",
      "Hech qanday iqtisodiy yutuq yoki yer urushdagi inson hayotidan ustun emasligi haqida hayotiy falsafangizni yozing.",
      "Xalqaro mojarolarni faqat diplomatik yo'l va ta'lim-ma'rifat orqali hal qilish lozimligini bugungi kun bilan bog'lab xulosa qiling."
    ],
    "rubric": [
      "Insoniylik, tinchlik qadri va tarixiy fojia chuqur hissiyot bilan tahlil qilingan.",
      "O'quvchi voqealarni zamonaviy hayotga bog'lay olgan."
    ]
  },
  {
    "id": "task-9-reflexive-jadid-bobolarimiz-fidosi-va-mening-bugunim",
    "grade": 9,
    "subject": "O'zbekiston tarixi",
    "style": "reflexive",
    "title": "Jadid bobolarimiz fidosi va mening bugunim",
    "topic": "Jadid bobolarimiz fidosi va mening bugunim",
    "context": "Mahmudxo'ja Behbudiy, Abdulla Qodiriy, Cho'lpon kabi jadid bobolarimiz millat savodsizlik va xurofotdan qutulishi uchun bor mol-mulklarini, hatto jonlarini ham tikdilar. Ularning orzusi — ozod, o'qimishli va qoloqlikdan xoli farovon xalq edi.",
    "question": "Jadidlarning hayot yo'li va mashaqqatlari bilan tanishgach, ularning asr boshidagi orzulari va bugungi kunda men ega bo'lib turgan imkoniyatlar (erkin ta'lim, mustaqillik) o'rtasida qanday mas'uliyatni his qilmoqdaman? Shaxsiy xulosangizni yozing.",
    "steps": [
      "Jadidlar yashagan davrdagi senzura, ta'qib va qorong'ulikni tasavvur qilib yozing.",
      "Ular intilib yeta olmagan ozodlik va zamonaviy ta'lim bugun bizning qo'limizda ekanligini faxr va mas'uliyat bilan tushuntiring.",
      "Shaxsiy hayotingizda qaysi kasb orqali jadid bobolaringizning \"millatni yuksaltirish\" orzusiga hissa qo'shishingiz haqida maqsadlaringizni yozing."
    ],
    "rubric": [
      "Tarixiy minnatdorlik va bugungi kun imkoniyatlarining qadri chuqur anglab yetilgan.",
      "\"Najot — ta'limda\" g'oyasi orqali o'quvchining shaxsiy kelajak maqsadlari shakllangan."
    ]
  }
]$tasks$::jsonb) as task_seed(
    id text,
    grade integer,
    subject text,
    style text,
    title text,
    topic text,
    context text,
    question text,
    steps jsonb,
    rubric jsonb
  )
)
insert into public.tasks (id, grade, subject, style, title, topic, context, question, steps, rubric, is_active)
select id, grade, subject, style, title, topic, context, question, steps, rubric, true
from pasted_tasks
on conflict (id) do update set
  grade = excluded.grade,
  subject = excluded.subject,
  style = excluded.style,
  title = excluded.title,
  topic = excluded.topic,
  context = excluded.context,
  question = excluded.question,
  steps = excluded.steps,
  rubric = excluded.rubric,
  is_active = excluded.is_active,
  updated_at = now();

with demo_records as (
  select *
  from jsonb_to_recordset($demo$[
  {
    "id": "demo-001",
    "grade": 5,
    "score": 84,
    "anonymous_id": "AT-5FKW8V",
    "task_title": "Yoshlar uchun yangi va mukammal Kalendar yaratish loyihasi",
    "submitted_at": "2026-07-01T09:01:00Z",
    "graded_at": "2026-07-01T12:07:00Z"
  },
  {
    "id": "demo-002",
    "grade": 5,
    "score": 51,
    "anonymous_id": "AT-5YLFD9",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-02T09:02:00Z",
    "graded_at": "2026-07-02T12:14:00Z"
  },
  {
    "id": "demo-003",
    "grade": 5,
    "score": 42,
    "anonymous_id": "AT-5U2WZH",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-03T09:03:00Z",
    "graded_at": "2026-07-03T12:21:00Z"
  },
  {
    "id": "demo-004",
    "grade": 5,
    "score": 46,
    "anonymous_id": "AT-5TH46W",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-04T09:04:00Z",
    "graded_at": "2026-07-04T12:28:00Z"
  },
  {
    "id": "demo-005",
    "grade": 5,
    "score": 59,
    "anonymous_id": "AT-53KR72",
    "task_title": "Nil daryosi toshqini va birinchi kalendar",
    "submitted_at": "2026-07-05T09:05:00Z",
    "graded_at": "2026-07-05T12:35:00Z"
  },
  {
    "id": "demo-006",
    "grade": 5,
    "score": 75,
    "anonymous_id": "AT-5N9PG2",
    "task_title": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "submitted_at": "2026-07-06T09:06:00Z",
    "graded_at": "2026-07-06T12:42:00Z"
  },
  {
    "id": "demo-007",
    "grade": 5,
    "score": 77,
    "anonymous_id": "AT-578SJJ",
    "task_title": "Yuliy kalendari va Grigoriy kalendari",
    "submitted_at": "2026-07-07T09:07:00Z",
    "graded_at": "2026-07-07T12:49:00Z"
  },
  {
    "id": "demo-008",
    "grade": 5,
    "score": 62,
    "anonymous_id": "AT-5UPUDC",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-08T09:08:00Z",
    "graded_at": "2026-07-08T12:56:00Z"
  },
  {
    "id": "demo-009",
    "grade": 5,
    "score": 88,
    "anonymous_id": "AT-56VPNM",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-09T09:09:00Z",
    "graded_at": "2026-07-09T12:03:00Z"
  },
  {
    "id": "demo-010",
    "grade": 5,
    "score": 55,
    "anonymous_id": "AT-5KUBZ9",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-10T09:10:00Z",
    "graded_at": "2026-07-10T12:10:00Z"
  },
  {
    "id": "demo-011",
    "grade": 5,
    "score": 85,
    "anonymous_id": "AT-5RTYUE",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-11T09:11:00Z",
    "graded_at": "2026-07-11T12:17:00Z"
  },
  {
    "id": "demo-012",
    "grade": 5,
    "score": 89,
    "anonymous_id": "AT-5YTDS5",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-12T09:12:00Z",
    "graded_at": "2026-07-12T12:24:00Z"
  },
  {
    "id": "demo-013",
    "grade": 5,
    "score": 41,
    "anonymous_id": "AT-5V257Y",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-13T09:13:00Z",
    "graded_at": "2026-07-13T12:31:00Z"
  },
  {
    "id": "demo-014",
    "grade": 5,
    "score": 41,
    "anonymous_id": "AT-546XSH",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-14T09:14:00Z",
    "graded_at": "2026-07-14T12:38:00Z"
  },
  {
    "id": "demo-015",
    "grade": 5,
    "score": 57,
    "anonymous_id": "AT-56PREW",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-15T09:15:00Z",
    "graded_at": "2026-07-15T12:45:00Z"
  },
  {
    "id": "demo-016",
    "grade": 5,
    "score": 69,
    "anonymous_id": "AT-5DBBR4",
    "task_title": "Nil daryosi toshqini va birinchi kalendar",
    "submitted_at": "2026-07-16T09:16:00Z",
    "graded_at": "2026-07-16T12:52:00Z"
  },
  {
    "id": "demo-017",
    "grade": 5,
    "score": 82,
    "anonymous_id": "AT-5PSRE3",
    "task_title": "Vatan tarixi — mening o'zligim",
    "submitted_at": "2026-07-17T09:17:00Z",
    "graded_at": "2026-07-17T12:59:00Z"
  },
  {
    "id": "demo-018",
    "grade": 5,
    "score": 48,
    "anonymous_id": "AT-59GECV",
    "task_title": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "submitted_at": "2026-07-18T09:18:00Z",
    "graded_at": "2026-07-18T12:06:00Z"
  },
  {
    "id": "demo-019",
    "grade": 5,
    "score": 93,
    "anonymous_id": "AT-5ECY8F",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-19T09:19:00Z",
    "graded_at": "2026-07-19T12:13:00Z"
  },
  {
    "id": "demo-020",
    "grade": 5,
    "score": 78,
    "anonymous_id": "AT-5Z9Q2Z",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-20T09:20:00Z",
    "graded_at": "2026-07-20T12:20:00Z"
  },
  {
    "id": "demo-021",
    "grade": 5,
    "score": 62,
    "anonymous_id": "AT-5XRAVB",
    "task_title": "\"Avesto\" va moddiy manbalarning topilishi",
    "submitted_at": "2026-07-21T09:21:00Z",
    "graded_at": "2026-07-21T12:27:00Z"
  },
  {
    "id": "demo-022",
    "grade": 5,
    "score": 73,
    "anonymous_id": "AT-5CM68N",
    "task_title": "Bizning sinf \"Tarixiy muzeyi\"ni yaratish",
    "submitted_at": "2026-07-22T09:22:00Z",
    "graded_at": "2026-07-22T12:34:00Z"
  },
  {
    "id": "demo-023",
    "grade": 5,
    "score": 57,
    "anonymous_id": "AT-5LVD3R",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-23T09:23:00Z",
    "graded_at": "2026-07-23T12:41:00Z"
  },
  {
    "id": "demo-024",
    "grade": 5,
    "score": 82,
    "anonymous_id": "AT-5LFYBZ",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-24T09:24:00Z",
    "graded_at": "2026-07-24T12:48:00Z"
  },
  {
    "id": "demo-025",
    "grade": 5,
    "score": 83,
    "anonymous_id": "AT-5U86KK",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-25T09:25:00Z",
    "graded_at": "2026-07-25T12:55:00Z"
  },
  {
    "id": "demo-026",
    "grade": 5,
    "score": 71,
    "anonymous_id": "AT-5B7MTT",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-26T09:26:00Z",
    "graded_at": "2026-07-26T12:02:00Z"
  },
  {
    "id": "demo-027",
    "grade": 5,
    "score": 70,
    "anonymous_id": "AT-5P7DAN",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-27T09:27:00Z",
    "graded_at": "2026-07-27T12:09:00Z"
  },
  {
    "id": "demo-028",
    "grade": 5,
    "score": 54,
    "anonymous_id": "AT-5NYS8L",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-28T09:28:00Z",
    "graded_at": "2026-07-28T12:16:00Z"
  },
  {
    "id": "demo-029",
    "grade": 5,
    "score": 46,
    "anonymous_id": "AT-5GME8E",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-01T09:29:00Z",
    "graded_at": "2026-07-01T12:23:00Z"
  },
  {
    "id": "demo-030",
    "grade": 5,
    "score": 49,
    "anonymous_id": "AT-5JEBBB",
    "task_title": "Vatan tarixi — mening o'zligim",
    "submitted_at": "2026-07-02T09:30:00Z",
    "graded_at": "2026-07-02T12:30:00Z"
  },
  {
    "id": "demo-031",
    "grade": 5,
    "score": 62,
    "anonymous_id": "AT-5EWVYC",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-03T09:31:00Z",
    "graded_at": "2026-07-03T12:37:00Z"
  },
  {
    "id": "demo-032",
    "grade": 5,
    "score": 43,
    "anonymous_id": "AT-55RDS7",
    "task_title": "Men ham tarix guvohiman",
    "submitted_at": "2026-07-04T09:32:00Z",
    "graded_at": "2026-07-04T12:44:00Z"
  },
  {
    "id": "demo-033",
    "grade": 5,
    "score": 45,
    "anonymous_id": "AT-5T6VDH",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-05T09:33:00Z",
    "graded_at": "2026-07-05T12:51:00Z"
  },
  {
    "id": "demo-034",
    "grade": 5,
    "score": 75,
    "anonymous_id": "AT-5F9QB8",
    "task_title": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "submitted_at": "2026-07-06T09:34:00Z",
    "graded_at": "2026-07-06T12:58:00Z"
  },
  {
    "id": "demo-035",
    "grade": 5,
    "score": 63,
    "anonymous_id": "AT-5EDTPQ",
    "task_title": "Men ham tarix guvohiman",
    "submitted_at": "2026-07-07T09:35:00Z",
    "graded_at": "2026-07-07T12:05:00Z"
  },
  {
    "id": "demo-036",
    "grade": 5,
    "score": 47,
    "anonymous_id": "AT-5N9YUF",
    "task_title": "Bizning sinf \"Tarixiy muzeyi\"ni yaratish",
    "submitted_at": "2026-07-08T09:36:00Z",
    "graded_at": "2026-07-08T12:12:00Z"
  },
  {
    "id": "demo-037",
    "grade": 5,
    "score": 53,
    "anonymous_id": "AT-53XFPH",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-09T09:37:00Z",
    "graded_at": "2026-07-09T12:19:00Z"
  },
  {
    "id": "demo-038",
    "grade": 5,
    "score": 65,
    "anonymous_id": "AT-5XMZND",
    "task_title": "Moddiy manbalar va Yozma manbalar",
    "submitted_at": "2026-07-10T09:38:00Z",
    "graded_at": "2026-07-10T12:26:00Z"
  },
  {
    "id": "demo-039",
    "grade": 5,
    "score": 43,
    "anonymous_id": "AT-5CWQBA",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-11T09:39:00Z",
    "graded_at": "2026-07-11T12:33:00Z"
  },
  {
    "id": "demo-040",
    "grade": 5,
    "score": 64,
    "anonymous_id": "AT-5B2K47",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-12T09:40:00Z",
    "graded_at": "2026-07-12T12:40:00Z"
  },
  {
    "id": "demo-041",
    "grade": 5,
    "score": 91,
    "anonymous_id": "AT-5NH9D6",
    "task_title": "Nil daryosi toshqini va birinchi kalendar",
    "submitted_at": "2026-07-13T09:41:00Z",
    "graded_at": "2026-07-13T12:47:00Z"
  },
  {
    "id": "demo-042",
    "grade": 5,
    "score": 41,
    "anonymous_id": "AT-5QBW2K",
    "task_title": "Yuliy kalendari va Grigoriy kalendari",
    "submitted_at": "2026-07-14T09:42:00Z",
    "graded_at": "2026-07-14T12:54:00Z"
  },
  {
    "id": "demo-043",
    "grade": 5,
    "score": 66,
    "anonymous_id": "AT-5GNQX6",
    "task_title": "\"Avesto\" va moddiy manbalarning topilishi",
    "submitted_at": "2026-07-15T09:43:00Z",
    "graded_at": "2026-07-15T12:01:00Z"
  },
  {
    "id": "demo-044",
    "grade": 5,
    "score": 57,
    "anonymous_id": "AT-5EF37L",
    "task_title": "Bizning sinf \"Tarixiy muzeyi\"ni yaratish",
    "submitted_at": "2026-07-16T09:44:00Z",
    "graded_at": "2026-07-16T12:08:00Z"
  },
  {
    "id": "demo-045",
    "grade": 5,
    "score": 93,
    "anonymous_id": "AT-5F23LK",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-17T09:45:00Z",
    "graded_at": "2026-07-17T12:15:00Z"
  },
  {
    "id": "demo-046",
    "grade": 5,
    "score": 56,
    "anonymous_id": "AT-5C5FLC",
    "task_title": "Men ham tarix guvohiman",
    "submitted_at": "2026-07-18T09:46:00Z",
    "graded_at": "2026-07-18T12:22:00Z"
  },
  {
    "id": "demo-047",
    "grade": 5,
    "score": 91,
    "anonymous_id": "AT-5WBXX5",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-19T09:47:00Z",
    "graded_at": "2026-07-19T12:29:00Z"
  },
  {
    "id": "demo-048",
    "grade": 5,
    "score": 88,
    "anonymous_id": "AT-5CAYYP",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-20T09:48:00Z",
    "graded_at": "2026-07-20T12:36:00Z"
  },
  {
    "id": "demo-049",
    "grade": 5,
    "score": 57,
    "anonymous_id": "AT-5NPC53",
    "task_title": "Moddiy manbalar va Yozma manbalar",
    "submitted_at": "2026-07-21T09:49:00Z",
    "graded_at": "2026-07-21T12:43:00Z"
  },
  {
    "id": "demo-050",
    "grade": 5,
    "score": 44,
    "anonymous_id": "AT-52DMTK",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-22T09:50:00Z",
    "graded_at": "2026-07-22T12:50:00Z"
  },
  {
    "id": "demo-051",
    "grade": 5,
    "score": 46,
    "anonymous_id": "AT-59X3YR",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-23T09:51:00Z",
    "graded_at": "2026-07-23T12:57:00Z"
  },
  {
    "id": "demo-052",
    "grade": 5,
    "score": 79,
    "anonymous_id": "AT-532GBC",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-24T09:52:00Z",
    "graded_at": "2026-07-24T12:04:00Z"
  },
  {
    "id": "demo-053",
    "grade": 5,
    "score": 91,
    "anonymous_id": "AT-5AWJG9",
    "task_title": "Era va Xronologiya tushunchasi",
    "submitted_at": "2026-07-25T09:53:00Z",
    "graded_at": "2026-07-25T12:11:00Z"
  },
  {
    "id": "demo-054",
    "grade": 5,
    "score": 75,
    "anonymous_id": "AT-547CE9",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-26T09:54:00Z",
    "graded_at": "2026-07-26T12:18:00Z"
  },
  {
    "id": "demo-055",
    "grade": 5,
    "score": 62,
    "anonymous_id": "AT-5WCRP4",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-27T09:55:00Z",
    "graded_at": "2026-07-27T12:25:00Z"
  },
  {
    "id": "demo-056",
    "grade": 5,
    "score": 62,
    "anonymous_id": "AT-5N26DX",
    "task_title": "Qaysi manba turi ishonchliroq — Yozmami yoki Moddiy?",
    "submitted_at": "2026-07-28T09:56:00Z",
    "graded_at": "2026-07-28T12:32:00Z"
  },
  {
    "id": "demo-057",
    "grade": 5,
    "score": 87,
    "anonymous_id": "AT-5RKW42",
    "task_title": "Moddiy manbalar va Yozma manbalar",
    "submitted_at": "2026-07-01T09:57:00Z",
    "graded_at": "2026-07-01T12:39:00Z"
  },
  {
    "id": "demo-058",
    "grade": 5,
    "score": 79,
    "anonymous_id": "AT-5E66H3",
    "task_title": "Tarixiy manbalarning turlari va ahamiyati",
    "submitted_at": "2026-07-02T09:58:00Z",
    "graded_at": "2026-07-02T12:46:00Z"
  },
  {
    "id": "demo-059",
    "grade": 5,
    "score": 39,
    "anonymous_id": "AT-574QUB",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-03T09:59:00Z",
    "graded_at": "2026-07-03T12:53:00Z"
  },
  {
    "id": "demo-060",
    "grade": 5,
    "score": 39,
    "anonymous_id": "AT-53MANE",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-04T09:00:00Z",
    "graded_at": "2026-07-04T12:00:00Z"
  },
  {
    "id": "demo-061",
    "grade": 5,
    "score": 89,
    "anonymous_id": "AT-5UXXQV",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-05T09:01:00Z",
    "graded_at": "2026-07-05T12:07:00Z"
  },
  {
    "id": "demo-062",
    "grade": 5,
    "score": 50,
    "anonymous_id": "AT-54UVB9",
    "task_title": "Era va Xronologiya tushunchasi",
    "submitted_at": "2026-07-06T09:02:00Z",
    "graded_at": "2026-07-06T12:14:00Z"
  },
  {
    "id": "demo-063",
    "grade": 5,
    "score": 87,
    "anonymous_id": "AT-5SVK46",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-07T09:03:00Z",
    "graded_at": "2026-07-07T12:21:00Z"
  },
  {
    "id": "demo-064",
    "grade": 5,
    "score": 78,
    "anonymous_id": "AT-5ASRLD",
    "task_title": "Moddiy manbalar va Yozma manbalar",
    "submitted_at": "2026-07-08T09:04:00Z",
    "graded_at": "2026-07-08T12:28:00Z"
  },
  {
    "id": "demo-065",
    "grade": 5,
    "score": 50,
    "anonymous_id": "AT-539RAZ",
    "task_title": "Nil daryosi toshqini va birinchi kalendar",
    "submitted_at": "2026-07-09T09:05:00Z",
    "graded_at": "2026-07-09T12:35:00Z"
  },
  {
    "id": "demo-066",
    "grade": 5,
    "score": 78,
    "anonymous_id": "AT-5WFCV8",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-10T09:06:00Z",
    "graded_at": "2026-07-10T12:42:00Z"
  },
  {
    "id": "demo-067",
    "grade": 5,
    "score": 85,
    "anonymous_id": "AT-58M6GT",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-11T09:07:00Z",
    "graded_at": "2026-07-11T12:49:00Z"
  },
  {
    "id": "demo-068",
    "grade": 5,
    "score": 50,
    "anonymous_id": "AT-5TTD5A",
    "task_title": "Moddiy manbalar va Yozma manbalar",
    "submitted_at": "2026-07-12T09:08:00Z",
    "graded_at": "2026-07-12T12:56:00Z"
  },
  {
    "id": "demo-069",
    "grade": 5,
    "score": 66,
    "anonymous_id": "AT-5UXPD2",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-13T09:09:00Z",
    "graded_at": "2026-07-13T12:03:00Z"
  },
  {
    "id": "demo-070",
    "grade": 5,
    "score": 55,
    "anonymous_id": "AT-52NRVY",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-14T09:10:00Z",
    "graded_at": "2026-07-14T12:10:00Z"
  },
  {
    "id": "demo-071",
    "grade": 5,
    "score": 51,
    "anonymous_id": "AT-5923JX",
    "task_title": "Era va Xronologiya tushunchasi",
    "submitted_at": "2026-07-15T09:11:00Z",
    "graded_at": "2026-07-15T12:17:00Z"
  },
  {
    "id": "demo-072",
    "grade": 5,
    "score": 91,
    "anonymous_id": "AT-53WN4K",
    "task_title": "Yoshlar uchun yangi va mukammal Kalendar yaratish loyihasi",
    "submitted_at": "2026-07-16T09:12:00Z",
    "graded_at": "2026-07-16T12:24:00Z"
  },
  {
    "id": "demo-073",
    "grade": 5,
    "score": 72,
    "anonymous_id": "AT-54PU54",
    "task_title": "Yuliy kalendari va Grigoriy kalendari",
    "submitted_at": "2026-07-17T09:13:00Z",
    "graded_at": "2026-07-17T12:31:00Z"
  },
  {
    "id": "demo-074",
    "grade": 5,
    "score": 80,
    "anonymous_id": "AT-5863DM",
    "task_title": "Vatan tarixi — mening o'zligim",
    "submitted_at": "2026-07-18T09:14:00Z",
    "graded_at": "2026-07-18T12:38:00Z"
  },
  {
    "id": "demo-075",
    "grade": 5,
    "score": 88,
    "anonymous_id": "AT-5V59N4",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-19T09:15:00Z",
    "graded_at": "2026-07-19T12:45:00Z"
  },
  {
    "id": "demo-076",
    "grade": 5,
    "score": 50,
    "anonymous_id": "AT-56LM4M",
    "task_title": "Vatan tushunchasi va tarix",
    "submitted_at": "2026-07-20T09:16:00Z",
    "graded_at": "2026-07-20T12:52:00Z"
  },
  {
    "id": "demo-077",
    "grade": 5,
    "score": 51,
    "anonymous_id": "AT-5H9LT3",
    "task_title": "Kalendarlar rivojlanishidagi xatolar va ularning yechimlari",
    "submitted_at": "2026-07-21T09:17:00Z",
    "graded_at": "2026-07-21T12:59:00Z"
  },
  {
    "id": "demo-078",
    "grade": 5,
    "score": 90,
    "anonymous_id": "AT-5UT5Z8",
    "task_title": "Yozma manbalar (Kitoblar, qo'lyozmalar, arxividagi hujjatlar)",
    "submitted_at": "2026-07-22T09:18:00Z",
    "graded_at": "2026-07-22T12:06:00Z"
  },
  {
    "id": "demo-079",
    "grade": 5,
    "score": 70,
    "anonymous_id": "AT-5FFU59",
    "task_title": "Yuliy kalendari",
    "submitted_at": "2026-07-23T09:19:00Z",
    "graded_at": "2026-07-23T12:13:00Z"
  },
  {
    "id": "demo-080",
    "grade": 5,
    "score": 75,
    "anonymous_id": "AT-5CX8TQ",
    "task_title": "\"O'tmishni o'rganmasdan ham baxtli yashash mumkinmi?\"",
    "submitted_at": "2026-07-24T09:20:00Z",
    "graded_at": "2026-07-24T12:20:00Z"
  },
  {
    "id": "demo-081",
    "grade": 6,
    "score": 45,
    "anonymous_id": "AT-6X2TM7",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-25T09:21:00Z",
    "graded_at": "2026-07-25T12:27:00Z"
  },
  {
    "id": "demo-082",
    "grade": 6,
    "score": 87,
    "anonymous_id": "AT-6XNSP9",
    "task_title": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "submitted_at": "2026-07-26T09:22:00Z",
    "graded_at": "2026-07-26T12:34:00Z"
  },
  {
    "id": "demo-083",
    "grade": 6,
    "score": 83,
    "anonymous_id": "AT-6L9Z5S",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-27T09:23:00Z",
    "graded_at": "2026-07-27T12:41:00Z"
  },
  {
    "id": "demo-084",
    "grade": 6,
    "score": 93,
    "anonymous_id": "AT-6DZQNP",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-28T09:24:00Z",
    "graded_at": "2026-07-28T12:48:00Z"
  },
  {
    "id": "demo-085",
    "grade": 6,
    "score": 66,
    "anonymous_id": "AT-6ZESQ8",
    "task_title": "Bobil podshosi Xammurapi qonunlari",
    "submitted_at": "2026-07-01T09:25:00Z",
    "graded_at": "2026-07-01T12:55:00Z"
  },
  {
    "id": "demo-086",
    "grade": 6,
    "score": 80,
    "anonymous_id": "AT-6RT4DN",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-02T09:26:00Z",
    "graded_at": "2026-07-02T12:02:00Z"
  },
  {
    "id": "demo-087",
    "grade": 6,
    "score": 72,
    "anonymous_id": "AT-6TDQ4Z",
    "task_title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "submitted_at": "2026-07-03T09:27:00Z",
    "graded_at": "2026-07-03T12:09:00Z"
  },
  {
    "id": "demo-088",
    "grade": 6,
    "score": 49,
    "anonymous_id": "AT-68XEAK",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-04T09:28:00Z",
    "graded_at": "2026-07-04T12:16:00Z"
  },
  {
    "id": "demo-089",
    "grade": 6,
    "score": 70,
    "anonymous_id": "AT-6NKPES",
    "task_title": "Iskandariya (Aleksandriya) kutubxonasini saqlab qolish",
    "submitted_at": "2026-07-05T09:29:00Z",
    "graded_at": "2026-07-05T12:23:00Z"
  },
  {
    "id": "demo-090",
    "grade": 6,
    "score": 82,
    "anonymous_id": "AT-6VDMUE",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-06T09:30:00Z",
    "graded_at": "2026-07-06T12:30:00Z"
  },
  {
    "id": "demo-091",
    "grade": 6,
    "score": 47,
    "anonymous_id": "AT-6TTDQZ",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-07T09:31:00Z",
    "graded_at": "2026-07-07T12:37:00Z"
  },
  {
    "id": "demo-092",
    "grade": 6,
    "score": 71,
    "anonymous_id": "AT-67VB36",
    "task_title": "Qadimgi Olimpiya o'yinlari",
    "submitted_at": "2026-07-08T09:32:00Z",
    "graded_at": "2026-07-08T12:44:00Z"
  },
  {
    "id": "demo-093",
    "grade": 6,
    "score": 67,
    "anonymous_id": "AT-6Y4437",
    "task_title": "Spartak qo'zg'oloni — ozodlik yo'lidagi fidoiylik",
    "submitted_at": "2026-07-09T09:33:00Z",
    "graded_at": "2026-07-09T12:51:00Z"
  },
  {
    "id": "demo-094",
    "grade": 6,
    "score": 66,
    "anonymous_id": "AT-6C3WPZ",
    "task_title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "submitted_at": "2026-07-10T09:34:00Z",
    "graded_at": "2026-07-10T12:58:00Z"
  },
  {
    "id": "demo-095",
    "grade": 6,
    "score": 60,
    "anonymous_id": "AT-66W63X",
    "task_title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "submitted_at": "2026-07-11T09:35:00Z",
    "graded_at": "2026-07-11T12:05:00Z"
  },
  {
    "id": "demo-096",
    "grade": 6,
    "score": 83,
    "anonymous_id": "AT-6PUWHA",
    "task_title": "Bobil podshosi Xammurapi qonunlari",
    "submitted_at": "2026-07-12T09:36:00Z",
    "graded_at": "2026-07-12T12:12:00Z"
  },
  {
    "id": "demo-097",
    "grade": 6,
    "score": 93,
    "anonymous_id": "AT-6H44F7",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-13T09:37:00Z",
    "graded_at": "2026-07-13T12:19:00Z"
  },
  {
    "id": "demo-098",
    "grade": 6,
    "score": 46,
    "anonymous_id": "AT-6K5B2D",
    "task_title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "submitted_at": "2026-07-14T09:38:00Z",
    "graded_at": "2026-07-14T12:26:00Z"
  },
  {
    "id": "demo-099",
    "grade": 6,
    "score": 71,
    "anonymous_id": "AT-6K69RB",
    "task_title": "Qadimgi Hindistonda kasta tizimi",
    "submitted_at": "2026-07-15T09:39:00Z",
    "graded_at": "2026-07-15T12:33:00Z"
  },
  {
    "id": "demo-100",
    "grade": 6,
    "score": 68,
    "anonymous_id": "AT-69ZRR9",
    "task_title": "Afina va Spartaning siyosiy tuzumi",
    "submitted_at": "2026-07-16T09:40:00Z",
    "graded_at": "2026-07-16T12:40:00Z"
  },
  {
    "id": "demo-101",
    "grade": 6,
    "score": 47,
    "anonymous_id": "AT-6J25PT",
    "task_title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "submitted_at": "2026-07-17T09:41:00Z",
    "graded_at": "2026-07-17T12:47:00Z"
  },
  {
    "id": "demo-102",
    "grade": 6,
    "score": 48,
    "anonymous_id": "AT-645FFQ",
    "task_title": "Bobil podshosi Xammurapi qonunlari",
    "submitted_at": "2026-07-18T09:42:00Z",
    "graded_at": "2026-07-18T12:54:00Z"
  },
  {
    "id": "demo-103",
    "grade": 6,
    "score": 90,
    "anonymous_id": "AT-6XMHGX",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-19T09:43:00Z",
    "graded_at": "2026-07-19T12:01:00Z"
  },
  {
    "id": "demo-104",
    "grade": 6,
    "score": 67,
    "anonymous_id": "AT-6TDB9V",
    "task_title": "Afina va Spartaning siyosiy tuzumi",
    "submitted_at": "2026-07-20T09:44:00Z",
    "graded_at": "2026-07-20T12:08:00Z"
  },
  {
    "id": "demo-105",
    "grade": 6,
    "score": 57,
    "anonymous_id": "AT-6KUN49",
    "task_title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "submitted_at": "2026-07-21T09:45:00Z",
    "graded_at": "2026-07-21T12:15:00Z"
  },
  {
    "id": "demo-106",
    "grade": 6,
    "score": 46,
    "anonymous_id": "AT-6W8HMR",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-22T09:46:00Z",
    "graded_at": "2026-07-22T12:22:00Z"
  },
  {
    "id": "demo-107",
    "grade": 6,
    "score": 92,
    "anonymous_id": "AT-6T23JJ",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-23T09:47:00Z",
    "graded_at": "2026-07-23T12:29:00Z"
  },
  {
    "id": "demo-108",
    "grade": 6,
    "score": 86,
    "anonymous_id": "AT-69ZXYF",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-24T09:48:00Z",
    "graded_at": "2026-07-24T12:36:00Z"
  },
  {
    "id": "demo-109",
    "grade": 6,
    "score": 49,
    "anonymous_id": "AT-6R5NES",
    "task_title": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "submitted_at": "2026-07-25T09:49:00Z",
    "graded_at": "2026-07-25T12:43:00Z"
  },
  {
    "id": "demo-110",
    "grade": 6,
    "score": 78,
    "anonymous_id": "AT-6478Y5",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-26T09:50:00Z",
    "graded_at": "2026-07-26T12:50:00Z"
  },
  {
    "id": "demo-111",
    "grade": 6,
    "score": 72,
    "anonymous_id": "AT-6NM873",
    "task_title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "submitted_at": "2026-07-27T09:51:00Z",
    "graded_at": "2026-07-27T12:57:00Z"
  },
  {
    "id": "demo-112",
    "grade": 6,
    "score": 45,
    "anonymous_id": "AT-6H3YYM",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-28T09:52:00Z",
    "graded_at": "2026-07-28T12:04:00Z"
  },
  {
    "id": "demo-113",
    "grade": 6,
    "score": 46,
    "anonymous_id": "AT-6N3KQ6",
    "task_title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "submitted_at": "2026-07-01T09:53:00Z",
    "graded_at": "2026-07-01T12:11:00Z"
  },
  {
    "id": "demo-114",
    "grade": 6,
    "score": 66,
    "anonymous_id": "AT-6PK8PC",
    "task_title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "submitted_at": "2026-07-02T09:54:00Z",
    "graded_at": "2026-07-02T12:18:00Z"
  },
  {
    "id": "demo-115",
    "grade": 6,
    "score": 84,
    "anonymous_id": "AT-6K9GYR",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-03T09:55:00Z",
    "graded_at": "2026-07-03T12:25:00Z"
  },
  {
    "id": "demo-116",
    "grade": 6,
    "score": 85,
    "anonymous_id": "AT-6RPNDR",
    "task_title": "Bobil podshosi Xammurapi qonunlari",
    "submitted_at": "2026-07-04T09:56:00Z",
    "graded_at": "2026-07-04T12:32:00Z"
  },
  {
    "id": "demo-117",
    "grade": 6,
    "score": 83,
    "anonymous_id": "AT-6J4ET2",
    "task_title": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "submitted_at": "2026-07-05T09:57:00Z",
    "graded_at": "2026-07-05T12:39:00Z"
  },
  {
    "id": "demo-118",
    "grade": 6,
    "score": 62,
    "anonymous_id": "AT-6YM3YZ",
    "task_title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "submitted_at": "2026-07-06T09:58:00Z",
    "graded_at": "2026-07-06T12:46:00Z"
  },
  {
    "id": "demo-119",
    "grade": 6,
    "score": 90,
    "anonymous_id": "AT-6HGWDQ",
    "task_title": "Afina va Spartaning siyosiy tuzumi",
    "submitted_at": "2026-07-07T09:59:00Z",
    "graded_at": "2026-07-07T12:53:00Z"
  },
  {
    "id": "demo-120",
    "grade": 6,
    "score": 57,
    "anonymous_id": "AT-634AXX",
    "task_title": "Xalqlarning buyuk ko'chishi va uning oqibatlari",
    "submitted_at": "2026-07-08T09:00:00Z",
    "graded_at": "2026-07-08T12:00:00Z"
  },
  {
    "id": "demo-121",
    "grade": 6,
    "score": 75,
    "anonymous_id": "AT-6D7YUU",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-09T09:01:00Z",
    "graded_at": "2026-07-09T12:07:00Z"
  },
  {
    "id": "demo-122",
    "grade": 6,
    "score": 71,
    "anonymous_id": "AT-6JW2G4",
    "task_title": "Qadimgi Olimpiya o'yinlari",
    "submitted_at": "2026-07-10T09:02:00Z",
    "graded_at": "2026-07-10T12:14:00Z"
  },
  {
    "id": "demo-123",
    "grade": 6,
    "score": 70,
    "anonymous_id": "AT-6AU3YV",
    "task_title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "submitted_at": "2026-07-11T09:03:00Z",
    "graded_at": "2026-07-11T12:21:00Z"
  },
  {
    "id": "demo-124",
    "grade": 6,
    "score": 60,
    "anonymous_id": "AT-6MYAZN",
    "task_title": "Afina va Spartaning siyosiy tuzumi",
    "submitted_at": "2026-07-12T09:04:00Z",
    "graded_at": "2026-07-12T12:28:00Z"
  },
  {
    "id": "demo-125",
    "grade": 6,
    "score": 59,
    "anonymous_id": "AT-6KVHAC",
    "task_title": "Qadimgi Hindistonda kasta tizimi",
    "submitted_at": "2026-07-13T09:05:00Z",
    "graded_at": "2026-07-13T12:35:00Z"
  },
  {
    "id": "demo-126",
    "grade": 6,
    "score": 63,
    "anonymous_id": "AT-6GBBNE",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-14T09:06:00Z",
    "graded_at": "2026-07-14T12:42:00Z"
  },
  {
    "id": "demo-127",
    "grade": 6,
    "score": 66,
    "anonymous_id": "AT-6S9BRF",
    "task_title": "Qadimgi Yunoniston madaniyati va Rim madaniyati",
    "submitted_at": "2026-07-15T09:07:00Z",
    "graded_at": "2026-07-15T12:49:00Z"
  },
  {
    "id": "demo-128",
    "grade": 6,
    "score": 75,
    "anonymous_id": "AT-65QNRP",
    "task_title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "submitted_at": "2026-07-16T09:08:00Z",
    "graded_at": "2026-07-16T12:56:00Z"
  },
  {
    "id": "demo-129",
    "grade": 6,
    "score": 88,
    "anonymous_id": "AT-6SJTD9",
    "task_title": "Qadimgi Hindistonda kasta tizimi",
    "submitted_at": "2026-07-17T09:09:00Z",
    "graded_at": "2026-07-17T12:03:00Z"
  },
  {
    "id": "demo-130",
    "grade": 6,
    "score": 48,
    "anonymous_id": "AT-6HRNAT",
    "task_title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "submitted_at": "2026-07-18T09:10:00Z",
    "graded_at": "2026-07-18T12:10:00Z"
  },
  {
    "id": "demo-131",
    "grade": 6,
    "score": 88,
    "anonymous_id": "AT-6KLCVN",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-19T09:11:00Z",
    "graded_at": "2026-07-19T12:17:00Z"
  },
  {
    "id": "demo-132",
    "grade": 6,
    "score": 57,
    "anonymous_id": "AT-6CHJ84",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-20T09:12:00Z",
    "graded_at": "2026-07-20T12:24:00Z"
  },
  {
    "id": "demo-133",
    "grade": 6,
    "score": 44,
    "anonymous_id": "AT-6YA656",
    "task_title": "Qadimgi Hindistonda kasta tizimi",
    "submitted_at": "2026-07-21T09:13:00Z",
    "graded_at": "2026-07-21T12:31:00Z"
  },
  {
    "id": "demo-134",
    "grade": 6,
    "score": 83,
    "anonymous_id": "AT-6EW4AQ",
    "task_title": "Iskandariya (Aleksandriya) kutubxonasini saqlab qolish",
    "submitted_at": "2026-07-22T09:14:00Z",
    "graded_at": "2026-07-22T12:38:00Z"
  },
  {
    "id": "demo-135",
    "grade": 6,
    "score": 42,
    "anonymous_id": "AT-6AVU5Q",
    "task_title": "Iskandariya (Aleksandriya) kutubxonasini saqlab qolish",
    "submitted_at": "2026-07-23T09:15:00Z",
    "graded_at": "2026-07-23T12:45:00Z"
  },
  {
    "id": "demo-136",
    "grade": 6,
    "score": 81,
    "anonymous_id": "AT-68GEAS",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-24T09:16:00Z",
    "graded_at": "2026-07-24T12:52:00Z"
  },
  {
    "id": "demo-137",
    "grade": 6,
    "score": 87,
    "anonymous_id": "AT-64U3J2",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-25T09:17:00Z",
    "graded_at": "2026-07-25T12:59:00Z"
  },
  {
    "id": "demo-138",
    "grade": 6,
    "score": 48,
    "anonymous_id": "AT-6NH275",
    "task_title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "submitted_at": "2026-07-26T09:18:00Z",
    "graded_at": "2026-07-26T12:06:00Z"
  },
  {
    "id": "demo-139",
    "grade": 6,
    "score": 76,
    "anonymous_id": "AT-6Z2QJE",
    "task_title": "Qadimgi Olimpiya o'yinlari",
    "submitted_at": "2026-07-27T09:19:00Z",
    "graded_at": "2026-07-27T12:13:00Z"
  },
  {
    "id": "demo-140",
    "grade": 6,
    "score": 40,
    "anonymous_id": "AT-6J6DLL",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-28T09:20:00Z",
    "graded_at": "2026-07-28T12:20:00Z"
  },
  {
    "id": "demo-141",
    "grade": 6,
    "score": 42,
    "anonymous_id": "AT-6KL6WQ",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-01T09:21:00Z",
    "graded_at": "2026-07-01T12:27:00Z"
  },
  {
    "id": "demo-142",
    "grade": 6,
    "score": 61,
    "anonymous_id": "AT-6QTL9G",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-02T09:22:00Z",
    "graded_at": "2026-07-02T12:34:00Z"
  },
  {
    "id": "demo-143",
    "grade": 6,
    "score": 85,
    "anonymous_id": "AT-66T4HQ",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-03T09:23:00Z",
    "graded_at": "2026-07-03T12:41:00Z"
  },
  {
    "id": "demo-144",
    "grade": 6,
    "score": 84,
    "anonymous_id": "AT-6X83WD",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-04T09:24:00Z",
    "graded_at": "2026-07-04T12:48:00Z"
  },
  {
    "id": "demo-145",
    "grade": 6,
    "score": 41,
    "anonymous_id": "AT-6EVG97",
    "task_title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "submitted_at": "2026-07-05T09:25:00Z",
    "graded_at": "2026-07-05T12:55:00Z"
  },
  {
    "id": "demo-146",
    "grade": 6,
    "score": 62,
    "anonymous_id": "AT-6ZJT5T",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-06T09:26:00Z",
    "graded_at": "2026-07-06T12:02:00Z"
  },
  {
    "id": "demo-147",
    "grade": 6,
    "score": 48,
    "anonymous_id": "AT-6VUV2Q",
    "task_title": "Spartak qo'zg'oloni — ozodlik yo'lidagi fidoiylik",
    "submitted_at": "2026-07-07T09:27:00Z",
    "graded_at": "2026-07-07T12:09:00Z"
  },
  {
    "id": "demo-148",
    "grade": 6,
    "score": 47,
    "anonymous_id": "AT-6APCFH",
    "task_title": "Bobil podshosi Xammurapi qonunlari",
    "submitted_at": "2026-07-08T09:28:00Z",
    "graded_at": "2026-07-08T12:16:00Z"
  },
  {
    "id": "demo-149",
    "grade": 6,
    "score": 40,
    "anonymous_id": "AT-63TZ7B",
    "task_title": "Iskandar Maqduniy (Aleksandr Makedonskiy) imperiyasi",
    "submitted_at": "2026-07-09T09:29:00Z",
    "graded_at": "2026-07-09T12:23:00Z"
  },
  {
    "id": "demo-150",
    "grade": 6,
    "score": 90,
    "anonymous_id": "AT-68HMQ7",
    "task_title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "submitted_at": "2026-07-10T09:30:00Z",
    "graded_at": "2026-07-10T12:30:00Z"
  },
  {
    "id": "demo-151",
    "grade": 6,
    "score": 69,
    "anonymous_id": "AT-6M8YEG",
    "task_title": "Qadimgi Misr va Qadimgi Ikki daryo oralig'i (Mesopotamiya)",
    "submitted_at": "2026-07-11T09:31:00Z",
    "graded_at": "2026-07-11T12:37:00Z"
  },
  {
    "id": "demo-152",
    "grade": 6,
    "score": 57,
    "anonymous_id": "AT-6HDYZ8",
    "task_title": "Qadimgi Rimda toza suv tarmog'i va yo'llar qurilishi (Muhandislik loyihasi)",
    "submitted_at": "2026-07-12T09:32:00Z",
    "graded_at": "2026-07-12T12:44:00Z"
  },
  {
    "id": "demo-153",
    "grade": 6,
    "score": 60,
    "anonymous_id": "AT-6VH5BP",
    "task_title": "Xalqlarning buyuk ko'chishi va uning oqibatlari",
    "submitted_at": "2026-07-13T09:33:00Z",
    "graded_at": "2026-07-13T12:51:00Z"
  },
  {
    "id": "demo-154",
    "grade": 6,
    "score": 55,
    "anonymous_id": "AT-6H9EKL",
    "task_title": "Qadimgi yunon faylasuflari va mening dunyoqarashim",
    "submitted_at": "2026-07-14T09:34:00Z",
    "graded_at": "2026-07-14T12:58:00Z"
  },
  {
    "id": "demo-155",
    "grade": 6,
    "score": 68,
    "anonymous_id": "AT-6GYCCN",
    "task_title": "Makedoniyalik Iskandarning Sharqqa yurishi – sivilizatsiyalar to'qnashuvimi yoki o'zaro boyishmi?",
    "submitted_at": "2026-07-15T09:35:00Z",
    "graded_at": "2026-07-15T12:05:00Z"
  },
  {
    "id": "demo-156",
    "grade": 6,
    "score": 75,
    "anonymous_id": "AT-6XYXKV",
    "task_title": "Gladiatorlar jangi – tomoshami yoki inson huquqining toptalishimi?",
    "submitted_at": "2026-07-16T09:36:00Z",
    "graded_at": "2026-07-16T12:12:00Z"
  },
  {
    "id": "demo-157",
    "grade": 6,
    "score": 47,
    "anonymous_id": "AT-69SRNT",
    "task_title": "Qadimgi Misrda ehromlarning (piramidalarning) qurilishi",
    "submitted_at": "2026-07-17T09:37:00Z",
    "graded_at": "2026-07-17T12:19:00Z"
  },
  {
    "id": "demo-158",
    "grade": 6,
    "score": 64,
    "anonymous_id": "AT-6UW83G",
    "task_title": "Qadimgi Hindistonda kasta tizimi",
    "submitted_at": "2026-07-18T09:38:00Z",
    "graded_at": "2026-07-18T12:26:00Z"
  },
  {
    "id": "demo-159",
    "grade": 6,
    "score": 64,
    "anonymous_id": "AT-6LZHXQ",
    "task_title": "Qadimgi Olimpiya o'yinlari",
    "submitted_at": "2026-07-19T09:39:00Z",
    "graded_at": "2026-07-19T12:33:00Z"
  },
  {
    "id": "demo-160",
    "grade": 6,
    "score": 59,
    "anonymous_id": "AT-6C88NR",
    "task_title": "Xalqlarning buyuk ko'chishi va uning oqibatlari",
    "submitted_at": "2026-07-20T09:40:00Z",
    "graded_at": "2026-07-20T12:40:00Z"
  },
  {
    "id": "demo-161",
    "grade": 7,
    "score": 60,
    "anonymous_id": "AT-7XBCKC",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-21T09:41:00Z",
    "graded_at": "2026-07-21T12:47:00Z"
  },
  {
    "id": "demo-162",
    "grade": 7,
    "score": 71,
    "anonymous_id": "AT-7H4B6S",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-22T09:42:00Z",
    "graded_at": "2026-07-22T12:54:00Z"
  },
  {
    "id": "demo-163",
    "grade": 7,
    "score": 86,
    "anonymous_id": "AT-7FJDYP",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-23T09:43:00Z",
    "graded_at": "2026-07-23T12:01:00Z"
  },
  {
    "id": "demo-164",
    "grade": 7,
    "score": 74,
    "anonymous_id": "AT-7XMP25",
    "task_title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "submitted_at": "2026-07-24T09:44:00Z",
    "graded_at": "2026-07-24T12:08:00Z"
  },
  {
    "id": "demo-165",
    "grade": 7,
    "score": 64,
    "anonymous_id": "AT-7TMS6G",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-25T09:45:00Z",
    "graded_at": "2026-07-25T12:15:00Z"
  },
  {
    "id": "demo-166",
    "grade": 7,
    "score": 81,
    "anonymous_id": "AT-74M89N",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-26T09:46:00Z",
    "graded_at": "2026-07-26T12:22:00Z"
  },
  {
    "id": "demo-167",
    "grade": 7,
    "score": 69,
    "anonymous_id": "AT-7VGQEX",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-27T09:47:00Z",
    "graded_at": "2026-07-27T12:29:00Z"
  },
  {
    "id": "demo-168",
    "grade": 7,
    "score": 76,
    "anonymous_id": "AT-78CUXH",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-28T09:48:00Z",
    "graded_at": "2026-07-28T12:36:00Z"
  },
  {
    "id": "demo-169",
    "grade": 7,
    "score": 48,
    "anonymous_id": "AT-74DBKX",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-01T09:49:00Z",
    "graded_at": "2026-07-01T12:43:00Z"
  },
  {
    "id": "demo-170",
    "grade": 7,
    "score": 80,
    "anonymous_id": "AT-7LYM8P",
    "task_title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "submitted_at": "2026-07-02T09:50:00Z",
    "graded_at": "2026-07-02T12:50:00Z"
  },
  {
    "id": "demo-171",
    "grade": 7,
    "score": 54,
    "anonymous_id": "AT-7NVJMH",
    "task_title": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "submitted_at": "2026-07-03T09:51:00Z",
    "graded_at": "2026-07-03T12:57:00Z"
  },
  {
    "id": "demo-172",
    "grade": 7,
    "score": 65,
    "anonymous_id": "AT-7YUCT2",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-04T09:52:00Z",
    "graded_at": "2026-07-04T12:04:00Z"
  },
  {
    "id": "demo-173",
    "grade": 7,
    "score": 79,
    "anonymous_id": "AT-7G5BCK",
    "task_title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "submitted_at": "2026-07-05T09:53:00Z",
    "graded_at": "2026-07-05T12:11:00Z"
  },
  {
    "id": "demo-174",
    "grade": 7,
    "score": 75,
    "anonymous_id": "AT-7YGS7E",
    "task_title": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "submitted_at": "2026-07-06T09:54:00Z",
    "graded_at": "2026-07-06T12:18:00Z"
  },
  {
    "id": "demo-175",
    "grade": 7,
    "score": 55,
    "anonymous_id": "AT-7EQRHU",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-07T09:55:00Z",
    "graded_at": "2026-07-07T12:25:00Z"
  },
  {
    "id": "demo-176",
    "grade": 7,
    "score": 41,
    "anonymous_id": "AT-7A4LQQ",
    "task_title": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "submitted_at": "2026-07-08T09:56:00Z",
    "graded_at": "2026-07-08T12:32:00Z"
  },
  {
    "id": "demo-177",
    "grade": 7,
    "score": 45,
    "anonymous_id": "AT-7FAMME",
    "task_title": "IV-VII asrlarda Xorazm vohasida qishloq xo'jaligini rivojlantirish",
    "submitted_at": "2026-07-09T09:57:00Z",
    "graded_at": "2026-07-09T12:39:00Z"
  },
  {
    "id": "demo-178",
    "grade": 7,
    "score": 88,
    "anonymous_id": "AT-7KE8BX",
    "task_title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "submitted_at": "2026-07-10T09:58:00Z",
    "graded_at": "2026-07-10T12:46:00Z"
  },
  {
    "id": "demo-179",
    "grade": 7,
    "score": 64,
    "anonymous_id": "AT-753DA8",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-11T09:59:00Z",
    "graded_at": "2026-07-11T12:53:00Z"
  },
  {
    "id": "demo-180",
    "grade": 7,
    "score": 86,
    "anonymous_id": "AT-78W7PV",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-12T09:00:00Z",
    "graded_at": "2026-07-12T12:00:00Z"
  },
  {
    "id": "demo-181",
    "grade": 7,
    "score": 90,
    "anonymous_id": "AT-7XHUMD",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-13T09:01:00Z",
    "graded_at": "2026-07-13T12:07:00Z"
  },
  {
    "id": "demo-182",
    "grade": 7,
    "score": 84,
    "anonymous_id": "AT-7Z6YYY",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-14T09:02:00Z",
    "graded_at": "2026-07-14T12:14:00Z"
  },
  {
    "id": "demo-183",
    "grade": 7,
    "score": 58,
    "anonymous_id": "AT-7CK9FV",
    "task_title": "Suv inshootlari — xalq farovonligi omilimi yoki tabaqalanish qurolimi?",
    "submitted_at": "2026-07-15T09:03:00Z",
    "graded_at": "2026-07-15T12:21:00Z"
  },
  {
    "id": "demo-184",
    "grade": 7,
    "score": 64,
    "anonymous_id": "AT-7BLDN2",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-16T09:04:00Z",
    "graded_at": "2026-07-16T12:28:00Z"
  },
  {
    "id": "demo-185",
    "grade": 7,
    "score": 65,
    "anonymous_id": "AT-7HEW76",
    "task_title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "submitted_at": "2026-07-17T09:05:00Z",
    "graded_at": "2026-07-17T12:35:00Z"
  },
  {
    "id": "demo-186",
    "grade": 7,
    "score": 45,
    "anonymous_id": "AT-7ARU5W",
    "task_title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "submitted_at": "2026-07-18T09:06:00Z",
    "graded_at": "2026-07-18T12:42:00Z"
  },
  {
    "id": "demo-187",
    "grade": 7,
    "score": 51,
    "anonymous_id": "AT-7TE5Q4",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-19T09:07:00Z",
    "graded_at": "2026-07-19T12:49:00Z"
  },
  {
    "id": "demo-188",
    "grade": 7,
    "score": 58,
    "anonymous_id": "AT-7AJUAE",
    "task_title": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "submitted_at": "2026-07-20T09:08:00Z",
    "graded_at": "2026-07-20T12:56:00Z"
  },
  {
    "id": "demo-189",
    "grade": 7,
    "score": 65,
    "anonymous_id": "AT-7ENTTW",
    "task_title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "submitted_at": "2026-07-21T09:09:00Z",
    "graded_at": "2026-07-21T12:03:00Z"
  },
  {
    "id": "demo-190",
    "grade": 7,
    "score": 78,
    "anonymous_id": "AT-7P5ZD4",
    "task_title": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "submitted_at": "2026-07-22T09:10:00Z",
    "graded_at": "2026-07-22T12:10:00Z"
  },
  {
    "id": "demo-191",
    "grade": 7,
    "score": 44,
    "anonymous_id": "AT-7L7YAK",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-23T09:11:00Z",
    "graded_at": "2026-07-23T12:17:00Z"
  },
  {
    "id": "demo-192",
    "grade": 7,
    "score": 47,
    "anonymous_id": "AT-7GN6DF",
    "task_title": "German jangchilari va tarixiy manbalar qadri",
    "submitted_at": "2026-07-24T09:12:00Z",
    "graded_at": "2026-07-24T12:24:00Z"
  },
  {
    "id": "demo-193",
    "grade": 7,
    "score": 79,
    "anonymous_id": "AT-7V9CA6",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-25T09:13:00Z",
    "graded_at": "2026-07-25T12:31:00Z"
  },
  {
    "id": "demo-194",
    "grade": 7,
    "score": 88,
    "anonymous_id": "AT-7DFDJW",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-26T09:14:00Z",
    "graded_at": "2026-07-26T12:38:00Z"
  },
  {
    "id": "demo-195",
    "grade": 7,
    "score": 89,
    "anonymous_id": "AT-7SZZCF",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-27T09:15:00Z",
    "graded_at": "2026-07-27T12:45:00Z"
  },
  {
    "id": "demo-196",
    "grade": 7,
    "score": 73,
    "anonymous_id": "AT-743JC5",
    "task_title": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "submitted_at": "2026-07-28T09:16:00Z",
    "graded_at": "2026-07-28T12:52:00Z"
  },
  {
    "id": "demo-197",
    "grade": 7,
    "score": 66,
    "anonymous_id": "AT-7EUVR3",
    "task_title": "Rim imperiyasi va germanlar",
    "submitted_at": "2026-07-01T09:17:00Z",
    "graded_at": "2026-07-01T12:59:00Z"
  },
  {
    "id": "demo-198",
    "grade": 7,
    "score": 79,
    "anonymous_id": "AT-7Q6L7G",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-02T09:18:00Z",
    "graded_at": "2026-07-02T12:06:00Z"
  },
  {
    "id": "demo-199",
    "grade": 7,
    "score": 71,
    "anonymous_id": "AT-7K75L9",
    "task_title": "IV-VII asrlarda Xorazm vohasida qishloq xo'jaligini rivojlantirish",
    "submitted_at": "2026-07-03T09:19:00Z",
    "graded_at": "2026-07-03T12:13:00Z"
  },
  {
    "id": "demo-200",
    "grade": 7,
    "score": 47,
    "anonymous_id": "AT-7BUBGF",
    "task_title": "German jangchilari va tarixiy manbalar qadri",
    "submitted_at": "2026-07-04T09:20:00Z",
    "graded_at": "2026-07-04T12:20:00Z"
  },
  {
    "id": "demo-201",
    "grade": 7,
    "score": 55,
    "anonymous_id": "AT-7Q8JP4",
    "task_title": "German jangchilari va tarixiy manbalar qadri",
    "submitted_at": "2026-07-05T09:21:00Z",
    "graded_at": "2026-07-05T12:27:00Z"
  },
  {
    "id": "demo-202",
    "grade": 7,
    "score": 83,
    "anonymous_id": "AT-73UDUL",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-06T09:22:00Z",
    "graded_at": "2026-07-06T12:34:00Z"
  },
  {
    "id": "demo-203",
    "grade": 7,
    "score": 39,
    "anonymous_id": "AT-7KWW46",
    "task_title": "Ilk o'rta asrlarda O'rta Osiyodagi tabaqalar",
    "submitted_at": "2026-07-07T09:23:00Z",
    "graded_at": "2026-07-07T12:41:00Z"
  },
  {
    "id": "demo-204",
    "grade": 7,
    "score": 76,
    "anonymous_id": "AT-7DVHD7",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-08T09:24:00Z",
    "graded_at": "2026-07-08T12:48:00Z"
  },
  {
    "id": "demo-205",
    "grade": 7,
    "score": 85,
    "anonymous_id": "AT-78QRSX",
    "task_title": "German jangchilari va tarixiy manbalar qadri",
    "submitted_at": "2026-07-09T09:25:00Z",
    "graded_at": "2026-07-09T12:55:00Z"
  },
  {
    "id": "demo-206",
    "grade": 7,
    "score": 92,
    "anonymous_id": "AT-7X3THA",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-10T09:26:00Z",
    "graded_at": "2026-07-10T12:02:00Z"
  },
  {
    "id": "demo-207",
    "grade": 7,
    "score": 64,
    "anonymous_id": "AT-7343LC",
    "task_title": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "submitted_at": "2026-07-11T09:27:00Z",
    "graded_at": "2026-07-11T12:09:00Z"
  },
  {
    "id": "demo-208",
    "grade": 7,
    "score": 43,
    "anonymous_id": "AT-7F6TSV",
    "task_title": "Rim imperiyasini inqirozdan saqlab qolish",
    "submitted_at": "2026-07-12T09:28:00Z",
    "graded_at": "2026-07-12T12:16:00Z"
  },
  {
    "id": "demo-209",
    "grade": 7,
    "score": 43,
    "anonymous_id": "AT-7UNURC",
    "task_title": "IV-VII asrlarda Xorazm vohasida qishloq xo'jaligini rivojlantirish",
    "submitted_at": "2026-07-13T09:29:00Z",
    "graded_at": "2026-07-13T12:23:00Z"
  },
  {
    "id": "demo-210",
    "grade": 7,
    "score": 55,
    "anonymous_id": "AT-7YHY38",
    "task_title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "submitted_at": "2026-07-14T09:30:00Z",
    "graded_at": "2026-07-14T12:30:00Z"
  },
  {
    "id": "demo-211",
    "grade": 7,
    "score": 58,
    "anonymous_id": "AT-7VPVM3",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-15T09:31:00Z",
    "graded_at": "2026-07-15T12:37:00Z"
  },
  {
    "id": "demo-212",
    "grade": 7,
    "score": 57,
    "anonymous_id": "AT-7VQHA3",
    "task_title": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "submitted_at": "2026-07-16T09:32:00Z",
    "graded_at": "2026-07-16T12:44:00Z"
  },
  {
    "id": "demo-213",
    "grade": 7,
    "score": 66,
    "anonymous_id": "AT-7U7FUU",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-17T09:33:00Z",
    "graded_at": "2026-07-17T12:51:00Z"
  },
  {
    "id": "demo-214",
    "grade": 7,
    "score": 62,
    "anonymous_id": "AT-7EP9AH",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-18T09:34:00Z",
    "graded_at": "2026-07-18T12:58:00Z"
  },
  {
    "id": "demo-215",
    "grade": 7,
    "score": 64,
    "anonymous_id": "AT-7Z9HUW",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-19T09:35:00Z",
    "graded_at": "2026-07-19T12:05:00Z"
  },
  {
    "id": "demo-216",
    "grade": 7,
    "score": 43,
    "anonymous_id": "AT-78K86R",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-20T09:36:00Z",
    "graded_at": "2026-07-20T12:12:00Z"
  },
  {
    "id": "demo-217",
    "grade": 7,
    "score": 81,
    "anonymous_id": "AT-7K7THC",
    "task_title": "G'arbiy va Sharqiy Rim imperiyalari (395-yildan so'ng)",
    "submitted_at": "2026-07-21T09:37:00Z",
    "graded_at": "2026-07-21T12:19:00Z"
  },
  {
    "id": "demo-218",
    "grade": 7,
    "score": 56,
    "anonymous_id": "AT-78LWMT",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-22T09:38:00Z",
    "graded_at": "2026-07-22T12:26:00Z"
  },
  {
    "id": "demo-219",
    "grade": 7,
    "score": 53,
    "anonymous_id": "AT-7ETV2V",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-23T09:39:00Z",
    "graded_at": "2026-07-23T12:33:00Z"
  },
  {
    "id": "demo-220",
    "grade": 7,
    "score": 45,
    "anonymous_id": "AT-7EBTHS",
    "task_title": "O'rta asrlarda Yevropa va Turondagi ijtimoiy tabaqalar",
    "submitted_at": "2026-07-24T09:40:00Z",
    "graded_at": "2026-07-24T12:40:00Z"
  },
  {
    "id": "demo-221",
    "grade": 7,
    "score": 45,
    "anonymous_id": "AT-7UPPU4",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-25T09:41:00Z",
    "graded_at": "2026-07-25T12:47:00Z"
  },
  {
    "id": "demo-222",
    "grade": 7,
    "score": 48,
    "anonymous_id": "AT-783DFR",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-26T09:42:00Z",
    "graded_at": "2026-07-26T12:54:00Z"
  },
  {
    "id": "demo-223",
    "grade": 7,
    "score": 88,
    "anonymous_id": "AT-7X4KRN",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-27T09:43:00Z",
    "graded_at": "2026-07-27T12:01:00Z"
  },
  {
    "id": "demo-224",
    "grade": 7,
    "score": 53,
    "anonymous_id": "AT-7XHBPA",
    "task_title": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "submitted_at": "2026-07-28T09:44:00Z",
    "graded_at": "2026-07-28T12:08:00Z"
  },
  {
    "id": "demo-225",
    "grade": 7,
    "score": 57,
    "anonymous_id": "AT-7JVJAT",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-01T09:45:00Z",
    "graded_at": "2026-07-01T12:15:00Z"
  },
  {
    "id": "demo-226",
    "grade": 7,
    "score": 51,
    "anonymous_id": "AT-79DHAA",
    "task_title": "Suv inshootlari — xalq farovonligi omilimi yoki tabaqalanish qurolimi?",
    "submitted_at": "2026-07-02T09:46:00Z",
    "graded_at": "2026-07-02T12:22:00Z"
  },
  {
    "id": "demo-227",
    "grade": 7,
    "score": 59,
    "anonymous_id": "AT-7F94QR",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-03T09:47:00Z",
    "graded_at": "2026-07-03T12:29:00Z"
  },
  {
    "id": "demo-228",
    "grade": 7,
    "score": 53,
    "anonymous_id": "AT-7FUCPD",
    "task_title": "Rim imperiyasi va germanlar",
    "submitted_at": "2026-07-04T09:48:00Z",
    "graded_at": "2026-07-04T12:36:00Z"
  },
  {
    "id": "demo-229",
    "grade": 7,
    "score": 88,
    "anonymous_id": "AT-7L3PBY",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-05T09:49:00Z",
    "graded_at": "2026-07-05T12:43:00Z"
  },
  {
    "id": "demo-230",
    "grade": 7,
    "score": 49,
    "anonymous_id": "AT-7MEFQY",
    "task_title": "Suv inshootlari — xalq farovonligi omilimi yoki tabaqalanish qurolimi?",
    "submitted_at": "2026-07-06T09:50:00Z",
    "graded_at": "2026-07-06T12:50:00Z"
  },
  {
    "id": "demo-231",
    "grade": 7,
    "score": 57,
    "anonymous_id": "AT-7XUBTS",
    "task_title": "O'zbekiston hududida o'rta asrlarning boshlanishi",
    "submitted_at": "2026-07-07T09:51:00Z",
    "graded_at": "2026-07-07T12:57:00Z"
  },
  {
    "id": "demo-232",
    "grade": 7,
    "score": 51,
    "anonymous_id": "AT-7HEEUG",
    "task_title": "G'arbiy Rim imperiyasining qulashi",
    "submitted_at": "2026-07-08T09:52:00Z",
    "graded_at": "2026-07-08T12:04:00Z"
  },
  {
    "id": "demo-233",
    "grade": 7,
    "score": 42,
    "anonymous_id": "AT-77D9Q4",
    "task_title": "Rim imperiyasi va germanlar",
    "submitted_at": "2026-07-09T09:53:00Z",
    "graded_at": "2026-07-09T12:11:00Z"
  },
  {
    "id": "demo-234",
    "grade": 7,
    "score": 50,
    "anonymous_id": "AT-7Y9FFV",
    "task_title": "Rim imperiyasi va germanlar",
    "submitted_at": "2026-07-10T09:54:00Z",
    "graded_at": "2026-07-10T12:18:00Z"
  },
  {
    "id": "demo-235",
    "grade": 7,
    "score": 62,
    "anonymous_id": "AT-7G8WDQ",
    "task_title": "Vatan tarixidan kelajak sari — Shaxsiy xulosa",
    "submitted_at": "2026-07-11T09:55:00Z",
    "graded_at": "2026-07-11T12:25:00Z"
  },
  {
    "id": "demo-236",
    "grade": 7,
    "score": 85,
    "anonymous_id": "AT-7GSXMT",
    "task_title": "Germanlarning kundalik hayoti va xo'jaligi",
    "submitted_at": "2026-07-12T09:56:00Z",
    "graded_at": "2026-07-12T12:32:00Z"
  },
  {
    "id": "demo-237",
    "grade": 7,
    "score": 90,
    "anonymous_id": "AT-73AE38",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-13T09:57:00Z",
    "graded_at": "2026-07-13T12:39:00Z"
  },
  {
    "id": "demo-238",
    "grade": 7,
    "score": 58,
    "anonymous_id": "AT-7TE3E7",
    "task_title": "IV-VII asrlarda Xorazm vohasining geografik va xo'jalik imkoniyatlari",
    "submitted_at": "2026-07-14T09:58:00Z",
    "graded_at": "2026-07-14T12:46:00Z"
  },
  {
    "id": "demo-239",
    "grade": 7,
    "score": 84,
    "anonymous_id": "AT-7PXQV7",
    "task_title": "Germanlarning Rimni bosib olishi — vayronagarchilikmi yoki yangi sivilizatsiya bosqichimi?",
    "submitted_at": "2026-07-15T09:59:00Z",
    "graded_at": "2026-07-15T12:53:00Z"
  },
  {
    "id": "demo-240",
    "grade": 7,
    "score": 88,
    "anonymous_id": "AT-72C2K3",
    "task_title": "Qadimgi german qabilalarining xo'jaligi va jamiyati",
    "submitted_at": "2026-07-16T09:00:00Z",
    "graded_at": "2026-07-16T12:00:00Z"
  },
  {
    "id": "demo-241",
    "grade": 7,
    "score": 90,
    "anonymous_id": "AT-72VF7C",
    "task_title": "Ilk o'rta asrlarda suv inshootlari va tabaqalanish",
    "submitted_at": "2026-07-17T09:01:00Z",
    "graded_at": "2026-07-17T12:07:00Z"
  },
  {
    "id": "demo-242",
    "grade": 8,
    "score": 71,
    "anonymous_id": "AT-87WDMS",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-18T09:02:00Z",
    "graded_at": "2026-07-18T12:14:00Z"
  },
  {
    "id": "demo-243",
    "grade": 8,
    "score": 41,
    "anonymous_id": "AT-8E5JZ3",
    "task_title": "Aleksandr Nevskiyning g'alaba omillari",
    "submitted_at": "2026-07-19T09:03:00Z",
    "graded_at": "2026-07-19T12:21:00Z"
  },
  {
    "id": "demo-244",
    "grade": 8,
    "score": 73,
    "anonymous_id": "AT-85VUE5",
    "task_title": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "submitted_at": "2026-07-20T09:04:00Z",
    "graded_at": "2026-07-20T12:28:00Z"
  },
  {
    "id": "demo-245",
    "grade": 8,
    "score": 74,
    "anonymous_id": "AT-8LCCW5",
    "task_title": "Filipp IV ning cherkovga qarshi siyosati",
    "submitted_at": "2026-07-21T09:05:00Z",
    "graded_at": "2026-07-21T12:35:00Z"
  },
  {
    "id": "demo-246",
    "grade": 8,
    "score": 73,
    "anonymous_id": "AT-8ZRQYB",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-22T09:06:00Z",
    "graded_at": "2026-07-22T12:42:00Z"
  },
  {
    "id": "demo-247",
    "grade": 8,
    "score": 41,
    "anonymous_id": "AT-84UHPH",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-23T09:07:00Z",
    "graded_at": "2026-07-23T12:49:00Z"
  },
  {
    "id": "demo-248",
    "grade": 8,
    "score": 69,
    "anonymous_id": "AT-85Y8FM",
    "task_title": "Fransiyani birlashtirishdagi to'siqlar",
    "submitted_at": "2026-07-24T09:08:00Z",
    "graded_at": "2026-07-24T12:56:00Z"
  },
  {
    "id": "demo-249",
    "grade": 8,
    "score": 89,
    "anonymous_id": "AT-8JUE8F",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-25T09:09:00Z",
    "graded_at": "2026-07-25T12:03:00Z"
  },
  {
    "id": "demo-250",
    "grade": 8,
    "score": 73,
    "anonymous_id": "AT-8VP8WW",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-26T09:10:00Z",
    "graded_at": "2026-07-26T12:10:00Z"
  },
  {
    "id": "demo-251",
    "grade": 8,
    "score": 39,
    "anonymous_id": "AT-8JVFLA",
    "task_title": "Rus yerlarining mo'g'ullar zulmidan ozod bo'lishi",
    "submitted_at": "2026-07-27T09:11:00Z",
    "graded_at": "2026-07-27T12:17:00Z"
  },
  {
    "id": "demo-252",
    "grade": 8,
    "score": 61,
    "anonymous_id": "AT-858JQ4",
    "task_title": "Aleksandr Nevskiyning g'alaba omillari",
    "submitted_at": "2026-07-28T09:12:00Z",
    "graded_at": "2026-07-28T12:24:00Z"
  },
  {
    "id": "demo-253",
    "grade": 8,
    "score": 64,
    "anonymous_id": "AT-87RQ4U",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-01T09:13:00Z",
    "graded_at": "2026-07-01T12:31:00Z"
  },
  {
    "id": "demo-254",
    "grade": 8,
    "score": 72,
    "anonymous_id": "AT-89SPQV",
    "task_title": "Fransiyani birlashtirishdagi to'siqlar",
    "submitted_at": "2026-07-02T09:14:00Z",
    "graded_at": "2026-07-02T12:38:00Z"
  },
  {
    "id": "demo-255",
    "grade": 8,
    "score": 92,
    "anonymous_id": "AT-86CXHQ",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-03T09:15:00Z",
    "graded_at": "2026-07-03T12:45:00Z"
  },
  {
    "id": "demo-256",
    "grade": 8,
    "score": 79,
    "anonymous_id": "AT-8D6H6S",
    "task_title": "Moskva knyazligining yuksalishi (Ivan Kalita va Dmitriy Donskoy)",
    "submitted_at": "2026-07-04T09:16:00Z",
    "graded_at": "2026-07-04T12:52:00Z"
  },
  {
    "id": "demo-257",
    "grade": 8,
    "score": 82,
    "anonymous_id": "AT-8MW3FD",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-05T09:17:00Z",
    "graded_at": "2026-07-05T12:59:00Z"
  },
  {
    "id": "demo-258",
    "grade": 8,
    "score": 50,
    "anonymous_id": "AT-8M6CUN",
    "task_title": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "submitted_at": "2026-07-06T09:18:00Z",
    "graded_at": "2026-07-06T12:06:00Z"
  },
  {
    "id": "demo-259",
    "grade": 8,
    "score": 61,
    "anonymous_id": "AT-8F7ENT",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-07T09:19:00Z",
    "graded_at": "2026-07-07T12:13:00Z"
  },
  {
    "id": "demo-260",
    "grade": 8,
    "score": 49,
    "anonymous_id": "AT-8FR4YX",
    "task_title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "submitted_at": "2026-07-08T09:20:00Z",
    "graded_at": "2026-07-08T12:20:00Z"
  },
  {
    "id": "demo-261",
    "grade": 8,
    "score": 88,
    "anonymous_id": "AT-8RKYXU",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-09T09:21:00Z",
    "graded_at": "2026-07-09T12:27:00Z"
  },
  {
    "id": "demo-262",
    "grade": 8,
    "score": 61,
    "anonymous_id": "AT-84TJ28",
    "task_title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "submitted_at": "2026-07-10T09:22:00Z",
    "graded_at": "2026-07-10T12:34:00Z"
  },
  {
    "id": "demo-263",
    "grade": 8,
    "score": 39,
    "anonymous_id": "AT-8FHGEC",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-11T09:23:00Z",
    "graded_at": "2026-07-11T12:41:00Z"
  },
  {
    "id": "demo-264",
    "grade": 8,
    "score": 45,
    "anonymous_id": "AT-8PQQ5U",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-12T09:24:00Z",
    "graded_at": "2026-07-12T12:48:00Z"
  },
  {
    "id": "demo-265",
    "grade": 8,
    "score": 55,
    "anonymous_id": "AT-8Y8D6M",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-13T09:25:00Z",
    "graded_at": "2026-07-13T12:55:00Z"
  },
  {
    "id": "demo-266",
    "grade": 8,
    "score": 79,
    "anonymous_id": "AT-8X7Y8M",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-14T09:26:00Z",
    "graded_at": "2026-07-14T12:02:00Z"
  },
  {
    "id": "demo-267",
    "grade": 8,
    "score": 71,
    "anonymous_id": "AT-8ENGTK",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-15T09:27:00Z",
    "graded_at": "2026-07-15T12:09:00Z"
  },
  {
    "id": "demo-268",
    "grade": 8,
    "score": 40,
    "anonymous_id": "AT-8GJEJP",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-16T09:28:00Z",
    "graded_at": "2026-07-16T12:16:00Z"
  },
  {
    "id": "demo-269",
    "grade": 8,
    "score": 72,
    "anonymous_id": "AT-8X66HB",
    "task_title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "submitted_at": "2026-07-17T09:29:00Z",
    "graded_at": "2026-07-17T12:23:00Z"
  },
  {
    "id": "demo-270",
    "grade": 8,
    "score": 62,
    "anonymous_id": "AT-8XGSKQ",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-18T09:30:00Z",
    "graded_at": "2026-07-18T12:30:00Z"
  },
  {
    "id": "demo-271",
    "grade": 8,
    "score": 41,
    "anonymous_id": "AT-86RKBP",
    "task_title": "Sulton Muhammad Xorazmshoh saltanati",
    "submitted_at": "2026-07-19T09:31:00Z",
    "graded_at": "2026-07-19T12:37:00Z"
  },
  {
    "id": "demo-272",
    "grade": 8,
    "score": 88,
    "anonymous_id": "AT-8GBVWS",
    "task_title": "Aleksandr Nevskiyning g'alaba omillari",
    "submitted_at": "2026-07-20T09:32:00Z",
    "graded_at": "2026-07-20T12:44:00Z"
  },
  {
    "id": "demo-273",
    "grade": 8,
    "score": 79,
    "anonymous_id": "AT-8ZES4D",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-21T09:33:00Z",
    "graded_at": "2026-07-21T12:51:00Z"
  },
  {
    "id": "demo-274",
    "grade": 8,
    "score": 75,
    "anonymous_id": "AT-8LP3VY",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-22T09:34:00Z",
    "graded_at": "2026-07-22T12:58:00Z"
  },
  {
    "id": "demo-275",
    "grade": 8,
    "score": 46,
    "anonymous_id": "AT-84CKE9",
    "task_title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "submitted_at": "2026-07-23T09:35:00Z",
    "graded_at": "2026-07-23T12:05:00Z"
  },
  {
    "id": "demo-276",
    "grade": 8,
    "score": 63,
    "anonymous_id": "AT-8TWF4L",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-24T09:36:00Z",
    "graded_at": "2026-07-24T12:12:00Z"
  },
  {
    "id": "demo-277",
    "grade": 8,
    "score": 60,
    "anonymous_id": "AT-8YAUTQ",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-25T09:37:00Z",
    "graded_at": "2026-07-25T12:19:00Z"
  },
  {
    "id": "demo-278",
    "grade": 8,
    "score": 52,
    "anonymous_id": "AT-84CW9T",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-26T09:38:00Z",
    "graded_at": "2026-07-26T12:26:00Z"
  },
  {
    "id": "demo-279",
    "grade": 8,
    "score": 69,
    "anonymous_id": "AT-8Z2AUK",
    "task_title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "submitted_at": "2026-07-27T09:39:00Z",
    "graded_at": "2026-07-27T12:33:00Z"
  },
  {
    "id": "demo-280",
    "grade": 8,
    "score": 53,
    "anonymous_id": "AT-8R2SB7",
    "task_title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "submitted_at": "2026-07-28T09:40:00Z",
    "graded_at": "2026-07-28T12:40:00Z"
  },
  {
    "id": "demo-281",
    "grade": 8,
    "score": 93,
    "anonymous_id": "AT-8RVCCA",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-01T09:41:00Z",
    "graded_at": "2026-07-01T12:47:00Z"
  },
  {
    "id": "demo-282",
    "grade": 8,
    "score": 40,
    "anonymous_id": "AT-8SQWVA",
    "task_title": "Sulton Muhammad Xorazmshoh saltanati",
    "submitted_at": "2026-07-02T09:42:00Z",
    "graded_at": "2026-07-02T12:54:00Z"
  },
  {
    "id": "demo-283",
    "grade": 8,
    "score": 41,
    "anonymous_id": "AT-8PKK38",
    "task_title": "Sulton Muhammad Xorazmshoh saltanati",
    "submitted_at": "2026-07-03T09:43:00Z",
    "graded_at": "2026-07-03T12:01:00Z"
  },
  {
    "id": "demo-284",
    "grade": 8,
    "score": 51,
    "anonymous_id": "AT-8LDJF7",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-04T09:44:00Z",
    "graded_at": "2026-07-04T12:08:00Z"
  },
  {
    "id": "demo-285",
    "grade": 8,
    "score": 60,
    "anonymous_id": "AT-8S7MKW",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-05T09:45:00Z",
    "graded_at": "2026-07-05T12:15:00Z"
  },
  {
    "id": "demo-286",
    "grade": 8,
    "score": 93,
    "anonymous_id": "AT-892RSG",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-06T09:46:00Z",
    "graded_at": "2026-07-06T12:22:00Z"
  },
  {
    "id": "demo-287",
    "grade": 8,
    "score": 82,
    "anonymous_id": "AT-8T6D7V",
    "task_title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "submitted_at": "2026-07-07T09:47:00Z",
    "graded_at": "2026-07-07T12:29:00Z"
  },
  {
    "id": "demo-288",
    "grade": 8,
    "score": 91,
    "anonymous_id": "AT-8F4P3S",
    "task_title": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "submitted_at": "2026-07-08T09:48:00Z",
    "graded_at": "2026-07-08T12:36:00Z"
  },
  {
    "id": "demo-289",
    "grade": 8,
    "score": 79,
    "anonymous_id": "AT-8DHNE6",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-09T09:49:00Z",
    "graded_at": "2026-07-09T12:43:00Z"
  },
  {
    "id": "demo-290",
    "grade": 8,
    "score": 71,
    "anonymous_id": "AT-8P6WS3",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-10T09:50:00Z",
    "graded_at": "2026-07-10T12:50:00Z"
  },
  {
    "id": "demo-291",
    "grade": 8,
    "score": 84,
    "anonymous_id": "AT-8KTQ5Z",
    "task_title": "Filipp IV ning cherkovga qarshi siyosati",
    "submitted_at": "2026-07-11T09:51:00Z",
    "graded_at": "2026-07-11T12:57:00Z"
  },
  {
    "id": "demo-292",
    "grade": 8,
    "score": 81,
    "anonymous_id": "AT-8XK86X",
    "task_title": "Sulton Muhammad Xorazmshoh saltanati",
    "submitted_at": "2026-07-12T09:52:00Z",
    "graded_at": "2026-07-12T12:04:00Z"
  },
  {
    "id": "demo-293",
    "grade": 8,
    "score": 68,
    "anonymous_id": "AT-87HBC3",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-13T09:53:00Z",
    "graded_at": "2026-07-13T12:11:00Z"
  },
  {
    "id": "demo-294",
    "grade": 8,
    "score": 55,
    "anonymous_id": "AT-89YBZV",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-14T09:54:00Z",
    "graded_at": "2026-07-14T12:18:00Z"
  },
  {
    "id": "demo-295",
    "grade": 8,
    "score": 63,
    "anonymous_id": "AT-8TYX9Q",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-15T09:55:00Z",
    "graded_at": "2026-07-15T12:25:00Z"
  },
  {
    "id": "demo-296",
    "grade": 8,
    "score": 54,
    "anonymous_id": "AT-8LQJPY",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-16T09:56:00Z",
    "graded_at": "2026-07-16T12:32:00Z"
  },
  {
    "id": "demo-297",
    "grade": 8,
    "score": 44,
    "anonymous_id": "AT-88LULE",
    "task_title": "Rus yerlarining mo'g'ullar zulmidan ozod bo'lishi",
    "submitted_at": "2026-07-17T09:57:00Z",
    "graded_at": "2026-07-17T12:39:00Z"
  },
  {
    "id": "demo-298",
    "grade": 8,
    "score": 78,
    "anonymous_id": "AT-85DM2A",
    "task_title": "Aleksandr Nevskiyning g'alaba omillari",
    "submitted_at": "2026-07-18T09:58:00Z",
    "graded_at": "2026-07-18T12:46:00Z"
  },
  {
    "id": "demo-299",
    "grade": 8,
    "score": 60,
    "anonymous_id": "AT-8ZHQBZ",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-19T09:59:00Z",
    "graded_at": "2026-07-19T12:53:00Z"
  },
  {
    "id": "demo-300",
    "grade": 8,
    "score": 51,
    "anonymous_id": "AT-8TGHYW",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-20T09:00:00Z",
    "graded_at": "2026-07-20T12:00:00Z"
  },
  {
    "id": "demo-301",
    "grade": 8,
    "score": 39,
    "anonymous_id": "AT-8GLABX",
    "task_title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "submitted_at": "2026-07-21T09:01:00Z",
    "graded_at": "2026-07-21T12:07:00Z"
  },
  {
    "id": "demo-302",
    "grade": 8,
    "score": 85,
    "anonymous_id": "AT-8XR5E3",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-22T09:02:00Z",
    "graded_at": "2026-07-22T12:14:00Z"
  },
  {
    "id": "demo-303",
    "grade": 8,
    "score": 84,
    "anonymous_id": "AT-8APHRU",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-23T09:03:00Z",
    "graded_at": "2026-07-23T12:21:00Z"
  },
  {
    "id": "demo-304",
    "grade": 8,
    "score": 41,
    "anonymous_id": "AT-857646",
    "task_title": "Filipp IV ning cherkovga qarshi siyosati",
    "submitted_at": "2026-07-24T09:04:00Z",
    "graded_at": "2026-07-24T12:28:00Z"
  },
  {
    "id": "demo-305",
    "grade": 8,
    "score": 52,
    "anonymous_id": "AT-84X9NV",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-25T09:05:00Z",
    "graded_at": "2026-07-25T12:35:00Z"
  },
  {
    "id": "demo-306",
    "grade": 8,
    "score": 59,
    "anonymous_id": "AT-8QB9FR",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-26T09:06:00Z",
    "graded_at": "2026-07-26T12:42:00Z"
  },
  {
    "id": "demo-307",
    "grade": 8,
    "score": 68,
    "anonymous_id": "AT-8FXE33",
    "task_title": "Filipp II Avgustning Normandiyani qo'shib olish loyihasi",
    "submitted_at": "2026-07-27T09:07:00Z",
    "graded_at": "2026-07-27T12:49:00Z"
  },
  {
    "id": "demo-308",
    "grade": 8,
    "score": 70,
    "anonymous_id": "AT-8E2UC2",
    "task_title": "Amir Temurning To'xtamishga zarbasi — rus yerlarini xalos etishdagi hal qiluvchi kuchmi?",
    "submitted_at": "2026-07-28T09:08:00Z",
    "graded_at": "2026-07-28T12:56:00Z"
  },
  {
    "id": "demo-309",
    "grade": 8,
    "score": 89,
    "anonymous_id": "AT-8AYUMJ",
    "task_title": "Amir Temurning rus yerlari ozodligidagi o'rni",
    "submitted_at": "2026-07-01T09:09:00Z",
    "graded_at": "2026-07-01T12:03:00Z"
  },
  {
    "id": "demo-310",
    "grade": 8,
    "score": 80,
    "anonymous_id": "AT-839UFP",
    "task_title": "Aleksandr Nevskiyning g'alaba omillari",
    "submitted_at": "2026-07-02T09:10:00Z",
    "graded_at": "2026-07-02T12:10:00Z"
  },
  {
    "id": "demo-311",
    "grade": 8,
    "score": 42,
    "anonymous_id": "AT-8FDA3X",
    "task_title": "Filipp IV ning cherkovga qarshi siyosati",
    "submitted_at": "2026-07-03T09:11:00Z",
    "graded_at": "2026-07-03T12:17:00Z"
  },
  {
    "id": "demo-312",
    "grade": 8,
    "score": 92,
    "anonymous_id": "AT-8LVFSH",
    "task_title": "Neva jangi (1240-y.) va Chud ko'lidagi jang (1242-y.)",
    "submitted_at": "2026-07-04T09:12:00Z",
    "graded_at": "2026-07-04T12:24:00Z"
  },
  {
    "id": "demo-313",
    "grade": 8,
    "score": 62,
    "anonymous_id": "AT-8DDPWK",
    "task_title": "Kulikovo jangi va qo'rquv ustidan g'alaba ozodligi",
    "submitted_at": "2026-07-05T09:13:00Z",
    "graded_at": "2026-07-05T12:31:00Z"
  },
  {
    "id": "demo-314",
    "grade": 8,
    "score": 47,
    "anonymous_id": "AT-8JT86D",
    "task_title": "Moskva knyazligining yuksalishi (Ivan Kalita va Dmitriy Donskoy)",
    "submitted_at": "2026-07-06T09:14:00Z",
    "graded_at": "2026-07-06T12:38:00Z"
  },
  {
    "id": "demo-315",
    "grade": 8,
    "score": 67,
    "anonymous_id": "AT-8KS5LN",
    "task_title": "Fransiyani birlashtirishdagi to'siqlar",
    "submitted_at": "2026-07-07T09:15:00Z",
    "graded_at": "2026-07-07T12:45:00Z"
  },
  {
    "id": "demo-316",
    "grade": 8,
    "score": 47,
    "anonymous_id": "AT-8VVPUT",
    "task_title": "Cherkovdan soliq olish — qirolning adolatli huquqimi yoki dindorlarga zulm?",
    "submitted_at": "2026-07-08T09:16:00Z",
    "graded_at": "2026-07-08T12:52:00Z"
  },
  {
    "id": "demo-317",
    "grade": 8,
    "score": 83,
    "anonymous_id": "AT-8GEXF5",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-09T09:17:00Z",
    "graded_at": "2026-07-09T12:59:00Z"
  },
  {
    "id": "demo-318",
    "grade": 8,
    "score": 67,
    "anonymous_id": "AT-8W6WVM",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-10T09:18:00Z",
    "graded_at": "2026-07-10T12:06:00Z"
  },
  {
    "id": "demo-319",
    "grade": 8,
    "score": 50,
    "anonymous_id": "AT-8MGJUG",
    "task_title": "Novgorod respublikasi va Vladimir-Suzdal knyazligi",
    "submitted_at": "2026-07-11T09:19:00Z",
    "graded_at": "2026-07-11T12:13:00Z"
  },
  {
    "id": "demo-320",
    "grade": 8,
    "score": 63,
    "anonymous_id": "AT-8DNV72",
    "task_title": "Moskva knyazi Ivan Kalitaning markazlashtirish loyihasi",
    "submitted_at": "2026-07-12T09:20:00Z",
    "graded_at": "2026-07-12T12:20:00Z"
  },
  {
    "id": "demo-321",
    "grade": 8,
    "score": 71,
    "anonymous_id": "AT-8QZ5SE",
    "task_title": "Fransiyadagi tabaqaviy tengsizlik va adolat mezonlari",
    "submitted_at": "2026-07-13T09:21:00Z",
    "graded_at": "2026-07-13T12:27:00Z"
  },
  {
    "id": "demo-322",
    "grade": 8,
    "score": 49,
    "anonymous_id": "AT-8RWZRA",
    "task_title": "Papalarning Avinyon tutqunligi",
    "submitted_at": "2026-07-14T09:22:00Z",
    "graded_at": "2026-07-14T12:34:00Z"
  },
  {
    "id": "demo-323",
    "grade": 9,
    "score": 42,
    "anonymous_id": "AT-9W32LT",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-15T09:23:00Z",
    "graded_at": "2026-07-15T12:41:00Z"
  },
  {
    "id": "demo-324",
    "grade": 9,
    "score": 62,
    "anonymous_id": "AT-9HUEZN",
    "task_title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "submitted_at": "2026-07-16T09:24:00Z",
    "graded_at": "2026-07-16T12:48:00Z"
  },
  {
    "id": "demo-325",
    "grade": 9,
    "score": 55,
    "anonymous_id": "AT-976Z34",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-17T09:25:00Z",
    "graded_at": "2026-07-17T12:55:00Z"
  },
  {
    "id": "demo-326",
    "grade": 9,
    "score": 73,
    "anonymous_id": "AT-965G3N",
    "task_title": "1916-yilgi qo'zg'olonda Jadidlarning yondashuvi adolatli edimi?",
    "submitted_at": "2026-07-18T09:26:00Z",
    "graded_at": "2026-07-18T12:02:00Z"
  },
  {
    "id": "demo-327",
    "grade": 9,
    "score": 40,
    "anonymous_id": "AT-9T66GL",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-19T09:27:00Z",
    "graded_at": "2026-07-19T12:09:00Z"
  },
  {
    "id": "demo-328",
    "grade": 9,
    "score": 45,
    "anonymous_id": "AT-946JMU",
    "task_title": "Xitoyni \"Ochiq eshiklar\" siyosatidan qutqarish loyihasi",
    "submitted_at": "2026-07-20T09:28:00Z",
    "graded_at": "2026-07-20T12:16:00Z"
  },
  {
    "id": "demo-329",
    "grade": 9,
    "score": 63,
    "anonymous_id": "AT-9DAV4L",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-21T09:29:00Z",
    "graded_at": "2026-07-21T12:23:00Z"
  },
  {
    "id": "demo-330",
    "grade": 9,
    "score": 66,
    "anonymous_id": "AT-9XQZ7U",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-22T09:30:00Z",
    "graded_at": "2026-07-22T12:30:00Z"
  },
  {
    "id": "demo-331",
    "grade": 9,
    "score": 84,
    "anonymous_id": "AT-93RD6S",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-23T09:31:00Z",
    "graded_at": "2026-07-23T12:37:00Z"
  },
  {
    "id": "demo-332",
    "grade": 9,
    "score": 63,
    "anonymous_id": "AT-9MXWAA",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-24T09:32:00Z",
    "graded_at": "2026-07-24T12:44:00Z"
  },
  {
    "id": "demo-333",
    "grade": 9,
    "score": 86,
    "anonymous_id": "AT-9XXHSE",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-25T09:33:00Z",
    "graded_at": "2026-07-25T12:51:00Z"
  },
  {
    "id": "demo-334",
    "grade": 9,
    "score": 89,
    "anonymous_id": "AT-9XUCBJ",
    "task_title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "submitted_at": "2026-07-26T09:34:00Z",
    "graded_at": "2026-07-26T12:58:00Z"
  },
  {
    "id": "demo-335",
    "grade": 9,
    "score": 81,
    "anonymous_id": "AT-9Q7Q5T",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-27T09:35:00Z",
    "graded_at": "2026-07-27T12:05:00Z"
  },
  {
    "id": "demo-336",
    "grade": 9,
    "score": 47,
    "anonymous_id": "AT-9UDCPD",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-28T09:36:00Z",
    "graded_at": "2026-07-28T12:12:00Z"
  },
  {
    "id": "demo-337",
    "grade": 9,
    "score": 53,
    "anonymous_id": "AT-9SYKWD",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-01T09:37:00Z",
    "graded_at": "2026-07-01T12:19:00Z"
  },
  {
    "id": "demo-338",
    "grade": 9,
    "score": 52,
    "anonymous_id": "AT-948W77",
    "task_title": "1916-yilgi Mardikorlikka olish farmoni",
    "submitted_at": "2026-07-02T09:38:00Z",
    "graded_at": "2026-07-02T12:26:00Z"
  },
  {
    "id": "demo-339",
    "grade": 9,
    "score": 91,
    "anonymous_id": "AT-9MCXNX",
    "task_title": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "submitted_at": "2026-07-03T09:39:00Z",
    "graded_at": "2026-07-03T12:33:00Z"
  },
  {
    "id": "demo-340",
    "grade": 9,
    "score": 87,
    "anonymous_id": "AT-9BRLV6",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-04T09:40:00Z",
    "graded_at": "2026-07-04T12:40:00Z"
  },
  {
    "id": "demo-341",
    "grade": 9,
    "score": 86,
    "anonymous_id": "AT-99JP5Q",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-05T09:41:00Z",
    "graded_at": "2026-07-05T12:47:00Z"
  },
  {
    "id": "demo-342",
    "grade": 9,
    "score": 46,
    "anonymous_id": "AT-9C2KQT",
    "task_title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "submitted_at": "2026-07-06T09:42:00Z",
    "graded_at": "2026-07-06T12:54:00Z"
  },
  {
    "id": "demo-343",
    "grade": 9,
    "score": 65,
    "anonymous_id": "AT-98S84Q",
    "task_title": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "submitted_at": "2026-07-07T09:43:00Z",
    "graded_at": "2026-07-07T12:01:00Z"
  },
  {
    "id": "demo-344",
    "grade": 9,
    "score": 46,
    "anonymous_id": "AT-95YSES",
    "task_title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "submitted_at": "2026-07-08T09:44:00Z",
    "graded_at": "2026-07-08T12:08:00Z"
  },
  {
    "id": "demo-345",
    "grade": 9,
    "score": 44,
    "anonymous_id": "AT-9EB32Y",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-09T09:45:00Z",
    "graded_at": "2026-07-09T12:15:00Z"
  },
  {
    "id": "demo-346",
    "grade": 9,
    "score": 45,
    "anonymous_id": "AT-969RAD",
    "task_title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "submitted_at": "2026-07-10T09:46:00Z",
    "graded_at": "2026-07-10T12:22:00Z"
  },
  {
    "id": "demo-347",
    "grade": 9,
    "score": 54,
    "anonymous_id": "AT-9HGVR7",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-11T09:47:00Z",
    "graded_at": "2026-07-11T12:29:00Z"
  },
  {
    "id": "demo-348",
    "grade": 9,
    "score": 40,
    "anonymous_id": "AT-9S6548",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-12T09:48:00Z",
    "graded_at": "2026-07-12T12:36:00Z"
  },
  {
    "id": "demo-349",
    "grade": 9,
    "score": 67,
    "anonymous_id": "AT-9GCEHA",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-13T09:49:00Z",
    "graded_at": "2026-07-13T12:43:00Z"
  },
  {
    "id": "demo-350",
    "grade": 9,
    "score": 42,
    "anonymous_id": "AT-9KXZK5",
    "task_title": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "submitted_at": "2026-07-14T09:50:00Z",
    "graded_at": "2026-07-14T12:50:00Z"
  },
  {
    "id": "demo-351",
    "grade": 9,
    "score": 72,
    "anonymous_id": "AT-978636",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-15T09:51:00Z",
    "graded_at": "2026-07-15T12:57:00Z"
  },
  {
    "id": "demo-352",
    "grade": 9,
    "score": 81,
    "anonymous_id": "AT-9SDZFE",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-16T09:52:00Z",
    "graded_at": "2026-07-16T12:04:00Z"
  },
  {
    "id": "demo-353",
    "grade": 9,
    "score": 81,
    "anonymous_id": "AT-9NTRZV",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-17T09:53:00Z",
    "graded_at": "2026-07-17T12:11:00Z"
  },
  {
    "id": "demo-354",
    "grade": 9,
    "score": 74,
    "anonymous_id": "AT-9ME9S2",
    "task_title": "1916-yilgi Mardikorlikka olish farmoni",
    "submitted_at": "2026-07-18T09:54:00Z",
    "graded_at": "2026-07-18T12:18:00Z"
  },
  {
    "id": "demo-355",
    "grade": 9,
    "score": 42,
    "anonymous_id": "AT-97C2AE",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-19T09:55:00Z",
    "graded_at": "2026-07-19T12:25:00Z"
  },
  {
    "id": "demo-356",
    "grade": 9,
    "score": 39,
    "anonymous_id": "AT-9TDCXB",
    "task_title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "submitted_at": "2026-07-20T09:56:00Z",
    "graded_at": "2026-07-20T12:32:00Z"
  },
  {
    "id": "demo-357",
    "grade": 9,
    "score": 81,
    "anonymous_id": "AT-9FTBAF",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-21T09:57:00Z",
    "graded_at": "2026-07-21T12:39:00Z"
  },
  {
    "id": "demo-358",
    "grade": 9,
    "score": 45,
    "anonymous_id": "AT-9GQC74",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-22T09:58:00Z",
    "graded_at": "2026-07-22T12:46:00Z"
  },
  {
    "id": "demo-359",
    "grade": 9,
    "score": 86,
    "anonymous_id": "AT-9A8YFL",
    "task_title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "submitted_at": "2026-07-23T09:59:00Z",
    "graded_at": "2026-07-23T12:53:00Z"
  },
  {
    "id": "demo-360",
    "grade": 9,
    "score": 47,
    "anonymous_id": "AT-9VVAWY",
    "task_title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "submitted_at": "2026-07-24T09:00:00Z",
    "graded_at": "2026-07-24T12:00:00Z"
  },
  {
    "id": "demo-361",
    "grade": 9,
    "score": 57,
    "anonymous_id": "AT-9DAGPD",
    "task_title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "submitted_at": "2026-07-25T09:01:00Z",
    "graded_at": "2026-07-25T12:07:00Z"
  },
  {
    "id": "demo-362",
    "grade": 9,
    "score": 63,
    "anonymous_id": "AT-95W7Q4",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-26T09:02:00Z",
    "graded_at": "2026-07-26T12:14:00Z"
  },
  {
    "id": "demo-363",
    "grade": 9,
    "score": 67,
    "anonymous_id": "AT-9LH95K",
    "task_title": "1916-yilgi qo'zg'olonda Jadidlarning yondashuvi adolatli edimi?",
    "submitted_at": "2026-07-27T09:03:00Z",
    "graded_at": "2026-07-27T12:21:00Z"
  },
  {
    "id": "demo-364",
    "grade": 9,
    "score": 92,
    "anonymous_id": "AT-9ZKC77",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-28T09:04:00Z",
    "graded_at": "2026-07-28T12:28:00Z"
  },
  {
    "id": "demo-365",
    "grade": 9,
    "score": 62,
    "anonymous_id": "AT-9VDX6D",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-01T09:05:00Z",
    "graded_at": "2026-07-01T12:35:00Z"
  },
  {
    "id": "demo-366",
    "grade": 9,
    "score": 59,
    "anonymous_id": "AT-9NNUA7",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-02T09:06:00Z",
    "graded_at": "2026-07-02T12:42:00Z"
  },
  {
    "id": "demo-367",
    "grade": 9,
    "score": 48,
    "anonymous_id": "AT-9Z5LQ8",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-03T09:07:00Z",
    "graded_at": "2026-07-03T12:49:00Z"
  },
  {
    "id": "demo-368",
    "grade": 9,
    "score": 78,
    "anonymous_id": "AT-9PH4QN",
    "task_title": "Turkistonda Jadid maktablari tarmog'ini kengaytirish",
    "submitted_at": "2026-07-04T09:08:00Z",
    "graded_at": "2026-07-04T12:56:00Z"
  },
  {
    "id": "demo-369",
    "grade": 9,
    "score": 65,
    "anonymous_id": "AT-9E2CRV",
    "task_title": "Xitoyni \"Ochiq eshiklar\" siyosatidan qutqarish loyihasi",
    "submitted_at": "2026-07-05T09:09:00Z",
    "graded_at": "2026-07-05T12:03:00Z"
  },
  {
    "id": "demo-370",
    "grade": 9,
    "score": 52,
    "anonymous_id": "AT-976PNQ",
    "task_title": "Qadimchilar va Jadidlar qarashlari",
    "submitted_at": "2026-07-06T09:10:00Z",
    "graded_at": "2026-07-06T12:10:00Z"
  },
  {
    "id": "demo-371",
    "grade": 9,
    "score": 79,
    "anonymous_id": "AT-9QN8CV",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-07T09:11:00Z",
    "graded_at": "2026-07-07T12:17:00Z"
  },
  {
    "id": "demo-372",
    "grade": 9,
    "score": 47,
    "anonymous_id": "AT-9EYQCK",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-08T09:12:00Z",
    "graded_at": "2026-07-08T12:24:00Z"
  },
  {
    "id": "demo-373",
    "grade": 9,
    "score": 61,
    "anonymous_id": "AT-9X5CGL",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-09T09:13:00Z",
    "graded_at": "2026-07-09T12:31:00Z"
  },
  {
    "id": "demo-374",
    "grade": 9,
    "score": 85,
    "anonymous_id": "AT-9FWL4S",
    "task_title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "submitted_at": "2026-07-10T09:14:00Z",
    "graded_at": "2026-07-10T12:38:00Z"
  },
  {
    "id": "demo-375",
    "grade": 9,
    "score": 59,
    "anonymous_id": "AT-9YSU2R",
    "task_title": "1916-yilgi Mardikorlikka olish farmoni",
    "submitted_at": "2026-07-11T09:15:00Z",
    "graded_at": "2026-07-11T12:45:00Z"
  },
  {
    "id": "demo-376",
    "grade": 9,
    "score": 63,
    "anonymous_id": "AT-9NAB99",
    "task_title": "1916-yilgi qo'zg'olonda Jadidlarning yondashuvi adolatli edimi?",
    "submitted_at": "2026-07-12T09:16:00Z",
    "graded_at": "2026-07-12T12:52:00Z"
  },
  {
    "id": "demo-377",
    "grade": 9,
    "score": 72,
    "anonymous_id": "AT-9ZLHJ4",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-13T09:17:00Z",
    "graded_at": "2026-07-13T12:59:00Z"
  },
  {
    "id": "demo-378",
    "grade": 9,
    "score": 67,
    "anonymous_id": "AT-9FWGKA",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-14T09:18:00Z",
    "graded_at": "2026-07-14T12:06:00Z"
  },
  {
    "id": "demo-379",
    "grade": 9,
    "score": 65,
    "anonymous_id": "AT-9FBD9K",
    "task_title": "1916-yilgi Mardikorlikka olish farmoni",
    "submitted_at": "2026-07-15T09:19:00Z",
    "graded_at": "2026-07-15T12:13:00Z"
  },
  {
    "id": "demo-380",
    "grade": 9,
    "score": 39,
    "anonymous_id": "AT-9UL3YQ",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-16T09:20:00Z",
    "graded_at": "2026-07-16T12:20:00Z"
  },
  {
    "id": "demo-381",
    "grade": 9,
    "score": 38,
    "anonymous_id": "AT-9E8F8M",
    "task_title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "submitted_at": "2026-07-17T09:21:00Z",
    "graded_at": "2026-07-17T12:27:00Z"
  },
  {
    "id": "demo-382",
    "grade": 9,
    "score": 52,
    "anonymous_id": "AT-9ZSM8A",
    "task_title": "Birinchi jahon urushining boshlanishi va harbiy bloklar",
    "submitted_at": "2026-07-18T09:22:00Z",
    "graded_at": "2026-07-18T12:34:00Z"
  },
  {
    "id": "demo-383",
    "grade": 9,
    "score": 80,
    "anonymous_id": "AT-9B6M4R",
    "task_title": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "submitted_at": "2026-07-19T09:23:00Z",
    "graded_at": "2026-07-19T12:41:00Z"
  },
  {
    "id": "demo-384",
    "grade": 9,
    "score": 68,
    "anonymous_id": "AT-9T2JM4",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-20T09:24:00Z",
    "graded_at": "2026-07-20T12:48:00Z"
  },
  {
    "id": "demo-385",
    "grade": 9,
    "score": 54,
    "anonymous_id": "AT-92R99J",
    "task_title": "Jadid bobolarimiz fidosi va mening bugunim",
    "submitted_at": "2026-07-21T09:25:00Z",
    "graded_at": "2026-07-21T12:55:00Z"
  },
  {
    "id": "demo-386",
    "grade": 9,
    "score": 41,
    "anonymous_id": "AT-92QBTH",
    "task_title": "1898-yilgi Andijon qo'zg'oloni sabablari",
    "submitted_at": "2026-07-22T09:26:00Z",
    "graded_at": "2026-07-22T12:02:00Z"
  },
  {
    "id": "demo-387",
    "grade": 9,
    "score": 72,
    "anonymous_id": "AT-9FBE8Y",
    "task_title": "Turkistonda \"Paxta yakkahokimligi\"ning o'rnatilishi",
    "submitted_at": "2026-07-23T09:27:00Z",
    "graded_at": "2026-07-23T12:09:00Z"
  },
  {
    "id": "demo-388",
    "grade": 9,
    "score": 59,
    "anonymous_id": "AT-98LK6K",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-24T09:28:00Z",
    "graded_at": "2026-07-24T12:16:00Z"
  },
  {
    "id": "demo-389",
    "grade": 9,
    "score": 51,
    "anonymous_id": "AT-985RFB",
    "task_title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "submitted_at": "2026-07-25T09:29:00Z",
    "graded_at": "2026-07-25T12:23:00Z"
  },
  {
    "id": "demo-390",
    "grade": 9,
    "score": 80,
    "anonymous_id": "AT-9S7S4T",
    "task_title": "Qadimchilar va Jadidlar qarashlari",
    "submitted_at": "2026-07-26T09:30:00Z",
    "graded_at": "2026-07-26T12:30:00Z"
  },
  {
    "id": "demo-391",
    "grade": 9,
    "score": 50,
    "anonymous_id": "AT-96VCJY",
    "task_title": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "submitted_at": "2026-07-27T09:31:00Z",
    "graded_at": "2026-07-27T12:37:00Z"
  },
  {
    "id": "demo-392",
    "grade": 9,
    "score": 69,
    "anonymous_id": "AT-9VXE7G",
    "task_title": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "submitted_at": "2026-07-28T09:32:00Z",
    "graded_at": "2026-07-28T12:44:00Z"
  },
  {
    "id": "demo-393",
    "grade": 9,
    "score": 72,
    "anonymous_id": "AT-949EBV",
    "task_title": "AQShning fuqarolar urushidan keyingi iqtisodiy yuksalishi",
    "submitted_at": "2026-07-01T09:33:00Z",
    "graded_at": "2026-07-01T12:51:00Z"
  },
  {
    "id": "demo-394",
    "grade": 9,
    "score": 80,
    "anonymous_id": "AT-9KTBUY",
    "task_title": "Yaponiyadagi \"Meydzi islohotlari\"",
    "submitted_at": "2026-07-02T09:34:00Z",
    "graded_at": "2026-07-02T12:58:00Z"
  },
  {
    "id": "demo-395",
    "grade": 9,
    "score": 41,
    "anonymous_id": "AT-9UKWZV",
    "task_title": "Imperializm va Mustamlakachilik — sivilizatsiya tarqatishmi yoki zulm?",
    "submitted_at": "2026-07-03T09:35:00Z",
    "graded_at": "2026-07-03T12:05:00Z"
  },
  {
    "id": "demo-396",
    "grade": 9,
    "score": 91,
    "anonymous_id": "AT-9T5S25",
    "task_title": "Turkistondagi Jadidchilik harakati",
    "submitted_at": "2026-07-04T09:36:00Z",
    "graded_at": "2026-07-04T12:12:00Z"
  },
  {
    "id": "demo-397",
    "grade": 9,
    "score": 46,
    "anonymous_id": "AT-9TTXCR",
    "task_title": "Qadimchilar va Jadidlar qarashlari",
    "submitted_at": "2026-07-05T09:37:00Z",
    "graded_at": "2026-07-05T12:19:00Z"
  },
  {
    "id": "demo-398",
    "grade": 9,
    "score": 57,
    "anonymous_id": "AT-95DG5J",
    "task_title": "Imperializm va Mustamlakachilik — sivilizatsiya tarqatishmi yoki zulm?",
    "submitted_at": "2026-07-06T09:38:00Z",
    "graded_at": "2026-07-06T12:26:00Z"
  },
  {
    "id": "demo-399",
    "grade": 9,
    "score": 90,
    "anonymous_id": "AT-99LBBD",
    "task_title": "Sanoat inqilobi va Monopoliyalarning vujudga kelishi",
    "submitted_at": "2026-07-07T09:39:00Z",
    "graded_at": "2026-07-07T12:33:00Z"
  },
  {
    "id": "demo-400",
    "grade": 9,
    "score": 91,
    "anonymous_id": "AT-9MWV58",
    "task_title": "XIX asr oxirida Buyuk Britaniya va Germaniya iqtisodiyoti",
    "submitted_at": "2026-07-08T09:40:00Z",
    "graded_at": "2026-07-08T12:40:00Z"
  },
  {
    "id": "demo-401",
    "grade": 9,
    "score": 46,
    "anonymous_id": "AT-9XQNEW",
    "task_title": "Qadimchilar va Jadidlar qarashlari",
    "submitted_at": "2026-07-09T09:41:00Z",
    "graded_at": "2026-07-09T12:47:00Z"
  },
  {
    "id": "demo-402",
    "grade": 9,
    "score": 87,
    "anonymous_id": "AT-9GXEJS",
    "task_title": "\"Tarix xatolaridan to'g'ri xulosa\" — Birinchi jahon urushi sabog'i",
    "submitted_at": "2026-07-10T09:42:00Z",
    "graded_at": "2026-07-10T12:54:00Z"
  }
]$demo$::jsonb) as demo_seed(
    id text,
    grade integer,
    score integer,
    anonymous_id text,
    task_title text,
    submitted_at timestamptz,
    graded_at timestamptz
  )
)
insert into public.demo_scoreboard_records (id, anonymous_id, grade, task_title, score, submitted_at, graded_at)
select id, anonymous_id, grade, task_title, score, submitted_at, graded_at
from demo_records
on conflict (id) do update set
  anonymous_id = excluded.anonymous_id,
  grade = excluded.grade,
  task_title = excluded.task_title,
  score = excluded.score,
  submitted_at = excluded.submitted_at,
  graded_at = excluded.graded_at;

drop view if exists public.global_stats;
drop view if exists public.scoreboard_entries;

create view public.scoreboard_entries as
select
  s.id::text as submission_id,
  s.task_id,
  t.title as task_title,
  ('AT-' || upper(substr(md5(s.student_id::text), 1, 6))) as student_id,
  ('AT-' || upper(substr(md5(s.student_id::text), 1, 6))) as anonymous_id,
  p.grade,
  s.score,
  s.submitted_at,
  s.graded_at,
  false as is_demo
from public.submissions s
join public.profiles p on p.id = s.student_id
join public.tasks t on t.id = s.task_id
where s.status = 'graded'
  and s.score is not null
union all
select
  d.id as submission_id,
  null::text as task_id,
  d.task_title,
  d.anonymous_id as student_id,
  d.anonymous_id,
  d.grade,
  d.score,
  d.submitted_at,
  d.graded_at,
  true as is_demo
from public.demo_scoreboard_records d;

create view public.global_stats as
with public_entries as (
  select * from public.scoreboard_entries
),
actual_submitted as (
  select count(*)::integer as count from public.submissions
),
demo_submitted as (
  select count(*)::integer as count from public.demo_scoreboard_records
),
top_grade as (
  select grade
  from public_entries
  group by grade
  order by count(*) desc, grade asc
  limit 1
)
select
  (select count(distinct student_id)::integer from public_entries) as total_students,
  ((select count from actual_submitted) + (select count from demo_submitted))::integer as submitted_works,
  (select count(*)::integer from public_entries) as graded_works,
  (select coalesce(round(avg(score))::integer, 0) from public_entries) as average_score,
  (select grade from top_grade) as top_grade;

grant select on public.scoreboard_entries to anon, authenticated;
grant select on public.global_stats to anon, authenticated;
