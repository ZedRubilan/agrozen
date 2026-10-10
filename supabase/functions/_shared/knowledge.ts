// supabase/functions/_shared/knowledge.ts
// Embedded Knowledge Base & RAG retrieval engine for AgroZen Edge Functions

export interface KnowledgeArticle {
  filename: string;
  title: string;
  content: string;
}

export const KNOWLEDGE_ARTICLES_UZ: KnowledgeArticle[] = [
  {
    "filename": "01_tayyorgarlik.md",
    "title": "Jo'jalar kelishidan oldin xonani tayyorlash",
    "content": "<!--\nManba: Ross 308 / Cobb 500 bo'yicha broyler yetishtirish reglamenti va O'zbekiston Veterinariya Qo'mitasi tavsiyalari\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Jo'jalar kelishidan oldin xonani tayyorlash\n\nBroyler yetishtirishdagi muvaffaqiyatning 70 foizi bir kunlik jo'jalar kelgunga qadar xona qanday tayyorlanganiga bog'liq. Agar jo'jalar nam, sovuq yoki yaxshi zararsizlantirilmagan (dezinfeksiya qilinmagan) xonaga joylashtirilsa, dastlabki 10 kunda katta nobudgarchilik muqarrar bo'ladi.\n\n---\n\n## 1. Mexanik tozalash va yuvish\nTayyorgarlik oldingi partiyadan bo'shagan zahoti boshlanadi:\n1. **Eski to'shamani chiqarish:** Eski go'ng va qipiqni tovuqxonadan kamida 50 metr uzoqlikka to'liq chiqarib tashlang.\n2. **Quruq supurish:** Devorlar, shift, to'sinlar, chiroqlar va ventilyatorlardagi chang va o'rgimchak to'rlarini tozalang. Changda juda ko'p virus va bakteriyalar saqlanadi.\n3. **Suv bilan bosim ostida yuvish:** Xonani yuqori bosimli suv purkagich (Kärcher va h.k., kamida 100–140 bar) bilan yuving. Devor va pol yuzasidagi yog'li qatlamni yuvish uchun 1–2% kir sodasi yoki maxsus yuvish vositalaridan foydalaning. Burchaklar va yoriqlarga alohida e'tibor bering.\n\n---\n\n## 2. Xona va uskunalarni dezinfeksiya qilish\nZararsizlantirish faqat yaxshilab yuvilgan va quritilgan yuzalarda samarali bo'ladi:\n* **Devor va shiftni oqlash:** Devorlarni 20% li yangi so'ndirilgan ohak qorishmasiga 2–3% mis kuporosi (temir/mis sulfat) qo'shib oqlang. Bu zamburug' va bakteriyalarni qiradi.\n* **Nam dezinfeksiya:** Pol va devorlarga tasdiqlangan dezinfeksiyalovchi eritmalar (glutaraldegid, to'rtlamchi ammoniy asosidagi yoki Virocid kabi preparatlar) seping.\n* **Uskunalarni tozalash:** Oxurlar, sug'orgichlar va shlanglarni dezinfeksiya eritmasiga botirib oling, so'ng toza suv bilan chayqab, quyoshda quriting.\n* **Sanitariya tanaffusi («bo'sh-band» qoidasi):** Dezinfeksiyadan keyin xona eshiklari yopilib, kamida **4–7 kun** bo'sh turishi shart.\n\n---\n\n## 3. Zararkunandalardan tozalash va yovvoyi qushlardan himoya\nKalamush va sichqonlar salmonellyoz, yovvoyi qushlar esa parranda grippi va Nyukasl kasalliklarini tashiydi:\n* Barcha deraza, darcha va shamollatish tuynuklariga mayda ko'zli (1.5 sm dan oshmagan) sim to'r torting.\n* Devor va poydevordagi barcha kemiruvchilar kirishi mumkin bo'lgan yoriqlarni shisha siniqlari qo'shilgan sement qorishmasi bilan suvang.\n* Bino tashqi perimetri bo'ylab kemiruvchilarga qarshi zaharli yemlar qo'ying.\n\n---\n\n## 4. To'shama: tanlash va to'shash qoidalari\nJo'jalar butun umrini to'shama ustida o'tkazadi. Sovuq yoki nam to'shama bo'g'im kasalliklari, assit (qorinda suv to'planishi) va o'limga olib keladi.\n* **Material:** Eng ma'quli — changdan tozalangan, quruq yog'och qipig'i (o'rtacha yoki yirik fraksiyali) yoki toza, mog'orlamagan maydalangan bug'doy somoni.\n* **Qalinligi:** Qish va erta bahorda — **7–10 sm**, yozda — **5–7 sm**.\n* **Talablar:** To'shama mutlaqo quruq (namligi 15% dan past), mog'orsiz va hidsiz bo'lishi kerak. Mayda yog'och changidan foydalanmang — jo'jalar uni yem deb yeb, jig'ildoni tiqilib qoladi.\n\n---\n\n## 5. Xonani oldindan isitish (24–48 soat oldin)\nYangi boshlovchilarning eng katta xatosi — isitishni jo'jalar kelishidan 2 soat oldin yoqishdir. Havo isishi mumkin, ammo pol muzdek qoladi.\n* **Jo'jalar kelishidan 24–48 soat oldin:** Isitish moslamalarini (pech, ten, bruder yoki infraqizil lampalar) yoqing.\n* **Pol harorati:** Jo'jalar tushirilayotgan paytda to'shama yuzasining harorati kamida **30–32°C**, jo'ja balandligidagi havo esa **33–34°C** bo'lishi shart.\n* Agar jo'ja sovuq polga o'tirsa, ichki a'zolari sovqotadi, kindik sarig'i so'rilmay qoladi va jo'ja nobud bo'ladi.\n\n---\n\n## 6. Jo'jalar kelishi oldidan tekshiruv (Check-list)\nMashina jo'jalarni olib kelishidan oldin tekshirib oling:\n- [ ] Isitish bir maromda ishlayapti, to'shama harorati 30–32°C.\n- [ ] Sug'orgichlar xona haroratidagi (20–22°C) toza suv bilan to'ldirilgan.\n- [ ] Start yemi qog'oz to'shamalar va dastlabki yem tovoqlariga sepilgan.\n- [ ] Yoritish to'liq yoqilgan (30–40 lyuks).\n- [ ] Shamollatish pol darajasida shabada (skvoznyak) hosil qilmaydigan qilib sozlangan.\n- [ ] Jo'ja bo'yi balandligida (poldan 5–8 sm) termometr va gigrometr o'rnatilgan.\n- [ ] Eshik oldiga dezinfeksiya gilamchasi qo'yilgan.\n"
  },
  {
    "filename": "02_birinchi_kunlar.md",
    "title": "Jo'jalarni qabul qilish va dastlabki 3 kun",
    "content": "<!--\nManba: Ross 308 / Cobb 500 bo'yicha broyler yetishtirish reglamenti\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Jo'jalarni qabul qilish va dastlabki 3 kun\n\nBroyler hayotining dastlabki 72 soati uning so'yish paytidagi vaznini belgilab beradi. Agar jo'ja 7-kunida o'zining dastlabki vaznidan kamida 4–4.5 barobar oshmasa (maqsad — 180 grammdan yuqori), keyinchalik bu orqada qolishni hech qanday dori yoki yem bilan to'ldirib bo'lmaydi.\n\n---\n\n## 1. Jo'jalarni tushirish va ko'rikdan o'tkazish\n* **Tushirish tezligi:** Qutilarni tez, lekin ehtiyotkorlik bilan tushiring. Qutilarni polga tashlamang.\n* **Dastlabki saralash:** Keltirilgan partiyaning sifatiga e'tibor bering. Sog'lom bir kunlik jo'ja:\n  * Vazni 40–44 gramm;\n  * Oyoqda baquvvat turadi, ko'zlari chaqnoq va tiniq;\n  * Kindigi to'liq bitgan, quruq, qon yoki qora qoraqasiz;\n  * Qorni yumshoq, shishmagan (osilib qolmagan);\n  * Pati toza, quruq va mayin, tuxum po'chog'i yopishmagan.\n* Nimjon, qiyshiq yoki oyog'i singan jo'jalarni alohida ajrating yoki darhol yaroqsizga chiqaring.\n\n---\n\n## 2. Dastlabki 2 soat: faqat suv!\nInkubatordan chiqqan va yo'l yurgan jo'jalar qattiq suvsizlangan bo'ladi. **Suv yemdan ko'ra muhimroq!**\n* **Suv harorati:** Qat'iy **20–22°C** bo'lishi kerak. Muzdek suv ichki a'zolarni shamollatadi va ichak tortishishiga sabab bo'ladi, 25°C dan issiq suvda esa bakteriyalar tez ko'payadi.\n* **Birinchi ichirish:** Yo'l stressini olish uchun dastlabki suvga glyukoza (1 litr suvga 20–30 g) yoki vitamin-elektrolit qo'shib berish juda foydali.\n* **Suvni ko'rsatish:** Bir nechta jo'janing tumshug'ini sug'orgichga tekkizib oling — qolganlari ularga qarab darhol o'rganadi.\n* Sug'orgichlar yetarli bo'lsin: 50 ta jo'jaga 1 ta vakuumli sug'orgich yoki 10–12 ta jo'jaga 1 ta nippel to'g'ri kelishi lozim.\n\n---\n\n## 3. Yem berish (suvdan 2 soat o'tgach)\nFaqat hamma jo'jalar suv ichib olganidan keyingina yem tarqating.\n* **Qayerga sepish kerak:** Jo'jalar uchun maxsus gofrirovka qilingan qog'oz yoki toza oq qog'oz to'shang (gazeta qog'ozi mumkin emas, bosma bo'yoq zaharli!). Qog'oz maydoni bruder joyining kamida 20–30 foizini egallasin.\n* **Qog'oz shitirlashi:** Jo'jalar qog'oz ustida yurganda shitirlagan ovoz chiqadi va bu ularning e'tiborini yemga tortadi.\n* **Yem sifati:** Faqat sifatli mayda donador «Start» yemidan foydalaning (donasi 1.5–2 mm). Unsimon kukun yem tumshuq va burun kataklarini to'sib qo'yadi.\n* Yemni oz-ozdan, lekin tez-tez (kuniga 5–6 marta) sepib turing, shunda yem doimo toza va xushbo'y saqlanadi.\n\n---\n\n## 4. Dastlabki kunlardagi yorug'lik rejimi\n* **1–3 kunlar:** 23 soat yuqori yorug'lik (30–40 lyuks) va 1 soat to'liq qorong'ilik.\n* 1 soatlik qorong'ilik jo'jalarni qorong'iga o'rgatadi. Agar to'satdan chiroq o'chib qolsa, jo'jalar vahimaga tushib, bir-birini bosib nobud qilmaydi.\n\n---\n\n## 5. Jig'ildonni tekshirish testi (Eng muhim ko'rsatkich)\nBu jo'jalarni qanchalik to'g'ri joylashtirganingizni ko'rsatuvchi eng xolis sinovdir:\n* **Joylashtirilgandan 8 soat o'tgach:** Xonaning turli joylaridan 50 ta jo'jani ushlab ko'ring. Ularning **80 foizida** jig'ildon to'la, yumshoq bo'lishi kerak (suv va yem aralashgan yumshoq gubka kabi).\n* **24 soat o'tgach:** Jo'jalarning **95–100 foizida** jig'ildon to'lgan bo'lishi shart.\n* *Jig'ildon qattiq bo'lsa:* Jo'jalar yem yegan, lekin suv icholmagan (suv sovuq yoki sug'orgich baland).\n* *Jig'ildon faqat suvga to'la bo'lsa:* Yem topolmagan (oxur yetishmaydi, qorong'i yoki yem sifatsiz).\n* *Jig'ildon bo'sh bo'lsa:* Jo'jalar sovqotgan yoki qattiq stressda.\n\n---\n\n## 6. Jo'jalar harakatiga qarab haroratni bilish\nTermometr adashishi mumkin, ammo jo'jalarning o'zi hech qachon aldamaydi:\n* **A'lo darajada:** Jo'jalar butun maydon bo'ylab bir tekis yoyilgan, erkin yugurib yuribdi, yem yeb, suv ichmoqda yoki oyoqlarini cho'zib xotirjam uxlamoqda. Yoqimli va sokin ovoz chiqaradi.\n* **Sovuq:** Isitkich ostiga qattiq to'planib, bir-birining ustiga chiqib olgan, ingichka va achinarli ovozda tinimsiz chirillaydi. Xavf: pastdagilar dimiqib o'ladi.\n* **Issiq:** Isitkichdan devorlar tomonga qochgan, qanotlarini keng yoyib, og'zini ochib tez-tez nafas oladi. Yem yemay qo'yadi.\n* **Skvoznyak (shabada):** Xonaning burchagiga yoki bir tomoniga to'planib olgan, sovuq havo oqimidan qochmoqda.\n"
  },
  {
    "filename": "03_harorat.md",
    "title": "Harorat va namlik (haftalar bo'yicha)",
    "content": "<!--\nManba: Parrandachilik mikroiqlim standartlari (Ross Broiler Management Handbook)\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Harorat va namlik (haftalar bo'yicha)\n\nBir kunlik jo'ja o'z tanasidagi haroratni o'zi boshqara olmaydi. Dastlabki 10–14 kunda uning tana harorati faqat tovuqxona mikroiqlimiga bog'liq bo'ladi. Haroratdagi atigi 2–3 darajali xatolik jo'jalarning ommaviy nobud bo'lishiga yoki o'smay qolishiga olib keladi.\n\n---\n\n## 1. Harorat va namlik me'yorlari jadvali\n\nO'lchovlar qat'iy ravishda **jo'janing orqa beli balandligida** (poldan 5–8 sm balandda) o'lchanadi, shift ostida emas!\n\n| Parranda yoshi | Havo harorati (°C) | To'shama harorati (°C) | Nisbiy namlik (%) |\n| :--- | :--- | :--- | :--- |\n| **1-kun** | **33 – 34°C** | 30 – 32°C | 60 – 70% |\n| **3-kun** | **33°C** | 30°C | 60 – 70% |\n| **7-kun (1-hafta)** | **31 – 32°C** | 29 – 30°C | 60 – 65% |\n| **14-kun (2-hafta)** | **28 – 29°C** | 27 – 28°C | 60 – 65% |\n| **21-kun (3-hafta)** | **26 – 27°C** | 25 – 26°C | 55 – 60% |\n| **28-kun (4-hafta)** | **23 – 24°C** | 22 – 23°C | 55 – 60% |\n| **35-kun (5-hafta)** | **21 – 22°C** | 20 – 21°C | 55 – 65% |\n| **42-kun (6-hafta)** | **19 – 20°C** | 19 – 20°C | 55 – 65% |\n\n---\n\n## 2. To'shama harorati havo haroratidan muhimroq\nNima uchun bu o'ta muhim:\n* Jo'ja butun vaqtini pol va to'shama ustida o'tkazadi.\n* Agar havo 34°C bo'lsa-yu, lekin qipiq ostidagi beton pol 22°C bo'lsa, jo'jalar 3–4 soatda qattiq sovqotadi.\n* Oyoq sovqotganda qon ichki a'zolardan qochadi, qorindagi qoldiq tuxum sarig'i so'rilmay qoladi va sarg'ish peritonit kasalligi boshlanadi (3–5 kunlardagi o'limning asosiy sababi).\n* **Qoida:** Jo'janing oyog'ini olib, o'z yuzingizga tekkizib ko'ring: oyoq issiq bo'lishi kerak! Agar oyoqlar muzdek bo'lsa — to'shama yaxshi isitilmagan.\n\n---\n\n## 3. Havoning nisbiy namligi (RH)\n* **Birinchi haftada (60–70%):** Inkubatorda namlik yuqori bo'ladi (70–80%). Agar tovuqxonada havo quruq bo'lsa (50% dan past), jo'jalar nafas olish orqali tez suv yo'qotadi, pati qurib, o'pkasi shikastlanadi. Namlikni ko'tarish uchun yo'laklarga suv seping yoki havoga suv purkang.\n* **2-haftadan keyin (55–65%):** Yuqori namlik (70% dan ortiq) 25–28°C haroratda juda xavfli — to'shama zax bo'ladi, ammiak gazi ko'payadi, koksidioz va bakteriyalar rivojlanadi.\n\n---\n\n## 4. Kunduzgi va tungi harorat farqi\nO'zbekiston iqlimida bahor va kuz oylarida kecha-kunduz harorat farqi 15–20°C ga yetishi mumkin (kunduzi +25°C, kechasi +5°C).\n* **Eng katta xato:** Kechasi isitishni o'chirib qo'yish yoki sovuq tushganda shamollatish darchalarini yopishni unutish.\n* Xonadagi harorat tebranishi sutka davomida **1.5–2°C** dan oshmasligi lozim.\n* Haroratning keskin o'ynashi shamollash kasalliklarini (bronxit, mikoplazmoz) keltirib chiqaradi va stress sababli vazn o'sishi to'xtaydi.\n\n---\n\n## 5. Termometrlarni to'g'ri o'rnatish\n* Termometr va elektron datchiklar qat'iy ravishda jo'ja bo'yi balandligida o'rnatilishi lozim.\n* Kamida 3 ta nuqtada termometr bo'lsin: isitkich ostida, chekka devor oldida va sug'orgichlar yaqinida.\n* Termometrlarni to'g'ridan-to'g'ri infraqizil lampa nuri tushadigan joyga qo'ymang, aks holda ular noto'g'ri yuqori haroratni ko'rsatadi.\n"
  },
  {
    "filename": "04_shamollatish.md",
    "title": "Shamollatish (ventilatsiya) va issiqlikdan saqlash",
    "content": "<!--\nManba: Parrandachilik mikroiqlimi va shamollatish bo'yicha amaliy qo'llanma (Ross/Cobb)\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Shamollatish (ventilatsiya) va issiqlikdan saqlash\n\nTovuqxonada shamollatish 5 ta asosiy vazifani bajaradi: kislorod kiritish, karbonat angidridni chiqarish, zaharli ammiak gazini yo'qotish, ortiqcha namlikni quritish va qushlarni sovutish. O'zbekistonning jazirama iqlimida to'g'ri ventilyatsiya — 25 kundan oshgan broylerlarning tirik qolishi uchun hal qiluvchi omildir.\n\n---\n\n## 1. Dastlabki 2–3 haftadagi minimal shamollatish\nJo'jalar yoshligida shamollatishning bosh maqsadi — xonadagi qimmatbaho issiqlikni chiqarib yubormasdan va pol sathida yelvizak (skvoznyak) hosil qilmasdan havoni yangilashdir.\n* **Qoida:** Tashqaridan kiradigan sovuq toza havo yuqori devor darchalari orqali shift ostiga yo'naltirilishi, u yerdagi issiq havo bilan aralashib, iligach, jo'jalar ustiga tushishi kerak.\n* **Havo tezligi:** Dastlabki 2 haftada pol sathidagi havo oqimi tezligi **0.15–0.2 m/s** dan oshmasligi shart.\n* **Skvoznyak o'ldiradi:** Agar sovuq havo to'g'ridan-to'g'ri pol bo'ylab essa, jo'jalar shamollaydi, burchaklarga tiqilib, dimiqib halok bo'ladi.\n\n---\n\n## 2. Ammiak gazi ($NH_3$) va namlik xavfi\nAmmiak gazi nam to'shamada tovuq tezagining bijg'ishi natijasida ajralib chiqadi.\n* **Fermerning oddiy sinovi:** Agar tovuqxonaga kirganingizda ammiak hidi burningizga ursa yoki ko'zingizni achishtirsa — bu havoda ammiak miqdori xavfli me'yordan oshganini bildiradi!\n* Bu qushlar uchun falokatdir: ammiak o'pka va nafas yo'llarining himoya to'qimasini kuydiradi. Natijada E. coli bakteriyalari va mikoplazma hech qanday to'siqsiz o'pkaga kirib, surunkali o'pka kasalligini keltirib chiqaradi.\n* **Chora:** Darhol toza havo kirishini kuchaytiring va nam to'shama qatlamini olib tashlab, quruq qipiq seping.\n\n---\n\n## 3. Tunnel ventilyatsiya va jazirama issiqqa qarshi kurash (25 kundan keyin)\n4 haftadan oshgan broyler 1.5 kg dan og'ir bo'ladi. Parrandalarda ter bezlari bo'lmaydi, qalin pat esa issiqlikni ushlab qoladi. Ularning yagona sovish yo'li — og'iz orqali tez-tez nafas olib suv bug'latish va badani bo'ylab esayotgan havo oqimidir.\n* **Tunnel effekti:** Katta ventilyatorlar binoning bir tomonidan havoni tortib chiqaradi, xona bo'ylab **2.0–2.5 m/s** tezlikda shamol esadi.\n* Bu tezlikdagi shamol qushlarga haroratni aslidan 4–6°C salqinroq his qilish imkonini beradi («shamolli sovutish effekti»).\n\n---\n\n## 4. Sovutish panellari (Cooling pads) va suv purkagichlar\nO'zbekistonda yozgi harorat +35–40°C dan oshganda, faqat havo haydash yetarli bo'lmaydi (qizigan shamol fen kabi ishlay boshlaydi):\n* **Sovutish kassetalari (pad):** Havo kirish darchalariga o'rnatilgan katakli qog'oz panellardan suv oqiziladi. Quruq va issiq havo nam paneldan o'tganda suv bug'lanadi va havo 6–10°C ga soviydi.\n* **Oltin qoida:** Panellarga suvni faqat tovuqxona ichidagi namlik 70% dan past va harorat 28°C dan yuqori bo'lganda yoqing! Agar xona allaqachon zax bo'lsa, suv bug'lanmaydi va dimlikdan qushlar bir necha soatda nobud bo'ladi.\n\n---\n\n## 5. Fermerlar uchun yozgi jaziramada amaliy maslahatlar:\n1. **Tomni oqlash:** Tovuqxona tomini tashqi tomondan ohak bilan oqlang — quyosh nuri qaytib, ichki harorat 3–4°C ga pasayadi.\n2. **Yemlanish vaqtini o'zgartirish:** Eng issiq vaqtlarda (soat 12:00 dan 17:00 gacha) yem oxurlarini ko'taring yoki chiroqni o'chiring. Yem hazm qilish ichki issiqlikni keskin oshiradi («issiqlik zarbasi»). Yemni faqat kechasi va erta tongda bering.\n3. **Muzdek toza suv:** Quvurlardagi suv salqin bo'lishi shart (18–20°C). Kunduzi qizigan suvni quvurlardan chiqarib yuboring.\n4. **S vitamini va elektrolitlar:** Qattiq issiq boshlanishidan 2–3 kun oldin suvga S vitamini va antistress elektrolitlar qo'shib ichiring.\n"
  },
  {
    "filename": "05_oziqlantirish.md",
    "title": "Oziqlantirish: Start, O'sish va Finish bosqichlari",
    "content": "<!--\nManba: Broylerlarni oziqlantirish bo'yicha qo'llanma (Ross/Cobb Nutrition Guidelines)\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Oziqlantirish: Start, O'sish va Finish bosqichlari\n\nZamonaviy broyler zotlarining genetikasi ularga atigi 6 haftada 42 grammdan 2.5 kilogrammgacha o'sish imkonini beradi. Ammo maxsus muvozanatlashtirilgan donador kombinatsiyalangan yemsiz bu natijaga erishib bo'lmaydi. Jo'jalarga uyda yorma, kepak yoki qaynatilgan tuxum berish aminokislotalar yetishmovchiligiga, raxitga va vaznning 2 barobar orqada qolishiga olib keladi.\n\n---\n\n## 1. Oziqlantirishning 3 ta asosiy bosqichi\n\n| Ko'rsatkich | 1-bosqich: «Start» | 2-bosqich: «O'sish» (Grover) | 3-bosqich: «Finish» |\n| :--- | :--- | :--- | :--- |\n| **Baqish davri** | **1 – 10 (yoki 14) kunlar** | **11 (yoki 15) – 28 kunlar** | **29 – 42 kunlar** |\n| **Yem shakli** | Mayda donador (1.5–2 mm) | Granula (2.5–3 mm) | Granula (3–3.5 mm) |\n| **Xom oqsil (protein)** | **21 – 23%** | **19 – 20%** | **17.5 – 18.5%** |\n| **Almashinuvchi energiya**| 3000 – 3050 kkal/kg | 3100 – 3150 kkal/kg | 3200 – 3250 kkal/kg |\n| **Bosqichning bosh maqsadi**| Ichki a'zolar, suyak, oshqozon va immunitetni shakllantirish | Mushak to'qimasi va suyaklarni jadal o'stirish | Ko'krak va son go'shtini semirtirish, sotuv vaznini olish |\n\n---\n\n## 2. Yemni bosqichma-bosqich almashtirish qoidasi\nBroylerning hazm qilish tizimi yem o'zgarishiga juda ta'sirchan. Bir yemdan ikkinchisiga birdaniga o'tish disbakterioz, ich ketishi va o'sishdan to'xtashga sabab bo'ladi.\n* Yem almashtirish doimo **3 kun** davomida aralashtirib amalga oshiriladi:\n  * **O'tishning 1-kuni:** 70% eski yem + 30% yangi yem;\n  * **O'tishning 2-kuni:** 50% eski yem + 50% yangi yem;\n  * **O'tishning 3-kuni:** 25% eski yem + 75% yangi yem;\n  * **4-kun:** 100% yangi yem.\n\n---\n\n## 3. 1 bosh broyler uchun kunlik yem sarfi jadvali (mo'ljal)\n\n| Yoshi (hafta) | 1 boshga kunlik yem (g) | Jami yeyilgan yem hisobi (g) |\n| :--- | :--- | :--- |\n| **1-hafta (1–7 kun)** | 15 – 25 g | ~130 – 160 g |\n| **2-hafta (8–14 kun)** | 35 – 55 g | ~450 – 500 g |\n| **3-hafta (15–21 kun)** | 65 – 85 g | ~1000 – 1100 g |\n| **4-hafta (22–28 kun)** | 95 – 120 g | ~1800 – 1900 g |\n| **5-hafta (29–35 kun)** | 130 – 155 g | ~2800 – 2900 g |\n| **6-hafta (36–42 kun)** | 160 – 180 g | ~3900 – 4200 g |\n\n*Jami 42 kun davomida bitta broyler taxminan **4.0 – 4.3 kg** sifatli tayyor yem iste'mol qiladi.*\n\n---\n\n## 4. Yem konversiyasi (FCR ko'rsatkichi)\nYem konversiyasi koeffitsiyenti — fermer foydasining asosiy ko'zgusi:\n$$\text{FCR} = \frac{\text{Jami yeyilgan yem (kg)}}{\text{Olingan tirik go'sht vazni (kg)}}$$\n* **A'lo natija:** FCR = 1.6 – 1.7 (1 kg tirik vazn olish uchun 1.6–1.7 kg yem sarflangan).\n* **O'rtacha natija:** FCR = 1.75 – 1.85.\n* **Zararli natija:** FCR > 2.0 (kasallik, sifatsiz yem yoki yemning yerga to'kilishi oqibatida fermer zarar ko'rmoqda).\n\n---\n\n## 5. Oxurlarni to'g'ri boshqarish\n* **Oxur balandligi:** Oxur cheti aniq qushning **ko'kragi va orqa beli** balandligida turishi kerak. Agar oxur past osilsa, qushlar yemni oyoqlari bilan sochib yuboradi va yemning 15 foizi axlatga aylanadi!\n* **Oxurni tozalab yeyish tartibi:** Kuniga bir marta qushlarga oxurdagi yemni 30–45 daqiqa davomida oxirigacha yalashiga imkon bering. Bu chang to'planishining va yem achishining oldini oladi.\n"
  },
  {
    "filename": "06_suv.md",
    "title": "Suv va sug'orish tizimini to'g'ri tashkil qilish",
    "content": "<!--\nManba: Parrandachilik korxonalarida suv ta'minoti standartlari (Ross Broiler Management Manual)\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Suv va sug'orish tizimini to'g'ri tashkil qilish\n\nSuv — broyler uchun eng muhim va shu bilan birga eng ko'p e'tibordan chetda qoladigan ozuqa moddasidir. Qush ozuqasiz bir necha kun yashashi mumkin, ammo suvsiz bir sutkada nobud bo'ladi. Agar jo'jalar suvdan qisilsa, ular darhol yem yeyishni to'xtatadi va o'sishi orqada qoladi.\n\n---\n\n## 1. Suvga bo'lgan ehtiyoj va «Suv : Yem» mutanosibligi\n* Qulay haroratda (20–22°C) broyler yeydigan quruq yemiga nisbatan **1.8–2.0 barobar ko'proq** suv ichadi.\n* Tovuqxonada harorat +30°C dan oshganda suv iste'moli **2.5–3.0 barobargacha** ortadi.\n* Agar xonada kunlik suv iste'moli kutilmaganda kamaysa — bu kasallik boshlanishining ilk xabarchisidir (kasallik alomatlari va o'limdan 24–48 soat oldin suv ichish pasayadi).\n\n---\n\n## 2. Ichimlik suvi sifatiga qo'yiladigan talablar\nBroylerlar ichadigan suv odam ichadigan suv kabi toza bo'lishi shart:\n* **Harorati:** Eng ma'quli **18–21°C**. 25°C dan iliq suvni qush xush ko'rmaydi va bunday suvda bakteriyalar juda tez ko'payadi. 14°C dan sovuq suv esa ichki a'zolarni shamollatadi va ichak spazmini keltirib chiqaradi.\n* **Kislotaliligi (pH):** Me'yor **6.5 – 7.5** oralig'ida bo'lishi lozim. pH darajasi 8 dan yuqori bo'lsa, ozuqa hazm qiluvchi fermentlar faolligi pasayadi.\n* **Bakteriyalardan xoli bo'lishi:** Suvda ichak tayoqchasi (E. coli) va salmonella bakteriyalari mutlaqo bo'lmasligi shart.\n* **Quvurlardagi shilliq parda (bioplyonka):** Plastik quvurlar ichida dori va vitamin qoldiqlaridan shilliq bakterial qatlam hosil bo'ladi. Har 2 haftada quvurlarni bosimli toza suv bilan, partiyalar oralig'ida esa maxsus vodorod peroksidi yoki organik kislotalar bilan yuvib zararsizlantiring.\n\n---\n\n## 3. Sug'orish tizimlarini tanlash va sozlash\n### Nippel sug'orgichlar (eng toza va tavsiya etiladigan usul)\n* **Zichlik:** Tomchi ushlagichli 1 ta nippelga **10–12 bosh** qush to'g'ri keladi.\n* **Balandlikni sozlash:**\n  * 1–3 kunlar: nippel jo'janing ko'zi balandligida (boshini 45° burchak ostida ko'taradi).\n  * 4-kundan boshlab: qush boshini 65–75° burchak ostida yuqoriga ko'tarib ichishi kerak, bunda uning oyoqlari to'liq yerda mustahkam turishi shart (qush oyoq uchida sakramasligi lozim).\n* **Suv bosimi:** Birinchi haftada suv bosimi minimal bo'ladi (quvurdagi suv ustuni 10–15 sm), to'rtinchi-beshinchi haftaga borib bosim oshiriladi (ustun 30–35 sm).\n\n### Vakuumli (qo'lda to'ldiriladigan) sug'orgichlar\n* Kichik xonadonlarda ishlatiladi: 50 ta jo'jaga 1 ta sug'orgich.\n* Kuniga kamida 2 marta qo'lda tozalab yuvilishi shart.\n* Sug'orgichni to'g'ridan-to'g'ri to'shama ustiga qo'ymang — yog'och yoki plastik taglik qo'ying, aks holda suv tezak bilan tez ifloslanadi.\n\n---\n\n## 4. Vaksina va dori ichirishda suvdan foydalanish qoidalari\n1. **Emlashdan 48 soat oldin:** Suvga xlor, kislota yoki dezinfeksiya moddalari qo'shishni to'xtating (ular tirik vaksina virusini o'ldiradi).\n2. **Chanqatish:** Vaksina berishdan 1.5–2 soat oldin suvni to'xtatib turing (issiqda — 1 soatdan oshmasin).\n3. **Stabilizator:** Suvdagi zararli xlor qoldiqlarini zararsizlantirish uchun 1 litr suvga 2 gramm yog'siz quruq sut qo'shing.\n4. Vaksina aralashtirilgan suv qushlar tomonidan qat'iy ravishda **1.5–2 soat** ichida to'liq ichib tugatilishi kerak.\n"
  },
  {
    "filename": "07_emlash.md",
    "title": "Broylerlarni emlash (Umumiy reja va asosiy qoidalar)",
    "content": "<!--\nManba: Markaziy Osiyoda broylerlar immunoprofilaktikasi bo'yicha namunaviy reja\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Broylerlarni emlash (Umumiy reja va asosiy qoidalar)\n\n> **MUHIM ESLATMA:** \n> AgroZen ilovasi dori dozalari va aniq shtammlarni tayinlamaydi. Emlash — bu davlat veterinariya nazorati ostidagi chora-tadbirdir. Aniq emlash sxemasi, shtammlari (La-Sota, Klon, Vinterfild va h.k.) hamda hududingizdagi kasallik holatini tuman bosh veterinari bilan maslahatlashib aniqlang!\n\n---\n\n## 1. Nima uchun broylerlarni emlash shart?\nBroylerlar atigi 40–45 kun yashaydi, lekin ularning immuniteti juda nozik bo'ladi. Parranda viruslari (Nyukasl/obmorok, Gamboro, yuqumli bronxit) chaqmoqdek tez tarqaladi: agar tovuqxonaga Nyukasl virusi kirsa, 48–72 soat ichida butun podaning **90–100 foizi** nobud bo'ladi. Virus yuqqan qushni antibiotik bilan davolab bo'lmaydi — faqat oldindan qilingan emlash asrab qoladi.\n\n---\n\n## 2. Broylerlarni emlashning namunaviy grafigi\n\n| Muddat (kun) | Kasallik nomi | Emlash usuli | Izoh |\n| :--- | :--- | :--- | :--- |\n| **1-kun** | Marek kasalligi, Yuqumli bronxit (IB), Nyukasl kasalligi (ND) | Inkubatorda purkash (sprey) yoki inyeksiya | Odatda inkubatoriyada bajariladi (fermerga berilgan veterinar guvohnomani tekshiring!) |\n| **7-kun** | Nyukasl (ND) + Yuqumli bronxit (IB) | Burun/ko'zga tomizish yoki suv orqali ichirish | Nafas yo'llarida dastlabki himoya to'sig'ini hosil qilish |\n| **11 – 14-kun** | Gamboro kasalligi (IBB — bursa kasalligi) | Ichimlik suvi orqali ichirish | Qushning asosiy immun organi — Fabritsiy xaltachasini himoyalash |\n| **18 – 21-kun** | Nyukasl (qayta emlash) / Gamboro (takroriy) | Ichimlik suvi orqali ichirish | Bo'rdoqilash oxirigacha baquvvat immunitetni saqlab qolish |\n\n---\n\n## 3. Suv orqali vaksina ichirishning oltin qoidalari\nYangi boshlovchilarning 90% xatosi — tirik vaksina virusini paqirdan tovuqqa yetib borguncha o'ldirib qo'yishidir:\n1. **Sovuq zanjir (+2...+8°C):** Vaksina dorixonadan muzli termosumkada keltirilishi shart. Vaksina +10°C dan isib ketsa yoki muzlatib qo'yilsa, virus o'ladi.\n2. **Xlorsiz toza suv:** Vodoprovod suvidagi xlor vaksina virusini 1 daqiqada nobud qiladi! Buloq suvidan foydalaning yoki suvni kamida 48 soat tindirib, unga albatta stabilizator qo'shing.\n3. **Rangli ko'rsatkich (indikator):** Maxsus ko'k rang beruvchi stabilizator tabletkalaridan foydalaning. Emlashdan 1–2 soat o'tgach jo'jalarning og'zini ochib ko'ring: ko'kargan til va jig'ildon qush vaksina ichganligini isbotlaydi.\n4. **Sug'orgichlar maydoni:** Barcha jo'jalar bir vaqtda suv icha olishi kerak, aks holda chaqqonlari ikki barobar ko'p ichadi, nimjonlari esa quruq qoladi.\n\n---\n\n## 4. Emlash paytida nimalar taqiqlanadi\n* Kasal, holsiz yoki sovuq qotgan jo'jalarni emlash qat'iyan taqiqlanadi — vaksina kasallikni kuchaytirib yuboradi.\n* Tirik vaksina berishdan 2 kun oldin va 2 kun keyin suvga antibiotik qo'shish man etiladi.\n* Vaksina eritmasini zanglagan yoki ruxlangan temir idishlarda tayyorlamang — faqat toza plastik idishlardan foydalaning.\n"
  },
  {
    "filename": "08_kasalliklar.md",
    "title": "Kasallik belgilari: qachon tezda veterinarni chaqirish kerak",
    "content": "<!--\nManba: Parrandalar yuqumli kasalliklarini klinik aniqlash bo'yicha qo'llanma (FAO / O'zR Veterinariya qo'mitasi)\nTekshiruvchi: AgroZen bosh veterinar maslahatchisi\nSana: 2026-10-09\nHolati: Tasdiqlangan\n-->\n\n# Kasallik belgilari: qachon tezda veterinarni chaqirish kerak\n\n> **AGROZENNING BOSH QOIDASI:** \n> Ilova veterinarning o'rnini bosa olmaydi. Agar qushlarda og'ir yuqumli kasallik belgilari ko'rinsa, o'zboshimchalik bilan bilinar-bilinmas antibiotik berish butun podaning qirilib ketishiga va qarzga botishga olib keladi. Xavfli alomatlar ko'ringanda darhol mutaxassis veterinarga murojaat qiling!\n\n---\n\n## 1. «Qizil chiroq» — o'ta xavfli xastalik alomatlari\n\nAgar podada quyidagi alomatlardan birontasi sezilsa, zudlik bilan chora ko'rish zarur:\n\n### 1. O'lim holatlarining (nobudgarchilikning) keskin ko'payishi\n* **Me'yor:** Kunlik tabiiy o'lim ko'rsatkichi umumiy qush sonining 0.1–0.15 foizidan oshmasligi kerak (masalan, 1000 ta jo'jadan kuniga 1–2 ta).\n* **XAVF SIGNALI (TREVOGA):** Agar bir sutkada **qushlarning 1 foizidan ko'prog'i** o'lsa (1000 tadan 10 tadan ko'p) — bu o'tkir yuqumli kasallik tarqalganidan dalolat beradi!\n\n### 2. Og'ir nafas qisishi va xirillash\n* Tovuqxona ichida baland ovozda eshitiladigan xirillash, hushtaksimon ovoz, aksirish va hiqillash.\n* Qushlar bo'ynini yuqoriga cho'zib, og'zini katta ochgan holda zo'rg'a nafas oladi.\n* Bosh va ko'z atroflarining shishishi («boyqush boshi»), ko'z burchaklarida ko'pik yoki yiring to'planishi.\n\n### 3. Xavfli axlat o'zgarishlari\n* **Qon aralash yoki to'q qizil axlat:** O'tkir koksidioz kasalligining aniq belgisi.\n* **Ko'pikli och-yashil va sarg'ish suyuq axlat:** Nyukasl yoki Gamboro kasalligi belgisi.\n* **Bo'rdek oq axlat va orqa chiqaruv yo'lining yopishib qolishi:** Yosh jo'jalarda pulloroz (salmonellyoz) alomati.\n\n### 4. Asab tizimi zararlanishi va falajlik\n* Bo'yinning burilib qolishi (qush boshini orqaga yoki pastga qarab qayirib oladi).\n* Bir tomonga qulab yotish, bosh qaltirashi, oyoq tortishishi (sudorogi).\n* Qanot va oyoqlarning shol bo'lib qolishi («shpagatga o'tirib qolish»).\n\n---\n\n## 2. Veterinar kelgunga qadar fermer nima qilishi kerak?\n1. **Ajratish (izolyatsiya):** Shubhali kasal va o'lgan qushlarni sog'lom podadan darhol olib chiqing. O'lgan qushlarni yopiq paketga solib, shifokor yorib ko'rishi uchun salqin joyga qo'ying.\n2. **Sharoitni tekshiring:** Harorat, shamollatish va suv ta'minotini qayta ko'ring. Ba'zida «kasallik» aslida oddiy havo yetishmasligi yoki chanqoqlik bo'lib chiqadi.\n3. **O'zboshimchalik bilan antibiotik BERMANG!** Agar veterinar laboratoriya tekshiruvi o'tkazgunga qadar qushlarga kuchli antibiotik ichirib qo'ysangiz, laboratoriya kasallik qo'zg'atuvchisini aniqlay olmaydi va to'g'ri dori tanlab bo'lmaydi.\n4. **Ma'lumotlarni tayyorlab turing:**\n   * Qushlarning aniq yoshi (kuni);\n   * Oxirgi 3 kunda qancha qush kasallandi va o'ldi;\n   * Qaysi zavodning yemi berilmoqda;\n   * Qilingan vaksinalar nomi, sanasi va flakon seriyalari;\n   * Qanday suv berilmoqda (vodoprovod, yerosti quduq, ariq).\n\n---\n\n## 3. Kasallik aniqlanganda xavfsizlik choralari\n* Hech qachon qo'shnilaringizning tovuqxonasiga bormang va o'z tovuqxonangizga begona odamlarni kiritmang.\n* Faqat tovuqxona ichida kiyiladigan alohida kiyim va etikdan foydalaning.\n* Eshik oldidagi dezinfeksiya gilamchasiga etikni botirib kiring.\n* O'lgan parrandalarni faqat veterinar ko'rsatmasi bilan yo'q qiling (yoqish yoki chuqurligi kamida 1.5 metrli chuqurga xlor sepib ko'mish). O'lgan qushlarni ariqqa, ko'chaga yoki axlatxonaga tashlash qat'iyan man etiladi!\n"
  },
  {
    "filename": "feed.md",
    "title": "Broylerlarni bosqichma-bosqich oziqlantirish",
    "content": "# Broylerlarni bosqichma-bosqich oziqlantirish\n\nBroyler jo'jalari juda tez o'sadi. Oziqlantirish 3 asosiy bosqichga bo'linadi:\n\n## Oziqlantirish bosqichlari:\n1. **Start (1–14 kunlar):**\n   - Xom protein: 21–23%\n   - Shakli: mayda yorma (1.5–2 mm)\n   - Ichki a'zolar va suyak tizimini shakllantirish uchun muhim.\n\n2. **O'sish / Grover (15–28 kunlar):**\n   - Xom protein: 19–20%\n   - Shakli: granula (2.5–3 mm)\n   - Go'sht va mushak massasining jadal o'sishi davri.\n\n3. **Finish (29–42 kunlar):**\n   - Xom protein: 17.5–18.5%\n   - Shakli: granula (3–3.5 mm)\n   - So'yish oldidan vazn to'plash. Ushbu bosqichda antibiotik va dori vositalarini berish qat'iyan taqiqlanadi!\n\n## Muhim qoidalar:\n- Yem doimo yemdonlarda bo'lishi kerak.\n- Suv har doim toza va yangi bo'lishi shart. 1 kg yem uchun broyler 1.8–2 litr suv ichadi.\n"
  },
  {
    "filename": "temperature.md",
    "title": "Broylerlar uchun harorat rejimi",
    "content": "# Broylerlar uchun harorat rejimi\n\nHarorat — dastlabki haftalarda jo'jalarning omon qolishi va rivojlanishidagi eng muhim omil. Bir kunlik jo'jalarda tana haroratini boshqarish tizimi hali rivojlanmagan bo'ladi.\n\n## Haftalar bo'yicha harorat jadvali:\n- **1-3 kunlar:** 32-33°C (bruder ostida to'shak sathida)\n- **4-7 kunlar:** 30-31°C\n- **2-hafta (8-14 kunlar):** 27-29°C\n- **3-hafta (15-21 kunlar):** 24-26°C\n- **4-hafta (22-28 kunlar):** 21-23°C\n- **5-6 haftalar (29-42 kunlar):** 18-20°C\n\n## Jo'jalar holatiga qarab baholash:\n- **Optimal holat:** jo'jalar butun xonaga bir tekis tarqalgan, faol yem va suv iste'mol qilmoqda.\n- **Sovuq bo'lsa:** isitkich ostiga zich to'planib, qattiq chirillaydi.\n- **Issiq bo'lsa:** devor burchaklariga qochadi, tumshug'ini ochib og'ir nafas oladi, qanotlarini yoyadi.\n- **Skvoznyak (shamol urishi):** shamol kelayotgan tomondan uzoqroq burchakka to'planadi.\n"
  },
  {
    "filename": "vaccination.md",
    "title": "Broylerlarni emlash (Vaksinatsiya)",
    "content": "# Broylerlarni emlash (Vaksinatsiya)\n\nO'z vaqtida emlash butun galani xavfli yuqumli kasalliklardan va nobudgarchilikdan saqlaydi.\n\n## Asosiy emlash taqvimi:\n1. **1-kun (inkubatorda):**\n   - Marek kasalligi\n   - Yuqumli bronxit (IB)\n2. **7-kun:**\n   - Nyukasl kasalligi (ND) + Yuqumli bronxit (ichirish yoki purkash usulida)\n3. **12–14 kun:**\n   - Gamboro kasalligi (IBD) — suv orqali ichirish usuli\n4. **20–22 kun:**\n   - Gamboro yoki Nyukaslga qarshi qayta emlash (hududdagi veterinariya tavsiyasiga binoan)\n\n## Vaksina ichirish qoidalari:\n- Vaksinatsiyadan 2 soat oldin suv to'xtatiladi (qushlar 1.5–2 soatda to'liq ichishi uchun).\n- Suv xlorlanmagan bo'lishi shart! Vaksina faolligini saqlash uchun yog'siz quruq sut (1 litr suvga 2 g) qo'shiladi.\n- Metall idishlardan foydalanish taqiqlanadi.\n"
  },
  {
    "filename": "ventilation.md",
    "title": "Broyler parrandaxonasida shamollatish (ventilyatsiya)",
    "content": "# Broyler parrandaxonasida shamollatish (ventilyatsiya)\n\nTo'g'ri ventilyatsiya karbonat angidrid, ammiak va ortiqcha namlikni chiqarib, qushlarni toza kislorod bilan ta'minlaydi.\n\n## Asosiy talablar:\n- Dastlabki 7 kunda: minimal ventilyatsiya (0.1–0.15 m/s), to'shak sathida skvoznyak bo'lmasligi kerak.\n- 2–4 haftalarda: o'rtacha ventilyatsiya va toza havo oqimi.\n- 5–6 haftalarda: ayniqsa yozning issiq kunlarida maksimal quvvatda ishlash.\n- Ammiak miqdori: 15 ppm dan oshmasligi kerak (agar inson ammiak hidini sezsa, me'yor buzilgan hisoblanadi).\n\n## Issiqdan saqlash:\nHarorat 30°C dan oshganda sovutish panellari, tumanlagichlar yoki tomni sovuq suv bilan sug'orishdan foydalaning.\n"
  }
];

