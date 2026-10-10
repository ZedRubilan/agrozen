/// Centralized, high-performance localization for AgroZen supporting:
/// - Uzbek (Latin) [uz]
/// - Russian [ru]
/// - English [en]
class AppStrings {
  AppStrings._();

  /// Resolve text according to the language code ('uz', 'ru', 'en').
  static String tr({
    required String? lang,
    required String uz,
    required String ru,
    required String en,
  }) {
    final code = (lang ?? 'uz').trim().toLowerCase();
    if (code.startsWith('en')) return en;
    if (code.startsWith('ru')) return ru;
    return uz;
  }

  // --- General / App ---
  static String appTitle(String lang) => 'AgroZen';

  static String proceed(String lang) => tr(
        lang: lang,
        uz: 'Davom etish',
        ru: 'Далее',
        en: 'Continue',
      );

  static String next(String lang) => tr(
        lang: lang,
        uz: 'Keyingisi',
        ru: 'Далее',
        en: 'Next',
      );

  static String save(String lang) => tr(
        lang: lang,
        uz: 'Saqlash',
        ru: 'Сохранить',
        en: 'Save',
      );

  static String cancel(String lang) => tr(
        lang: lang,
        uz: 'Bekor qilish',
        ru: 'Отмена',
        en: 'Cancel',
      );

  static String understood(String lang) => tr(
        lang: lang,
        uz: 'Tushundim',
        ru: 'Понятно',
        en: 'Understood',
      );

  // --- Onboarding: Language ---
  static String chooseLanguageTitle(String lang) => tr(
        lang: lang,
        uz: 'Tilni tanlang',
        ru: 'Выберите язык',
        en: 'Select Language',
      );

  static String chooseLanguageSubtitle(String lang) => tr(
        lang: lang,
        uz: 'O\'zingizga qulay tilni tanlang',
        ru: 'Выберите удобный для вас язык',
        en: 'Choose your preferred language',
      );

  // --- Onboarding: Region ---
  static String selectRegionTitle(String lang) => tr(
        lang: lang,
        uz: 'Viloyatni tanlang',
        ru: 'Выберите регион',
        en: 'Select Region',
      );

  static String selectRegionSubtitle(String lang) => tr(
        lang: lang,
        uz: 'Yaqin atrofdagi veterinar va ob-havo ma\'lumotlari uchun',
        ru: 'Для связи с районным ветеринаром и точного прогноза погоды',
        en: 'For regional veterinarian contact and localized weather forecast',
      );

  static String searchDistrict(String lang) => tr(
        lang: lang,
        uz: 'Viloyat yoki tumanni qidiring...',
        ru: 'Поиск региона или района...',
        en: 'Search region or district...',
      );

  // --- Onboarding: Batch Setup ---
  static String batchSetupTitle(String lang) => tr(
        lang: lang,
        uz: 'Yangi broyler partiyasi',
        ru: 'Новая партия бройлеров',
        en: 'New Broiler Batch',
      );

  static String batchSetupSubtitle(String lang) => tr(
        lang: lang,
        uz: 'Keling, birinchi partiyangiz parametrlarini kiritamiz',
        ru: 'Давайте настроим параметры вашей первой партии',
        en: 'Let us set up the parameters for your first flock',
      );

  static String farmerNameLabel(String lang) => tr(
        lang: lang,
        uz: 'Ismingiz / Ferma nomi',
        ru: 'Ваше имя / Название фермы',
        en: 'Your Name / Farm Name',
      );

  static String chickCountLabel(String lang) => tr(
        lang: lang,
        uz: 'Jo\'jalar soni (bosh)',
        ru: 'Количество цыплят (голов)',
        en: 'Number of chicks (heads)',
      );

  static String chickCountHint(String lang) => tr(
        lang: lang,
        uz: 'Masalan: 500 yoki 1000',
        ru: 'Например: 500 или 1000',
        en: 'e.g. 500 or 1000',
      );

  static String arrivalDateLabel(String lang) => tr(
        lang: lang,
        uz: 'Jo\'jalar keltirilgan sana',
        ru: 'Дата прибытия цыплят',
        en: 'Chick Arrival Date',
      );

