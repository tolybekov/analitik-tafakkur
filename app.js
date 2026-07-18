(function () {
  "use strict";

  var STORE = {
    lang: "at_lang",
    role: "at_role",
    activeTask: "at_active_task",
    filters: "at_filters",
    editTask: "at_edit_task",
    reviewSubmission: "at_review_submission"
  };

  var LANGS = ["uz", "ru", "en"];
  var GRADES = [5, 6, 7, 8, 9];
  var STYLES = ["case", "swot", "fishbone", "insert", "venn", "debate", "disney", "reflexive"];

  var i18n = {
    uz: {
      appName: "Analitik Tafakkur",
      platform: "O'zbekiston tarixi va tarbiya fanlari uchun tahliliy platforma",
      studentSide: "O'quvchi",
      professorSide: "Ustoz",
      globalStats: "Umumiy reyting",
      publicStats: "Barcha natijalar",
      totalStudents: "O'quvchilar",
      submittedWorks: "Ishlar",
      gradedWorks: "Baholangan",
      averageScore: "O'rtacha ball",
      noScores: "Hali baholangan ishlar yo'q",
      leaderboard: "Reyting jadvali",
      place: "O'rin",
      student: "O'quvchi",
      anonymousId: "Anonim ID",
      grade: "Sinf",
      school: "Maktab",
      score: "Ball",
      works: "Ish",
      profile: "Ro'yxatdan o'tish",
      fullName: "Ism va familiya",
      schoolName: "Maktab nomi",
      professorSchool: "Tashkilot yoki maktab",
      email: "Email",
      password: "Parol",
      inviteCode: "Ustoz taklif kodi",
      selectGrade: "Sinfni tanlang",
      register: "Ro'yxatdan o'tish",
      signIn: "Kirish",
      signOut: "Chiqish",
      signedInAs: "Kirish bajarildi",
      profileRequired: "Profil maydonlarini to'ldiring.",
      authHelpStudent: "O'quvchi email va parol bilan ro'yxatdan o'tadi, javoblari bazada saqlanadi.",
      authHelpProfessor: "Ustoz ro'yxatdan o'tishi uchun taklif kodi kerak. Kod Supabase SQL faylida belgilanadi.",
      checkEmail: "Email tasdiqlash yoqilgan. Pochtangizni tasdiqlang, keyin shu yerda kiring.",
      dbConnected: "Supabase ulandi",
      dbMissing: "Database hali ulanmagan",
      setupNeeded: "Haqiqiy ro'yxatdan o'tish va umumiy statistika ishlashi uchun Supabase loyihasini ulang.",
      setupShort: "config.js fayliga Supabase URL va anon/public key kiriting, database.sql faylini Supabase SQL editorida ishga tushiring.",
      taskLibrary: "Topshiriqlar",
      allGrades: "Barcha sinflar",
      allStyles: "Barcha metodlar",
      startTask: "Boshlash",
      continueTask: "Davom etish",
      submitWork: "Ishni yuborish",
      myWorks: "Mening ishlarim",
      waiting: "Kutilmoqda",
      graded: "Baholandi",
      feedback: "Izoh",
      chooseTask: "Topshiriq tanlang",
      chooseTaskBody: "Profilni saqlang va sinfingizga mos tahliliy topshiriqni boshlang.",
      questionLanguage: "Savollar o'zbek tilida beriladi.",
      context: "Vaziyat",
      question: "Savol",
      steps: "Tahlil yo'nalishi",
      rubric: "Baholash mezonlari",
      professorWorkspace: "Ustoz paneli",
      taskEditor: "Topshiriq muharriri",
      gradingQueue: "Baholash",
      selectTask: "Topshiriqni tanlang",
      title: "Sarlavha",
      subject: "Fan",
      topic: "Mavzu",
      method: "Metod",
      saveTask: "Topshiriqni saqlash",
      addTask: "Yangi topshiriq",
      duplicateTask: "Nusxa olish",
      resetTasks: "Namunaviy topshiriqlarni tiklash",
      resetConfirm: "Namunaviy topshiriqlar bazaga qayta yozilsinmi?",
      selectSubmission: "Ishni tanlang",
      noSubmissions: "Hali yuborilgan ish yo'q",
      saveGrade: "Bahoni saqlash",
      submittedAt: "Yuborilgan vaqt",
      task: "Topshiriq",
      answers: "Javoblar",
      emptyValue: "Kiritilmagan",
      saved: "Saqlandi",
      case: "Keys metod",
      swot: "SWOT",
      fishbone: "Fishbone",
      insert: "INSERT",
      venn: "Venn diagramma",
      debate: "Debat",
      disney: "Walt Disney strategiyasi",
      reflexive: "Refleksiya",
      problem: "Muammo",
      evidence: "Dalillar",
      solution: "Yechim",
      result: "Kutilgan natija",
      strengths: "Kuchli tomonlar",
      weaknesses: "Zaif tomonlar",
      opportunities: "Imkoniyatlar",
      threats: "Xavflar",
      mainEffect: "Asosiy oqibat",
      causes: "Sabablar",
      people: "Inson omili",
      process: "Jarayon",
      environment: "Muhit",
      known: "V - bilganim",
      newInfo: "+ - yangi ma'lumot",
      conflict: "- - fikrimga zid",
      questionMark: "? - savolim",
      leftSide: "Birinchi tushuncha",
      shared: "Umumiy jihatlar",
      rightSide: "Ikkinchi tushuncha",
      position: "Pozitsiya",
      argument: "Dalil",
      rebuttal: "Qarshi fikrga javob",
      conclusion: "Xulosa",
      dreamer: "Orzuchi",
      realist: "Realist",
      critic: "Tanqidchi",
      actionPlan: "Harakat rejasi",
      learned: "Nimani o'rgandim",
      surprised: "Meni hayratlantirgan narsa",
      nextStep: "Keyingi qadam",
      placeholderLong: "Javobingizni dalillar bilan yozing...",
      visualTitle: "Tarixiy manba, tahlil va baho",
      visualSubtitle: "5-9-sinflar uchun keys, diagramma va refleksiya ishlari",
      taskSaved: "Topshiriq saqlandi",
      gradeSaved: "Baho saqlandi",
      workSubmitted: "Ish yuborildi",
      topGrade: "Eng faol sinf",
      none: "Yo'q",
      exportData: "JSON eksport",
      importHint: "Kitoblar yuborilgach, yangi topshiriqlar shu bazaga qo'shiladi.",
      professorNote: "Ustozlar topshiriq matnini, metodini va mezonlarini o'zgartiradi.",
      pendingOnly: "Faqat kutilayotgan",
      allWorks: "Barcha ishlar",
      loading: "Yuklanmoqda...",
      professorOnly: "Bu bo'lim uchun ustoz sifatida kiring.",
      studentOnly: "Topshiriq yuborish uchun o'quvchi sifatida kiring.",
      dbError: "Database xatosi"
    },
    ru: {
      appName: "Analitik Tafakkur",
      platform: "Аналитическая платформа по истории и воспитанию Узбекистана",
      studentSide: "Ученик",
      professorSide: "Учитель",
      globalStats: "Общий рейтинг",
      publicStats: "Все результаты",
      totalStudents: "Ученики",
      submittedWorks: "Работы",
      gradedWorks: "Оценено",
      averageScore: "Средний балл",
      noScores: "Оцененных работ пока нет",
      leaderboard: "Рейтинг",
      place: "Место",
      student: "Ученик",
      anonymousId: "Анонимный ID",
      grade: "Класс",
      school: "Школа",
      score: "Балл",
      works: "Работ",
      profile: "Регистрация",
      fullName: "Имя и фамилия",
      schoolName: "Название школы",
      professorSchool: "Организация или школа",
      email: "Email",
      password: "Пароль",
      inviteCode: "Код приглашения учителя",
      selectGrade: "Выберите класс",
      register: "Зарегистрироваться",
      signIn: "Войти",
      signOut: "Выйти",
      signedInAs: "Вход выполнен",
      profileRequired: "Заполните поля профиля.",
      authHelpStudent: "Ученик регистрируется по email и паролю, ответы сохраняются в базе.",
      authHelpProfessor: "Для регистрации учителя нужен код приглашения из SQL-файла Supabase.",
      checkEmail: "Подтверждение email включено. Подтвердите почту, затем войдите здесь.",
      dbConnected: "Supabase подключен",
      dbMissing: "Database не подключена",
      setupNeeded: "Для настоящей регистрации и общей статистики подключите проект Supabase.",
      setupShort: "Добавьте Supabase URL и anon/public key в config.js, затем выполните database.sql в SQL editor Supabase.",
      taskLibrary: "Задания",
      allGrades: "Все классы",
      allStyles: "Все методы",
      startTask: "Начать",
      continueTask: "Продолжить",
      submitWork: "Отправить работу",
      myWorks: "Мои работы",
      waiting: "Ожидает",
      graded: "Оценено",
      feedback: "Комментарий",
      chooseTask: "Выберите задание",
      chooseTaskBody: "Сохраните профиль и начните аналитическое задание для своего класса.",
      questionLanguage: "Вопросы показаны на узбекском языке.",
      context: "Ситуация",
      question: "Вопрос",
      steps: "Направление анализа",
      rubric: "Критерии оценки",
      professorWorkspace: "Панель учителя",
      taskEditor: "Редактор заданий",
      gradingQueue: "Оценивание",
      selectTask: "Выберите задание",
      title: "Заголовок",
      subject: "Предмет",
      topic: "Тема",
      method: "Метод",
      saveTask: "Сохранить задание",
      addTask: "Новое задание",
      duplicateTask: "Дублировать",
      resetTasks: "Восстановить образцы",
      resetConfirm: "Записать образцы заданий в базу заново?",
      selectSubmission: "Выберите работу",
      noSubmissions: "Отправленных работ пока нет",
      saveGrade: "Сохранить оценку",
      submittedAt: "Время отправки",
      task: "Задание",
      answers: "Ответы",
      emptyValue: "Не заполнено",
      saved: "Сохранено",
      case: "Кейс-метод",
      swot: "SWOT",
      fishbone: "Fishbone",
      insert: "INSERT",
      venn: "Диаграмма Венна",
      debate: "Дебаты",
      disney: "Стратегия Walt Disney",
      reflexive: "Рефлексия",
      problem: "Проблема",
      evidence: "Доказательства",
      solution: "Решение",
      result: "Ожидаемый результат",
      strengths: "Сильные стороны",
      weaknesses: "Слабые стороны",
      opportunities: "Возможности",
      threats: "Риски",
      mainEffect: "Главное последствие",
      causes: "Причины",
      people: "Человеческий фактор",
      process: "Процесс",
      environment: "Среда",
      known: "V - уже знаю",
      newInfo: "+ - новая информация",
      conflict: "- - противоречит мнению",
      questionMark: "? - вопрос",
      leftSide: "Первое понятие",
      shared: "Общее",
      rightSide: "Второе понятие",
      position: "Позиция",
      argument: "Аргумент",
      rebuttal: "Ответ оппоненту",
      conclusion: "Вывод",
      dreamer: "Мечтатель",
      realist: "Реалист",
      critic: "Критик",
      actionPlan: "План действий",
      learned: "Что я изучил",
      surprised: "Что удивило",
      nextStep: "Следующий шаг",
      placeholderLong: "Напишите ответ с аргументами...",
      visualTitle: "Исторический источник, анализ и оценка",
      visualSubtitle: "Кейсы, диаграммы и рефлексия для 5-9 классов",
      taskSaved: "Задание сохранено",
      gradeSaved: "Оценка сохранена",
      workSubmitted: "Работа отправлена",
      topGrade: "Самый активный класс",
      none: "Нет",
      exportData: "Экспорт JSON",
      importHint: "Позже новые задания будут добавлены в эту базу по отправленным книгам.",
      professorNote: "Учителя меняют текст, метод и критерии заданий.",
      pendingOnly: "Только ожидающие",
      allWorks: "Все работы",
      loading: "Загрузка...",
      professorOnly: "Войдите как учитель для этого раздела.",
      studentOnly: "Войдите как ученик, чтобы отправить работу.",
      dbError: "Ошибка database"
    },
    en: {
      appName: "Analitik Tafakkur",
      platform: "Analytical learning platform for Uzbekistan history and education",
      studentSide: "Student",
      professorSide: "Professor",
      globalStats: "Global rating",
      publicStats: "All results",
      totalStudents: "Students",
      submittedWorks: "Works",
      gradedWorks: "Graded",
      averageScore: "Average",
      noScores: "No graded work yet",
      leaderboard: "Leaderboard",
      place: "Rank",
      student: "Student",
      anonymousId: "Anonymous ID",
      grade: "Grade",
      school: "School",
      score: "Score",
      works: "Works",
      profile: "Registration",
      fullName: "Full name",
      schoolName: "School name",
      professorSchool: "Organization or school",
      email: "Email",
      password: "Password",
      inviteCode: "Professor invite code",
      selectGrade: "Select grade",
      register: "Register",
      signIn: "Sign in",
      signOut: "Sign out",
      signedInAs: "Signed in",
      profileRequired: "Fill in the profile fields.",
      authHelpStudent: "Students register with email and password, and answers are stored in the database.",
      authHelpProfessor: "Professors need the invite code configured in the Supabase SQL file.",
      checkEmail: "Email confirmation is enabled. Confirm your email, then sign in here.",
      dbConnected: "Supabase connected",
      dbMissing: "Database not connected",
      setupNeeded: "Connect a Supabase project for real registration and shared statistics.",
      setupShort: "Put your Supabase URL and anon/public key in config.js, then run database.sql in the Supabase SQL editor.",
      taskLibrary: "Tasks",
      allGrades: "All grades",
      allStyles: "All methods",
      startTask: "Start",
      continueTask: "Continue",
      submitWork: "Submit work",
      myWorks: "My works",
      waiting: "Waiting",
      graded: "Graded",
      feedback: "Feedback",
      chooseTask: "Choose a task",
      chooseTaskBody: "Save your profile and start an analytical task for your grade.",
      questionLanguage: "Questions are shown in Uzbek.",
      context: "Case",
      question: "Question",
      steps: "Analysis path",
      rubric: "Rubric",
      professorWorkspace: "Professor panel",
      taskEditor: "Task editor",
      gradingQueue: "Grading",
      selectTask: "Select task",
      title: "Title",
      subject: "Subject",
      topic: "Topic",
      method: "Method",
      saveTask: "Save task",
      addTask: "New task",
      duplicateTask: "Duplicate",
      resetTasks: "Restore sample tasks",
      resetConfirm: "Write the sample tasks into the database again?",
      selectSubmission: "Select work",
      noSubmissions: "No submitted work yet",
      saveGrade: "Save grade",
      submittedAt: "Submitted at",
      task: "Task",
      answers: "Answers",
      emptyValue: "Not entered",
      saved: "Saved",
      case: "Case method",
      swot: "SWOT",
      fishbone: "Fishbone",
      insert: "INSERT",
      venn: "Venn diagram",
      debate: "Debate",
      disney: "Walt Disney strategy",
      reflexive: "Reflective questions",
      problem: "Problem",
      evidence: "Evidence",
      solution: "Solution",
      result: "Expected result",
      strengths: "Strengths",
      weaknesses: "Weaknesses",
      opportunities: "Opportunities",
      threats: "Threats",
      mainEffect: "Main effect",
      causes: "Causes",
      people: "People",
      process: "Process",
      environment: "Environment",
      known: "V - I knew",
      newInfo: "+ - new information",
      conflict: "- - challenged my view",
      questionMark: "? - my question",
      leftSide: "First concept",
      shared: "Common points",
      rightSide: "Second concept",
      position: "Position",
      argument: "Argument",
      rebuttal: "Rebuttal",
      conclusion: "Conclusion",
      dreamer: "Dreamer",
      realist: "Realist",
      critic: "Critic",
      actionPlan: "Action plan",
      learned: "What I learned",
      surprised: "What surprised me",
      nextStep: "Next step",
      placeholderLong: "Write your answer with evidence...",
      visualTitle: "Historical source, analysis, and grading",
      visualSubtitle: "Cases, diagrams, and reflections for grades 5-9",
      taskSaved: "Task saved",
      gradeSaved: "Grade saved",
      workSubmitted: "Work submitted",
      topGrade: "Most active grade",
      none: "None",
      exportData: "Export JSON",
      importHint: "New tasks will later be added to this database from the books you send.",
      professorNote: "Professors can change task text, method, and rubrics.",
      pendingOnly: "Pending only",
      allWorks: "All works",
      loading: "Loading...",
      professorOnly: "Sign in as a professor for this section.",
      studentOnly: "Sign in as a student to submit work.",
      dbError: "Database error"
    }
  };

  var seedTasks = [
    {
      id: "task-5-case-temur",
      grade: 5,
      subject: "Tarix",
      style: "case",
      title: "Amir Temur tuzuklari: adolatli qaror",
      topic: "Davlat boshqaruvi va mas'uliyat",
      context: "Sinf kengashida ikki guruh bir xil kutubxona vaqtini so'ramoqda. Bir guruh tarix loyihasini yakunlashi kerak, ikkinchisi esa tarbiya darsidagi taqdimotga tayyorlanmoqda. Amir Temur tuzuklaridagi adolat, tartib va mas'uliyat g'oyalariga tayanib qaror qabul qiling.",
      question: "Sinf sardori sifatida qaysi qarorni tanlaysiz va uni tarixiy tamoyillar bilan qanday asoslay olasiz?",
      steps: ["Vaziyatdagi asosiy muammoni belgilang.", "Har bir guruh manfaatini va mas'uliyatini yozing.", "Kamida ikki yechim taklif qiling.", "Eng adolatli qarorni dalillar bilan himoya qiling."],
      rubric: ["Tarixiy tushuncha vaziyat bilan bog'langan.", "Dalillar aniq va izchil keltirilgan.", "Qaror ikki tomon manfaatini hisobga oladi.", "Xulosa mas'uliyatli harakat rejasini beradi."]
    },
    {
      id: "task-5-insert-silk-road",
      grade: 5,
      subject: "Tarix",
      style: "insert",
      title: "Buyuk ipak yo'li va shaharlardagi bilim almashinuvi",
      topic: "Samarqand, Buxoro va Xiva",
      context: "Buyuk ipak yo'li savdo, hunarmandchilik, ilm va madaniyat almashinuviga xizmat qilgan. O'zbekiston hududidagi qadimiy shaharlar turli xalqlar uchrashgan markaz bo'lgan.",
      question: "Matndagi ma'lumotlarni INSERT usulida tahlil qiling: qaysi fikrlarni oldindan bilardingiz, qaysilari yangi, qaysi fikrlar savol tug'diradi?",
      steps: ["V belgisi ostiga avval bilgan ma'lumotlaringizni yozing.", "+ belgisi ostiga yangi ma'lumotlarni kiriting.", "- belgisi ostiga sizni o'ylantirgan yoki boshqacha ko'ringan fikrni yozing.", "? belgisi ostiga qo'shimcha izlanish savolini yozing."],
      rubric: ["Har bir belgi mazmunli to'ldirilgan.", "Savollar mavzuga mos va izlanishga undaydi.", "Fikrlar tarixiy tushuncha bilan bog'langan.", "Yakuniy kuzatuv aniq yozilgan."]
    },
    {
      id: "task-6-venn-sogd-bactria",
      grade: 6,
      subject: "Tarix",
      style: "venn",
      title: "So'g'd va Baqtriya: o'xshashlik va farqlar",
      topic: "Qadimgi davlatlar",
      context: "So'g'd va Baqtriya qadimgi O'rta Osiyo tarixida muhim o'rin egallagan. Ikkalasida ham shahar madaniyati, savdo aloqalari va boshqaruv shakllari rivojlangan, ammo ularning geografik joylashuvi va tashqi aloqalari turlicha bo'lgan.",
      question: "Venn diagramma orqali So'g'd va Baqtriyaning farqli va umumiy jihatlarini tahlil qiling.",
      steps: ["So'g'dga xos uchta jihatni yozing.", "Baqtriyaga xos uchta jihatni yozing.", "Ikkalasiga umumiy bo'lgan kamida uchta jihatni belgilang.", "Qaysi umumiy jihat tarixiy rivojlanishda eng muhim bo'lganini tushuntiring."],
      rubric: ["Farqlar va o'xshashliklar ajratilgan.", "Geografiya, savdo va madaniyat hisobga olingan.", "Xulosa sabab-oqibat aloqasini ko'rsatadi.", "Tushunchalar aniq va tartibli yozilgan."]
    },
    {
      id: "task-6-fishbone-zarafshan",
      grade: 6,
      subject: "Tarix",
      style: "fishbone",
      title: "Zarafshon vohasida shaharlarning rivojlanishi",
      topic: "Sabab va oqibat",
      context: "Vohalarda suv manbalari, savdo yo'llari, hunarmandchilik va dehqonchilik shaharlar paydo bo'lishiga ta'sir qilgan. Har bir omil boshqa omillar bilan bog'liq bo'lgan.",
      question: "Fishbone usulida shaharlarning rivojlanishiga olib kelgan asosiy sabablarni guruhlang.",
      steps: ["Asosiy oqibatni yozing: shaharlarning rivojlanishi.", "Tabiiy sharoit, inson omili, savdo va boshqaruv sabablarini ajrating.", "Har bir sababga bitta tarixiy izoh qo'shing.", "Eng kuchli sababni tanlab, nima uchunligini yozing."],
      rubric: ["Sabablar to'g'ri guruhlangan.", "Har bir sabab oqibat bilan bog'langan.", "Tarixiy izohlar mavzuga mos.", "Eng muhim sabab asoslangan."]
    },
    {
      id: "task-7-swot-khorezmshah",
      grade: 7,
      subject: "Tarix",
      style: "swot",
      title: "Xorazmshohlar davlati: imkoniyat va xatarlar",
      topic: "O'rta asrlar boshqaruvi",
      context: "Xorazmshohlar davlati keng hudud, savdo yo'llari va harbiy salohiyatga ega bo'lgan. Shu bilan birga ichki nizolar, diplomatik xatolar va tashqi bosim davlat barqarorligiga ta'sir ko'rsatgan.",
      question: "SWOT tahlil yordamida Xorazmshohlar davlatining kuchli va zaif tomonlarini, imkoniyat va xatarlarini ko'rsating.",
      steps: ["Kuchli tomonlarni tarixiy dalillar bilan yozing.", "Zaif tomonlarni boshqaruv va birlik nuqtai nazaridan ko'rsating.", "Mavjud imkoniyatlarni savdo va diplomatiya bilan bog'lang.", "Xatarlarni tashqi va ichki omillarga ajrating."],
      rubric: ["SWOT bo'limlari to'liq to'ldirilgan.", "Tarixiy dalillar mavzuga mos.", "Ichki va tashqi omillar farqlangan.", "Xulosa strategik fikrni ko'rsatadi."]
    },
    {
      id: "task-7-debate-navoiy",
      grade: 7,
      subject: "Tarbiya",
      style: "debate",
      title: "Alisher Navoiy qarashlari: bilim va odob",
      topic: "Ma'naviyat va ta'lim",
      context: "Alisher Navoiy asarlarida ilm, odob, mehnat va insoniylik qadri ulug'lanadi. Bugungi maktab hayotida ham bilim va odob bir-birini to'ldiradi.",
      question: "Debat shaklida fikr bildiring: 'Bilim kuchli bo'lishi uchun odob va mas'uliyat zarur'. Ushbu fikrni yoqlang yoki unga qarshi asosli munosabat bildiring.",
      steps: ["O'z pozitsiyangizni aniq tanlang.", "Kamida ikki dalil yozing.", "Qarshi fikr bo'lishi mumkin bo'lgan nuqtani ko'rsating.", "Qarshi fikrga javob va yakuniy xulosa yozing."],
      rubric: ["Pozitsiya ravshan bildirilgan.", "Dalillar tarbiya va adabiy meros bilan bog'langan.", "Qarshi fikr hurmat bilan tahlil qilingan.", "Xulosa amaliy hayotga ulanadi."]
    },
    {
      id: "task-8-disney-jadid-school",
      grade: 8,
      subject: "Tarix",
      style: "disney",
      title: "Jadid maktabi uchun islohot rejasi",
      topic: "Jadidchilik va ta'lim",
      context: "Jadidlar yangi usul maktablari orqali savodxonlik, dunyoviy fanlar va milliy uyg'onish g'oyalarini kuchaytirishga harakat qilgan. Har bir islohot orzu, real imkoniyat va tanqidiy bahoni talab qiladi.",
      question: "Walt Disney strategiyasi orqali jadid maktabini rivojlantirish rejasini tuzing.",
      steps: ["Orzuchi sifatida ideal maktab qanday bo'lishini tasvirlang.", "Realist sifatida mavjud resurslar va birinchi qadamlarni yozing.", "Tanqidchi sifatida xavf va to'siqlarni belgilang.", "Uch rolni birlashtirib aniq harakat rejasini tuzing."],
      rubric: ["Uch rol alohida va mazmunli ishlatilgan.", "Reja tarixiy sharoitga mos.", "Xavflar real ko'rsatilgan.", "Harakat rejasi aniq va bajariladigan."]
    },
    {
      id: "task-8-case-khanate",
      grade: 8,
      subject: "Tarix",
      style: "case",
      title: "Qo'qon xonligida mahalliy boshqaruv",
      topic: "Boshqaruv va ijtimoiy hayot",
      context: "Mahalliy boshqaruvda soliq, xavfsizlik, savdo va aholi ehtiyojlari muvozanatda turishi kerak. Agar bozorda tartib buzilsa, aholi va savdogarlar ishonchi pasayadi.",
      question: "Qo'qon xonligi davridagi mahalliy hokim sifatida bozordagi nizoni qanday hal qilgan bo'lardingiz?",
      steps: ["Nizoning iqtisodiy va ijtimoiy sabablarini yozing.", "Aholi, savdogar va boshqaruv manfaatlarini ajrating.", "Adolatli tartib uchun ikki taklif bering.", "Qaroringizning mumkin bo'lgan oqibatini baholang."],
      rubric: ["Muammo tarixiy sharoitda ko'rib chiqilgan.", "Manfaatdor tomonlar ajratilgan.", "Takliflar amaliy va adolatli.", "Oqibatlar tahlil qilingan."]
    },
    {
      id: "task-9-fishbone-independence",
      grade: 9,
      subject: "Tarbiya",
      style: "fishbone",
      title: "Mustaqillikdan keyingi ta'lim islohotlari",
      topic: "Ta'lim va fuqarolik mas'uliyati",
      context: "Mustaqillikdan keyingi davrda ta'lim tizimi milliy qadriyatlar, zamonaviy bilim, kadrlar tayyorlash va fuqarolik mas'uliyatini uyg'unlashtirishga intildi.",
      question: "Fishbone orqali ta'lim islohotlariga ta'sir qilgan asosiy omillarni tahlil qiling.",
      steps: ["Asosiy oqibatni yozing: ta'lim sifatini oshirish zarurati.", "Qonunchilik, jamiyat ehtiyoji, iqtisodiy talab va texnologiya omillarini ajrating.", "Har bir omilga misol yozing.", "Qaysi omil eng tez ta'sir qilganini asoslang."],
      rubric: ["Omillar aniq guruhlangan.", "Har bir omil misol bilan tushuntirilgan.", "Sabab-oqibat aloqasi bor.", "Xulosa mustaqil fikrni ko'rsatadi."]
    },
    {
      id: "task-9-reflective-citizen",
      grade: 9,
      subject: "Tarbiya",
      style: "reflexive",
      title: "Faol fuqaro va maktab jamoasi",
      topic: "Fuqarolik pozitsiyasi",
      context: "Faol fuqaro o'z huquqini biladi, majburiyatini bajaradi va jamoa muammolariga befarq bo'lmaydi. Maktabdagi kichik tashabbuslar ham fuqarolik madaniyatini shakllantiradi.",
      question: "Refleksiv savollar orqali o'zingizning fuqarolik pozitsiyangizni baholang.",
      steps: ["Mavzudan nimani o'rganganingizni yozing.", "Sizni o'ylantirgan yoki hayratlantirgan jihatni belgilang.", "Maktab jamoasida bajarishingiz mumkin bo'lgan bitta tashabbusni yozing.", "Tashabbus qanday natija berishini taxmin qiling."],
      rubric: ["Shaxsiy xulosa samimiy va aniq.", "Fuqarolik mas'uliyati tushuntirilgan.", "Tashabbus real va foydali.", "Natija taxmini asoslangan."]
    }
  ];

  if (Array.isArray(window.AT_EXTRA_TASKS)) {
    seedTasks = seedTasks.concat(window.AT_EXTRA_TASKS);
  }

  var demoScoreboardEntries = Array.isArray(window.AT_DEMO_SCOREBOARD)
    ? window.AT_DEMO_SCOREBOARD.slice()
    : [];

  var state = {
    lang: normalizeLang(load(STORE.lang, "uz")),
    role: load(STORE.role, "student") === "professor" ? "professor" : "student",
    activeTaskId: load(STORE.activeTask, ""),
    filters: load(STORE.filters, { grade: "all", style: "all" }),
    editTaskId: load(STORE.editTask, ""),
    reviewSubmissionId: load(STORE.reviewSubmission, ""),
    gradingFilter: "pending",
    loading: true,
    dbReady: false,
    dbMessage: "",
    client: null,
    session: null,
    user: null,
    profile: null,
    tasks: seedTasks.slice(),
    submissions: [],
    scoreboard: [],
    globalStats: null
  };

  function load(key, fallback) {
    try {
      var raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (error) {
      return fallback;
    }
  }

  function save(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  function normalizeLang(lang) {
    return LANGS.indexOf(lang) >= 0 ? lang : "uz";
  }

  function t(key, vars) {
    var text = (i18n[state.lang] && i18n[state.lang][key]) || i18n.uz[key] || key;
    if (!vars) {
      return text;
    }
    Object.keys(vars).forEach(function (name) {
      text = text.replace(new RegExp("\\{" + name + "\\}", "g"), vars[name]);
    });
    return text;
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function uid(prefix) {
    return prefix + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
  }

  function formatDate(value) {
    if (!value) {
      return "";
    }
    return new Intl.DateTimeFormat(state.lang === "uz" ? "uz-UZ" : state.lang, {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  function isConfigured() {
    var config = window.AT_SUPABASE || {};
    return Boolean(window.supabase && config.url && config.anonKey && config.url.indexOf("https://") === 0);
  }

  async function init() {
    if (isConfigured()) {
      var config = window.AT_SUPABASE;
      state.client = window.supabase.createClient(config.url, config.anonKey, {
        auth: {
          autoRefreshToken: true,
          persistSession: true,
          detectSessionInUrl: true
        }
      });
      state.dbReady = true;
      var sessionResult = await state.client.auth.getSession();
      if (sessionResult.error) {
        state.dbMessage = sessionResult.error.message;
      }
      state.session = sessionResult.data && sessionResult.data.session;
      state.user = state.session && state.session.user;
      state.client.auth.onAuthStateChange(async function (_event, session) {
        state.session = session;
        state.user = session && session.user;
        await refreshData();
        render();
      });
    } else {
      state.dbReady = false;
      state.dbMessage = t("setupShort");
    }

    await refreshData();
    state.loading = false;
    render();
  }

  async function refreshData() {
    if (!state.dbReady) {
      state.tasks = seedTasks.slice();
      state.scoreboard = demoScoreboardEntries.map(normalizeDemoScore);
      state.submissions = [];
      state.globalStats = buildLocalGlobalStats();
      return;
    }

    try {
      await Promise.all([loadTasksFromDb(), loadPublicStatsFromDb()]);
      await loadProfileFromDb();
      await loadSubmissionsFromDb();
      state.dbMessage = "";
    } catch (error) {
      state.dbMessage = error.message || String(error);
    }
  }

  async function loadTasksFromDb() {
    var result = await state.client
      .from("tasks")
      .select("*")
      .eq("is_active", true)
      .order("grade", { ascending: true })
      .order("created_at", { ascending: true });
    if (result.error) {
      throw result.error;
    }
    state.tasks = (result.data && result.data.length ? result.data : seedTasks).map(normalizeTask);
    if (!getTask(state.activeTaskId) && state.tasks[0]) {
      state.activeTaskId = "";
      save(STORE.activeTask, "");
    }
  }

  async function loadPublicStatsFromDb() {
    var entries = await state.client
      .from("scoreboard_entries")
      .select("*")
      .order("score", { ascending: false });
    if (entries.error) {
      throw entries.error;
    }
    state.scoreboard = (entries.data || []).map(function (row) {
      var publicId = row.anonymous_id || anonymousIdFrom(row.student_id || row.submission_id || row.task_title || row.score);
      return {
        id: publicId,
        anonymousId: publicId,
        submissionId: row.submission_id,
        name: publicId,
        school: "",
        grade: row.grade,
        score: row.score,
        taskTitle: row.task_title,
        submittedAt: row.submitted_at,
        gradedAt: row.graded_at
      };
    });

    var stats = await state.client.from("global_stats").select("*").limit(1);
    if (stats.error) {
      throw stats.error;
    }
    state.globalStats = stats.data && stats.data[0] ? stats.data[0] : null;
  }

  function anonymousIdFrom(value) {
    var text = String(value || "learner");
    var hash = 2166136261;
    for (var index = 0; index < text.length; index += 1) {
      hash ^= text.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return "AT-" + (hash >>> 0).toString(36).toUpperCase().padStart(6, "0").slice(0, 6);
  }

  function normalizeDemoScore(row) {
    return {
      id: row.anonymousId,
      anonymousId: row.anonymousId,
      submissionId: row.id,
      name: row.anonymousId,
      school: "",
      grade: row.grade,
      score: row.score,
      taskTitle: row.taskTitle,
      submittedAt: row.submittedAt,
      gradedAt: row.gradedAt,
      isDemo: true
    };
  }

  function buildLocalGlobalStats() {
    var totalScore = demoScoreboardEntries.reduce(function (sum, row) {
      return sum + Number(row.score || 0);
    }, 0);
    var topGrade = demoScoreboardEntries.reduce(function (counts, row) {
      counts[row.grade] = (counts[row.grade] || 0) + 1;
      return counts;
    }, {});
    var grade = Object.keys(topGrade).sort(function (a, b) {
      return topGrade[b] - topGrade[a] || Number(a) - Number(b);
    })[0];
    return {
      total_students: new Set(demoScoreboardEntries.map(function (row) {
        return row.anonymousId;
      })).size,
      submitted_works: demoScoreboardEntries.length,
      graded_works: demoScoreboardEntries.length,
      average_score: demoScoreboardEntries.length ? Math.round(totalScore / demoScoreboardEntries.length) : 0,
      top_grade: grade || null
    };
  }

  async function loadProfileFromDb() {
    state.profile = null;
    if (!state.user) {
      return;
    }
    var result = await state.client
      .from("profiles")
      .select("*")
      .eq("id", state.user.id)
      .maybeSingle();
    if (result.error) {
      throw result.error;
    }
    state.profile = result.data ? normalizeProfile(result.data) : null;
  }

  async function loadSubmissionsFromDb() {
    state.submissions = [];
    if (!state.user || !state.profile) {
      return;
    }

    var query = state.client
      .from("submissions")
      .select("*, tasks(title, grade, style), profiles!submissions_student_id_fkey(full_name, school, grade)")
      .order("submitted_at", { ascending: false });

    if (state.profile.role !== "professor") {
      query = query.eq("student_id", state.user.id);
    }

    var result = await query;
    if (result.error) {
      throw result.error;
    }
    state.submissions = (result.data || []).map(normalizeSubmission);
  }

  function normalizeTask(row) {
    return {
      id: row.id,
      grade: Number(row.grade),
      subject: row.subject || "",
      style: row.style || "case",
      title: row.title || "",
      topic: row.topic || "",
      context: row.context || "",
      question: row.question || "",
      steps: Array.isArray(row.steps) ? row.steps : [],
      rubric: Array.isArray(row.rubric) ? row.rubric : [],
      isActive: row.is_active !== false
    };
  }

  function normalizeProfile(row) {
    return {
      id: row.id,
      role: row.role,
      name: row.full_name || "",
      school: row.school || "",
      grade: row.grade == null ? null : Number(row.grade),
      email: state.user && state.user.email
    };
  }

  function normalizeSubmission(row) {
    var profile = row.profiles || {};
    var task = row.tasks || {};
    return {
      id: row.id,
      taskId: row.task_id,
      taskTitle: task.title || "",
      studentId: row.student_id,
      studentName: profile.full_name || "",
      school: profile.school || "",
      grade: profile.grade,
      answers: row.answers || {},
      status: row.status || "waiting",
      score: typeof row.score === "number" ? row.score : null,
      feedback: row.feedback || "",
      submittedAt: row.submitted_at,
      gradedAt: row.graded_at
    };
  }

  function getStyleLabel(style) {
    return t(style);
  }

  function getTask(id) {
    return state.tasks.find(function (task) {
      return task.id === id;
    });
  }

  function getSubmission(id) {
    return state.submissions.find(function (submission) {
      return submission.id === id;
    });
  }

  function getStudentWorks() {
    if (!state.profile) {
      return [];
    }
    return state.submissions.filter(function (submission) {
      return submission.studentId === state.profile.id;
    });
  }

  function getFilteredTasks() {
    return state.tasks.filter(function (task) {
      var gradeMatch = state.filters.grade === "all" || String(task.grade) === String(state.filters.grade);
      var styleMatch = state.filters.style === "all" || task.style === state.filters.style;
      return gradeMatch && styleMatch;
    });
  }

  function calculateStats() {
    var leaderboardMap = {};
    state.scoreboard.forEach(function (entry) {
      var publicId = entry.anonymousId || entry.id;
      if (!leaderboardMap[publicId]) {
        leaderboardMap[publicId] = {
          id: publicId,
          name: publicId,
          school: "",
          grade: entry.grade,
          works: 0,
          total: 0,
          best: 0
        };
      }
      leaderboardMap[publicId].works += 1;
      leaderboardMap[publicId].total += Number(entry.score || 0);
      leaderboardMap[publicId].best = Math.max(leaderboardMap[publicId].best, Number(entry.score || 0));
    });

    var leaderboard = Object.keys(leaderboardMap).map(function (key) {
      var item = leaderboardMap[key];
      item.average = item.works ? Math.round(item.total / item.works) : 0;
      return item;
    }).sort(function (a, b) {
      return b.average - a.average || b.best - a.best || a.name.localeCompare(b.name);
    });

    var stats = state.globalStats || {};
    return {
      totalStudents: Number(stats.total_students || leaderboard.length || 0),
      submittedWorks: Number(stats.submitted_works || state.scoreboard.length || 0),
      gradedWorks: Number(stats.graded_works || state.scoreboard.length || 0),
      averageScore: stats.average_score == null ? 0 : Math.round(Number(stats.average_score)),
      scopeLabel: t("allGrades"),
      leaderboard: leaderboard
    };
  }

  function render() {
    document.documentElement.lang = state.lang;
    document.title = t("appName");
    var app = document.getElementById("app");
    app.innerHTML = [
      renderHeader(),
      '<main class="workspace">',
      '<aside class="side-column">',
      renderVisualPanel(),
      renderGlobalStats(),
      '</aside>',
      '<section class="main-column">',
      state.loading ? renderLoadingPanel() : (state.role === "student" ? renderStudentView() : renderProfessorView()),
      '</section>',
      '</main>',
      renderToast()
    ].join("");
    drawLearningCanvas();
  }

  function renderHeader() {
    return [
      '<header class="topbar">',
      '<div class="brand-block">',
      '<div class="brand-mark" aria-hidden="true">AT</div>',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("platform")) + '</p>',
      '<h1>' + escapeHtml(t("appName")) + '</h1>',
      '</div>',
      '</div>',
      '<div class="top-actions">',
      '<span class="status-pill ' + (state.dbReady ? "good" : "") + '">' + escapeHtml(state.dbReady ? t("dbConnected") : t("dbMissing")) + '</span>',
      '<div class="segmented" role="tablist" aria-label="Role">',
      roleButton("student", "studentSide"),
      roleButton("professor", "professorSide"),
      '</div>',
      '<div class="language-switch" aria-label="Language">',
      langButton("uz", "UZ"),
      langButton("ru", "RU"),
      langButton("en", "EN"),
      '</div>',
      '</div>',
      '</header>'
    ].join("");
  }

  function roleButton(role, labelKey) {
    var active = state.role === role ? " active" : "";
    return '<button class="segmented-button' + active + '" type="button" data-set-role="' + role + '">' + escapeHtml(t(labelKey)) + '</button>';
  }

  function langButton(lang, label) {
    var active = state.lang === lang ? " active" : "";
    return '<button class="lang-button' + active + '" type="button" data-set-lang="' + lang + '">' + label + '</button>';
  }

  function renderLoadingPanel() {
    return '<section class="panel workspace-panel empty-workspace"><h2>' + escapeHtml(t("loading")) + '</h2></section>';
  }

  function renderSetupNotice() {
    if (state.dbReady) {
      return "";
    }
    return [
      '<section class="panel setup-panel">',
      '<h2>' + escapeHtml(t("setupNeeded")) + '</h2>',
      '<p>' + escapeHtml(t("setupShort")) + '</p>',
      '</section>'
    ].join("");
  }

  function renderVisualPanel() {
    return [
      '<section class="panel visual-panel">',
      '<canvas id="learningCanvas" width="680" height="380" aria-label="' + escapeHtml(t("visualTitle")) + '"></canvas>',
      '<div class="visual-copy">',
      '<strong>' + escapeHtml(t("visualTitle")) + '</strong>',
      '<span>' + escapeHtml(t("visualSubtitle")) + '</span>',
      '</div>',
      '</section>'
    ].join("");
  }

  function renderGlobalStats() {
    var stats = calculateStats();
    var rows = stats.leaderboard.slice(0, 8).map(function (item, index) {
      return [
        '<tr>',
        '<td>' + (index + 1) + '</td>',
        '<td><strong>' + escapeHtml(item.name) + '</strong></td>',
        '<td>' + escapeHtml(item.grade || "") + '</td>',
        '<td>' + escapeHtml(item.average) + '</td>',
        '<td>' + escapeHtml(item.works) + '</td>',
        '</tr>'
      ].join("");
    }).join("");

    return [
      '<section class="panel stats-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("publicStats")) + '</p>',
      '<h2>' + escapeHtml(t("globalStats")) + '</h2>',
      '</div>',
      '<span class="status-pill">' + escapeHtml(stats.scopeLabel) + '</span>',
      '</div>',
      '<div class="metric-grid">',
      metric("totalStudents", stats.totalStudents),
      metric("submittedWorks", stats.submittedWorks),
      metric("gradedWorks", stats.gradedWorks),
      metric("averageScore", stats.gradedWorks ? stats.averageScore : "-"),
      '</div>',
      '<h3>' + escapeHtml(t("leaderboard")) + '</h3>',
      stats.leaderboard.length ? [
        '<div class="table-wrap">',
        '<table class="leaderboard">',
        '<thead><tr>',
        '<th>' + escapeHtml(t("place")) + '</th>',
        '<th>' + escapeHtml(t("anonymousId")) + '</th>',
        '<th>' + escapeHtml(t("grade")) + '</th>',
        '<th>' + escapeHtml(t("score")) + '</th>',
        '<th>' + escapeHtml(t("works")) + '</th>',
        '</tr></thead>',
        '<tbody>' + rows + '</tbody>',
        '</table>',
        '</div>'
      ].join("") : '<p class="empty-state">' + escapeHtml(t("noScores")) + '</p>',
      '</section>'
    ].join("");
  }

  function metric(labelKey, value) {
    return '<div class="metric"><span>' + escapeHtml(t(labelKey)) + '</span><strong>' + escapeHtml(value) + '</strong></div>';
  }

  function renderStudentView() {
    return [
      '<section class="view-stack">',
      renderSetupNotice(),
      '<div class="student-grid">',
      renderStudentPanel(),
      renderTaskLibrary(),
      '</div>',
      renderTaskWorkspace(),
      '</section>'
    ].join("");
  }

  function renderStudentPanel() {
    if (!state.dbReady || !state.profile || state.profile.role !== "student") {
      return renderAuthPanel("student");
    }

    return [
      '<section class="panel profile-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("signedInAs")) + '</p>',
      '<h2>' + escapeHtml(state.profile.name) + '</h2>',
      '</div>',
      '<button class="secondary-button" type="button" data-sign-out>' + escapeHtml(t("signOut")) + '</button>',
      '</div>',
      '<p class="note">' + escapeHtml(state.profile.school) + ' · ' + escapeHtml(state.profile.grade) + '-' + escapeHtml(t("grade").toLowerCase()) + '</p>',
      '<p class="note">' + escapeHtml(t("questionLanguage")) + '</p>',
      renderMyWorks(),
      '</section>'
    ].join("");
  }

  function renderAuthPanel(role) {
    var isStudent = role === "student";
    var help = isStudent ? t("authHelpStudent") : t("authHelpProfessor");
    return [
      '<section class="panel profile-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(isStudent ? t("studentSide") : t("professorSide")) + '</p>',
      '<h2>' + escapeHtml(t("profile")) + '</h2>',
      '</div>',
      state.user ? '<button class="secondary-button" type="button" data-sign-out>' + escapeHtml(t("signOut")) + '</button>' : '',
      '</div>',
      '<p class="note">' + escapeHtml(help) + '</p>',
      !state.dbReady ? '<p class="empty-state">' + escapeHtml(t("setupShort")) + '</p>' : '',
      state.user && state.profile ? '<p class="note">' + escapeHtml(t("signedInAs") + ': ' + (state.user.email || "")) + '</p>' : '',
      '<form id="authForm" class="form-stack" data-auth-role="' + role + '" novalidate>',
      textInput("fullName", t("fullName"), state.profile ? state.profile.name : "", true),
      textInput("school", isStudent ? t("schoolName") : t("professorSchool"), state.profile ? state.profile.school : "", true),
      isStudent ? gradeSelect(state.profile ? state.profile.grade : "") : '',
      !isStudent ? textInput("professorCode", t("inviteCode"), "", true) : '',
      textInput("email", t("email"), state.user ? state.user.email : "", !state.user),
      passwordInput(),
      '<div class="button-row">',
      '<button class="primary-button" type="submit" data-auth-action="signup"' + (state.dbReady ? "" : " disabled") + '>' + escapeHtml(t("register")) + '</button>',
      '<button class="secondary-button" type="submit" data-auth-action="signin"' + (state.dbReady ? "" : " disabled") + '>' + escapeHtml(t("signIn")) + '</button>',
      '</div>',
      '</form>',
      state.dbMessage ? '<p class="note error-text">' + escapeHtml(state.dbMessage) + '</p>' : '',
      '</section>'
    ].join("");
  }

  function textInput(name, label, value, required) {
    return [
      '<label class="field">',
      '<span>' + escapeHtml(label) + '</span>',
      '<input name="' + name + '" value="' + escapeHtml(value || "") + '"' + (required ? " required" : "") + '>',
      '</label>'
    ].join("");
  }

  function passwordInput() {
    return [
      '<label class="field">',
      '<span>' + escapeHtml(t("password")) + '</span>',
      '<input name="password" type="password" minlength="6" autocomplete="current-password" required>',
      '</label>'
    ].join("");
  }

  function gradeSelect(value) {
    return [
      '<label class="field"><span>' + escapeHtml(t("selectGrade")) + '</span><select name="grade" required>',
      '<option value="">' + escapeHtml(t("selectGrade")) + '</option>',
      GRADES.map(function (grade) {
        return '<option value="' + grade + '"' + (String(value) === String(grade) ? " selected" : "") + '>' + grade + '</option>';
      }).join(""),
      '</select></label>'
    ].join("");
  }

  function renderMyWorks() {
    var works = getStudentWorks();
    if (!works.length) {
      return '<div class="mini-list"><h3>' + escapeHtml(t("myWorks")) + '</h3><p class="empty-state">' + escapeHtml(t("noSubmissions")) + '</p></div>';
    }
    var items = works.map(function (work) {
      var task = getTask(work.taskId);
      return [
        '<article class="work-row">',
        '<div>',
        '<strong>' + escapeHtml(task ? task.title : work.taskTitle || t("task")) + '</strong>',
        '<span>' + escapeHtml(formatDate(work.submittedAt)) + '</span>',
        work.feedback ? '<span>' + escapeHtml(t("feedback") + ': ' + work.feedback) + '</span>' : '',
        '</div>',
        '<span class="status-pill ' + (work.status === "graded" ? "good" : "") + '">',
        work.status === "graded" ? escapeHtml(work.score) : escapeHtml(t("waiting")),
        '</span>',
        '</article>'
      ].join("");
    }).join("");
    return '<div class="mini-list"><h3>' + escapeHtml(t("myWorks")) + '</h3>' + items + '</div>';
  }

  function renderTaskLibrary() {
    var tasks = getFilteredTasks();
    return [
      '<section class="panel library-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("importHint")) + '</p>',
      '<h2>' + escapeHtml(t("taskLibrary")) + '</h2>',
      '</div>',
      '</div>',
      '<div class="filter-bar">',
      '<label class="compact-field"><span>' + escapeHtml(t("grade")) + '</span><select data-filter="grade">',
      '<option value="all">' + escapeHtml(t("allGrades")) + '</option>',
      GRADES.map(function (grade) {
        return '<option value="' + grade + '"' + (String(state.filters.grade) === String(grade) ? " selected" : "") + '>' + grade + '</option>';
      }).join(""),
      '</select></label>',
      '<label class="compact-field"><span>' + escapeHtml(t("method")) + '</span><select data-filter="style">',
      '<option value="all">' + escapeHtml(t("allStyles")) + '</option>',
      STYLES.map(function (style) {
        return '<option value="' + style + '"' + (state.filters.style === style ? " selected" : "") + '>' + escapeHtml(getStyleLabel(style)) + '</option>';
      }).join(""),
      '</select></label>',
      '</div>',
      '<div class="task-list">',
      tasks.map(renderTaskCard).join(""),
      '</div>',
      '</section>'
    ].join("");
  }

  function renderTaskCard(task) {
    var active = state.activeTaskId === task.id ? " active" : "";
    var canStart = state.dbReady && state.profile && state.profile.role === "student";
    return [
      '<article class="task-card' + active + '">',
      '<div class="task-card-top">',
      '<span class="method-badge ' + task.style + '">' + escapeHtml(getStyleLabel(task.style)) + '</span>',
      '<span class="grade-badge">' + escapeHtml(task.grade) + '</span>',
      '</div>',
      '<h3>' + escapeHtml(task.title) + '</h3>',
      '<p>' + escapeHtml(task.topic) + '</p>',
      '<button class="secondary-button" type="button" data-start-task="' + escapeHtml(task.id) + '"' + (canStart ? "" : " disabled") + '>' + escapeHtml(state.activeTaskId === task.id ? t("continueTask") : t("startTask")) + '</button>',
      '</article>'
    ].join("");
  }

  function renderTaskWorkspace() {
    var task = getTask(state.activeTaskId);
    if (!task) {
      return [
        '<section class="panel workspace-panel empty-workspace">',
        '<h2>' + escapeHtml(t("chooseTask")) + '</h2>',
        '<p>' + escapeHtml(state.dbReady ? t("chooseTaskBody") : t("studentOnly")) + '</p>',
        '</section>'
      ].join("");
    }

    return [
      '<section class="panel workspace-panel">',
      '<div class="task-intro">',
      '<div>',
      '<span class="method-badge ' + task.style + '">' + escapeHtml(getStyleLabel(task.style)) + '</span>',
      '<h2>' + escapeHtml(task.title) + '</h2>',
      '<p>' + escapeHtml(task.subject) + ' · ' + escapeHtml(task.grade) + '-' + escapeHtml(t("grade").toLowerCase()) + '</p>',
      '</div>',
      '</div>',
      renderTaskDetail(task),
      '<form id="answerForm" class="answer-form" data-task-id="' + escapeHtml(task.id) + '">',
      renderWorkspaceFields(task.style),
      '<button class="primary-button" type="submit">' + escapeHtml(t("submitWork")) + '</button>',
      '</form>',
      '</section>'
    ].join("");
  }

  function renderTaskDetail(task) {
    return [
      '<div class="task-detail-grid">',
      detailBlock("context", task.context),
      detailBlock("question", task.question),
      detailList("steps", task.steps),
      detailList("rubric", task.rubric),
      '</div>'
    ].join("");
  }

  function detailBlock(labelKey, value) {
    return '<section class="detail-block"><h3>' + escapeHtml(t(labelKey)) + '</h3><p>' + escapeHtml(value) + '</p></section>';
  }

  function detailList(labelKey, values) {
    return [
      '<section class="detail-block">',
      '<h3>' + escapeHtml(t(labelKey)) + '</h3>',
      '<ol>',
      (values || []).map(function (value) {
        return '<li>' + escapeHtml(value) + '</li>';
      }).join(""),
      '</ol>',
      '</section>'
    ].join("");
  }

  function renderWorkspaceFields(style) {
    var groups = {
      case: ["problem", "evidence", "solution", "result"],
      swot: ["strengths", "weaknesses", "opportunities", "threats"],
      fishbone: ["mainEffect", "causes", "people", "process", "environment"],
      insert: ["known", "newInfo", "conflict", "questionMark"],
      venn: ["leftSide", "shared", "rightSide"],
      debate: ["position", "argument", "rebuttal", "conclusion"],
      disney: ["dreamer", "realist", "critic", "actionPlan"],
      reflexive: ["learned", "surprised", "nextStep"]
    };
    var keys = groups[style] || groups.case;
    var className = keys.length === 3 ? "answer-grid three" : keys.length === 5 ? "answer-grid fish" : "answer-grid";
    return '<div class="' + className + '">' + keys.map(answerField).join("") + '</div>';
  }

  function answerField(key) {
    return [
      '<label class="field answer-field">',
      '<span>' + escapeHtml(t(key)) + '</span>',
      '<textarea data-answer-key="' + key + '" placeholder="' + escapeHtml(t("placeholderLong")) + '" required></textarea>',
      '</label>'
    ].join("");
  }

  function renderProfessorView() {
    if (!state.dbReady || !state.profile || state.profile.role !== "professor") {
      return '<section class="view-stack">' + renderSetupNotice() + renderAuthPanel("professor") + '</section>';
    }

    var editTask = getTask(state.editTaskId) || state.tasks[0];
    if (editTask && state.editTaskId !== editTask.id) {
      state.editTaskId = editTask.id;
      save(STORE.editTask, state.editTaskId);
    }
    return [
      '<section class="view-stack">',
      '<section class="panel professor-header">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("signedInAs") + ': ' + (state.user.email || "")) + '</p>',
      '<h2>' + escapeHtml(t("professorWorkspace")) + '</h2>',
      '</div>',
      '<div class="button-row">',
      '<button class="secondary-button" type="button" data-export-json>' + escapeHtml(t("exportData")) + '</button>',
      '<button class="secondary-button" type="button" data-sign-out>' + escapeHtml(t("signOut")) + '</button>',
      '</div>',
      '</div>',
      '</section>',
      '<div class="professor-grid">',
      renderTaskEditor(editTask),
      renderGradingQueue(),
      '</div>',
      '</section>'
    ].join("");
  }

  function renderTaskEditor(task) {
    if (!task) {
      return "";
    }
    return [
      '<section class="panel editor-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("taskLibrary")) + '</p>',
      '<h2>' + escapeHtml(t("taskEditor")) + '</h2>',
      '</div>',
      '</div>',
      '<label class="field"><span>' + escapeHtml(t("selectTask")) + '</span><select data-edit-task-select>',
      state.tasks.map(function (item) {
        return '<option value="' + escapeHtml(item.id) + '"' + (item.id === task.id ? " selected" : "") + '>' + escapeHtml(item.grade + " · " + item.title) + '</option>';
      }).join(""),
      '</select></label>',
      '<form id="taskEditorForm" class="form-stack" data-task-id="' + escapeHtml(task.id) + '">',
      textInput("title", t("title"), task.title, true),
      '<div class="inline-fields">',
      '<label class="field"><span>' + escapeHtml(t("grade")) + '</span><select name="grade" required>',
      GRADES.map(function (grade) {
        return '<option value="' + grade + '"' + (Number(task.grade) === grade ? " selected" : "") + '>' + grade + '</option>';
      }).join(""),
      '</select></label>',
      textInput("subject", t("subject"), task.subject, true),
      '</div>',
      '<div class="inline-fields">',
      textInput("topic", t("topic"), task.topic, true),
      '<label class="field"><span>' + escapeHtml(t("method")) + '</span><select name="style" required>',
      STYLES.map(function (style) {
        return '<option value="' + style + '"' + (task.style === style ? " selected" : "") + '>' + escapeHtml(getStyleLabel(style)) + '</option>';
      }).join(""),
      '</select></label>',
      '</div>',
      textareaInput("context", t("context"), task.context, true),
      textareaInput("question", t("question"), task.question, true),
      textareaInput("steps", t("steps"), (task.steps || []).join("\n"), true),
      textareaInput("rubric", t("rubric"), (task.rubric || []).join("\n"), true),
      '<div class="button-row">',
      '<button class="primary-button" type="submit">' + escapeHtml(t("saveTask")) + '</button>',
      '<button class="secondary-button" type="button" data-duplicate-task="' + escapeHtml(task.id) + '">' + escapeHtml(t("duplicateTask")) + '</button>',
      '<button class="secondary-button" type="button" data-add-task>' + escapeHtml(t("addTask")) + '</button>',
      '<button class="ghost-button" type="button" data-reset-tasks>' + escapeHtml(t("resetTasks")) + '</button>',
      '</div>',
      '</form>',
      '</section>'
    ].join("");
  }

  function textareaInput(name, label, value, required) {
    return [
      '<label class="field">',
      '<span>' + escapeHtml(label) + '</span>',
      '<textarea name="' + name + '"' + (required ? " required" : "") + '>' + escapeHtml(value) + '</textarea>',
      '</label>'
    ].join("");
  }

  function renderGradingQueue() {
    var filtered = state.submissions.filter(function (submission) {
      return state.gradingFilter === "all" || submission.status !== "graded";
    });
    var selected = getSubmission(state.reviewSubmissionId) || filtered[0] || state.submissions[0];
    if (selected && state.reviewSubmissionId !== selected.id) {
      state.reviewSubmissionId = selected.id;
      save(STORE.reviewSubmission, state.reviewSubmissionId);
    }
    return [
      '<section class="panel grading-panel">',
      '<div class="section-heading">',
      '<div>',
      '<p class="eyebrow">' + escapeHtml(t("professorSide")) + '</p>',
      '<h2>' + escapeHtml(t("gradingQueue")) + '</h2>',
      '</div>',
      '<select data-grading-filter aria-label="' + escapeHtml(t("gradingQueue")) + '">',
      '<option value="pending"' + (state.gradingFilter === "pending" ? " selected" : "") + '>' + escapeHtml(t("pendingOnly")) + '</option>',
      '<option value="all"' + (state.gradingFilter === "all" ? " selected" : "") + '>' + escapeHtml(t("allWorks")) + '</option>',
      '</select>',
      '</div>',
      filtered.length ? '<div class="submission-layout"><div class="submission-list">' + filtered.map(renderSubmissionButton).join("") + '</div>' + renderSubmissionReview(selected) + '</div>' : '<p class="empty-state">' + escapeHtml(t("noSubmissions")) + '</p>',
      '</section>'
    ].join("");
  }

  function renderSubmissionButton(submission) {
    var task = getTask(submission.taskId);
    var active = state.reviewSubmissionId === submission.id ? " active" : "";
    return [
      '<button class="submission-button' + active + '" type="button" data-review-submission="' + escapeHtml(submission.id) + '">',
      '<strong>' + escapeHtml(submission.studentName) + '</strong>',
      '<span>' + escapeHtml(task ? task.title : submission.taskTitle || t("task")) + '</span>',
      '<small>' + escapeHtml(submission.status === "graded" ? submission.score : t("waiting")) + '</small>',
      '</button>'
    ].join("");
  }

  function renderSubmissionReview(submission) {
    if (!submission) {
      return "";
    }
    var task = getTask(submission.taskId);
    var score = typeof submission.score === "number" ? submission.score : 75;
    return [
      '<article class="review-pane">',
      '<div class="review-meta">',
      '<span>' + escapeHtml(t("student")) + ': <strong>' + escapeHtml(submission.studentName) + '</strong></span>',
      '<span>' + escapeHtml(t("grade")) + ': <strong>' + escapeHtml(submission.grade || "") + '</strong></span>',
      '<span>' + escapeHtml(t("submittedAt")) + ': <strong>' + escapeHtml(formatDate(submission.submittedAt)) + '</strong></span>',
      '</div>',
      '<h3>' + escapeHtml(task ? task.title : submission.taskTitle || t("task")) + '</h3>',
      '<div class="answer-review">',
      Object.keys(submission.answers || {}).map(function (key) {
        return '<section><h4>' + escapeHtml(t(key)) + '</h4><p>' + escapeHtml(submission.answers[key] || t("emptyValue")) + '</p></section>';
      }).join(""),
      '</div>',
      '<form id="gradeForm" class="form-stack" data-submission-id="' + escapeHtml(submission.id) + '">',
      '<label class="field score-field"><span>' + escapeHtml(t("score")) + '</span><input type="range" min="0" max="100" value="' + score + '" data-score-range><input name="score" type="number" min="0" max="100" value="' + score + '" required></label>',
      textareaInput("feedback", t("feedback"), submission.feedback || "", false),
      '<button class="primary-button" type="submit">' + escapeHtml(t("saveGrade")) + '</button>',
      '</form>',
      '</article>'
    ].join("");
  }

  function renderToast() {
    return '<div id="toast" class="toast" role="status" aria-live="polite"></div>';
  }

  function showToast(message) {
    var toast = document.getElementById("toast");
    if (!toast) {
      return;
    }
    toast.textContent = message;
    toast.classList.add("visible");
    window.clearTimeout(showToast.timer);
    showToast.timer = window.setTimeout(function () {
      toast.classList.remove("visible");
    }, 2200);
  }

  async function handleAuthSubmit(form, action) {
    var data = new FormData(form);
    var role = form.getAttribute("data-auth-role");
    var email = String(data.get("email") || "").trim();
    var password = String(data.get("password") || "");
    var fullName = String(data.get("fullName") || "").trim();
    var school = String(data.get("school") || "").trim();
    var grade = role === "student" ? Number(data.get("grade")) : null;
    var professorCode = role === "professor" ? String(data.get("professorCode") || "").trim() : null;

    if (!state.dbReady) {
      showToast(t("setupNeeded"));
      return;
    }

    try {
      if (!email || password.length < 6) {
        throw new Error(t("email") + " / " + t("password"));
      }

      if (action === "signup") {
        validateProfileFields(role, fullName, school, grade, professorCode);
        var signUp = await state.client.auth.signUp({
          email: email,
          password: password,
          options: {
            data: {
              full_name: fullName,
              role: role
            }
          }
        });
        if (signUp.error) {
          throw signUp.error;
        }
        state.session = signUp.data.session;
        state.user = signUp.data.user;
        if (!state.session) {
          state.dbMessage = t("checkEmail");
          render();
          return;
        }
      } else {
        var signIn = await state.client.auth.signInWithPassword({ email: email, password: password });
        if (signIn.error) {
          throw signIn.error;
        }
        state.session = signIn.data.session;
        state.user = signIn.data.user;
        await loadProfileFromDb();
        if (state.profile) {
          await refreshData();
          render();
          showToast(t("saved"));
          return;
        }
        validateProfileFields(role, fullName, school, grade, professorCode);
      }

      await completeProfile(role, fullName, school, grade, professorCode);
      await refreshData();
      render();
      showToast(t("saved"));
    } catch (error) {
      state.dbMessage = (error && error.message) || String(error);
      render();
      showToast(t("dbError"));
    }
  }

  function validateProfileFields(role, fullName, school, grade, professorCode) {
    if (!fullName || !school) {
      throw new Error(t("profileRequired"));
    }
    if (role === "student" && GRADES.indexOf(Number(grade)) === -1) {
      throw new Error(t("selectGrade"));
    }
    if (role === "professor" && !professorCode) {
      throw new Error(t("inviteCode"));
    }
  }

  async function completeProfile(role, fullName, school, grade, professorCode) {
    var result = await state.client.rpc("complete_profile", {
      p_full_name: fullName,
      p_school: school,
      p_grade: role === "student" ? grade : null,
      p_role: role,
      p_professor_code: role === "professor" ? professorCode : null
    });
    if (result.error) {
      throw result.error;
    }
  }

  async function saveTaskFromForm(form) {
    var taskForm = new FormData(form);
    var taskId = form.getAttribute("data-task-id");
    var payload = {
      id: taskId,
      title: String(taskForm.get("title")).trim(),
      grade: Number(taskForm.get("grade")),
      subject: String(taskForm.get("subject")).trim(),
      topic: String(taskForm.get("topic")).trim(),
      style: String(taskForm.get("style")),
      context: String(taskForm.get("context")).trim(),
      question: String(taskForm.get("question")).trim(),
      steps: splitLines(taskForm.get("steps")),
      rubric: splitLines(taskForm.get("rubric")),
      is_active: true
    };
    var result = await state.client.from("tasks").upsert(payload, { onConflict: "id" });
    if (result.error) {
      throw result.error;
    }
  }

  function splitLines(value) {
    return String(value || "")
      .split(/\n+/)
      .map(function (line) {
        return line.trim();
      })
      .filter(Boolean);
  }

  function createBlankTask() {
    return {
      id: uid("task"),
      grade: 5,
      subject: "Tarix",
      style: "case",
      title: "Yangi tahliliy topshiriq",
      topic: "Yangi mavzu",
      context: "Vaziyat matnini shu yerga yozing.",
      question: "Asosiy tahliliy savolni yozing.",
      steps: ["Muammoni aniqlang.", "Dalillarni yozing.", "Xulosa chiqaring."],
      rubric: ["Mavzuga moslik", "Dalillar sifati", "Tahlil chuqurligi", "Xulosa aniqligi"],
      is_active: true
    };
  }

  async function exportJson() {
    var payload = {
      exportedAt: new Date().toISOString(),
      tasks: state.tasks,
      submissions: state.submissions,
      scoreboard: state.scoreboard
    };
    var blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    var url = URL.createObjectURL(blob);
    var link = document.createElement("a");
    link.href = url;
    link.download = "analitik-tafakkur-data.json";
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
  }

  function drawLearningCanvas() {
    var canvas = document.getElementById("learningCanvas");
    if (!canvas || !canvas.getContext) {
      return;
    }
    var ctx = canvas.getContext("2d");
    var w = canvas.width;
    var h = canvas.height;

    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = "#f7f8f4";
    ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = "#dce9e2";
    ctx.fillRect(0, 250, w, 130);
    ctx.fillStyle = "#14635a";
    ctx.fillRect(72, 70, 270, 170);
    ctx.fillStyle = "#f9f6ea";
    ctx.fillRect(88, 86, 238, 138);
    ctx.strokeStyle = "#315c8f";
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(120, 185);
    ctx.bezierCurveTo(165, 120, 230, 135, 292, 102);
    ctx.stroke();
    ctx.fillStyle = "#a33e35";
    [[125, 175], [185, 138], [248, 121], [292, 102]].forEach(function (point) {
      ctx.beginPath();
      ctx.arc(point[0], point[1], 7, 0, Math.PI * 2);
      ctx.fill();
    });
    ctx.fillStyle = "#10211f";
    ctx.font = "700 34px Arial";
    ctx.fillText("5-9", 116, 130);
    ctx.font = "600 18px Arial";
    ctx.fillText("Tarix", 116, 158);
    ctx.fillText("Tarbiya", 215, 158);
    ctx.fillStyle = "#c89422";
    ctx.fillRect(392, 104, 156, 176);
    ctx.fillStyle = "#fdfbf4";
    ctx.fillRect(408, 84, 156, 176);
    ctx.fillStyle = "#286c4d";
    ctx.fillRect(424, 64, 156, 176);
    ctx.strokeStyle = "#fdfbf4";
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(454, 98);
    ctx.lineTo(548, 98);
    ctx.moveTo(454, 126);
    ctx.lineTo(530, 126);
    ctx.moveTo(454, 154);
    ctx.lineTo(558, 154);
    ctx.stroke();
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(414, 274, 205, 35);
    ctx.fillStyle = "#10211f";
    ctx.font = "700 18px Arial";
    ctx.fillText("SWOT  INSERT  VENN", 430, 298);
    ctx.fillStyle = "#a33e35";
    ctx.fillRect(95, 274, 54, 54);
    ctx.fillStyle = "#315c8f";
    ctx.fillRect(162, 274, 54, 54);
    ctx.fillStyle = "#c89422";
    ctx.fillRect(229, 274, 54, 54);
    ctx.fillStyle = "#ffffff";
    ctx.font = "700 23px Arial";
    ctx.fillText("K", 113, 309);
    ctx.fillText("S", 180, 309);
    ctx.fillText("R", 247, 309);
  }

  async function handleClick(event) {
    var roleButtonEl = event.target.closest("[data-set-role]");
    if (roleButtonEl) {
      state.role = roleButtonEl.getAttribute("data-set-role");
      save(STORE.role, state.role);
      render();
      return;
    }

    var langButtonEl = event.target.closest("[data-set-lang]");
    if (langButtonEl) {
      state.lang = normalizeLang(langButtonEl.getAttribute("data-set-lang"));
      save(STORE.lang, state.lang);
      render();
      return;
    }

    var signOutButton = event.target.closest("[data-sign-out]");
    if (signOutButton && state.client) {
      await state.client.auth.signOut();
      state.user = null;
      state.session = null;
      state.profile = null;
      state.submissions = [];
      await refreshData();
      render();
      return;
    }

    var startButton = event.target.closest("[data-start-task]");
    if (startButton && !startButton.disabled) {
      state.activeTaskId = startButton.getAttribute("data-start-task");
      save(STORE.activeTask, state.activeTaskId);
      render();
      document.querySelector(".workspace-panel").scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }

    var reviewButton = event.target.closest("[data-review-submission]");
    if (reviewButton) {
      state.reviewSubmissionId = reviewButton.getAttribute("data-review-submission");
      save(STORE.reviewSubmission, state.reviewSubmissionId);
      render();
      return;
    }

    var addTaskButton = event.target.closest("[data-add-task]");
    if (addTaskButton) {
      var newTask = createBlankTask();
      try {
        var result = await state.client.from("tasks").insert(newTask);
        if (result.error) {
          throw result.error;
        }
        state.editTaskId = newTask.id;
        save(STORE.editTask, state.editTaskId);
        await refreshData();
        render();
      } catch (error) {
        showToast(error.message || t("dbError"));
      }
      return;
    }

    var duplicateButton = event.target.closest("[data-duplicate-task]");
    if (duplicateButton) {
      var original = getTask(duplicateButton.getAttribute("data-duplicate-task"));
      if (original) {
        var copy = Object.assign({}, original, { id: uid("task"), title: original.title + " / copy" });
        try {
          var copyResult = await state.client.from("tasks").insert(copy);
          if (copyResult.error) {
            throw copyResult.error;
          }
          state.editTaskId = copy.id;
          save(STORE.editTask, state.editTaskId);
          await refreshData();
          render();
        } catch (error) {
          showToast(error.message || t("dbError"));
        }
      }
      return;
    }

    var resetButton = event.target.closest("[data-reset-tasks]");
    if (resetButton && window.confirm(t("resetConfirm"))) {
      try {
        var resetResult = await state.client.from("tasks").upsert(seedTasks.map(function (task) {
          return Object.assign({}, task, { is_active: true });
        }), { onConflict: "id" });
        if (resetResult.error) {
          throw resetResult.error;
        }
        await refreshData();
        render();
        showToast(t("saved"));
      } catch (error) {
        showToast(error.message || t("dbError"));
      }
      return;
    }

    var exportButton = event.target.closest("[data-export-json]");
    if (exportButton) {
      exportJson();
    }
  }

  function handleChange(event) {
    var filter = event.target.closest("[data-filter]");
    if (filter) {
      state.filters[filter.getAttribute("data-filter")] = filter.value;
      save(STORE.filters, state.filters);
      render();
      return;
    }

    var editSelect = event.target.closest("[data-edit-task-select]");
    if (editSelect) {
      state.editTaskId = editSelect.value;
      save(STORE.editTask, state.editTaskId);
      render();
      return;
    }

    var gradingFilter = event.target.closest("[data-grading-filter]");
    if (gradingFilter) {
      state.gradingFilter = gradingFilter.value;
      render();
    }
  }

  function handleInput(event) {
    if (event.target.matches("[data-score-range]")) {
      var number = event.target.closest("form").querySelector('input[name="score"]');
      if (number) {
        number.value = event.target.value;
      }
    }
    if (event.target.matches('input[name="score"]')) {
      var range = event.target.closest("form").querySelector("[data-score-range]");
      if (range) {
        range.value = event.target.value;
      }
    }
  }

  async function handleSubmit(event) {
    if (event.target.id === "authForm") {
      event.preventDefault();
      var action = event.submitter && event.submitter.getAttribute("data-auth-action") || "signin";
      await handleAuthSubmit(event.target, action);
      return;
    }

    if (event.target.id === "answerForm") {
      event.preventDefault();
      if (!state.profile || state.profile.role !== "student") {
        showToast(t("studentOnly"));
        return;
      }
      var taskId = event.target.getAttribute("data-task-id");
      var answers = {};
      event.target.querySelectorAll("[data-answer-key]").forEach(function (field) {
        answers[field.getAttribute("data-answer-key")] = field.value.trim();
      });
      try {
        var result = await state.client.from("submissions").insert({
          task_id: taskId,
          student_id: state.profile.id,
          answers: answers
        });
        if (result.error) {
          throw result.error;
        }
        await refreshData();
        render();
        showToast(t("workSubmitted"));
      } catch (error) {
        showToast(error.message || t("dbError"));
      }
      return;
    }

    if (event.target.id === "taskEditorForm") {
      event.preventDefault();
      try {
        await saveTaskFromForm(event.target);
        await refreshData();
        render();
        showToast(t("taskSaved"));
      } catch (error) {
        showToast(error.message || t("dbError"));
      }
      return;
    }

    if (event.target.id === "gradeForm") {
      event.preventDefault();
      var gradeForm = new FormData(event.target);
      var submissionId = event.target.getAttribute("data-submission-id");
      try {
        var result = await state.client.from("submissions").update({
          score: Math.max(0, Math.min(100, Number(gradeForm.get("score")))),
          feedback: String(gradeForm.get("feedback")).trim(),
          status: "graded",
          graded_at: new Date().toISOString(),
          graded_by: state.profile.id
        }).eq("id", submissionId);
        if (result.error) {
          throw result.error;
        }
        await refreshData();
        render();
        showToast(t("gradeSaved"));
      } catch (error) {
        showToast(error.message || t("dbError"));
      }
    }
  }

  document.addEventListener("click", function (event) {
    handleClick(event);
  });
  document.addEventListener("change", handleChange);
  document.addEventListener("input", handleInput);
  document.addEventListener("submit", function (event) {
    handleSubmit(event);
  });

  init();
}());