export const KNOWLEDGE_ARTICLES_RU: KnowledgeArticle[] = [
  {
    "filename": "01_preparation.md",
    "title": "Подготовка помещения до завоза цыплят",
    "content": "<!--\nИсточник: Регламент бройлерного птицеводства (Ross 308 / Cobb 500) и рекомендации Ветеринарного комитета РУз\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Подготовка помещения до завоза цыплят\n\nУспех выращивания бройлеров на 70% зависит от того, насколько качественно подготовлено помещение до приезда суточных цыплят. Если посадить цыплят в сырой, холодный или плохо продезинфицированный сарай, падёж в первые 10 дней неизбежен.\n\n---\n\n## 1. Механическая очистка и мойка\nПодготовка начинается сразу после освобождения помещения от предыдущей партии:\n1. **Удаление старой подстилки:** Полностью вывезите старый помёт и подстилку минимум за 50 метров от птичника.\n2. **Сухая чистка:** Сметите пыль, паутину и остатки пуха со стен, потолка, балок, светильников и вентиляторов. Пыль содержит огромное количество вирусов и бактерий.\n3. **Влажная мойка:** Промойте помещение водой под высоким давлением (минимум 100–140 бар). Используйте 1–2% раствор моющего средства или кальцинированной соды, чтобы смыть жировую плёнку. Особое внимание уделите углам, стыкам пола со стенами и щелям.\n\n---\n\n## 2. Дезинфекция помещения и оборудования\nДезинфекция эффективна только на чистых и высушенных поверхностях:\n* **Побелка стен и потолка:** Обработайте стены свежегашёной известью (20% суспензия) с добавлением 2–3% медного купороса. Это уничтожает грибки и бактерии.\n* **Влажная дезинфекция:** Обработайте пол и стены сертифицированными дезинфектантами (препараты на основе глутарового альдегида, четвертичных аммониевых соединений или вироцида) строго по инструкции.\n* **Оборудование:** Кормушки, поилки, шланги замочите в дезинфицирующем растворе, затем промойте чистой водой и просушите на солнце.\n* **Санитарный разрыв:** После дезинфекции помещение должно простоять пустым с закрытыми дверями минимум **4–7 дней** («пусто-занято»).\n\n---\n\n## 3. Дератизация и защита от диких птиц\nГрызуны переносят сальмонеллез и пастереллез, а дикие птицы — птичий грипп и болезнь Ньюкасла:\n* Закройте сеткой (ячейка не более 1.5 см) все окна, вентиляционные отверстия и форточки.\n* Заделайте раствором с битым стеклом все норы и щели в стенах и фундаменте.\n* Разложите приманки против мышей и крыс по периметру здания снаружи птичника.\n\n---\n\n## 4. Подстилка: выбор и укладка\nЦыплята проводят на подстилке всю жизнь. Холодная или влажная подстилка вызывает воспаление суставов, асцит и гибель.\n* **Материал:** Лучший выбор — сухие древесные опилки крупных или средних фракций (хвойные или лиственные, без пыли) или чистая, сухая, измельченная солома пшеницы.\n* **Толщина слоя:** Зимой и весной — **7–10 см**, летом — **5–7 см**.\n* **Требования:** Подстилка должна быть абсолютно сухой (влажность до 15%), без плесени и запаха гнили. Запрещено использовать мелкую древесную пыль — цыплята склёвывают её и забивают зоб.\n\n---\n\n## 5. Прогрев помещения (за 24–48 часов)\nСамая частая ошибка новичков — включать обогрев за 2 часа до привоза цыплят. Воздух успевает нагреться, а пол остаётся ледяным.\n* **За 24–48 часов до посадки:** Запустите обогреватели (печи, теплогенераторы, инфракрасные лампы).\n* **Температура пола:** К моменту выгрузки цыплят температура самой подстилки должна быть не менее **30–32°C**, а воздуха на высоте цыпленка — **33–34°C**.\n* Если цыпленок сядет на холодный пол, его внутренние органы охладятся, желточный мешок перестанет рассасываться, и цыпленок погибнет.\n\n---\n\n## 6. Чек-лист готовности перед прибытием машины\nПеред тем как ехать за цыплятами, проверьте:\n- [ ] Обогрев работает стабильно, температура подстилки 30–32°C.\n- [ ] Поилки заполнены чистой водой комнатной температуры (20–22°C).\n- [ ] Корм «Старт» насыпан на бумажные подстилки и в стартовые лотки.\n- [ ] Свет включен на полную яркость (30–40 люкс).\n- [ ] Вентиляция настроена на минимальный приток без сквозняков на полу.\n- [ ] Подготовлены термометр и гигрометр на уровне роста цыплят (5–8 см от пола).\n- [ ] Есть дезинфекционный коврик у входа в птичник.\n"
  },
  {
    "filename": "02_first_days.md",
    "title": "Приём цыплят и первые 3 дня",
    "content": "<!--\nИсточник: Регламент бройлерного птицеводства (Ross 308 / Cobb 500)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Приём цыплят и первые 3 дня\n\nПервые 72 часа жизни бройлера определяют его конечный вес при забое. Если цыпленок на 7-й день жизни не набрал вес минимум в 4–4.5 раза больше начального (цель — от 180 г), компенсировать это отставание в будущем уже не получится.\n\n---\n\n## 1. Выгрузка и осмотр цыплят\n* **Скорость выгрузки:** Разгружайте коробки с цыплятами быстро, но без резких движений. Не бросайте ящики на пол.\n* **Первичная выбраковка:** Обратите внимание на качество партии. Здоровый суточный цыпленок:\n  * Весит 40–44 грамма;\n  * Активно стоит на ногах, блестящие чистые глаза;\n  * Пуповина полностью зажившая, сухая, без струпа и кровоподтеков;\n  * Живот мягкий, не вздутый;\n  * Пух чистый, сухой и пушистый, без прилипшей скорлупы.\n* Ослабленных и травмированных цыплят отсадите отдельно под лампу или сразу отбракуйте.\n\n---\n\n## 2. Первые 2 часа: только вода!\nЦыплята после инкубатора и дороги сильно обезвожены. **Вода важнее корма!**\n* **Температура воды:** Строго **20–22°C**. Ледяная вода вызывает переохлаждение внутренних органов и спазм ЖКТ, а горячая (выше 25°C) способствует быстрому размножению бактерий.\n* **Первая выпойка:** В первые часы в воду полезно добавить глюкозу (20–30 г на 1 л) или витаминно-электролитный комплекс для снятия стресса от транспортировки.\n* **Знакомство с водой:** Опустите клювы нескольких цыплят в поилку — остальные мгновенно повторят за ними.\n* Доступ к поилкам должен быть свободным: 1 вакуумная поилка на 50 цыплят или 1 ниппель на 10–12 цыплят.\n\n---\n\n## 3. Раздача корма (через 2 часа после воды)\nТолько после того, как все цыплята попили воду, рассыпайте корм.\n* **Куда сыпать:** Используйте специальную гофрированную бумагу для бройлеров или чистые листы плотной бумаги (газеты с типографской краской использовать нельзя!). Бумага должна покрывать не менее 20–30% площади брудера.\n* **Шуршание бумаги:** Цыплята бегают по бумаге, она шуршит и привлекает их внимание к корму.\n* **Качество корма:** Используйте только качественный престартер/старт в виде мелкой крупки (частицы 1.5–2 мм). Мучнистый корм забивает клювы и дыхательные пути.\n* Подсыпайте корм часто и небольшими порциями (5–6 раз в сутки), чтобы он всегда оставался свежим и ароматным.\n\n---\n\n## 4. Световой режим в первые дни\n* **Дни 1–3:** 23 часа света высокой интенсивности (30–40 люкс) и 1 час полной темноты.\n* 1 час темноты нужен для того, чтобы цыплята привыкли к отсутствию света и не паниковали (не давили друг друга в кучах), если внезапно отключится электричество.\n\n---\n\n## 5. Тест наполненности зоба (Контроль зобика)\nЭто главный объективный показатель того, насколько правильно вы приняли цыплят:\n* **Через 8 часов после посадки:** Выборочно возьмите 50 цыплят из разных концов зоны. У **80%** из них зоб должен быть полным, мягким и округлым (как мягкая губка с кормом и водой).\n* **Через 24 часа:** У **95–100%** цыплят зоб должен быть полным.\n* *Если зоб твердый:* Цыплята едят корм, но не нашли воду или вода слишком холодная.\n* *Если зоб водянистый:* Пьют много воды, но не находят корм (мало кормушек, темно или плохой корм).\n* *Если зоб пустой:* Цыплята мерзнут или испытывают стресс.\n\n---\n\n## 6. Как определить комфорт по поведению птицы\nТермометр может ошибаться, но сами цыплята никогда не врут:\n* **Идеально:** Цыплята равномерно распределены по всей площади, активно бегают, кушают, пьют или спокойно спят, вытянув лапки. Издают тихое, довольное щебетание.\n* **Холодно:** Сбились в плотную кучу под источником тепла, громко и жалобно пищат. Риск: задохнутся нижние цыплята.\n* **Жарко:** Отошли от центра к стенам, распластали крылья, тяжело дышат открытыми клювами. Отказываются от еды.\n* **Сквозняк:** Сбились в кучу у одной стены или в одном углу, избегая потока холодного воздуха.\n"
  },
  {
    "filename": "03_temperature.md",
    "title": "Температура и влажность по неделям",
    "content": "<!--\nИсточник: Стандарты микроклимата птичников (Ross Broiler Management Handbook)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Температура и влажность по неделям\n\nСуточный цыпленок не умеет самостоятельно регулировать температуру своего тела. В первые 10–14 дней его терморегуляция зависит исключительно от микроклимата в помещении. Ошибка всего в 2–3 градуса может привести к резкому падежу или отставанию в росте.\n\n---\n\n## 1. Таблица температурного режима (по неделям и дням)\n\nИзмерения проводятся строго **на уровне спины цыпленка** (5–8 см от пола), а не под потолком!\n\n| Возраст птицы | Температура воздуха (°C) | Температура подстилки (°C) | Относительная влажность (%) |\n| :--- | :--- | :--- | :--- |\n| **День 1** | **33 – 34°C** | 30 – 32°C | 60 – 70% |\n| **День 3** | **33°C** | 30°C | 60 – 70% |\n| **День 7 (Неделя 1)** | **31 – 32°C** | 29 – 30°C | 60 – 65% |\n| **День 14 (Неделя 2)** | **28 – 29°C** | 27 – 28°C | 60 – 65% |\n| **День 21 (Неделя 3)** | **26 – 27°C** | 25 – 26°C | 55 – 60% |\n| **День 28 (Неделя 4)** | **23 – 24°C** | 22 – 23°C | 55 – 60% |\n| **День 35 (Неделя 5)** | **21 – 22°C** | 20 – 21°C | 55 – 65% |\n| **День 42 (Неделя 6)** | **19 – 20°C** | 19 – 20°C | 55 – 65% |\n\n---\n\n## 2. Температура подстилки важнее температуры воздуха\nПочему это критично:\n* Цыпленок касается лапками и животом пола 100% времени.\n* Если воздух прогрет до 34°C, а бетонный пол под тонким слоем опилок имеет температуру 22°C, цыплята переохладятся за 3–4 часа.\n* При переохлаждении лапок кровь оттекает от внутренних органов, остаточный желток не рассасывается, развивается желточный перитонит (основная причина гибели на 3–5 день).\n* **Правило:** Прикоснитесь тыльной стороной ладони или ступней цыпленка к своей щеке: лапка цыпленка должна быть теплой! Если лапки холодные — подстилка не прогрета.\n\n---\n\n## 3. Влажность воздуха (Относительная влажность — RH)\n* **В первую неделю (60–70%):** В инкубаторе влажность высокая (70–80%). Если в птичнике сухой воздух (менее 50%), цыплята быстро теряют влагу через легкие, пух пересыхает, ухудшается дыхание. Для поднятия влажности увлажняйте проходы или распыляйте воду в воздух.\n* **Со 2-й недели и до конца (55–65%):** Избыточная влажность (выше 70%) при температуре 25–28°C опасна — подстилка намокает, бурно выделяется аммиак, развиваются кокцидии и бактерии.\n\n---\n\n## 4. Разница дневных и ночных температур\nВ климате Узбекистана суточные перепады температур весной и осенью могут достигать 15–20°C (днем +25°C, ночью +5°C).\n* **Главная ошибка:** Отключать отопление на ночь или забывать прикрыть вентиляционные жалюзи при похолодании.\n* Суточные колебания температуры в птичнике не должны превышать **1.5–2°C**.\n* Резкие скачки температуры вызывают простудные заболевания (инфекционный бронхит, микоплазмоз) и стресс, останавливающий рост.\n\n---\n\n## 5. Расположение термометров\n* Термометры и электронные датчики должны висеть строго на уровне цыпленка.\n* Установите минимум 3 термометра: под брудером/обогревателем, у дальней стены и около поилок.\n* Защищайте датчики от прямого попадания тепловых лучей инфракрасных ламп, иначе показания будут завышены.\n"
  },
  {
    "filename": "04_ventilation.md",
    "title": "Вентиляция и борьба с жарой",
    "content": "<!--\nИсточник: Практическое руководство по микроклимату и вентиляции птичников (Ross/Cobb)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Вентиляция и борьба с жарой\n\nВентиляция в птичнике решает 5 ключевых задач: подача кислорода, удаление углекислого газа, удаление токсичного аммиака, удаление лишней влаги и охлаждение птицы. В жарком климате Узбекистана правильная вентиляция — вопрос выживания всего поголовья в возрасте старше 25 дней.\n\n---\n\n## 1. Минимальная вентиляция (первые 2–3 недели)\nКогда цыплята маленькие, главная цель вентиляции — обновить воздух, не создавая сквозняка и не выдувая драгоценное тепло.\n* **Принцип:** Холодный свежий воздух снаружи должен поступать через верхние приточные клапаны под потолок, смешиваться с теплым воздухом помещения и только потом опускаться к цыплятам.\n* **Скорость воздуха:** На уровне цыплят скорость движения воздуха в первые 2 недели не должна превышать **0.15–0.2 м/с**.\n* **Сквозняк убивает:** Если холодный воздух дует прямо по полу, цыплята простывают, сбиваются в углы и гибнут от завала.\n\n---\n\n## 2. Опасность аммиака ($NH_3$) и сырости\nАммиак образуется при разложении мочевой кислоты помета во влажной подстилке.\n* **Простой тест фермера:** Если вы зашли в птичник и почувствовали запах аммиака или у вас заслезились глаза — концентрация аммиака превысила 20 ppm!\n* Для птицы это катастрофа: аммиак парализует реснички дыхательных путей. Бактерии (E. coli, микоплазма) беспрепятственно проникают в легкие и воздухоносные мешки, вызывая хронический колибактериоз.\n* **Решение:** Немедленно увеличьте приток свежего воздуха и замените влажные участки подстилки сухими опилками.\n\n---\n\n## 3. Туннельная вентиляция и борьба с жарой (после 25 дней)\nБройлер старше 4 недель весит более 1.5 кг. У него нет потовых желез, а густое перо задерживает тепло. Единственный способ охладиться — испарение влаги через дыхание (одышка) и отдача тепла через обдув тела воздухом.\n* **Туннельный эффект:** Вентиляторы вытягивают воздух с одного торца здания, создавая мощный сквозной поток со скоростью **2.0–2.5 м/с**.\n* При такой скорости воздуха птица ощущает температуру на 4–6°C ниже фактической (эффект «ветрового охлаждения»).\n\n---\n\n## 4. Панели испарительного охлаждения (Cooling pads) и туманообразование\nКогда температура воздуха на улице в Узбекистане поднимается выше 35–38°C, одной вентиляции недостаточно (горячий воздух начинает работать как фен):\n* **Охлаждающие панели (пэды):** Вода смачивает сотовые панели на притоке. Горячий сухой воздух проходит сквозь них, испаряет воду и охлаждается на 6–10°C.\n* **Важное правило:** Включайте подачу воды на панели только при влажности воздуха ниже 70% и температуре выше 28°C. Если в птичнике уже сыро, испарение остановится, и птицы мгновенно задохнутся.\n\n---\n\n## 5. Практические советы для фермеров в жаркие дни:\n1. **Побелка крыши:** Покрасьте шифер или профнастил крыши снаружи известью — отражение солнечных лучей снизит температуру внутри здания на 3–4°C.\n2. **Смещение графика кормления:** В самые жаркие часы (с 12:00 до 17:00) поднимите кормушки или выключите свет. Переваривание корма выделяет дополнительное тепло («тепловой удар»). Кормите птицу ночью и рано утром.\n3. **Холодная вода:** Вода в трубах должна быть прохладной (18–20°C). Сливайте нагревшуюся воду из систем поения в дневное время.\n4. **Витамин C и электролиты:** За 2–3 дня до наступления жары добавляйте в воду витамин С и антистрессовые электролиты.\n"
  },
  {
    "filename": "05_feeding.md",
    "title": "Кормление бройлеров: фазы Старт, Рост и Финиш",
    "content": "<!--\nИсточник: Справочник по кормлению бройлеров (Ross/Cobb Nutrition Guidelines)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Кормление бройлеров: фазы Старт, Рост и Финиш\n\nГенетика современного бройлера позволяет ему вырасти от 42 граммов до 2.5 килограммов всего за 6 недель. Однако без сбалансированного гранулированного комбикорма раскрыть этот потенциал невозможно. Кормление самодельными дроблеными зерносмесями или вареными яйцами приводит к нехватке аминокислот, рахиту и падению веса в 2 раза ниже нормы.\n\n---\n\n## 1. Три основные фазы кормления\n\n| Параметр | Фаза 1: «Старт» (Pre-starter / Starter) | Фаза 2: «Рост» (Grower) | Фаза 3: «Финиш» (Finisher) |\n| :--- | :--- | :--- | :--- |\n| **Период применения** | **1 – 10 (или 14) дни** | **11 (или 15) – 28 дни** | **29 – 42 дни** |\n| **Форма корма** | Мелкая крупка (1.5–2 мм) | Гранулы (2.5–3 мм) | Гранулы (3–3.5 мм) |\n| **Сырой протеин (белок)** | **21 – 23%** | **19 – 20%** | **17.5 – 18.5%** |\n| **Обменная энергия** | 3000 – 3050 ккал/кг | 3100 – 3150 ккал/кг | 3200 – 3250 ккал/кг |\n| **Главная цель фазы** | Развитие внутренних органов, скелета, ЖКТ и иммунитета | Быстрое наращивание мышечной массы и скелета | Финишный откорм грудки и бедра, набор товарного веса |\n\n---\n\n## 2. Правило плавного перехода между кормами\nПищеварительная система бройлера очень чувствительна к смене рациона. Резкая смена корма вызывает дисбактериоз, кормовой понос (диарею) и потерю аппетита.\n* Переход всегда осуществляется в течение **3 дней**:\n  * **День 1 перехода:** 70% старого корма + 30% нового корма;\n  * **День 2 перехода:** 50% старого корма + 50% нового корма;\n  * **День 3 перехода:** 25% старого корма + 75% нового корма;\n  * **День 4:** 100% новый корм.\n\n---\n\n## 3. Таблица суточного расхода корма на 1 голову (ориентир)\n\n| Возраст (неделя) | Расход в сутки на голову (г) | Суммарное потребление нарастающим итогом (г) |\n| :--- | :--- | :--- |\n| **Неделя 1 (дни 1–7)** | 15 – 25 г | ~130 – 160 г |\n| **Неделя 2 (дни 8–14)** | 35 – 55 г | ~450 – 500 г |\n| **Неделя 3 (дни 15–21)** | 65 – 85 г | ~1000 – 1100 г |\n| **Неделя 4 (дни 22–28)** | 95 – 120 г | ~1800 – 1900 г |\n| **Неделя 5 (дни 29–35)** | 130 – 155 г | ~2800 – 2900 г |\n| **Неделя 6 (дни 36–42)** | 160 – 180 г | ~3900 – 4200 г |\n\n*Итого на выращивание одного бройлера до 42 дней расходуется около **4.0 – 4.3 кг** качественного комбикорма.*\n\n---\n\n## 4. Конверсия корма (FCR)\nКоэффициент конверсии корма — главный экономический показатель:\n$$\text{FCR} = \frac{\text{Всего съедено корма (кг)}}{\text{Итоговый живой вес птицы (кг)}}$$\n* **Отличный результат:** FCR = 1.6 – 1.7 (на 1 кг живой массы затрачено 1.6–1.7 кг корма).\n* **Средний результат:** FCR = 1.75 – 1.85.\n* **Убыточный результат:** FCR > 2.0 (происходит перерасход корма из-за болезней, низкого качества корма или выгребания птицей на пол).\n\n---\n\n## 5. Грамотное использование кормушек\n* **Высота кормушек:** Нижний край желоба или бункера должен находиться строго **на уровне спины/зоба** птицы. Если кормушка висит низко, цыплята загребают корм лапами, и до 15% корма втаптывается в подстилку!\n* **Суточная очистка:** Один раз в день давайте птице полностью выесть остатки корма в кормушках до дна в течение 30–45 минут. Это предотвратит накопление пылевидных остатков и плесени.\n"
  },
  {
    "filename": "06_water.md",
    "title": "Вода и организация поения",
    "content": "<!--\nИсточник: Стандарты водоснабжения птицеводческих предприятий (Ross Broiler Management Manual)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Вода и организация поения\n\nВода — самое важное и при этом часто недооцененное питательное вещество для бройлера. Птица может прожить без корма несколько дней, но без воды погибает в течение суток. Если цыплята недополучают воду, они немедленно перестают усваивать корм и останавливаются в росте.\n\n---\n\n## 1. Потребность в воде и соотношение «Вода : Корм»\n* При нормальной температуре (20–22°C) бройлер выпивает воды в **1.8–2.0 раза больше**, чем съедает сухого корма.\n* При температуре в птичнике выше 30°C потребление воды увеличивается в **2.5–3.0 раза**.\n* Если суточный расход воды снизился — это первый признак надвигающейся болезни за 24–48 часов до появления клинических симптомов или падежа.\n\n---\n\n## 2. Требования к качеству питьевой воды\nВода для бройлеров должна отвечать тем же санитарным нормам, что и питьевая вода для человека:\n* **Температура:** Оптимально **18–21°C**. Вода теплее 25°C невкусна птице и служит инкубатором для бактерий. Вода холоднее 14°C охлаждает внутренности и вызывает спазмы кишечника.\n* **Кислотность (pH):** Норма в диапазоне **6.5 – 7.5**. Вода с pH выше 8 снижает эффективность пищеварительных ферментов.\n* **Бактериальная чистота:** Полное отсутствие бактерий группы кишечной палочки (E. coli) и сальмонелл.\n* **Биопленка в трубах:** Внутри пластиковых водопроводов образуется слизистая плёнка из бактерий и остатков витаминов. Раз в 2 недели промывайте систему чистой водой под напором, а между посадками партий — дезинфицирующими растворами перекиси водорода или органических кислот.\n\n---\n\n## 3. Выбор и настройка систем поения\n### Ниппельные поилки (рекомендуемый стандарт)\n* **Плотность:** 1 ниппель с каплеуловителем на **10–12 голов**.\n* **Регулировка высоты:** \n  * В 1–3 дни: ниппель должен быть на уровне глаз цыпленка (тянется под углом 45° вверх).\n  * Начиная с 4-го дня: птица должна пить с поднятой головой под углом 65–75°, при этом лапки полностью стоят на полу (цыпленок не должен прыгать на цыпочках).\n* **Давление воды:** В первую неделю давление минимальное (высота водяного столба в трубке 10–15 см), чтобы капли выступали от легкого касания. К 5-й неделе давление увеличивают (столб 30–35 см).\n\n### Колокольные (вакуумные) поилки\n* Используются в небольших приусадебных хозяйствах: 1 поилка на 50 цыплят.\n* Требуют регулярного ручного мытья 2 раза в день.\n* Не ставьте поилки прямо на опилки — используйте деревянные или пластиковые подставки, чтобы вода не засорялась пометом.\n\n---\n\n## 4. Правила поения при выпаивании вакцин и витаминов\n1. **За 48 часов до вакцинации:** Полностью прекратите добавление в воду любых дезинфектантов, хлора или подкислителей (они убивают живой вирус вакцины).\n2. **Жажда:** Перед подачей вакцины перекройте воду на 1.5–2 часа (в жару — не более чем на 1 час).\n3. **Стабилизатор:** Добавьте в воду сухое обезжиренное молоко (2 г на 1 л) для нейтрализации следов хлора.\n4. Вакцина должна быть выпита птицей строго за **1.5–2 часа**.\n"
  },
  {
    "filename": "07_vaccination.md",
    "title": "Вакцинация бройлеров (Общий график и правила)",
    "content": "<!--\nИсточник: Типовые схемы иммунопрофилактики бройлеров в Центральной Азии\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Вакцинация бройлеров (Общий график и правила)\n\n> **ВАЖНОЕ ПРЕДУПРЕЖДЕНИЕ:** \n> AgroZen не назначает конкретные дозировки и штаммы препаратов. Вакцинация — это государственная ветеринарная мера. Точную схему, штаммы (Ла-Сота, Клон, Винтерфилд и др.) и эпизоотическую обстановку в вашем районе уточняйте у официального районного ветеринара!\n\n---\n\n## 1. Зачем вакцинировать бройлеров?\nБройлеры живут всего 40–45 дней, но обладают очень нежной иммунной системой. Инфекции птиц (болезнь Ньюкасла, болезнь Гамборо, инфекционный бронхит) распространяются молниеносно: если в птичник занесен вирус Ньюкасла, за 48–72 часа погибает **до 90–100%** поголовья. Вылечить зараженную вирусом птицу антибиотиками невозможно — помогает только своевременная вакцинация.\n\n---\n\n## 2. Типовой график вакцинации бройлеров\n\n| Срок (день) | Заболевание | Метод вакцинации | Примечание |\n| :--- | :--- | :--- | :--- |\n| **День 1** | Болезнь Марека, Инфекционный бронхит (ИБ), болезнь Ньюкасла (НБ) | Спрей-метод или инъекция в инкубаторе | Обычно делается на инкубаторе до отправки фермеру (проверяйте ветсправку!) |\n| **День 7** | Болезнь Ньюкасла (ND) + Инфекционный бронхит (IB) | Капли в нос/глаз или выпойка через воду | Формирование первичного иммунитета дыхательных путей |\n| **День 11 – 14** | Болезнь Гамборо (ИББ — инфекционная бурсальная болезнь) | Выпаивание через питьевую воду | Защита фабрициевой сумки (главного органа иммунитета птицы) |\n| **День 18 – 21** | Болезнь Ньюкасла (ревакцинация) / Гамборо (повторно) | Выпаивание через питьевую воду | Закрепление напряженного иммунитета до конца откорма |\n\n---\n\n## 3. Золотые правила выпаивания вакцин через воду\n90% неудач вакцинации у новичков связаны с тем, что живой вирус вакцины погибает еще в ведре до того, как цыпленок его выпьет:\n1. **Холодовая цепь (+2...+8°C):** Вакцину везите из ветаптеки в термосумке со льдом. Нагревание вакцины выше +10°C или замораживание убивает вирус.\n2. **Чистая вода без хлора:** Хлор в водопроводной воде убивает вирус за 1 минуту! Используйте родниковую воду или отстаивайте воду не менее 48 часов, обязательно добавляя молоко-стабилизатор.\n3. **Краситель-индикатор:** Используйте специальные таблетки со стабилизатором и синим пищевым красителем. Через 1–2 часа после вакцинации загляните в клювы цыплят: синий язык и зоб подтверждают, что птица действительно выпила вакцину.\n4. **Фронт поения:** Убедитесь, что все цыплята имеют одновременный доступ к воде, иначе сильные выпьют двойную дозу, а слабые не получат ничего.\n\n---\n\n## 4. Что запрещено делать во время вакцинации\n* Запрещено вакцинировать явно больную, вялую или переохлажденную птицу — вакцина вызовет вспышку болезни вместо иммунитета.\n* Запрещено давать антибиотики за 2 дня до и 2 дня после введения живой вакцины.\n* Запрещено разводить вакцину в ржавых или оцинкованных металлических ведрах — используйте только чистый пищевой пластик.\n"
  },
  {
    "filename": "08_diseases.md",
    "title": "Признаки болезни: когда срочно звать ветеринара",
    "content": "<!--\nИсточник: Клиническая диагностика инфекционных болезней птиц (FAO / Ветеринарный комитет РУз)\nПроверил: Главный ветеринарный консультант AgroZen\nДата: 2026-10-09\nСтатус: Утверждено\n-->\n\n# Признаки болезни: когда срочно звать ветеринара\n\n> **ГЛАВНОЕ ПРАВИЛО AGROZEN:** \n> Приложение не заменяет ветеринарного врача. Если у птицы появились признаки острой инфекции, самолечение «народными средствами» или наугад купленными антибиотиками приведёт к потере всей партии и денег. При первых опасных симптомах вызывайте ветеринара!\n\n---\n\n## 1. «Красные флаги» — симптомы экстренной опасности\n\nЕсли вы заметили хотя бы один из следующих признаков, действовать нужно немедленно:\n\n### 1. Резкий рост падежа (смертности)\n* **Норма:** В норме ежедневный падёж не должен превышать 0.1–0.15% от общего стада (например, 1–2 цыпленка в день на 1000 голов).\n* **ТРЕВОГА:** Если за одни сутки погибло **более 1% поголовья** (более 10 цыплят на 1000 голов) — это сигнал острой вспышки инфекции!\n\n### 2. Тяжелые дыхательные расстройства\n* Громкие хрипы, свист, клокотание или щелкающие звуки при дыхании, слышные во всем птичнике.\n* Птицы сидят, вытянув шею вверх, жадно хватая воздух широко открытым клювом.\n* Отеки головы, припухлость вокруг глаз («совиная голова»), пена или гной в уголках глаз.\n\n### 3. Опасные изменения помета\n* **Кровавый или темно-коричневый помет:** Верный признак острого кокцидиоза.\n* **Ярко-зеленый водянистый помет с пеной:** Признак болезни Ньюкасла или болезни Гамборо.\n* **Белый меловой помет (заклеивание клоаки):** Признак пуллороза (сальмонеллеза) у молодняка.\n\n### 4. Нервные явления и параличи\n* Искривление шеи (птица выворачивает голову на спину или вниз).\n* Падение на бок, дрожание головы, судороги лап.\n* Паралич крыльев и ног («посадка на шпагат»).\n\n---\n\n## 2. Что нужно сделать ДО приезда ветеринара\n1. **Изоляция:** Немедленно уберите подозрительных и мертвых птиц из общего помещения. Поместите трупы в плотный герметичный пакет в прохладное место до приезда врача для вскрытия.\n2. **Проверьте условия содержания:** Проверьте температуру, вентиляцию и доступ к воде. Иногда «болезнь» оказывается банальным перегревом или отказом поилок.\n3. **НЕ давайте антибиотики наугад!** Если вы напоите птицу сильным антибиотиком широкого спектра до взятия проб, ветеринарная лаборатория не сможет высеять возбудителя и определить его чувствительность к лекарствам.\n4. **Подготовьте данные:**\n   * Точный возраст птицы в днях;\n   * Количество заболевших и погибших за последние 3 дня;\n   * Название корма и фабрики;\n   * Названия вакцин, даты вакцинации и серии флаконов;\n   * Какая вода используется (водопровод, скважина, арык).\n\n---\n\n## 3. Биобезопасность при подозрении на вспышку\n* Не посещайте птичники ваших соседей и запретите вход любым посторонним людям в ваш двор.\n* Наденьте отдельную сменную обувь и одежду, которой вы пользуетесь только внутри сарая.\n* Опустите обувь в дезинфицирующий раствор на пороге.\n* Трупы павших птиц утилизируйте только по указанию ветврача (сжигание или захоронение в яме глубиной не менее 1.5 м с пересыпкой хлорной известью). Выбрасывать павшую птицу в арыки, мусорные баки или на улицу строго запрещено законом!\n"
  },
  {
    "filename": "feed.md",
    "title": "Кормление бройлеров по фазам",
    "content": "# Кормление бройлеров по фазам\n\nБройлеры имеют интенсивный обмен веществ. Кормление делится на три основные фазы:\n\n## Фазы кормления:\n1. **Старт (1–14 дни):**\n   - Сырой протеин: 21–23%\n   - Форма: мелкая крупка (1.5–2 мм)\n   - Способствует формированию внутренних органов и костяка.\n\n2. **Рост / Гровер (15–28 дни):**\n   - Сырой протеин: 19–20%\n   - Форма: гранула (2.5–3 мм)\n   - Интенсивный набор мышечной массы.\n\n3. **Финиш (29–42 дни):**\n   - Сырой протеин: 17.5–18.5%\n   - Форма: гранула (3–3.5 мм)\n   - Набор веса перед сдачей. Запрещено использовать антибиотики в этой фазе!\n\n## Важные правила:\n- Корм должен быть доступен круглосуточно.\n- Вода должна быть всегда чистой и прохладной. На 1 кг съеденного корма бройлер выпивает около 1.8–2 л воды.\n"
  },
  {
    "filename": "temperature.md",
    "title": "Температурный режим для бройлеров",
    "content": "# Температурный режим для бройлеров\n\nТемпература — ключевой фактор выживания цыплят в первые недели. У суточного цыпленка еще не развита собственная терморегуляция.\n\n## Температурный график по неделям:\n- **1-3 день:** 32-33°C (на уровне подстилки под брудером)\n- **4-7 день:** 30-31°C\n- **2 неделя (8-14 дни):** 27-29°C\n- **3 неделя (15-21 дни):** 24-26°C\n- **4 неделя (22-28 дни):** 21-23°C\n- **5-6 недели (29-42 дни):** 18-20°C\n\n## Поведение цыплят как главный индикатор:\n- **Оптимально:** цыплята равномерно распределены по помещению, активно едят, пьют и отдыхают.\n- **Холодно:** сбиваются в плотную кучу под обогревателем, громко пищат.\n- **Жарко:** разбегаются к краям, открывают клюв, тяжело дышат, распускают крылья.\n- **Сквозняк:** сбиваются в группу в одной стороне вдали от сквозняка.\n"
  },
  {
    "filename": "vaccination.md",
    "title": "Вакцинация бройлеров",
    "content": "# Вакцинация бройлеров\n\nСвоевременная вакцинация защищает стадо от массовой гибели.\n\n## Основной календарь вакцинации:\n1. **1-й день (в инкубаторе):**\n   - Болезнь Марека\n   - Инфекционный бронхит (ИБК)\n2. **7-й день:**\n   - Болезнь Ньюкасла (НБ) + Инфекционный бронхит (выпаивание или спрей)\n3. **12–14 день:**\n   - Болезнь Гамборо (ИББ) — метод выпаивания\n4. **20–22 день:**\n   - Ревакцинация против болезни Гамборо или Ньюкасла (по эпизоотической ситуации в районе)\n\n## Правила выпаивания вакцины:\n- За 2 часа до дачи вакцины птицу лишают воды (чтобы выпили за 1.5–2 часа).\n- Вода должна быть без хлора! Используйте обезжиренное молоко (2 г сухого молока на 1 л воды) для стабилизации вакцины.\n- Металлические поилки использовать запрещено.\n"
  },
  {
    "filename": "ventilation.md",
    "title": "Вентиляция птичника для бройлеров",
    "content": "# Вентиляция птичника для бройлеров\n\nПравильная вентиляция удаляет углекислый газ, аммиак и влагу, обеспечивая птичник свежим кислородом.\n\n## Требования:\n- В первые 7 дней: минимальная вентиляция (0.1–0.15 м/с), исключая сквозняки на уровне пола.\n- 2–4 недели: умеренная вентиляция с притоком свежего воздуха.\n- 5–6 недели: максимальная производительность, особенно в жаркий период.\n- Предельно допустимая концентрация аммиака: не более 15 ppm (если человек чувствует запах аммиака — норма уже превышена!).\n\n## Опасность жары:\nПри температуре выше 30°C используйте охлаждающие панели, туманообразование или полив крыши холодной водой.\n"
  }
];

