import 'package:flutter/material.dart';

class CourseRulePoint {
  final IconData icon;
  final String badge;
  final String title;
  final String description;

  const CourseRulePoint({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });
}

class CourseModuleGuide {
  final int id;
  final String shortTag;
  final String title;
  final String subtitle;
  final String durationLabel;
  final List<CourseRulePoint> keyPoints;
  final String farmerTakeaway;
  final String detailedNote;
  final String videoUrl;
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctOptionIndex;
  final String quizExplanation;

  const CourseModuleGuide({
    required this.id,
    required this.shortTag,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.keyPoints,
    required this.farmerTakeaway,
    required this.detailedNote,
    required this.videoUrl,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctOptionIndex,
    required this.quizExplanation,
  });
}

class CourseGuideData {
  static String normalizeLang(String lang) {
    final code = lang.trim().toLowerCase();
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('ru')) return 'ru';
    return 'uz';
  }

  static List<CourseModuleGuide> getModules(String rawLang) {
    final lang = normalizeLang(rawLang);
    return [
      getModule(1, lang),
      getModule(2, lang),
      getModule(3, lang),
      getModule(4, lang),
      getModule(5, lang),
    ];
  }

  static CourseModuleGuide getModule(int id, String rawLang) {
    final lang = normalizeLang(rawLang);
    switch (id) {
      case 1:
        if (lang == 'en') {
          return const CourseModuleGuide(
            id: 1,
            shortTag: 'Barn Prep',
            title: 'Pre-Placement Barn Preparation',
            subtitle: 'Disinfection, dry bedding, and 24-hour preheating',
            durationLabel: '1 min read',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.thermostat_rounded,
                badge: '33–34°C',
                title: 'Preheat 24 hours early',
                description:
                    'Warm air to 33–34°C and floor bedding to 30–32°C before chicks arrive.',
              ),
              CourseRulePoint(
                icon: Icons.layers_rounded,
                badge: '5–7 cm',
                title: 'Spread dry wood shavings',
                description:
                    'Wash & disinfect walls with 20% slaked lime, then lay dry, mold-free shavings.',
              ),
              CourseRulePoint(
                icon: Icons.wb_sunny_rounded,
                badge: '23h Light',
                title: 'Ready warm water & light',
                description:
                    'Fill drinkers so water reaches 20–22°C and keep 23 hours of bright light on Days 1–3.',
              ),
            ],
            farmerTakeaway:
                'Prevents early chick chilling — stops up to 80% of first-week losses.',
            detailedNote:
                'Before broiler chicks arrive, the barn must be completely cleaned, washed, and disinfected.\n\n'
                '• Preheat the barn to 33-34°C at least 24 hours in advance.\n'
                '• Spread dry wood shavings 5-7 cm deep.\n'
                '• Fill nipple or bell drinkers with fresh, clean water.\n'
                '• Provide 23 hours of light during the initial brooding days.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+barn+preparation+disinfection+preheating',
            quizQuestion:
                'To what temperature should the barn be preheated 24 hours before chick arrival?',
            quizOptions: ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            correctOptionIndex: 2,
            quizExplanation:
                'Day-old chicks cannot regulate their own body temperature; preheating the barn floor and air to 33-34°C prevents chilling and early mortality.',
          );
        } else if (lang == 'ru') {
          return const CourseModuleGuide(
            id: 1,
            shortTag: 'Подготовка',
            title: 'Подготовка помещения до завоза цыплят',
            subtitle: 'Дезинфекция, сухая подстилка и прогрев за 24 часа',
            durationLabel: '1 мин',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.thermostat_rounded,
                badge: '33–34°C',
                title: 'Прогрейте птичник за 24 часа',
                description:
                    'Доведите воздух до 33–34°C, а пол и подстилку — до 30–32°C до посадки.',
              ),
              CourseRulePoint(
                icon: Icons.layers_rounded,
                badge: '5–7 см',
                title: 'Сухая древесная стружка',
                description:
                    'Продезинфицируйте помещение (20% известь) и засыпьте сухую чистую стружку.',
              ),
              CourseRulePoint(
                icon: Icons.wb_sunny_rounded,
                badge: '23 ч свет',
                title: 'Тёплая вода и яркий свет',
                description:
                    'Наполните поилки заранее (вода 20–22°C) и включите свет на 23 часа в сутки.',
              ),
            ],
            farmerTakeaway:
                'Защищает цыплят от переохлаждения и предотвращает до 80% потерь первой недели.',
            detailedNote:
                'Перед приёмом партии бройлеров птичник должен быть тщательно очищен, вымыт и продезинфицирован.\n\n'
                '• За 24 часа прогрейте помещение до 33-34°C.\n'
                '• Насыпьте сухую стружку толщиной 5-7 см.\n'
                '• Установите ниппельные или вакуумные поилки и проверьте подачу воды.\n'
                '• Обеспечьте круглосуточное освещение (23 часа) в первые дни.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+barn+preparation+disinfection+preheating',
            quizQuestion:
                'До какой температуры необходимо прогреть птичник за 24 часа до завоза цыплят?',
            quizOptions: ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            correctOptionIndex: 2,
            quizExplanation:
                'Суточные цыплята еще не могут сами удерживать тепло тела; прогрев пола и воздуха до 33-34°C защищает их от переохлаждения.',
          );
        } else {
          return const CourseModuleGuide(
            id: 1,
            shortTag: 'Bino tayyorlash',
            title: "Jo'jalar kelishidan oldin xonani tayyorlash",
            subtitle: "Dezinfeksiya, quruq to'shama va 24 soat oldin isitish",
            durationLabel: '1 daqiqa',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.thermostat_rounded,
                badge: '33–34°C',
                title: '24 soat oldin xonani qizdiring',
                description:
                    "Jo'ja kelishidan oldin havo 33–34°C, pol (to'shama) esa 30–32°C bo'lishi shart.",
              ),
              CourseRulePoint(
                icon: Icons.layers_rounded,
                badge: '5–7 sm',
                title: "Quruq yog'och qirindisi to'shang",
                description:
                    "Binoni yuvib, 20% ohak bilan oqlang va quruq toza qipiq to'shang.",
              ),
              CourseRulePoint(
                icon: Icons.wb_sunny_rounded,
                badge: '23 soat',
                title: "Iliq suv va yorug'lik tayyorlang",
                description:
                    "Suvni 20–22°C iliq holda quying va ilk kunlarda 23 soat yorug'lik bering.",
              ),
            ],
            farmerTakeaway:
                "Ilk haftadagi shamollash va nobodlikning 80% oldini oladi.",
            detailedNote:
                "Broyler jo'jalari kelishidan oldin bino to'liq tozalangan, yuvilgan va dezinfeksiya qilingan bo'lishi shart.\n\n"
                "• 24 soat oldin xonani 33-34°C gacha qizdiring.\n"
                "• Qalinligi 5-7 sm quruq yog'och qirindisi (to'shama) to'shang.\n"
                "• Suv idishlarini (nippel yoki vakuum) toza suv bilan to'ldiring.\n"
                "• Dastlabki kunlarda 23 soatlik yorug'lik rejimini ta'minlang.",
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+barn+preparation+disinfection+preheating',
            quizQuestion:
                "Jo'jalar kelishidan 24 soat oldin xonani qanday haroratgacha qizdirish lozim?",
            quizOptions: ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            correctOptionIndex: 2,
            quizExplanation:
                "Bir kunlik jo'jalar tana haroratini mustaqil boshqara olmaydi; xona va to'shamani 33-34°C gacha qizdirish ularni shamollashdan asraydi.",
          );
        }

      case 2:
        if (lang == 'en') {
          return const CourseModuleGuide(
            id: 2,
            shortTag: 'First 3 Days',
            title: 'First 3 Days: The Critical Phase',
            subtitle: 'Crop fill check, warm water, and chick behavior',
            durationLabel: '1 min read',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.fact_check_rounded,
                badge: '80% at 8h',
                title: 'Check crop fill after 8 hours',
                description:
                    'At least 80% of chicks must have soft, full crops (both water and feed).',
              ),
              CourseRulePoint(
                icon: Icons.water_drop_rounded,
                badge: '20–22°C',
                title: 'Keep drinking water warm',
                description:
                    'Cold water chills chicks and slows digestion; flush lines to keep water fresh.',
              ),
              CourseRulePoint(
                icon: Icons.visibility_rounded,
                badge: 'Watch Flock',
                title: 'Read chick body language',
                description:
                    'Huddling together = too cold. Panting with open beaks = too hot. Spread evenly = ideal.',
              ),
            ],
            farmerTakeaway:
                'Good first 72 hours guarantees 180–190g weight by Day 7 and strong immunity.',
            detailedNote:
                'The first 72 hours determine the survival and growth of the entire flock.\n\n'
                '• Check crop fill after 8 hours: at least 80% of chicks must have feed and water.\n'
                '• Water temperature should be warm (20-22°C).\n'
                '• If chicks huddle together — they are cold. If panting with open beaks — too hot.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+chicks+first+3+days+crop+fill',
            quizQuestion:
                'What percentage of chicks must have found water and feed within the first 8 hours?',
            quizOptions: [
              'At least 80%',
              'Around 40%',
              'Does not matter',
              'Only 20%',
            ],
            correctOptionIndex: 0,
            quizExplanation:
                'According to Ross-308 standards, at least 80% of chicks should have full, soft crops 8 hours after placement to ensure uniform growth.',
          );
        } else if (lang == 'ru') {
          return const CourseModuleGuide(
            id: 2,
            shortTag: 'Первые 3 дня',
            title: 'Первые 3 дня: решающий период',
            subtitle: 'Проверка зоба, тёплая вода и поведение цыплят',
            durationLabel: '1 мин',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.fact_check_rounded,
                badge: '80% за 8 ч',
                title: 'Проверьте зоб через 8 часов',
                description:
                    'Минимум у 80% цыплят зоб должен быть мягким и полным (корм + вода).',
              ),
              CourseRulePoint(
                icon: Icons.water_drop_rounded,
                badge: '20–22°C',
                title: 'Поите только тёплой водой',
                description:
                    'Холодная вода тормозит пищеварение; поддерживайте температуру воды 20–22°C.',
              ),
              CourseRulePoint(
                icon: Icons.visibility_rounded,
                badge: 'Поведение',
                title: 'Следите за поведением стада',
                description:
                    'Сбиваются в кучу = холодно. Дышат клювом = жарко. Равномерно бегают = норма.',
              ),
            ],
            farmerTakeaway:
                'Правильные первые 72 часа дают вес 180–190 г к 7-му дню и крепкий иммунитет.',
            detailedNote:
                'Первые 72 часа определяют выживаемость всей партии.\n\n'
                '• Проверьте зоб цыплят через 8 часов: 80% должны быть с кормом и водой.\n'
                '• Вода должна быть тёплой (20-22°C).\n'
                '• Если цыплята сбиваются в кучу — им холодно. Если тяжело дышат и раскрывают клювы — жарко.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+chicks+first+3+days+crop+fill',
            quizQuestion:
                'Какой процент цыплят должен найти воду и корм в первые 8 часов?',
            quizOptions: [
              'Не менее 80%',
              'Около 40%',
              'Не имеет значения',
              'Только 20%',
            ],
            correctOptionIndex: 0,
            quizExplanation:
                'По стандарту Ross-308 через 8 часов после посадки минимум у 80% цыплят зоб должен быть мягким и наполненным кормом и водой.',
          );
        } else {
          return const CourseModuleGuide(
            id: 2,
            shortTag: 'Ilk 3 kun',
            title: 'Dastlabki 3 kun: hal qiluvchi davr',
            subtitle: "Jig'ildon nazorati, iliq suv va jo'ja xulqi",
            durationLabel: '1 daqiqa',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.fact_check_rounded,
                badge: '8 soat / 80%',
                title: "8 soatda jig'ildonni tekshiring",
                description:
                    "Kamida 80% jo'janing jig'ildoni yumshoq (yem va suvga to'la) bo'lishi shart.",
              ),
              CourseRulePoint(
                icon: Icons.water_drop_rounded,
                badge: '20–22°C',
                title: 'Suv doim iliq va toza bo\'lsin',
                description:
                    "Sovuq suv ichakni shamollatadi; suv harorati 20–22°C bo'lishini nazorat qiling.",
              ),
              CourseRulePoint(
                icon: Icons.visibility_rounded,
                badge: 'Kuzatuv',
                title: "Jo'jalar holatiga qarab baholang",
                description:
                    "To'planib olsa = sovuq. Og'zini ochib hansirasa = issiq. Bir tekis yursa = a'lo.",
              ),
            ],
            farmerTakeaway:
                "Ilk 72 soat to'g'ri o'tsa, 7-kunda vazn 185+ grammga yetadi va o'sish tezlashadi.",
            detailedNote:
                "Dastlabki 72 soat butun partiyaning yashovchanligini belgilaydi.\n\n"
                "• 8 soatdan keyin jig'ildonni tekshiring: 80% jo'jalarda yem va suv bo'lishi shart.\n"
                "• Suv iliq (20-22°C) bo'lishi kerak.\n"
                "• Agar jo'jalar to'planib olsa — sovuq. Agar og'zini ochib hansirasa — issiq.",
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+chicks+first+3+days+crop+fill',
            quizQuestion:
                "Dastlabki 8 soat ichida jo'jalarning necha foizi suv va yemni topishi shart?",
            quizOptions: [
              'Kamida 80%',
              'Taxminan 40%',
              "Farqi yo'q",
              'Faqat 20%',
            ],
            correctOptionIndex: 0,
            quizExplanation:
                "Ross-308 standartiga ko'ra, 8 soatdan so'ng kamida 80% jo'janing jig'ildoni yumshoq va to'la bo'lishi bir tekis o'sishni ta'minlaydi.",
          );
        }

      case 3:
        if (lang == 'en') {
          return const CourseModuleGuide(
            id: 3,
            shortTag: 'Microclimate',
            title: 'Temperature and Ventilation Control',
            subtitle: 'Step-down cooling, fresh air, and ammonia removal',
            durationLabel: '1 min read',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.trending_down_rounded,
                badge: '33–22°C',
                title: 'Lower temp by 2–3°C weekly',
                description:
                    'Days 1–3: 33–34°C • Day 7: 30°C • Day 14: 27°C • Day 28+: 20–22°C.',
              ),
              CourseRulePoint(
                icon: Icons.air_rounded,
                badge: 'Fresh Air',
                title: 'Remove ammonia & moisture',
                description:
                    'Keep minimum ventilation running even in cold weather without direct drafts on birds.',
              ),
              CourseRulePoint(
                icon: Icons.health_and_safety_rounded,
                badge: 'Stop Ascites',
                title: 'Prevent water belly (ascites)',
                description:
                    'Stale air and high ammonia burn airways and cause fluid buildup in fast-growing broilers.',
              ),
            ],
            farmerTakeaway:
                'Good air & temperature cuts feed waste by up to 15% and prevents heat stress.',
            detailedNote:
                'Target brooding temperatures:\n\n'
                '• Days 1-3: 33-34°C\n'
                '• Days 4-7: 32°C\n'
                '• Week 2: 29°C\n'
                '• Week 3: 27°C\n'
                '• Week 4+: 22-24°C\n\n'
                'Ventilation is vital: insufficient fresh air causes ammonia buildup and ascites (water belly).',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+temperature+ventilation+management',
            quizQuestion:
                'What is the primary risk of improper ventilation in the barn?',
            quizOptions: [
              'Increased appetite',
              'Ammonia buildup and ascites (water belly)',
              'Cold feet',
              'No negative impact',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Poor air exchange traps ammonia and carbon dioxide, damaging the respiratory tract and causing ascites (water belly) in fast-growing broilers.',
          );
        } else if (lang == 'ru') {
          return const CourseModuleGuide(
            id: 3,
            shortTag: 'Микроклимат',
            title: 'Управление температурой и вентиляцией',
            subtitle: 'Снижение температуры, свежий воздух и удаление аммиака',
            durationLabel: '1 мин',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.trending_down_rounded,
                badge: '33–22°C',
                title: 'Снижайте на 2–3°C каждую неделю',
                description:
                    '1–3 дни: 33–34°C • 7 день: 30°C • 14 день: 27°C • с 28 дня: 20–22°C.',
              ),
              CourseRulePoint(
                icon: Icons.air_rounded,
                badge: 'Воздух',
                title: 'Удаляйте аммиак и сырость',
                description:
                    'Проветривайте птичник даже зимой, направляя поток воздуха вверх без сквозняка.',
              ),
              CourseRulePoint(
                icon: Icons.health_and_safety_rounded,
                badge: 'Без асцита',
                title: 'Защита от водянки (асцита)',
                description:
                    'Нехватка кислорода и аммиак вызывают водянку и остановку роста бройлеров.',
              ),
            ],
            farmerTakeaway:
                'Чистый воздух экономит до 15% корма и защищает стадо от удушья в жару.',
            detailedNote:
                'Температурный график:\n\n'
                '• Дни 1-3: 33-34°C\n'
                '• Дни 4-7: 32°C\n'
                '• Неделя 2: 29°C\n'
                '• Неделя 3: 27°C\n'
                '• Неделя 4+: 22-24°C\n\n'
                'Вентиляция обязательна: недостаток свежего воздуха приводит к асциту (водянке) и замедлению роста.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+temperature+ventilation+management',
            quizQuestion:
                'К чему в первую очередь приводит отсутствие правильной вентиляции?',
            quizOptions: [
              'К улучшению аппетита',
              'К накоплению аммиака и асциту (водянке)',
              'К переохлаждению ног',
              'Ни к чему',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Плохой воздухообмен приводит к скоплению аммиака и углекислого газа, что вызывает ожоги дыхательных путей и асцит (водянку).',
          );
        } else {
          return const CourseModuleGuide(
            id: 3,
            shortTag: 'Harorat va havo',
            title: 'Harorat va shamollatish boshqaruvi',
            subtitle: "Haroratni bosqichma-bosqich tushirish va toza havo",
            durationLabel: '1 daqiqa',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.trending_down_rounded,
                badge: '33–22°C',
                title: 'Har hafta 2–3°C ga pasaytiring',
                description:
                    "1–3 kun: 33–34°C • 7-kun: 30°C • 14-kun: 27°C • 28-kundan: 20–22°C.",
              ),
              CourseRulePoint(
                icon: Icons.air_rounded,
                badge: 'Toza havo',
                title: "Ammiak va zaharli gazni chiqaring",
                description:
                    "Qishda ham shamollatishni to'xtatmang (yelvizaksiz, havoni shiftga yo'naltirib).",
              ),
              CourseRulePoint(
                icon: Icons.health_and_safety_rounded,
                badge: 'Assit oldini olish',
                title: "Qorinda suv yig'ilishidan saqlang",
                description:
                    "Kislorod yetishmasa va ammiak ko'paysa, jo'jada assit (suv yig'ilishi) paydo bo'ladi.",
              ),
            ],
            farmerTakeaway:
                "Toza havo yem sarfini 15% gacha tejaydi va yozgi qizib ketishdan saqlaydi.",
            detailedNote:
                "Harorat jadvali:\n\n"
                "• 1-3 kunlar: 33-34°C\n"
                "• 4-7 kunlar: 32°C\n"
                "• 2-hafta: 29°C\n"
                "• 3-hafta: 27°C\n"
                "• 4+ hafta: 22-24°C\n\n"
                "Shamollatish o'ta zarur: toza havoning yetishmasligi parrandada suv yig'ilishi (assit) va o'sish to'xtashiga olib keladi.",
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+temperature+ventilation+management',
            quizQuestion:
                "To'g'ri shamollatish yo'qligi birinchi navbatda nimaga olib keladi?",
            quizOptions: [
              'Ishtaha ochilishiga',
              "Ammiak to'planishi va suv yig'ilishiga (assit)",
              'Oyoqlari sovushiga',
              'Hech narsaga',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                "Havo almashinuvi yomon bo'lsa, ammiak va karbonat angidrid to'planib, nafas yo'llarini zararlaydi hamda assit (qorinda suv yig'ilishi) kelib chiqadi.",
          );
        }

      case 4:
        if (lang == 'en') {
          return const CourseModuleGuide(
            id: 4,
            shortTag: '3 Feed Phases',
            title: 'Proper Feeding Phases',
            subtitle: 'Starter, Grower, and Finisher protein & ration targets',
            durationLabel: '1 min read',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.egg_alt_rounded,
                badge: 'Days 1–10',
                title: 'Starter (22–23% protein)',
                description:
                    'Fine crumble feed that builds strong bones, organs, and early immunity.',
              ),
              CourseRulePoint(
                icon: Icons.bolt_rounded,
                badge: 'Days 11–24',
                title: 'Grower (20–21% protein)',
                description:
                    'Transition gradually over 2–3 days to fuel rapid muscle and frame growth.',
              ),
              CourseRulePoint(
                icon: Icons.scale_rounded,
                badge: 'Days 25–42',
                title: 'Finisher (18–19% protein)',
                description:
                    'High-energy pellets for final market weight (2.5–2.8 kg) with optimal FCR.',
              ),
            ],
            farmerTakeaway:
                'Feed is 70% of costs. Matching phases saves 3–4M UZS per 1,000 birds.',
            detailedNote:
                'Broiler nutrition consists of 3 essential phases:\n\n'
                '1. Starter (Days 1-10): 22-23% protein. Builds skeletal structure and immunity.\n'
                '2. Grower (Days 11-24): 20-21% protein. Rapid muscle mass development.\n'
                '3. Finisher (Days 25-42): 18-19% protein. Final fattening before harvest.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+starter+grower+finisher+feeding',
            quizQuestion:
                'How many main feeding phases are used in standard broiler production?',
            quizOptions: [
              '1 phase',
              '3 phases (Starter, Grower, Finisher)',
              '5 phases',
              'Phases are optional',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Broilers require 3 distinct nutritional phases: Starter (high protein for organs/skeleton), Grower (muscle growth), and Finisher (energy for final weight).',
          );
        } else if (lang == 'ru') {
          return const CourseModuleGuide(
            id: 4,
            shortTag: '3 фазы корма',
            title: 'Фазы правильного кормления',
            subtitle: 'Нормы протеина и переход между Старт, Рост и Финиш',
            durationLabel: '1 мин',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.egg_alt_rounded,
                badge: '1–10 дни',
                title: 'Старт (22–23% протеина)',
                description:
                    'Мелкая крупка для формирования крепкого скелета, органов и иммунитета.',
              ),
              CourseRulePoint(
                icon: Icons.bolt_rounded,
                badge: '11–24 дни',
                title: 'Рост (20–21% протеина)',
                description:
                    'Плавный переход за 2–3 дня для быстрого набора мышечной массы.',
              ),
              CourseRulePoint(
                icon: Icons.scale_rounded,
                badge: '25–42 дни',
                title: 'Финиш (18–19% протеина)',
                description:
                    'Энергетический гранулированный корм для набора 2,5–2,8 кг убойного веса.',
              ),
            ],
            farmerTakeaway:
                'Корм — это 70% затрат. 3-фазное кормление экономит 3–4 млн сум на 1000 голов.',
            detailedNote:
                'Кормление бройлеров состоит из 3 ключевых этапов:\n\n'
                '1. Старт (1-10 дни): протеин 22-23%. Закладывает скелет и иммунитет.\n'
                '2. Рост (11-24 дни): протеин 20-21%. Интенсивный набор мышечной массы.\n'
                '3. Финиш (25-42 дни): протеин 18-19%. Завершающий откорм перед забоем.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+starter+grower+finisher+feeding',
            quizQuestion:
                'Сколько основных фаз кормления используется при выращивании бройлеров?',
            quizOptions: [
              '1 фаза',
              '3 фазы (Старт, Рост, Финиш)',
              '5 фаз',
              'Фазы не нужны',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Применяются 3 фазы: Старт (высокий протеин для скелета и иммунитета), Рост (набор мышечной массы) и Финиш (энергия для убойного веса).',
          );
        } else {
          return const CourseModuleGuide(
            id: 4,
            shortTag: '3 fazali yem',
            title: "To'g'ri oziqlantirish fazalari",
            subtitle: "Start, O'sish va Finish yemlari me'yorlari",
            durationLabel: '1 daqiqa',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.egg_alt_rounded,
                badge: '1–10 kun',
                title: 'Start (22–23% oqsil)',
                description:
                    "Mayda granula — suyak, ichki a'zolar va kuchli immunitetni shakllantiradi.",
              ),
              CourseRulePoint(
                icon: Icons.bolt_rounded,
                badge: '11–24 kun',
                title: "O'sish / Rost (20–21% oqsil)",
                description:
                    "Yemni 2–3 kun aralashtirib o'tkazing; mushak va tana vaznini tez o'stiradi.",
              ),
              CourseRulePoint(
                icon: Icons.scale_rounded,
                badge: '25–42 kun',
                title: 'Finish (18–19% oqsil)',
                description:
                    "Yuqori energiyali yem — 42-kunga kelib 2.5–2.8 kg tovar vazn beradi.",
              ),
            ],
            farmerTakeaway:
                "Yem xarajatning 70% qismi. 3 fazali rejim har 1000 boshda 3–4 mln so'm tejaydi.",
            detailedNote:
                "Broylerlarni oziqlantirish 3 muhim bosqichdan iborat:\n\n"
                "1. Start (1-10 kunlar): oqsil 22-23%. Skelet va immunitetni shakllantiradi.\n"
                "2. O'sish (11-24 kunlar): oqsil 20-21%. Mushak massasining jadal o'sishi.\n"
                "3. Finish (25-42 kunlar): oqsil 18-19%. So'yish oldidan yakuniy semirtirish.",
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+starter+grower+finisher+feeding',
            quizQuestion:
                "Broylerlarni boqishda nechta asosiy oziqlantirish fazasi qo'llaniladi?",
            quizOptions: [
              '1 ta faza',
              "3 ta faza (Start, O'sish, Finish)",
              '5 ta faza',
              'Faza kerak emas',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                "Broylerlar 3 bosqichda oziqlantiriladi: Start (skelet va immunitet uchun yuqori oqsil), O'sish (mushak massasi) va Finish (yakuniy vazn uchun energiya).",
          );
        }

      default:
        if (lang == 'en') {
          return const CourseModuleGuide(
            id: 5,
            shortTag: 'Biosecurity',
            title: 'Diseases and Working with Veterinarians',
            subtitle: 'Entry disinfection, >1% red alert, and safe vet care',
            durationLabel: '1 min read',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.door_front_door_rounded,
                badge: 'Bio-Barrier',
                title: 'Disinfection mat & clean boots',
                description:
                    'Keep a lime/disinfectant footbath at the door, wear barn-only boots, block visitors.',
              ),
              CourseRulePoint(
                icon: Icons.warning_amber_rounded,
                badge: '>1% Alert',
                title: 'Isolate & call vet if mortality > 1%',
                description:
                    'If daily losses exceed 1%, immediately separate sick birds and call your district vet.',
              ),
              CourseRulePoint(
                icon: Icons.medical_services_rounded,
                badge: 'No Self-Meds',
                title: 'Never give unprescribed antibiotics',
                description:
                    'Blind antibiotic use damages bird livers, wastes money, and ruins meat safety.',
              ),
            ],
            farmerTakeaway:
                'Prevention costs pennies compared to treatment and protects your entire loan repayment.',
            detailedNote:
                'The golden rule of poultry farming: prevention is vastly cheaper than treatment!\n\n'
                '• Strict biosecurity: disinfection mats at entrances, designated footwear.\n'
                '• If daily mortality exceeds 1%, immediately isolate the barn and call a veterinarian.\n'
                '• Never administer antibiotics without professional prescription.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+biosecurity+disease+prevention',
            quizQuestion:
                'What emergency action should be taken if daily mortality exceeds 1%?',
            quizOptions: [
              'Administer antibiotics without consultation',
              'Immediately isolate the barn and call the veterinarian',
              'Just wait it out',
              'Increase barn lighting',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Daily mortality above 1% is a critical red alert indicating potential infectious outbreak or acute climate failure; immediate veterinary intervention is mandatory.',
          );
        } else if (lang == 'ru') {
          return const CourseModuleGuide(
            id: 5,
            shortTag: 'Биозащита',
            title: 'Болезни и работа с ветеринаром',
            subtitle: 'Дезбарьер, сигнал тревоги >1% и работа с врачом',
            durationLabel: '1 мин',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.door_front_door_rounded,
                badge: 'Дезковрик',
                title: 'Сменная обувь и дезбарьер у входа',
                description:
                    'Запретите вход посторонним, используйте отдельную обувь и дезковрик.',
              ),
              CourseRulePoint(
                icon: Icons.warning_amber_rounded,
                badge: 'Падеж >1%',
                title: 'При падеже >1% — звоните ветеринару',
                description:
                    'Немедленно отсадите слабую птицу в изолятор и вызовите участкового врача.',
              ),
              CourseRulePoint(
                icon: Icons.medical_services_rounded,
                badge: 'Без самолечения',
                title: 'Никаких антибиотиков без врача',
                description:
                    'Самовольная дача лекарств сажает печень птицы и ведёт к убыткам.',
              ),
            ],
            farmerTakeaway:
                'Профилактика в 10 раз дешевле лечения и защищает возврат вашего агрокредита.',
            detailedNote:
                'Главное правило птицевода: профилактика дешевле лечения!\n\n'
                '• Соблюдайте биобезопасность: дезковрик у входа, сменная обувь.\n'
                '• При падеже более 1% в сутки немедленно изолируйте птичник и звоните ветеринару.\n'
                '• Не используйте антибиотики без назначения специалиста.',
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+biosecurity+disease+prevention',
            quizQuestion:
                'Что необходимо сделать при превышении суточного падежа в 1%?',
            quizOptions: [
              'Самостоятельно дать антибиотики',
              'Срочно изолировать птичник и позвонить ветеринару',
              'Просто подождать',
              'Увеличить свет',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                'Суточный падеж выше 1% — критический сигнал возможной инфекции или сбоя микроклимата; требуется немедленная изоляция и вызов ветеринара.',
          );
        } else {
          return const CourseModuleGuide(
            id: 5,
            shortTag: 'Bioxavfsizlik',
            title: 'Kasalliklar va veterinar bilan ishlash',
            subtitle: 'Dezbariyer, 1% xavf chegarasi va veterinar yordami',
            durationLabel: '1 daqiqa',
            keyPoints: [
              CourseRulePoint(
                icon: Icons.door_front_door_rounded,
                badge: 'Dezbariyer',
                title: 'Maxsus poyabzal va ohakli gilamcha',
                description:
                    "Kirishda dezgilamcha qo'ying, begonalarni kiritmang va alohida etik kiying.",
              ),
              CourseRulePoint(
                icon: Icons.warning_amber_rounded,
                badge: '>1% xavf',
                title: "Nobodlik 1% dan oshsa — Veterinar!",
                description:
                    "Holsiz jo'jalarni darhol alohida joyga ajrating va tuman veterinarini chaqiring.",
              ),
              CourseRulePoint(
                icon: Icons.medical_services_rounded,
                badge: 'Retseptsiz yo\'q',
                title: "Mustaqil antibiotik bermang",
                description:
                    "Veterinar tavsiyasisiz berilgan dori jo'ja jigarini ishdan chiqaradi va zarar keltiradi.",
              ),
            ],
            farmerTakeaway:
                "Kasallik oldini olish davolashdan 10 barobar arzon — kredit va foydangiz himoyasi.",
            detailedNote:
                "Parrandachining asosiy qoidasi: kasallikning oldini olish davolashdan ancha arzon!\n\n"
                "• Biologik xavfsizlikka rioya qiling: dezbariyer, maxsus poyabzal.\n"
                "• Sutkalik nobodlik 1% dan oshsa, zudlik bilan hududni cheklang va veterinarga murojaat qiling.\n"
                "• Mutaxassis tavsiyasisiz antibiotiklarni aslo qo'llamang.",
            videoUrl:
                'https://www.youtube.com/results?search_query=ross+308+broiler+biosecurity+disease+prevention',
            quizQuestion:
                "Sutkalik nobodlik 1% dan oshganda nima qilish zarur?",
            quizOptions: [
              'Mustaqil antibiotik berish',
              'Hududni darhol cheklab, veterinarga murojaat qilish',
              'Kutish',
              'Chiroqni kuchaytirish',
            ],
            correctOptionIndex: 1,
            quizExplanation:
                "Kunlik nobodlik 1% dan oshishi xavfli infeksiya yoki mikroiqlim buzilishidan darak beradi; darhol binoni izolyatsiya qilib, veterinarni chaqirish shart.",
          );
        }
    }
  }
}