  static String todayLabel(String lang) => tr(
        lang: lang,
        uz: 'Bugun',
        ru: 'Сегодня',
        en: 'Today',
      );

  // --- Onboarding: Legal Disclaimer ---
  static String disclaimerTitle(String lang) => tr(
        lang: lang,
        uz: 'Muhim ogohlantirish',
        ru: 'Важное предупреждение',
        en: 'Important Disclaimer',
      );

  static String disclaimerBody(String lang) => tr(
        lang: lang,
        uz: 'AgroZen — broyler parvarishlash bo\'yicha maslahat beruvchi raqamli yordamchidir. '
            'Ilova litsenziyali veterinariya xizmatining o\'rnini bosmaydi.\n\n'
            '• AI mustaqil ravishda antibiotik yoki dori vositalarini buyurmaydi.\n'
            '• Yuqori nobodlik yoki ommaviy kasallik belgilarida darhol mutaxassis veterinar bilan bog\'laning.\n'
            '• Parrandalaringiz salomatligi uchun asosiy mas\'uliyat o\'z zimmangizda.',
        ru: 'AgroZen — консультационный цифровой помощник по выращиванию бройлеров. '
            'Приложение не заменяет лицензированного ветеринарного врача.\n\n'
            '• ИИ не назначает антибиотики и лекарственные препараты самостоятельно.\n'
            '• При высоком падеже или симптомах болезни немедленно свяжитесь с ветеринаром.\n'
            '• Основная ответственность за здоровье птицы лежит на птицеводе.',
        en: 'AgroZen is a digital advisory assistant for broiler poultry farming. '
            'This application does not replace a licensed veterinary specialist.\n\n'
            '• The AI assistant never prescribes antibiotics or pharmaceutical dosages.\n'
            '• In case of high mortality or disease symptoms, contact your district veterinarian immediately.\n'
            '• Ultimate responsibility for flock health rests with the poultry farmer.',
      );

  static String acceptDisclaimer(String lang) => tr(
        lang: lang,
        uz: 'Tushundim va roziman',
        ru: 'Понятно и согласен',
        en: 'I Understand & Agree',
      );

  // --- Main Navigation ---
  static String navHome(String lang) => tr(
        lang: lang,
        uz: 'Asosiy',
        ru: 'Главная',
        en: 'Home',
      );

  static String navDiary(String lang) => tr(
        lang: lang,
        uz: 'Kundalik',
        ru: 'Дневник',
        en: 'Diary',
      );

  static String navAsk(String lang) => tr(
        lang: lang,
        uz: 'Yordamchi',
        ru: 'Ассистент',
        en: 'AI Assistant',
      );

  static String navCourse(String lang) => tr(
        lang: lang,
        uz: 'O\'qish',
        ru: 'Обучение',
        en: 'Course',
      );

  static String navSettings(String lang) => tr(
        lang: lang,
        uz: 'Sozlamalar',
        ru: 'Настройки',
        en: 'Settings',
      );

  // --- Dashboard / Home ---
  static String greeting(String lang, String name) => tr(
        lang: lang,
        uz: 'Assalomu alaykum, $name!',
        ru: 'Здравствуйте, $name!',
        en: 'Welcome, $name!',
      );

  static String dayProgress(String lang, int day) => tr(
        lang: lang,
        uz: '$day-kun (42 kundan)',
        ru: '$day-й день из 42',
        en: 'Day $day of 42',
      );

  static String regionHeader(String lang, String district, int count) => tr(
        lang: lang,
        uz: 'Hudud: $district | Partiya: $count bosh',
        ru: 'Регион: $district | Партия: $count голов',
        en: 'Region: $district | Flock: $count birds',
      );

  static String targetTempTitle(String lang) => tr(
        lang: lang,
        uz: 'Me\'yor harorat',
        ru: 'Норма тепла',
        en: 'Target Temp',
      );