export const KNOWLEDGE_ARTICLES_EN: KnowledgeArticle[] = [
  {
    "filename": "01_preparation.md",
    "title": "Barn Preparation Prior to Chick Placement",
    "content": "<!--\nSource: Ross-308 / Cobb-500 Broiler Management Manual & Uzbekistan Veterinary Committee Guidelines\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Barn Preparation Prior to Chick Placement\n\nOver 70% of broiler farming success is determined by how thoroughly the house is prepared before day-old chicks arrive. Placing chicks in damp, cold, or inadequately sanitized housing leads to heavy mortality within the first 10 days.\n\n---\n\n## 1. Mechanical Cleaning and Washing\nPreparation begins immediately after depopulating the previous batch:\n1. **Litter Removal:** Completely transport all old litter and manure at least 50 meters away from the poultry house.\n2. **Dry Cleaning:** Sweep dust, cobwebs, and down from ceilings, trusses, light fixtures, and fans. Dust harbors enormous bacterial and viral loads.\n3. **High-Pressure Washing:** Wash the entire house with high-pressure water (minimum 100–140 bar). Use a 1–2% detergent or washing soda solution to dissolve fatty residues, paying meticulous attention to wall-floor seams and corners.\n\n---\n\n## 2. Disinfection and Equipment Sanitation\nDisinfection is only effective on clean, fully dried surfaces:\n* **Wall and Ceiling Whitewashing:** Treat walls with a 20% fresh slaked lime suspension combined with 2–3% copper sulfate to eradicate fungi and bacteria.\n* **Wet Disinfection:** Apply certified broad-spectrum disinfectants (glutaraldehyde, quaternary ammonium, or Virocid formulations) following manufacturer specifications.\n* **Equipment Care:** Soak feeders, drinkers, and hoses in disinfectant solution, rinse thoroughly with fresh water, and sun-dry.\n* **Sanitary Downtime (\"All-In / All-Out\"):** After disinfection, keep the barn sealed and vacant for at least **4–7 days**.\n\n---\n\n## 3. Pest Exclusion and Wild Bird Biosecurity\nRodents carry Salmonella and Pasteurella, while wild birds vector Avian Influenza and Newcastle Disease:\n* Mesh all windows, eaves, and ventilation inlets with galvanized wire (aperture ≤ 1.5 cm).\n* Seal all foundation and wall crevices using mortar reinforced with crushed glass.\n* Set tamper-proof rodent bait stations along the exterior building perimeter.\n\n---\n\n## 4. Bedding: Selection and Depth\nBroilers spend their entire life cycle on bedding. Cold or wet litter induces footpad dermatitis, ascites, and systemic infection.\n* **Material:** Ideal choices are dust-free, dry, medium-to-coarse wood shavings (conifer or hardwood) or clean chopped wheat straw.\n* **Layer Depth:** Winter and early spring: **7–10 cm**; Summer: **5–7 cm**.\n* **Requirements:** Bedding must be completely dry (moisture < 15%), mold-free, and odorless. Avoid fine sawdust; chicks ingest it, causing crop impaction.\n\n---\n\n## 5. Barn Pre-Heating (24–48 Hours Ahead)\nA common novice mistake is activating heating just 2 hours before arrival. Air warms quickly, but concrete floors remain freezing cold.\n* **24–48 Hours Prior:** Ignite heaters (gas brooders, space heaters, radiant tubes).\n* **Floor Temperature:** At placement, bedding surface temperature must measure **30–32°C**, and air temperature at chick height must be **33–34°C**.\n* If a chick sits on cold flooring, internal organs chill, yolk sac absorption fails, and systemic sepsis follows.\n\n---\n\n## 6. Pre-Placement Readiness Checklist\nBefore dispatching transport to pick up chicks, verify:\n- [ ] Heating operates stably with bedding temperature at 30–32°C.\n- [ ] Drinkers are filled with fresh water at room temperature (20–22°C).\n- [ ] Starter crumb feed is distributed on paper brooding sheets and initial feeder pans.\n- [ ] Lighting is set to full intensity (30–40 lux).\n- [ ] Minimum ventilation is tuned with zero floor drafts.\n- [ ] Calibrated thermometers and hygrometers are set at chick eye level (5–8 cm above floor).\n- [ ] Footwear disinfection mat is prepared at the entrance.\n"
  },
  {
    "filename": "02_first_days.md",
    "title": "Chick Placement and the First 3 Days",
    "content": "<!--\nSource: Ross-308 / Cobb-500 Broiler Management Handbook\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Chick Placement and the First 3 Days\n\nThe first 72 hours of a broiler chick's life directly determine harvest weight. If chicks fail to quadruple their initial hatch weight by Day 7 (target: ≥ 180 g), this growth deficit cannot be recovered by late feeding or medications.\n\n---\n\n## 1. Chick Unloading and Quality Assessment\n* **Unloading Speed:** Unload chick boxes promptly without rough movements. Never drop boxes to the floor.\n* **Initial Culling:** Inspect batch quality upon delivery. A healthy day-old chick:\n  * Weighs between 40–44 grams;\n  * Stands firmly and alertly on its legs with bright, clean eyes;\n  * Has a fully healed, dry navel free from scabs and bleeding;\n  * Possesses a soft, pliable abdomen without bloating;\n  * Has clean, dry, fluffy down with no adhering shell fragments.\n* Isolate weak or deformed chicks immediately under dedicated warmth or cull humanely.\n\n---\n\n## 2. First 2 Hours: Water Only!\nChicks arriving from hatchery transit are severely dehydrated. **Water takes absolute priority over feed!**\n* **Water Temperature:** Strictly maintained at **20–22°C**. Freezing water causes visceral hypothermia and gut cramping, while water above 25°C rapidly cultivates bacteria.\n* **First Drink:** Adding glucose (20–30 g per liter) or vitamin-electrolyte stress packs assists rapid transport recovery.\n* **Guiding to Drinkers:** Gently dip the beaks of a few chicks into drinkers — flock peers rapidly mimic them.\n* Drinker availability: 1 bell drinker per 50 chicks or 1 nipple per 10–12 birds.\n\n---\n\n## 3. Feed Presentation (2 Hours Post-Watering)\nOnly after the entire flock has drunk water should feed be introduced.\n* **Brooding Paper:** Spread dedicated textured brooding paper covering at least 20–30% of the brooding area (do not use ink newsprint as newsprint ink is toxic).\n* **Paper Rustle:** Chicks running over the paper generate rustling sounds, naturally drawing peers to explore feed crumbs.\n* **Feed Texture:** Use only high-quality starter crumbs (1.5–2 mm particle size). Powdery flour-like feed obstructs nostrils and beaks.\n* Replenish feed frequently in modest amounts (5–6 times daily) to preserve aroma and cleanliness.\n\n---\n\n## 4. Lighting Regimen in Early Days\n* **Days 1–3:** 23 hours of bright light (30–40 lux) with 1 hour of total darkness.\n* The 1 hour of darkness conditions chicks to darkness, preventing catastrophic piling and smothering during sudden power outages.\n\n---\n\n## 5. The Crop Fill Test (Primary Health Metric)\nThis is the single most objective field test of placement quality:\n* **8 Hours Post-Placement:** Sample 50 chicks from varied zones. At least **80%** must have soft, pliable crops filled with blended feed and water (like a moist sponge).\n* **24 Hours Post-Placement:** At least **95–100%** must display full crops.\n* *Hard crop:* Chicks found feed but lack water (water too cold or lines too high).\n* *Watery crop:* Chicks drinking but failing to find feed (insufficient feeder space or inadequate light).\n* *Empty crop:* Chicks chilled or experiencing severe stress.\n\n---\n\n## 6. Reading Chick Behavior for Climate Assessment\nThermometers can misread, but chicks never lie:\n* **Ideal:** Chicks evenly dispersed across the brooding floor, eating, drinking, or resting stretched out. Soft, contented chirping.\n* **Cold:** Huddled in dense clusters directly beneath heaters, chirping distressfully. High risk of bottom birds smothering.\n* **Hot:** Fleeing heat sources toward perimeter walls, panting with open beaks and outstretched wings. Feed intake ceases.\n* **Drafts:** Clustered against one corner away from cold incoming air currents.\n"
  },
  {
    "filename": "03_temperature.md",
    "title": "Temperature and Humidity Standards",
    "content": "<!--\nSource: Poultry Microclimate Standards (Ross Broiler Management Handbook)\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Temperature and Humidity Standards\n\nDay-old broiler chicks cannot regulate their internal body temperature. During the first 10–14 days, thermoregulation depends entirely on the housing microclimate. An error of just 2–3 degrees Celsius can trigger sudden mortality or permanent growth stunting.\n\n---\n\n## 1. Broiler Temperature and Humidity Schedule\n\nMeasurements are taken strictly at **chick back level** (5–8 cm from the floor), never at the ceiling!\n\n| Bird Age | Air Temperature (°C) | Bedding Temperature (°C) | Relative Humidity (%) |\n| :--- | :--- | :--- | :--- |\n| **Day 1** | **33 – 34°C** | 30 – 32°C | 60 – 70% |\n| **Day 3** | **33°C** | 30°C | 60 – 70% |\n| **Day 7 (Week 1)** | **31 – 32°C** | 29 – 30°C | 60 – 65% |\n| **Day 14 (Week 2)** | **28 – 29°C** | 27 – 28°C | 60 – 65% |\n| **Day 21 (Week 3)** | **26 – 27°C** | 25 – 26°C | 55 – 60% |\n| **Day 28 (Week 4)** | **23 – 24°C** | 22 – 23°C | 55 – 60% |\n| **Day 35 (Week 5)** | **21 – 22°C** | 20 – 21°C | 55 – 65% |\n| **Day 42 (Week 6)** | **19 – 20°C** | 19 – 20°C | 55 – 65% |\n\n---\n\n## 2. Bedding Temperature Outweighs Air Temperature\nWhy floor temperature is vital:\n* Chicks rest their feet and bellies on the litter 100% of the time.\n* If house air registers 34°C but concrete flooring under thin litter sits at 22°C, chicks suffer hypothermia within 3–4 hours.\n* Chilled footpads drain core blood flow, inhibiting yolk sac absorption and inciting fatal yolk sac peritonitis (primary cause of mortality on Days 3–5).\n* **Field Rule:** Touch a chick's footpad to your cheek: the chick's foot must feel pleasantly warm! If cold, litter has not preheated properly.\n\n---\n\n## 3. Relative Humidity (RH)\n* **Week 1 (60–70%):** Hatcheries maintain high humidity (70–80%). If barn air is dry (< 50%), chicks lose pulmonary moisture rapidly, down parches, and respiratory tracts inflame. Humidify walkways or mist air to preserve humidity.\n* **From Week 2 Onward (55–65%):** High humidity (> 70%) combined with warmth (25–28°C) is hazardous — litter cakes, ammonia spikes, and coccidia proliferate.\n\n---\n\n## 4. Managing Diurnal Temperature Fluctuations\nIn Uzbekistan's continental climate, day-night temperatures often swing by 15–20°C (e.g. +25°C daytime down to +5°C night).\n* **Critical Mistake:** Shutting off heat overnight or leaving ventilation shutters wide open during night cold snaps.\n* Diurnal fluctuations inside the poultry barn should never exceed **1.5–2°C**.\n* Severe swings trigger viral respiratory complexes (IB, mycoplasma) and metabolic stress that halts weight gain.\n\n---\n\n## 5. Sensor and Thermometer Placement\n* Install sensors strictly at chick head/back level.\n* Maintain at least 3 checkpoints: under the brooder/heater, near perimeter walls, and beside drinker lines.\n* Shield sensors from radiant infrared lamps to avoid falsely elevated readings.\n"
  },
  {
    "filename": "04_ventilation.md",
    "title": "Ventilation and Heat Stress Management",
    "content": "<!--\nSource: Poultry Microclimate and Ventilation Guide (Ross/Cobb)\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Ventilation and Heat Stress Management\n\nVentilation in a poultry house solves 5 critical objectives: providing oxygen, exhausting carbon dioxide, eliminating toxic ammonia, removing excess humidity, and cooling the flock. In Uzbekistan's intense climate, correct ventilation is a life-or-death factor for broilers beyond 25 days of age.\n\n---\n\n## 1. Minimum Ventilation (First 2–3 Weeks)\nDuring early brooding, the primary goal is refreshing air without exhausting valuable heat or creating floor-level drafts.\n* **Principle:** Incoming cold outdoor air must enter through high ceiling inlets, mix with upper thermal air layers, and gently descend warmed toward chick height.\n* **Air Velocity:** At chick level, air speed must never exceed **0.15–0.2 m/s** during the first 2 weeks.\n* **Drafts Kill:** Cold drafts flowing directly along the floor chill chicks, causing corner pile-ups and suffocation.\n\n---\n\n## 2. Ammonia Hazards ($NH_3$) and Damp Litter\nAmmonia is generated by bacterial fermentation of uric acid in damp litter.\n* **Farmer's Field Test:** If entering the barn burns your eyes or causes a sharp nasal sting, ammonia exceeds 20 ppm!\n* For broilers, this is catastrophic: ammonia strips tracheal mucosal cilia, enabling E. coli and mycoplasma to penetrate deep into air sacs, causing chronic respiratory complexes.\n* **Action:** Immediately increase fresh air intake and replace damp litter spots with fresh dry shavings.\n\n---\n\n## 3. Tunnel Ventilation and Heat Stress (After Day 25)\nBroilers over 4 weeks weigh > 1.5 kg. Birds possess no sweat glands, and dense plumage retains body heat. Their sole cooling mechanisms are panting (respiratory evaporative loss) and convective heat transfer from airspeed.\n* **Tunnel Effect:** Large exhaust fans extract air from one end of the barn, pulling a longitudinal wind stream at **2.0–2.5 m/s**.\n* At this airspeed, convective heat loss produces a chill effect making birds perceive temperatures 4–6°C lower than actual ambient air.\n\n---\n\n## 4. Evaporative Cooling Pads and Fogging\nWhen outdoor temperatures in Uzbekistan climb above 35–38°C, fan circulation alone is insufficient (hot airflow acts like a hairdryer):\n* **Cooling Pads:** Water flows over cellulose paper pads at air inlets. Hot dry outside air passes through, evaporates moisture, and drops 6–10°C in temperature.\n* **Golden Rule:** Activate pad water ONLY when relative humidity is below 70% and temperature is above 28°C. If barn air is already humid, evaporation stops and suffocating heat stroke occurs.\n\n---\n\n## 5. Practical Hot-Weather Countermeasures for Farmers:\n1. **Roof Whitewashing:** Whitewash outer roof surfaces with lime — reflected solar radiation reduces interior barn heat by 3–4°C.\n2. **Night Feeding Shift:** During peak heat (12:00 to 17:00), elevate feed lines or dim lighting. Digestive heat increment triggers fatal heat stroke. Feed birds during cool night and early dawn hours.\n3. **Flushing Water Lines:** Keep drinker lines cool (18–20°C). Regularly flush stagnated, hot pipe water during peak afternoon hours.\n4. **Vitamin C & Electrolytes:** Provide sodium bicarbonate, potassium chloride, and Vitamin C in drinking water 2–3 days prior to forecasted heatwaves.\n"
  },
  {
    "filename": "05_feeding.md",
    "title": "Broiler Feeding Phases: Starter, Grower, and Finisher",
    "content": "<!--\nSource: Broiler Nutrition Guidelines (Ross/Cobb Nutrition Guidelines)\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Broiler Feeding Phases: Starter, Grower, and Finisher\n\nModern broiler genetics enable a chick to grow from 42 grams to 2.5 kilograms within just 6 weeks. However, achieving this potential requires balanced, commercial crumbled and pelleted rations. Feeding homemade ground grain mixtures or boiled eggs results in severe amino acid deficiencies, rickets, and 50% stunted body weight.\n\n---\n\n## 1. The Three Primary Feeding Phases\n\n| Parameter | Phase 1: Starter | Phase 2: Grower | Phase 3: Finisher |\n| :--- | :--- | :--- | :--- |\n| **Duration** | **Days 1 – 10 (or 14)** | **Days 11 (or 15) – 28** | **Days 29 – 42** |\n| **Feed Form** | Fine Crumb (1.5–2 mm) | Pellets (2.5–3 mm) | Pellets (3–3.5 mm) |\n| **Crude Protein** | **21 – 23%** | **19 – 20%** | **17.5 – 18.5%** |\n| **Metabolizable Energy** | 3000 – 3050 kcal/kg | 3100 – 3150 kcal/kg | 3200 – 3250 kcal/kg |\n| **Primary Goal** | Organ, skeletal, digestive, and immune development | Rapid muscle and skeletal frame accretion | Breast and thigh meat deposition, market weight |\n\n---\n\n## 2. The 3-Day Feed Transition Protocol\nA broiler's digestive tract is acutely sensitive to abrupt ration shifts. Sudden changes cause dysbiosis, wet droppings, and feed refusal.\n* Always transition over **3 consecutive days**:\n  * **Day 1 of transition:** 70% current feed + 30% new feed;\n  * **Day 2 of transition:** 50% current feed + 50% new feed;\n  * **Day 3 of transition:** 25% current feed + 75% new feed;\n  * **Day 4:** 100% new feed.\n\n---\n\n## 3. Daily Feed Intake per Bird Benchmark\n\n| Age (Week) | Daily Feed per Bird (g) | Cumulative Intake (g) |\n| :--- | :--- | :--- |\n| **Week 1 (Days 1–7)** | 15 – 27 g | ~148 g |\n| **Week 2 (Days 8–14)** | 31 – 54 g | ~448 g |\n| **Week 3 (Days 15–21)** | 60 – 98 g | ~999 g |\n| **Week 4 (Days 22–28)** | 105 – 145 g | ~1871 g |\n| **Week 5 (Days 29–35)** | 151 – 185 g | ~3051 g |\n| **Week 6 (Days 36–42)** | 190 – 215 g | ~4471 g |\n\n*Over the full 42-day cycle, one broiler consumes approximately **4.0 – 4.5 kg** of quality balanced feed.*\n\n---\n\n## 4. Feed Conversion Ratio (FCR)\nFeed Conversion Ratio is the premier benchmark of farm profitability:\n$$\text{FCR} = \frac{\text{Total Feed Consumed (kg)}}{\text{Total Live Body Weight (kg)}}$$\n* **Excellent FCR:** 1.6 – 1.7 (1.6–1.7 kg feed required per 1 kg live weight gain).\n* **Average FCR:** 1.75 – 1.85.\n* **Loss-making FCR:** > 2.0 (feed wasted due to disease, substandard nutrition, or spillage).\n\n---\n\n## 5. Feeder Pan Height Management\n* **Feeder Height:** The lip of the feeder pan or trough must align exactly with the bird's **back/crop level**. Low feeders permit birds to flick feed with beaks and feet, discarding up to 15% directly into the litter!\n* **Daily Clean-Out:** Permit birds to clean out feeder pans completely for 30–45 minutes once daily to prevent stale fine dust accumulation and mycotoxin formation.\n"
  },
  {
    "filename": "06_water.md",
    "title": "Water Supply and Drinking System Management",
    "content": "<!--\nSource: Poultry Water Supply Standards (Ross Broiler Management Manual)\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Water Supply and Drinking System Management\n\nWater is the most crucial yet frequently neglected nutrient for broilers. Birds can survive days without feed, but perish within 24 hours without water. Restricting water immediately stops feed assimilation and halts growth.\n\n---\n\n## 1. Water Demand and the \"Water : Feed\" Ratio\n* Under comfortable temperatures (20–22°C), broilers drink **1.8–2.0 times more** water by weight than dry feed consumed.\n* When barn temperatures exceed 30°C, water consumption increases **2.5–3.0 times**.\n* A sudden dip in daily water consumption is the earliest clinical herald of impending disease, manifesting 24–48 hours before visible symptoms or mortality.\n\n---\n\n## 2. Drinking Water Quality Standards\nWater offered to broilers must meet the same sanitary standards as potable human tap water:\n* **Temperature:** Optimally **18–21°C**. Water above 25°C is unpalatable to birds and fosters bacterial growth. Water below 14°C causes gut spasms and chilling.\n* **Acidity (pH):** Ideal range is **6.5 – 7.5**. Water exceeding pH 8.0 impairs digestive enzyme efficacy.\n* **Microbiological Purity:** Zero coliforms (E. coli) and Salmonella.\n* **Biofilm in Water Lines:** Bacterial slime and vitamin residues coat inner PVC pipes. Flush lines under pressure every 2 weeks, and sanitize thoroughly between flocks with stabilized hydrogen peroxide or organic acids.\n\n---\n\n## 3. Selecting and Adjusting Drinker Systems\n### Nipple Drinkers (Industry Best Practice)\n* **Density:** 1 nipple with drip cup per **10–12 birds**.\n* **Height Adjustment:**\n  * Days 1–3: Nipple at chick eye level (bird points beak upward at a 45° angle).\n  * Day 4 onward: Birds stretch upward at a 65–75° angle while feet remain planted flat on the floor (birds must not stand on tiptoes).\n* **Water Pressure:** During Week 1, maintain low pressure (water column 10–15 cm) for effortless triggering. By Week 5, increase column to 30–35 cm.\n\n### Bell / Vacuum Drinkers\n* Common in smaller setups: 1 bell drinker per 50 chicks.\n* Requires manual scrubbing and refilling at least twice daily.\n* Never place bell drinkers directly on loose litter — rest them on plastic platforms to avoid contamination.\n\n---\n\n## 4. Water Administration Protocols for Vaccines and Vitamins\n1. **48 Hours Prior to Vaccination:** Terminate all water acidifiers, chlorine, and sanitizers (which destroy live vaccine viruses).\n2. **Water Deprivation (Thirsting):** Withdraw water 1.5–2 hours prior to vaccination (in extreme heat, no more than 1 hour).\n3. **Stabilizer:** Add non-fat dry skimmed milk powder (2 g per liter) to neutralize residual heavy metals and chlorine traces.\n4. The entire vaccine volume must be consumed within **1.5–2 hours**.\n"
  },
  {
    "filename": "07_vaccination.md",
    "title": "Broiler Vaccination: Schedule and Field Principles",
    "content": "<!--\nSource: Central Asian Broiler Immunoprophylaxis Framework\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Broiler Vaccination: Schedule and Field Principles\n\n> **IMPORTANT NOTICE:** \n> AgroZen does not prescribe vaccine strains or medication dosages. Vaccination is a state veterinary regulation measure. Finalize your specific farm schedule, strain selection (LaSota, Clone, Winterfield), and local disease status with your certified district veterinarian!\n\n---\n\n## 1. Why Is Vaccination Crucial for Broilers?\nBroilers live only 40–45 days, but their immunological system is exceptionally delicate. Avian viral diseases (Newcastle Disease, Gumboro / IBD, Infectious Bronchitis) propagate like wildfire: if Newcastle Disease enters an unimmunized barn, **90–100% of the flock can perish within 48–72 hours**. Viral infections cannot be treated with antibiotics — only prophylactic vaccination prevents catastrophic loss.\n\n---\n\n## 2. Standard Broiler Vaccination Timeline\n\n| Day | Disease | Method | Field Note |\n| :--- | :--- | :--- | :--- |\n| **Day 1** | Marek's Disease, Infectious Bronchitis (IB), Newcastle Disease (ND) | Coarse spray or subcutaneous injection at hatchery | Handled at the hatchery prior to chick dispatch (verify veterinary certificate) |\n| **Day 7** | Newcastle Disease (ND) + Infectious Bronchitis (IB) | Eye/nose drops or drinking water | Establishes mucosal respiratory barrier |\n| **Days 11 – 14** | Gumboro Disease (IBD — Infectious Bursal Disease) | Drinking water | Protects the Bursa of Fabricius (primary immune organ) |\n| **Days 18 – 21** | Newcastle Disease booster / Gumboro revaccination | Drinking water | Secures immune titer through slaughter |\n\n---\n\n## 3. Golden Rules of Drinking Water Vaccination\nOver 90% of field vaccine failures stem from killing the live viral antigen before birds consume it:\n1. **Cold Chain (+2 to +8°C):** Transport vaccine vials from the pharmacy inside insulated ice coolers. Exposure above +10°C or freezing destroys live viral titers.\n2. **Chlorine-Free Water:** Tap water chlorine kills live virus particles within 60 seconds! Use untreated spring water or de-chlorinated water rested 48 hours, fortified with milk powder stabilizer.\n3. **Blue Dye Indicator:** Use commercial blue dye stabilizer tablets. 1–2 hours following vaccination, inspect chick beaks: a blue tongue and crop verify genuine vaccine ingestion.\n4. **Adequate Drinking Space:** Ensure sufficient drinker access so all birds drink concurrently, preventing dominant chicks from overconsuming while timid birds receive none.\n\n---\n\n## 4. Vaccination Contraindications\n* Never vaccinate clinically sick, chilled, or severely stressed birds — the live vaccine will trigger outright disease flare-ups.\n* Never administer antibacterial drugs 2 days before and 2 days after live viral vaccines.\n* Never prepare vaccine solutions in galvanized or rusted metal containers — use food-grade plastic only.\n"
  },
  {
    "filename": "08_diseases.md",
    "title": "Disease Signs: When to Immediately Consult a Veterinarian",
    "content": "<!--\nSource: Clinical Diagnostics of Avian Infectious Diseases (FAO / Uzbekistan State Veterinary Committee)\nVerified by: AgroZen Chief Veterinary Consultant\nDate: 2026-10-09\nStatus: Approved\n-->\n\n# Disease Signs: When to Immediately Consult a Veterinarian\n\n> **CORE AGROZEN PRINCIPLE:** \n> AgroZen does not replace a veterinary physician. If a flock shows acute infectious symptoms, self-treating with blind antibiotic dosing will decimate the flock and cause grave financial loss. Contact your veterinarian at the first dangerous sign!\n\n---\n\n## 1. Red Flag Emergency Symptoms\n\nIf you observe any of the following signs, take immediate action:\n\n### 1. Acute Mortality Spike\n* **Normal Range:** Baseline daily mortality should never exceed 0.1–0.15% of the total flock (e.g. 1–2 birds per day out of 1,000).\n* **CRITICAL ALERT:** If daily mortality surpasses **1% in 24 hours** (> 10 birds out of 1,000), an acute disease outbreak is actively spreading!\n\n### 2. Severe Respiratory Distress\n* Loud rattling, whistling, gurgling, or clicking sounds audible across the entire poultry barn.\n* Birds craning necks upward, gasping desperately for breath through open beaks.\n* Facial edema, periocular swelling (\"owl head\"), foamy or purulent ocular discharge.\n\n### 3. Alarm Signs in Droppings\n* **Bloody or dark reddish-brown droppings:** Hallmarks of acute coccidiosis.\n* **Vivid green, watery frothy droppings:** Highly indicative of Newcastle Disease or Gumboro Disease.\n* **Chalky white diarrhea pasting the vent:** Sign of pullorum disease (Salmonella pullorum) in young stock.\n\n### 4. Neurological Dysfunction and Paralysis\n* Torticollis / twisted neck (birds twisting head backward or upside down).\n* Loss of balance, head tremors, clonic leg convulsions.\n* Complete wing and leg paralysis (birds stuck in a split posture).\n\n---\n\n## 2. Mandatory Protocol BEFORE the Veterinarian Arrives\n1. **Isolation:** Immediately remove suspect and dead birds from the flock. Seal dead birds in clean airtight bags in a cool location for veterinary necropsy.\n2. **Review Environmental Equipment:** Inspect temperature, airflow, and drinker lines. Occasionally \"disease outbreaks\" stem from sudden drinker line blockages or extreme overheating.\n3. **NEVER Administer Blind Antibiotics!** Dosing flocks with broad-spectrum antimicrobials before diagnostic sampling renders veterinary lab cultures sterile, preventing accurate pathogen isolation and sensitivity testing.\n4. **Compile Flock Records:**\n   * Exact flock age in days;\n   * Counts of sick and dead birds over the preceding 3 days;\n   * Feed manufacturer, ration phase, and batch lot;\n   * Administered vaccine brand names, dates, and serial batch numbers;\n   * Water supply source (piped municipal, deep borehole, canal).\n\n---\n\n## 3. Biosecurity Rules During Suspected Outbreaks\n* Do not enter neighboring poultry farms and forbid outside visitors from entering your premises.\n* Don dedicated protective footwear and overalls used solely inside that specific barn.\n* Step thoroughly into disinfection mats placed at entryways.\n* Dispose of mortalities strictly according to veterinary direction (incineration or deep burial ≥ 1.5 meters layered with bleaching powder). Discarding carcasses into open canals, streets, or trash heaps is illegal and spreads disease.\n"
  },
  {
    "filename": "feed.md",
    "title": "Broiler Phase Feeding",
    "content": "# Broiler Phase Feeding\n\nBroilers possess rapid metabolic growth rates. Feeding is structured into three primary phases:\n\n## Feeding Phases:\n1. **Starter (Days 1–14):**\n   - Crude protein: 21–23%\n   - Form: fine crumbs (1.5–2 mm)\n   - Stimulates skeletal framing and visceral organ development.\n\n2. **Grower (Days 15–28):**\n   - Crude protein: 19–20%\n   - Form: pellets (2.5–3 mm)\n   - Rapid accretion of lean muscle mass.\n\n3. **Finisher (Days 29–42):**\n   - Crude protein: 17.5–18.5%\n   - Form: pellets (3–3.5 mm)\n   - Final weight gain prior to processing. Antibiotics are strictly banned during this withdrawal phase!\n\n## Golden Rules:\n- Feed must remain available 24/7.\n- Clean, cool water must always accompany feed. For every 1 kg of dry feed eaten, broilers consume roughly 1.8–2.0 liters of water.\n"
  },
  {
    "filename": "temperature.md",
    "title": "Temperature Guidelines for Broilers",
    "content": "# Temperature Guidelines for Broilers\n\nTemperature is the decisive factor in chick survival during the initial weeks. A day-old chick has no physiological internal thermoregulation.\n\n## Temperature Schedule by Week:\n- **Days 1–3:** 32–33°C (at litter level under the brooder)\n- **Days 4–7:** 30–31°C\n- **Week 2 (Days 8–14):** 27–29°C\n- **Week 3 (Days 15–21):** 24–26°C\n- **Week 4 (Days 22–28):** 21–23°C\n- **Weeks 5–6 (Days 29–42):** 18–20°C\n\n## Chick Behavior as the Ultimate Gauge:\n- **Optimal:** Chicks evenly dispersed across the barn, actively feeding, drinking, and resting comfortably.\n- **Cold:** Huddling in tight clusters under heaters, loud distress chirping.\n- **Hot:** Moving away towards walls, panting with open beaks, spreading wings.\n- **Drafts:** Crowding together in one sector away from cold airflow.\n"
  },
  {
    "filename": "vaccination.md",
    "title": "Broiler Vaccination",
    "content": "# Broiler Vaccination\n\nTimely immunization protects the entire flock against mass mortality.\n\n## Core Vaccination Timeline:\n1. **Day 1 (at hatchery):**\n   - Marek's Disease\n   - Infectious Bronchitis (IB)\n2. **Day 7:**\n   - Newcastle Disease (ND) + Infectious Bronchitis (drinking water or coarse spray)\n3. **Days 12–14:**\n   - Gumboro Disease (IBD) — via drinking water\n4. **Days 20–22:**\n   - Revaccination against Gumboro or Newcastle (based on regional veterinary guidance)\n\n## Water Vaccination Rules:\n- Deprive birds of water 2 hours before administration (ensuring entire solution is consumed within 1.5–2 hours).\n- Water must be completely chlorine-free! Add skimmed milk powder (2 g dry milk per 1 liter water) to stabilize the live viral vaccine.\n- Metal drinkers and buckets are strictly prohibited.\n"
  },
  {
    "filename": "ventilation.md",
    "title": "Broiler Barn Ventilation",
    "content": "# Broiler Barn Ventilation\n\nProper ventilation eliminates carbon dioxide, ammonia, and moisture, supplying the flock with fresh oxygen.\n\n## Primary Requirements:\n- First 7 days: Minimum ventilation (0.1–0.15 m/s), eliminating drafts at floor level.\n- Weeks 2–4: Moderate ventilation providing steady fresh air exchange.\n- Weeks 5–6: Maximum fan output, especially during high ambient summer conditions.\n- Maximum allowable ammonia concentration: 15 ppm (if humans perceive ammonia odor, levels are already excessive!).\n\n## Heat Stress Protection:\nWhen temperatures exceed 30°C, employ evaporative cooling pads, fogging misters, or roof cold-water sprinkling.\n"
  }
];

export const NORMS_DATA = {
  "breed": "Ross-308 / Cobb-500",
  "critical_thresholds": {
    "daily_mortality_alert_percent": 1,
    "cumulative_mortality_warning_percent": 4,
    "weight_deficit_alert_percent": 15,
    "feed_drop_alert_percent": 20
  },
  "weekly_norms": [
    {
      "week": 1,
      "target_weight_g": 185,
      "daily_feed_g": 27,
      "cumulative_feed_g": 165,
      "temperature_c": 29.5,
      "temp_celsius": 29.5,
      "humidity_percent": 65,
      "mortality_threshold_percent": 1
    },
    {
      "week": 2,
      "target_weight_g": 510,
      "daily_feed_g": 54,
      "cumulative_feed_g": 540,
      "temperature_c": 26.5,
      "temp_celsius": 26.5,
      "humidity_percent": 60,
      "mortality_threshold_percent": 0.6
    },
    {
      "week": 3,
      "target_weight_g": 1055,
      "daily_feed_g": 98,
      "cumulative_feed_g": 1225,
      "temperature_c": 23,
      "temp_celsius": 23,
      "humidity_percent": 60,
      "mortality_threshold_percent": 0.5
    },
    {
      "week": 4,
      "target_weight_g": 1745,
      "daily_feed_g": 145,
      "cumulative_feed_g": 2240,
      "temperature_c": 20.5,
      "temp_celsius": 20.5,
      "humidity_percent": 60,
      "mortality_threshold_percent": 0.4
    },
    {
      "week": 5,
      "target_weight_g": 2480,
      "daily_feed_g": 185,
      "cumulative_feed_g": 3535,
      "temperature_c": 19,
      "temp_celsius": 19,
      "humidity_percent": 60,
      "mortality_threshold_percent": 0.4
    },
    {
      "week": 6,
      "target_weight_g": 3125,
      "daily_feed_g": 215,
      "cumulative_feed_g": 5040,
      "temperature_c": 18,
      "temp_celsius": 18,
      "humidity_percent": 60,
      "mortality_threshold_percent": 0.4
    }
  ],
  "daily_norms": {
    "1": {
      "weight_g": 42,
      "feed_g": 12,
      "water_ml": 24,
      "temp_c": 33,
      "mortality_max_percent": 0.3
    },
    "2": {
      "weight_g": 56,
      "feed_g": 15,
      "water_ml": 30,
      "temp_c": 32.5,
      "mortality_max_percent": 0.3
    },
    "3": {
      "weight_g": 73,
      "feed_g": 18,
      "water_ml": 36,
      "temp_c": 32,
      "mortality_max_percent": 0.25
    },
    "4": {
      "weight_g": 95,
      "feed_g": 21,
      "water_ml": 42,
      "temp_c": 31.5,
      "mortality_max_percent": 0.25
    },
    "5": {
      "weight_g": 120,
      "feed_g": 23,
      "water_ml": 46,
      "temp_c": 31,
      "mortality_max_percent": 0.2
    },
    "6": {
      "weight_g": 150,
      "feed_g": 25,
      "water_ml": 50,
      "temp_c": 30,
      "mortality_max_percent": 0.2
    },
    "7": {
      "weight_g": 185,
      "feed_g": 27,
      "water_ml": 54,
      "temp_c": 29.5,
      "mortality_max_percent": 0.2
    },
    "8": {
      "weight_g": 220,
      "feed_g": 31,
      "water_ml": 62,
      "temp_c": 29,
      "mortality_max_percent": 0.15
    },
    "9": {
      "weight_g": 260,
      "feed_g": 35,
      "water_ml": 70,
      "temp_c": 28.5,
      "mortality_max_percent": 0.15
    },
    "10": {
      "weight_g": 305,
      "feed_g": 39,
      "water_ml": 78,
      "temp_c": 28,
      "mortality_max_percent": 0.15
    },
    "11": {
      "weight_g": 350,
      "feed_g": 43,
      "water_ml": 86,
      "temp_c": 27.5,
      "mortality_max_percent": 0.12
    },
    "12": {
      "weight_g": 400,
      "feed_g": 47,
      "water_ml": 94,
      "temp_c": 27,
      "mortality_max_percent": 0.12
    },
    "13": {
      "weight_g": 455,
      "feed_g": 51,
      "water_ml": 102,
      "temp_c": 26.8,
      "mortality_max_percent": 0.1
    },
    "14": {
      "weight_g": 510,
      "feed_g": 54,
      "water_ml": 108,
      "temp_c": 26.5,
      "mortality_max_percent": 0.1
    },
    "15": {
      "weight_g": 575,
      "feed_g": 60,
      "water_ml": 120,
      "temp_c": 26,
      "mortality_max_percent": 0.1
    },
    "16": {
      "weight_g": 645,
      "feed_g": 66,
      "water_ml": 132,
      "temp_c": 25.5,
      "mortality_max_percent": 0.08
    },
    "17": {
      "weight_g": 720,
      "feed_g": 72,
      "water_ml": 144,
      "temp_c": 25,
      "mortality_max_percent": 0.08
    },
    "18": {
      "weight_g": 800,
      "feed_g": 78,
      "water_ml": 156,
      "temp_c": 24.5,
      "mortality_max_percent": 0.08
    },
    "19": {
      "weight_g": 880,
      "feed_g": 85,
      "water_ml": 170,
      "temp_c": 24,
      "mortality_max_percent": 0.08
    },
    "20": {
      "weight_g": 965,
      "feed_g": 91,
      "water_ml": 182,
      "temp_c": 23.5,
      "mortality_max_percent": 0.07
    },
    "21": {
      "weight_g": 1055,
      "feed_g": 98,
      "water_ml": 196,
      "temp_c": 23,
      "mortality_max_percent": 0.07
    },
    "22": {
      "weight_g": 1145,
      "feed_g": 105,
      "water_ml": 210,
      "temp_c": 22.5,
      "mortality_max_percent": 0.07
    },
    "23": {
      "weight_g": 1240,
      "feed_g": 112,
      "water_ml": 224,
      "temp_c": 22,
      "mortality_max_percent": 0.06
    },
    "24": {
      "weight_g": 1335,
      "feed_g": 119,
      "water_ml": 238,
      "temp_c": 21.8,
      "mortality_max_percent": 0.06
    },
    "25": {
      "weight_g": 1435,
      "feed_g": 126,
      "water_ml": 252,
      "temp_c": 21.5,
      "mortality_max_percent": 0.06
    },
    "26": {
      "weight_g": 1535,
      "feed_g": 132,
      "water_ml": 264,
      "temp_c": 21,
      "mortality_max_percent": 0.06
    },
    "27": {
      "weight_g": 1640,
      "feed_g": 139,
      "water_ml": 278,
      "temp_c": 20.8,
      "mortality_max_percent": 0.05
    },
    "28": {
      "weight_g": 1745,
      "feed_g": 145,
      "water_ml": 290,
      "temp_c": 20.5,
      "mortality_max_percent": 0.05
    },
    "29": {
      "weight_g": 1850,
      "feed_g": 151,
      "water_ml": 302,
      "temp_c": 20.2,
      "mortality_max_percent": 0.05
    },
    "30": {
      "weight_g": 1955,
      "feed_g": 157,
      "water_ml": 314,
      "temp_c": 20,
      "mortality_max_percent": 0.05
    },
    "31": {
      "weight_g": 2060,
      "feed_g": 163,
      "water_ml": 326,
      "temp_c": 19.8,
      "mortality_max_percent": 0.05
    },
    "32": {
      "weight_g": 2165,
      "feed_g": 169,
      "water_ml": 338,
      "temp_c": 19.5,
      "mortality_max_percent": 0.05
    },
    "33": {
      "weight_g": 2270,
      "feed_g": 175,
      "water_ml": 350,
      "temp_c": 19.3,
      "mortality_max_percent": 0.05
    },
    "34": {
      "weight_g": 2375,
      "feed_g": 180,
      "water_ml": 360,
      "temp_c": 19.2,
      "mortality_max_percent": 0.05
    },
    "35": {
      "weight_g": 2480,
      "feed_g": 185,
      "water_ml": 370,
      "temp_c": 19,
      "mortality_max_percent": 0.05
    },
    "36": {
      "weight_g": 2580,
      "feed_g": 190,
      "water_ml": 380,
      "temp_c": 18.8,
      "mortality_max_percent": 0.05
    },
    "37": {
      "weight_g": 2680,
      "feed_g": 195,
      "water_ml": 390,
      "temp_c": 18.6,
      "mortality_max_percent": 0.05
    },
    "38": {
      "weight_g": 2775,
      "feed_g": 199,
      "water_ml": 398,
      "temp_c": 18.4,
      "mortality_max_percent": 0.05
    },
    "39": {
      "weight_g": 2870,
      "feed_g": 203,
      "water_ml": 406,
      "temp_c": 18.2,
      "mortality_max_percent": 0.05
    },
    "40": {
      "weight_g": 2960,
      "feed_g": 207,
      "water_ml": 414,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    },
    "41": {
      "weight_g": 3045,
      "feed_g": 211,
      "water_ml": 422,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    },
    "42": {
      "weight_g": 3125,
      "feed_g": 215,
      "water_ml": 430,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    }
  }
};