  static String insideHouseSubtitle(String lang) => tr(
        lang: lang,
        uz: 'Xonada',
        ru: 'В птичнике',
        en: 'In House',
      );

  static String flockCountTitle(String lang) => tr(
        lang: lang,
        uz: 'Parrandalar',
        ru: 'Поголовье',
        en: 'Flock Size',
      );

  static String fromInitial(String lang, int initial) => tr(
        lang: lang,
        uz: '$initial tadan',
        ru: 'из $initial',
        en: 'of $initial initial',
      );

  static String watchVideoGuide(String lang) => tr(
        lang: lang,
        uz: 'Videoni ko\'rish',
        ru: 'Смотреть видеогид',
        en: 'Watch Video Guide',
      );

  static String callVetButton(String lang, String vetName) => tr(
        lang: lang,
        uz: 'Veterinarga qo\'ng\'iroq ($vetName)',
        ru: 'Позвонить ветеринару ($vetName)',
        en: 'Call Veterinarian ($vetName)',
      );

  static String listenAudio(String lang) => tr(
        lang: lang,
        uz: 'Tinglash',
        ru: 'Слушать',
        en: 'Listen',
      );

  static String stopAudio(String lang) => tr(
        lang: lang,
        uz: 'To\'xtatish',
        ru: 'Стоп',
        en: 'Stop',
      );

  // --- Weather & Climate System ---
  static String weatherCardTitle(String lang) => tr(
        lang: lang,
        uz: 'Tashqi ob-havo va iqlim tavsiyasi',
        ru: 'Погода снаружи и микроклимат',
        en: 'Outdoor Weather & Microclimate',
      );

  static String outsideTempLabel(String lang) => tr(
        lang: lang,
        uz: 'Tashqarida',
        ru: 'Снаружи',
        en: 'Outdoor',
      );

  static String insideTargetLabel(String lang) => tr(
        lang: lang,
        uz: 'Xona me\'yori',
        ru: 'Норма в зале',
        en: 'House Target',
      );

  static String tempDiffLabel(String lang) => tr(
        lang: lang,
        uz: 'Farq (ΔT)',
        ru: 'Разница (ΔT)',
        en: 'Diff (ΔT)',
      );

  static String humidityLabel(String lang) => tr(
        lang: lang,
        uz: 'Namlik',
        ru: 'Влажность',
        en: 'Humidity',
      );

  static String climateStatusOptimal(String lang) => tr(
        lang: lang,
        uz: 'Ideal mikroiqlim',
        ru: 'Оптимальный климат',
        en: 'Optimal Climate',
      );

  static String climateStatusHeatAlert(String lang) => tr(
        lang: lang,
        uz: 'Issiq urish xavfi!',
        ru: 'Опасность перегрева!',
        en: 'Heat Stress Risk!',
      );

  static String climateStatusColdAlert(String lang) => tr(
        lang: lang,
        uz: 'Sovuq urish xavfi!',
        ru: 'Опасность переохлаждения!',
        en: 'Cold Stress Risk!',
      );

  // --- Daily Plan Screen ---
  static String dailyPlanTitle(String lang) => tr(
        lang: lang,
        uz: 'Kunlik reja (1–42)',
        ru: 'План по дням (1–42)',
        en: 'Daily Plan (1–42)',
      );

  static String currentBatchDayBadge(String lang) => tr(
        lang: lang,
        uz: 'Bu sizning bugungi partiya kuningiz!',
        ru: 'Это ваш текущий день партии!',
        en: 'This is your flock\'s current day!',
      );

  static String stageRecommendationsTitle(String lang) => tr(
        lang: lang,
        uz: 'Bosqich bo\'yicha tavsiyalar',
        ru: 'Рекомендации по периоду',
        en: 'Growth Stage Guidelines',
      );

  // --- Flock Diary ---
  static String diaryTitle(String lang) => tr(
        lang: lang,
        uz: 'Partiya kundaligi',
        ru: 'Дневник партии',
        en: 'Flock Diary',
      );

  static String logMortalityCard(String lang) => tr(
        lang: lang,
        uz: 'Nobodlik yozish',
        ru: 'Записать падёж',
        en: 'Log Mortality',
      );

  static String logFeedCard(String lang) => tr(
        lang: lang,
        uz: 'Yem sarfini yozish',
        ru: 'Записать расход корма',
        en: 'Log Feed Intake',
      );

  static String logWeightCard(String lang) => tr(
        lang: lang,
        uz: 'Nazorat vaznini yozish',
        ru: 'Записать контрольный вес',
        en: 'Log Sample Weight',
      );

  static String todayMortalityLabel(String lang) => tr(
        lang: lang,
        uz: 'Bugungi nobodlik',
        ru: 'Падёж сегодня',
        en: 'Mortality Today',
      );

  static String todayFeedLabel(String lang) => tr(
        lang: lang,
        uz: 'Bugungi yem sarfi',
        ru: 'Расход корма сегодня',
        en: 'Feed Intake Today',
      );

  static String lastWeightLabel(String lang) => tr(
        lang: lang,
        uz: 'Oxirgi o\'rtacha vazn',
        ru: 'Последний средний вес',
        en: 'Last Average Weight',
      );

  // --- AI Assistant / AskScreen ---
  static String askTitle(String lang) => tr(
        lang: lang,
        uz: 'AgroZen AI Maslahatchi',
        ru: 'АгроЗен ИИ Помощник',
        en: 'AgroZen AI Assistant',
      );

  static String remainingQuota(String lang, int count, int max) => tr(
        lang: lang,
        uz: 'Bugun qoldi: $count/$max',
        ru: 'Сегодня осталось: $count/$max',
        en: 'Left today: $count/$max',
      );

  static String askInputHint(String lang) => tr(
        lang: lang,
        uz: 'Savol bering yoki rasm yuboring...',
        ru: 'Задайте вопрос или прикрепите фото...',
        en: 'Ask a question or attach a photo...',
      );

  static String takePhotoOption(String lang) => tr(
        lang: lang,
        uz: 'Kameradan rasm olish',
        ru: 'Сделать фото на камеру',
        en: 'Take Photo with Camera',
      );

  static String pickGalleryOption(String lang) => tr(
        lang: lang,
        uz: 'Galereyadan tanlash',
        ru: 'Выбрать из галереи',
        en: 'Choose from Gallery',
      );

  static String analyzingPhotoMessage(String lang) => tr(
        lang: lang,
        uz: 'Rasm tahlil qilinmoqda (parranda, go\'ng yoki xona sharoiti)...',
        ru: 'Анализирую фото (птица, помёт или микроклимат)...',
        en: 'Analyzing photo (poultry, droppings, or house condition)...',
      );

  // --- Pre-Credit Course & Certificate ---
  static String courseTitle(String lang) => tr(
        lang: lang,
        uz: 'Kreditdan oldingi kurs',
        ru: 'Кредитный спецкурс',
        en: 'Pre-Credit Training Course',
      );

  static String certificateTitle(String lang) => tr(
        lang: lang,
        uz: 'Muvaffaqiyat Sertifikati',
        ru: 'Сертификат Успешности',
        en: 'Certificate of Completion',
      );

  static String shareCertificate(String lang) => tr(
        lang: lang,
        uz: 'Sertifikatni ulashish (PDF/Rasm)',
        ru: 'Поделиться сертификатом (PDF/Фото)',
        en: 'Share Certificate (PDF/Image)',
      );

  // --- Settings ---
  static String settingsTitle(String lang) => tr(
        lang: lang,
        uz: 'Sozlamalar',
        ru: 'Настройки',
        en: 'Settings',
      );

  static String languageOptionUzbek(String lang) => 'O\'zbekcha';
  static String languageOptionRussian(String lang) => 'Русский';
  static String languageOptionEnglish(String lang) => 'English';

  static String resetBatchButton(String lang) => tr(
        lang: lang,
        uz: 'Yangi partiyani boshlash (Qayta o\'rnatish)',
        ru: 'Начать новую партию (Сброс)',
        en: 'Start New Flock (Reset)',
      );
}