export interface DailyPlanItem {
  day: number;
  tasks_ru: string;
  tasks_uz: string;
  tasks_en: string[];
  video_url: string | null;
}

export const BROILER_PLAN_DATA: DailyPlanItem[] = [
  {
    "day": 1,
    "tasks_ru": "Подготовьте брудер. Проверьте температуру (32-33°C на уровне подстилки). Включите свет 24 часа. Напоите цыплят теплой водой (20-22°C) с глюкозой/витаминами. Через 2 часа насыпьте стартовый комбикорм на лотки/бумагу.",
    "tasks_uz": "Bruderni tayyorlang. Haroratni tekshiring (to'shak sathida 32-33°C). 24 soatlik yorug'likni yoqing. Jo'jalarga glyukoza/vitaminli iliq suv (20-22°C) bering. 2 soatdan so'ng podnos/qog'ozlarga start yemini seping.",
    "tasks_en": [
      "Prepare the brooder and verify floor temperature (32-33°C at litter level).",
      "Keep 24-hour lighting on and provide warm water (20-22°C) with glucose/vitamins.",
      "Spread starter crumble feed on trays or chick paper 2 hours after placement."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+day+1+brooding+setup"
  },
  {
    "day": 2,
    "tasks_ru": "Контроль температуры (32°C). Проверьте наполненность зобов у 50 цыплят (должно быть 95%+ с мягким кормом и водой). Чистите поилки, обновляйте воду.",
    "tasks_uz": "Harorat nazorati (32°C). 50 ta jo'janing jig'ildonini tekshiring (95%+ yumshoq yem va suv bilan to'lgan bo'lishi kerak). Sug'orgichlarni tozalang, suvni yangilang.",
    "tasks_en": [
      "Maintain floor temperature at 32°C.",
      "Check crop fill on 50 random chicks (at least 95% should have soft feed and water).",
      "Clean drinkers and refresh water."
    ],
    "video_url": null
  },
  {
    "day": 3,
    "tasks_ru": "Температура 31-32°C. Влажность 60-70%. Начните приучать к бункерным кормушкам. Осмотрите слабых цыплят. Контролируйте вентиляцию без сквозняков.",
    "tasks_uz": "Harorat 31-32°C. Namlik 60-70%. Bunkyerli yemdonlarga o'rgatishni boshlang. Kuchsiz jo'jalarni ajrating. Qoralamasiz (skvoznyaksiz) shamollatishni nazorat qiling.",
    "tasks_en": [
      "Maintain temperature at 31-32°C and relative humidity at 60-70%.",
      "Begin transitioning chicks to pan/hopper feeders and inspect weak chicks.",
      "Ensure minimum ventilation without floor-level drafts."
    ],
    "video_url": null
  },
  {
    "day": 4,
    "tasks_ru": "Температура 30-31°C. Переход на постоянные кормушки. Контрольное взвешивание выборки цыплят. Запишите расход корма и падёж в дневник.",
    "tasks_uz": "Harorat 30-31°C. Doimiy yemdonlarga o'tish. Namuna jo'jalarni nazorat taroziga tortish. Kunlik yem sarfi va nobudgarchilikni kundalikka yozing.",
    "tasks_en": [
      "Keep temperature at 30-31°C and transition chicks to permanent feeders.",
      "Weigh a sample of chicks and record daily feed consumption and mortality in the diary."
    ],
    "video_url": null
  },
  {
    "day": 5,
    "tasks_ru": "Температура 30°C. Проверьте подстилку возле поилок, при необходимости подсыпьте сухие опилки. Курс витаминов по схеме ветеринара.",
    "tasks_uz": "Harorat 30°C. Sug'orgichlar atrofidagi to'shakni tekshiring, zarur bo'lsa quruq qipiq seping. Veterinariya sxemasi bo'yicha vitamin berish.",
    "tasks_en": [
      "Maintain temperature at 30°C.",
      "Inspect litter around drinkers and top-dress with dry wood shavings if needed.",
      "Continue vitamin supplementation per your veterinarian's schedule."
    ],
    "video_url": null
  },
  {
    "day": 6,
    "tasks_ru": "Температура 29-30°C. Подготовка к первой вакцинации (Ньюкасл/Бронхит или Гамборо по региональному календарю). Проверьте чистоту систем поения.",
    "tasks_uz": "Harorat 29-30°C. Birinchi emlashga tayyorgarlik (Nyukasl/Bronxit yoki Gamboro hududiy taqvim bo'yicha). Suv ta'minoti tizimi tozaligini tekshiring.",
    "tasks_en": [
      "Keep temperature at 29-30°C.",
      "Prepare for the first scheduled vaccination (Newcastle/Bronchitis per regional schedule).",
      "Inspect and flush drinking lines."
    ],
    "video_url": null
  },
  {
    "day": 7,
    "tasks_ru": "Конец 1-й недели. Взвешивание цыплят (норма Ross-308/Cobb-500: 185 г). Первая плановая вакцинация методом выпаивания. Температура 29.5°C.",
    "tasks_uz": "1-hafta yakuni. Jo'jalarni tortish (Ross-308/Cobb-500 normasi: 185 g). Ichirish usuli bilan birinchi rejali emlash. Harorat 29.5°C.",
    "tasks_en": [
      "End of Week 1: weigh sample chicks (Ross-308/Cobb-500 target: 185 g).",
      "Administer first scheduled drinking-water vaccination.",
      "Maintain temperature at 29.5°C."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+week+1+management+weighing"
  },
  {
    "day": 8,
    "tasks_ru": "Температура 28-29°C. Начните расширение зоны содержания цыплят. Введите 1 час темноты в сутки для формирования костяка и иммунитета.",
    "tasks_uz": "Harorat 28-29°C. Jo'jalar saqlanadigan joyni kengaytirishni boshlang. Suyak va immunitet rivojlanishi uchun kuniga 1 soat qorong'ilik kiriting.",
    "tasks_en": [
      "Keep temperature at 28-29°C and expand the brooding area.",
      "Introduce 1 hour of darkness per day to support skeletal and immune development."
    ],
    "video_url": null
  },
  {
    "day": 9,
    "tasks_ru": "Температура 28°C. Проверьте вентиляцию: аммиачный запах не должен ощущаться. Контроль расхода воды (должен быть в 1.8-2 раза больше веса съеденного корма).",
    "tasks_uz": "Harorat 28°C. Shamollatishni tekshiring: ammiak hidi bo'lmasligi kerak. Suv sarfini nazorat qiling (yeyilgan yem og'irligidan 1.8-2 baravar ko'p bo'lishi kerak).",
    "tasks_en": [
      "Maintain temperature at 28°C and check ventilation (no ammonia odor should be present).",
      "Monitor water intake (should be 1.8 to 2.0 times the weight of feed consumed)."
    ],
    "video_url": null
  },
  {
    "day": 10,
    "tasks_ru": "Температура 27-28°C. Проверьте высоту поилок и кормушек — поднимите на уровень спины птицы. Осмотрите помёт на отсутствие кокцидиоза (кровавых следов).",
    "tasks_uz": "Harorat 27-28°C. Sug'orgich va yemdonlar balandligini qushning orqa qismi balandligiga moslang. Axlatni qon izlari (koksidioz) yo'qligiga tekshiring.",
    "tasks_en": [
      "Maintain temperature at 27-28°C.",
      "Adjust drinker and feeder height to match bird back level.",
      "Inspect droppings for any signs of coccidiosis (bloody traces)."
    ],
    "video_url": null
  },
  {
    "day": 11,
    "tasks_ru": "Температура 27°C. Увеличение темнового периода до 2 часов. Контроль качества подстилки, рыхление слежавшихся мест.",
    "tasks_uz": "Harorat 27°C. Qorong'i davrni 2 soatga uzaytiring. To'shak sifatini nazorat qiling, qotib qolgan joylarni yumshating.",
    "tasks_en": [
      "Keep temperature at 27°C and increase the dark period to 2 hours.",
      "Check litter quality and rake any caked spots."
    ],
    "video_url": null
  },
  {
    "day": 12,
    "tasks_ru": "Температура 26-27°C. Подготовка ко второй вакцинации (болезнь Гамборо). За 2 часа до вакцинации перекройте воду для формирования жажды.",
    "tasks_uz": "Harorat 26-27°C. Ikkinchi emlashga tayyorgarlik (Gamboro kasalligi). Emlashdan 2 soat oldin chanqash hosil qilish uchun suvni to'xtating.",
    "tasks_en": [
      "Maintain temperature at 26-27°C.",
      "Prepare for the second vaccination (Gumboro/IBD); withdraw water 2 hours prior to build thirst."
    ],
    "video_url": null
  },
  {
    "day": 13,
    "tasks_ru": "Температура 26°C. План вакцинации Гамборо через воду с нейтрализатором хлора (молочный порошок или спец. таблетка).",
    "tasks_uz": "Harorat 26°C. Gamboro vaksinasini xlor neytrallovchi (sut kukuni yoki maxsus tabletka) qo'shilgan suv orqali berish.",
    "tasks_en": [
      "Keep temperature at 26°C.",
      "Administer Gumboro (IBD) vaccine via drinking water stabilized with skim milk powder or chlorine neutralizer."
    ],
    "video_url": null
  },
  {
    "day": 14,
    "tasks_ru": "Конец 2-й недели. Взвешивание (норма: 510 г). Начало плавного перехода со Стартера на Ростовой комбикорм (75% старт / 25% рост).",
    "tasks_uz": "2-hafta yakuni. Taroziga tortish (norma: 510 g). Start yemdan O'sish (Grover) yemiga bosqichma-bosqich o'tish (75% start / 25% o'sish).",
    "tasks_en": [
      "End of Week 2: weigh sample birds (target: 510 g).",
      "Begin gradual transition from Starter to Grower feed (75% Starter / 25% Grower)."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+week+2+feed+transition+grower"
  },
  {
    "day": 15,
    "tasks_ru": "Температура 25-26°C. Переход корма: 50% Старт / 50% Рост. Проверьте активность стада и однородность поголовья.",
    "tasks_uz": "Harorat 25-26°C. Yem o'tishi: 50% Start / 50% O'sish. Gala faolligi va bir xil o'sayotganini tekshiring.",
    "tasks_en": [
      "Maintain temperature at 25-26°C.",
      "Feed transition day 2: mix 50% Starter / 50% Grower.",
      "Check flock activity and uniformity."
    ],
    "video_url": null
  },
  {
    "day": 16,
    "tasks_ru": "Температура 25°C. Переход корма: 25% Старт / 75% Рост. Контроль влажности подстилки — удалите мокрые участки.",
    "tasks_uz": "Harorat 25°C. Yem o'tishi: 25% Start / 75% O'sish. To'shak namligini tekshiring — namlangan joylarni olib tashlang.",
    "tasks_en": [
      "Keep temperature at 25°C.",
      "Feed transition day 3: mix 25% Starter / 75% Grower.",
      "Monitor litter moisture and remove wet patches."
    ],
    "video_url": null
  },
  {
    "day": 17,
    "tasks_ru": "Температура 24-25°C. Полный переход на 100% Ростовой комбикорм (гранула 2.5-3 мм). Увеличьте вентиляцию по мере роста живой массы.",
    "tasks_uz": "Harorat 24-25°C. To'liq 100% O'sish (Grover) yemiga o'tish (2.5-3 mm granula). Tirik vazn oshishi bilan shamollatish quvvatini oshiring.",
    "tasks_en": [
      "Maintain temperature at 24-25°C.",
      "Complete transition to 100% Grower feed (2.5-3 mm pellets).",
      "Increase ventilation rate as total flock biomass grows."
    ],
    "video_url": null
  },
  {
    "day": 18,
    "tasks_ru": "Температура 24°C. Темновой режим: 4 часа темноты (для здорового сердца и конечностей). Проверка давления в линии ниппелей.",
    "tasks_uz": "Harorat 24°C. Qorong'ilik rejimi: 4 soat (yurak va oyoq sog'lig'i uchun). Nippel sug'orgichlardagi bosimni tekshirish.",
    "tasks_en": [
      "Keep temperature at 24°C and provide 4 hours of darkness for cardiovascular and leg health.",
      "Check water pressure in nipple drinker lines."
    ],
    "video_url": null
  },
  {
    "day": 19,
    "tasks_ru": "Температура 23-24°C. Профилактика респираторных болезней (эфирные масла или щадящая аэрозольная дезинфекция в присутствии птицы).",
    "tasks_uz": "Harorat 23-24°C. Nafas yo'llari kasalliklarining oldini olish (efir moylari yoki parrandalar borligida yumshoq aerozol dezinfeksiya).",
    "tasks_en": [
      "Maintain temperature at 23-24°C.",
      "Perform respiratory health checks and maintain clean air quality."
    ],
    "video_url": null
  },
  {
    "day": 20,
    "tasks_ru": "Температура 23°C. Проверьте плотность посадки. Если птичник позволяет, откройте всю оставшуюся площадь помещения.",
    "tasks_uz": "Harorat 23°C. Zichlikni tekshiring. Agar bino imkon bersa, xonaning qolgan barcha maydonini to'liq oching.",
    "tasks_en": [
      "Keep temperature at 23°C.",
      "Check stocking density and open the full house area if not already done."
    ],
    "video_url": null
  },
  {
    "day": 21,
    "tasks_ru": "Конец 3-й недели. Контрольное взвешивание (норма: 1055 г). Ревакцинация против Ньюкасла (по рекомендации ветврача).",
    "tasks_uz": "3-hafta yakuni. Nazorat tortish (norma: 1055 g). Nyukaslga qarshi qayta emlash (veterinar tavsiyasiga ko'ra).",
    "tasks_en": [
      "End of Week 3: weigh sample birds (target: 1055 g).",
      "Administer booster vaccination against Newcastle disease as advised by your veterinarian."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+week+3+management+ventilation"
  },
  {
    "day": 22,
    "tasks_ru": "Температура 22-23°C. Контроль потребления воды. В жаркую погоду охлаждайте поступающую воду (оптимум 16-18°C).",
    "tasks_uz": "Harorat 22-23°C. Suv ichilishini nazorat qiling. Issiq havoda berilayotgan suvni salqin tuting (optimal 16-18°C).",
    "tasks_en": [
      "Maintain temperature at 22-23°C.",
      "Monitor water intake and keep drinking water cool (16-18°C) during warm weather."
    ],
    "video_url": null
  },
  {
    "day": 23,
    "tasks_ru": "Температура 22°C. Проверка лап птицы на пододерматит (натоптыши). Если влажно под ногами — добавьте известь-пушонку и свежую подстилку.",
    "tasks_uz": "Harorat 22°C. Oyoq panjalarini pododermatitga tekshiring. Agar to'shak nam bo'lsa — so'ndirilgan ohak va yangi to'shak seping.",
    "tasks_en": [
      "Keep temperature at 22°C.",
      "Inspect footpads for pododermatitis; if litter is damp, add fresh dry bedding and improve airflow."
    ],
    "video_url": null
  },
  {
    "day": 24,
    "tasks_ru": "Температура 21-22°C. Контроль скорости воздуха на уровне птицы: не допускать прямого обдува холодным воздухом.",
    "tasks_uz": "Harorat 21-22°C. Qushlar sathida havo harakati tezligini nazorat qiling: sovuq havo to'g'ridan-to'g'ri urilishiga yo'l qo'ymang.",
    "tasks_en": [
      "Maintain temperature at 21-22°C.",
      "Check air velocity at bird height and prevent cold incoming air from dropping directly onto the flock."
    ],
    "video_url": null
  },
  {
    "day": 25,
    "tasks_ru": "Температура 21°C. Проверьте конверсию корма (FCR). Очистка ламп и плафонов от птичьей пыли для поддержания светового потока.",
    "tasks_uz": "Harorat 21°C. Yem konversiyasini (FCR) hisoblang. Yorug'lik tushishini ta'minlash uchun chiroqlarni changdan tozalang.",
    "tasks_en": [
      "Keep temperature at 21°C and calculate feed conversion ratio (FCR).",
      "Wipe dust from light fixtures to maintain proper illumination."
    ],
    "video_url": null
  },
  {
    "day": 26,
    "tasks_ru": "Температура 21°C. Осмотр птиц: проверьте дыхание (хрипы, вытягивание шеи). При признаках болезни обратитесь к ветеринару.",
    "tasks_uz": "Harorat 21°C. Qushlarni ko'zdan kechiring: nafas olishni tekshiring (xirillash, bo'yin cho'zish). Kasallik belgilarida veterinar chaqiring.",
    "tasks_en": [
      "Maintain temperature at 21°C.",
      "Listen and observe for respiratory signs (rales, gasping); consult your veterinarian immediately if observed."
    ],
    "video_url": null
  },
  {
    "day": 27,
    "tasks_ru": "Температура 20-21°C. Подготовка к переходу на Финишный комбикорм. Проверьте запасы корма на складе.",
    "tasks_uz": "Harorat 20-21°C. Finish yemiga o'tishga tayyorgarlik. Omborxonada yem zaxirasini tekshiring.",
    "tasks_en": [
      "Keep temperature at 20-21°C.",
      "Prepare for transitioning to Finisher feed and verify feed storage inventory."
    ],
    "video_url": null
  },
  {
    "day": 28,
    "tasks_ru": "Конец 4-й недели. Взвешивание (норма: 1745 г). Начало перехода с Роста на Финиш (гранула 3.5-4 мм, 70% Рост / 30% Финиш).",
    "tasks_uz": "4-hafta yakuni. Taroziga tortish (norma: 1745 g). Groverdan Finishga o'tishni boshlash (granula 3.5-4 mm, 70% O'sish / 30% Finish).",
    "tasks_en": [
      "End of Week 4: weigh sample birds (target: 1745 g).",
      "Start transitioning from Grower to Finisher pellets (3.5-4 mm, 70% Grower / 30% Finisher)."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+week+4+finisher+feed+management"
  },
  {
    "day": 29,
    "tasks_ru": "Температура 20°C. Переход корма: 50% Рост / 50% Финиш. Обеспечьте бесперебойную подачу свежей воды.",
    "tasks_uz": "Harorat 20°C. Yem o'tishi: 50% O'sish / 50% Finish. Toza suvning to'xtovsiz berilishini ta'minlang.",
    "tasks_en": [
      "Maintain temperature at 20°C.",
      "Feed transition day 2: mix 50% Grower / 50% Finisher and ensure uninterrupted fresh water."
    ],
    "video_url": null
  },
  {
    "day": 30,
    "tasks_ru": "Температура 20°C. Переход корма: 25% Рост / 75% Финиш. Проверьте работу аварийных вентиляторов или генератора.",
    "tasks_uz": "Harorat 20°C. Yem o'tishi: 25% O'sish / 75% Finish. Avariya ventilyatorlari va generatorning ishlashini tekshiring.",
    "tasks_en": [
      "Keep temperature at 20°C.",
      "Feed transition day 3: mix 25% Grower / 75% Finisher.",
      "Test backup fans and emergency power generator."
    ],
    "video_url": null
  },
  {
    "day": 31,
    "tasks_ru": "Температура 19-20°C. 100% Финишный комбикорм. Прекращение выпойки антибиотиков и кокцидиостатиков (период выведения до убоя).",
    "tasks_uz": "Harorat 19-20°C. 100% Finish yemi. Antibiotik va koksidiostatiklarni ichirishni to'xtatish (so'yishdan oldingi tozalanish davri).",
    "tasks_en": [
      "Maintain temperature at 19-20°C and feed 100% Finisher ration.",
      "Observe strict withdrawal periods for any medications or coccidiostats prior to harvest."
    ],
    "video_url": null
  },
  {
    "day": 32,
    "tasks_ru": "Температура 19°C. Контроль перегрева: если на улице жара >30°C, включайте туманообразование или смачивание крыши.",
    "tasks_uz": "Harorat 19°C. Qizib ketishdan saqlash: tashqarida havo >30°C bo'lsa, tumanlagichlar yoki tomga suv sepishni yoqing.",
    "tasks_en": [
      "Keep temperature at 19°C.",
      "Guard against heat stress: if outdoor temperature exceeds 30°C, activate cooling pads or roof sprinkling."
    ],
    "video_url": null
  },
  {
    "day": 33,
    "tasks_ru": "Температура 19°C. Проверьте состояние перьевого покрова и кожных покровов. Не допускайте столпотворения птицы у кормушек.",
    "tasks_uz": "Harorat 19°C. Pat qoplami va teri holatini tekshiring. Yemdonlar atrofida qushlar tiqilinchini oldini oling.",
    "tasks_en": [
      "Maintain temperature at 19°C.",
      "Inspect feather cover and skin condition; prevent crowding around feeders."
    ],
    "video_url": null
  },
  {
    "day": 34,
    "tasks_ru": "Температура 18-19°C. Поднимите кормушки до уровня груди птицы, чтобы минимизировать рассыпание корма.",
    "tasks_uz": "Harorat 18-19°C. Yem isrof bo'lishini kamaytirish uchun yemdonlarni qushning ko'krak sathigacha ko'taring.",
    "tasks_en": [
      "Keep temperature at 18-19°C.",
      "Raise feeders to bird breast height to minimize feed spillage."
    ],
    "video_url": null
  },
  {
    "day": 35,
    "tasks_ru": "Конец 5-й недели. Контрольное взвешивание (норма: 2480 г). Оценка готовности к первому прореживанию стада (если планируется).",
    "tasks_uz": "5-hafta yakuni. Nazorat tortish (norma: 2480 g). Podani birinchi siyraklatishga tayyorligini baholang (agar rejalashtirilgan bo'lsa).",
    "tasks_en": [
      "End of Week 5: weigh sample birds (target: 2480 g).",
      "Assess flock readiness for partial thinning if planned."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+week+5+weighing+thinning"
  },
  {
    "day": 36,
    "tasks_ru": "Температура 18-19°C. Контроль влажности воздуха (оптимум 55-65%). Максимальное проветривание в дневное время.",
    "tasks_uz": "Harorat 18-19°C. Havo namligini nazorat qilish (optimal 55-65%). Kunduzgi vaqtda maksimal shamollatish.",
    "tasks_en": [
      "Maintain temperature at 18-19°C and relative humidity at 55-65%.",
      "Run maximum daytime ventilation to remove heat and moisture."
    ],
    "video_url": null
  },
  {
    "day": 37,
    "tasks_ru": "Температура 18°C. Проверка чистоты воды. Подготовка тары/ящиков для будущей отгрузки и дезинфекция транспорта.",
    "tasks_uz": "Harorat 18°C. Suv tozaligini tekshiring. Bo'lajak sotish/tashish uchun yashiklarni tayyorlash va transportni dezinfeksiya qilish.",
    "tasks_en": [
      "Keep temperature at 18°C and verify water cleanliness.",
      "Prepare and disinfect transport crates and vehicles for upcoming harvest."
    ],
    "video_url": null
  },
  {
    "day": 38,
    "tasks_ru": "Температура 18°C. Мониторинг аппетита и подвижности. Запись данных по приросту и расходу корма в дневник.",
    "tasks_uz": "Harorat 18°C. Ishtaha va harakatchanlikni kuzatish. Kundalikka vazn qo'shilishi va yem sarfini qayd etish.",
    "tasks_en": [
      "Maintain temperature at 18°C.",
      "Monitor flock appetite and mobility; log weight gain and feed intake in the diary."
    ],
    "video_url": null
  },
  {
    "day": 39,
    "tasks_ru": "Температура 18°C. Проверьте соответствие веса рыночным требованиям покупателей (оптимум 2.8 - 3.0 кг).",
    "tasks_uz": "Harorat 18°C. Qushlar vazni xaridorlarning bozor talabiga mosligini tekshiring (optimal 2.8 - 3.0 kg).",
    "tasks_en": [
      "Keep temperature at 18°C.",
      "Check average bird weight against buyer market targets (2.8 - 3.0 kg)."
    ],
    "video_url": null
  },
  {
    "day": 40,
    "tasks_ru": "Температура 18°C. Подготовка к завершению цикла: согласуйте график отгрузки с закупщиками или убойным цехом.",
    "tasks_uz": "Harorat 18°C. Siklni yakunlashga tayyorgarlik: xaridorlar yoki kushxona bilan topshirish vaqtini kelishib oling.",
    "tasks_en": [
      "Maintain temperature at 18°C.",
      "Prepare for cycle completion and confirm pickup schedule with buyers or processing plant."
    ],
    "video_url": null
  },
  {
    "day": 41,
    "tasks_ru": "Температура 18°C. За 8-10 часов до отлова прекратите подачу корма для опорожнения кишечника. Воду НЕ отключать до самого начала отлова!",
    "tasks_uz": "Harorat 18°C. Qushlarni ushlashdan 8-10 soat oldin ichaklarni bo'shatish uchun yem berishni to'xtating. Suvni ushlash boshlanguncha UZMANG!",
    "tasks_en": [
      "Keep temperature at 18°C.",
      "Withdraw feed 8-10 hours before catching to clear the digestive tract; keep water available until catching begins."
    ],
    "video_url": null
  },
  {
    "day": 42,
    "tasks_ru": "Финальный день (42 дня). Отлов при синем/приглушенном свете без травм. Итоговое взвешивание, фиксация FCR и сохранности партии в AgroZen.",
    "tasks_uz": "Yakuniy kun (42 kun). Shikast yetkazmaslik uchun ko'k/xira chiroqda ushlash. Yakuniy taroziga tortish, AgroZen ilovasida partiyani yakunlash.",
    "tasks_en": [
      "Final Day (Day 42): catch birds calmly under dim or blue light to prevent bruising.",
      "Complete final weighing and record batch FCR and livability in AgroZen."
    ],
    "video_url": "https://www.youtube.com/results?search_query=broiler+harvesting+catching+best+practices"
  }
];

export const VETS_DATA = [
  {
    "district": "Toshkent",
    "name": "Dr. Rustam Karimov",
    "phone": "+998901234501",
    "organization": "Toshkent viloyati Parrandachilik va Veterinariya markazi",
    "address": "Toshkent viloyati, Zangiota tumani, Qatortol ko'chasi 14"
  },
  {
    "district": "Samarqand",
    "name": "Dr. Jamshid Ergashev",
    "phone": "+998933334502",
    "organization": "Samarqand Davlat Veterinariya Boshqarmasi",
    "address": "Samarqand sh., Mirzo Ulug'bek ko'chasi 45"
  },
  {
    "district": "Buxoro",
    "name": "Dr. Alisher Narzullayev",
    "phone": "+998914004503",
    "organization": "Buxoro Parrandachilik Diagnostika Markazi",
    "address": "Buxoro sh., Ibrohim Mo'minov ko'chasi 12"
  },
  {
    "district": "Andijon",
    "name": "Dr. Nodirbek Usmonov",
    "phone": "+998902004504",
    "organization": "Andijon Parranda Salomatligi Xizmati",
    "address": "Andijon sh., Bobur shoh ko'chasi 78"
  },
  {
    "district": "Farg'ona",
    "name": "Dr. Mansur Qodirov",
    "phone": "+998911504505",
    "organization": "Farg'ona Viloyati Davlat Veterinariya Bo'limi",
    "address": "Farg'ona sh., Al-Farg'oniy ko'chasi 22"
  },
  {
    "district": "Namangan",
    "name": "Dr. Salohiddin Mirzayev",
    "phone": "+998932114506",
    "organization": "Namangan Parrandachilik Ilmiy-Amaliy Markazi",
    "address": "Namangan sh., Kosonsoy ko'chasi 5"
  },
  {
    "district": "Qashqadaryo",
    "name": "Dr. Baxtiyor Normurodov",
    "phone": "+998973104507",
    "organization": "Qashqadaryo Veterinariya Diagnostika Laboratoriyasi",
    "address": "Qarshi sh., Mustaqillik shoh ko'chasi 33"
  },
  {
    "district": "Surxondaryo",
    "name": "Dr. Ilhom Xoliqov",
    "phone": "+998994404508",
    "organization": "Termiz Parrandachilik Xizmati",
    "address": "Termiz sh., At-Termiziy ko'chasi 19"
  },
  {
    "district": "Jizzax",
    "name": "Dr. Otabek Sobirov",
    "phone": "+998905504509",
    "organization": "Jizzax Viloyati Veterinariya Stansiyasi",
    "address": "Jizzax sh., Sharof Rashidov ko'chasi 10"
  },
  {
    "district": "Sirdaryo",
    "name": "Dr. Farrux Yusupov",
    "phone": "+998916604510",
    "organization": "Guliston Veterinariya Laboratoriyasi",
    "address": "Guliston sh., O'zbekiston ko'chasi 6"
  },
  {
    "district": "Xorazm",
    "name": "Dr. Sherzod Matyoqubov",
    "phone": "+998937704511",
    "organization": "Urganch Parrandachilik Maslahat Markazi",
    "address": "Urganch sh., Al-Xorazmiy ko'chasi 15"
  },
  {
    "district": "Navoiy",
    "name": "Dr. G'ayrat Hamroyev",
    "phone": "+998792204512",
    "organization": "Navoiy Parranda Salomatligi Markazi",
    "address": "Navoiy sh., G'alaba shoh ko'chasi 8"
  },
  {
    "district": "Qoraqalpog'iston",
    "name": "Dr. Azamat Seytov",
    "phone": "+998612204513",
    "organization": "Qoraqalpog'iston Respublikasi Veterinariya Qo'mitasi",
    "address": "Nukus sh., Dosliq guzari 52"
  }
];

/**
 * Clean and normalize text for keyword matching
 */
function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-zA-Zа-яА-ЯёЁ0-9]/g, ' ')
    .split(/\s+/)
    .filter((word) => word.length > 2);
}

/**
 * Retrieve relevant articles and norms context for a given question and language
 */
export function retrieveRelevantKnowledge(
  query: string,
  language: 'uz' | 'ru' | 'en' = 'uz',
  maxArticles = 3
): { topics: string[]; contextText: string } {
  const articles =
    language === 'ru'
      ? KNOWLEDGE_ARTICLES_RU
      : language === 'en'
        ? KNOWLEDGE_ARTICLES_EN
        : KNOWLEDGE_ARTICLES_UZ;
  const queryTokens = tokenize(query);
  const queryLower = query.toLowerCase();

  // English / Uzbek / Russian domain stem hints mapped to article filenames
  const stemHints: Record<string, string[]> = {
    'temperature.md': ['temp', 'heat', 'cold', 'brood', 'degree', 'humidity', 'chill', 'pant', 'huddle', 'harorat', 'issiq', 'sovuq', 'температур', 'тепл', 'холод'],
    'feed.md': ['feed', 'starter', 'grower', 'finisher', 'protein', 'crumb', 'pellet', 'fcr', 'ration', 'weight', 'yem', 'oqsil', 'корм', 'белок', 'протеин'],
    'water.md': ['water', 'drink', 'nipple', 'flush', 'chlorin', 'thirst', 'dehydrat', 'suv', 'ichimlik', 'вод', 'поил', 'ниппел'],
    'diseases.md': ['diseas', 'sick', 'mortal', 'dead', 'coccid', 'newcastle', 'gumboro', 'bronchit', 'vaccin', 'dropp', 'blood', 'kasal', 'vaksina', 'болезн', 'вакцин', 'падеж'],
    'sanitation.md': ['sanit', 'clean', 'disinfect', 'biosecur', 'litter', 'shaving', 'bedding', 'lime', 'tozalik', 'dezinfeksiya', 'санитар', 'дезинфекц', 'подстилк'],
    'ventilation.md': ['ventil', 'air', 'fan', 'ammonia', 'draft', 'tunnel', 'oxygen', 'cooling', 'shamol', 'havo', 'вентиляц', 'воздух', 'аммиак'],
  };

  const scored = articles.map((article) => {
    let score = 0;
    const titleTokens = tokenize(article.title);
    const contentLower = article.content.toLowerCase();

    for (const token of queryTokens) {
      if (titleTokens.includes(token)) {
        score += 6;
      }
      if (contentLower.includes(token)) {
        score += 2;
      }
    }

    const hints = stemHints[article.filename] ?? [];
    for (const stem of hints) {
      if (queryLower.includes(stem)) {
        score += 4;
      }
    }

    return { article, score };
  });

  scored.sort((a, b) => b.score - a.score);

  // If match found, select top articles
  let selected = scored.filter((s) => s.score > 0).slice(0, maxArticles);
  if (selected.length === 0 && scored.length > 0) {
    selected = [scored[0]];
  }

  const topics = selected.map((s) => s.article.filename);
  const contextParts = selected.map(
    (s) => '### ' + s.article.title + ' (' + s.article.filename + '):\n' + s.article.content
  );

  // Check if norms are relevant
  const normsKeywords = [
    'norma', 'normasi', 'ogirlik', 'vazn', 'harorat', 'temperatura', 'gradus',
    'yem', 'sarfi', 'suv', 'hafta', 'kun', 'jadval', 'ross', 'cobb',
    'норма', 'вес', 'масса', 'температура', 'градус', 'корм', 'расход', 'вода', 'неделя', 'день',
    'norm', 'norms', 'weight', 'target', 'temperature', 'feed', 'consumption', 'water', 'week', 'day',
    'gram', 'chart', 'schedule', 'growth'
  ];

  const mentionsNorms = normsKeywords.some((kw) => queryLower.includes(kw));
  if (mentionsNorms) {
    topics.push('norms.json');
    const normsHeader =
      language === 'en'
        ? '### Ross-308 / Cobb-500 Weekly Norms Table:\n'
        : language === 'ru'
          ? '### Таблица еженедельных норм Ross-308 / Cobb-500:\n'
          : '### Ross-308 / Cobb-500 haftalik me\'yorlar jadvali (Weekly Norms):\n';
    contextParts.push(
      normsHeader + JSON.stringify(NORMS_DATA.weekly_norms, null, 2)
    );
  }

  return {
    topics,
    contextText: contextParts.join('\n\n---\n\n'),
  };
}

export const retrieveRelevantArticles = retrieveRelevantKnowledge;

