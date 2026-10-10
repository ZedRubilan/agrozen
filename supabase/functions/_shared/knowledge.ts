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
    "content": "# Broylerlarni bosqichma-bosqich oziqlantirish\n\nBroyler jo'jalari juda tez o'sadi. Oziqlantirish 3 asosiy bosqichga bo'linadi:\n\n## Oziqlantirish bosqichlari:\n1. **Start (1–14 kunlar):**\n   - Xom protein: 22–24%\n   - Shakli: mayda yorma (2 mm)\n   - Ichki a'zolar va suyak tizimini shakllantirish uchun muhim.\n\n2. **O'sish / Grover (15–28 kunlar):**\n   - Xom protein: 20–21%\n   - Shakli: granula (2.5–3 mm)\n   - Go'sht va mushak massasining jadal o'sishi davri.\n\n3. **Finish (29–42 kunlar):**\n   - Xom protein: 18–19%\n   - Shakli: granula (3.5–4 mm)\n   - So'yish oldidan vazn to'plash. Ushbu bosqichda antibiotik va dori vositalarini berish qat'iyan taqiqlanadi!\n\n## Muhim qoidalar:\n- Yem doimo yemdonlarda bo'lishi kerak.\n- Suv har doim toza va yangi bo'lishi shart. 1 kg yem uchun broyler 1.8–2 litr suv ichadi.\n"
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
    "content": "# Кормление бройлеров по фазам\n\nБройлеры имеют интенсивный обмен веществ. Кормление делится на три основные фазы:\n\n## Фазы кормления:\n1. **Старт (1–14 дни):**\n   - Сырой протеин: 22–24%\n   - Форма: мелкая крупка (2 мм)\n   - Способствует формированию внутренних органов и костяка.\n\n2. **Рост / Гровер (15–28 дни):**\n   - Сырой протеин: 20–21%\n   - Форма: гранула (2.5–3 мм)\n   - Интенсивный набор мышечной массы.\n\n3. **Финиш (29–42 дни):**\n   - Сырой протеин: 18–19%\n   - Форма: гранула (3.5–4 мм)\n   - Набор веса перед сдачей. Запрещено использовать антибиотики в этой фазе!\n\n## Важные правила:\n- Корм должен быть доступен круглосуточно.\n- Вода должна быть всегда чистой и прохладной. На 1 кг съеденного корма бройлер выпивает около 1.8–2 л воды.\n"
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
      "daily_feed_g": 24,
      "cumulative_feed_g": 167,
      "temperature_c": 30,
      "humidity_percent": 65,
      "mortality_threshold_percent": 1
    },
    {
      "week": 2,
      "target_weight_g": 465,
      "daily_feed_g": 54,
      "cumulative_feed_g": 475,
      "temperature_c": 27,
      "humidity_percent": 65,
      "mortality_threshold_percent": 0.6
    },
    {
      "week": 3,
      "target_weight_g": 975,
      "daily_feed_g": 95,
      "cumulative_feed_g": 1050,
      "temperature_c": 24,
      "humidity_percent": 65,
      "mortality_threshold_percent": 0.5
    },
    {
      "week": 4,
      "target_weight_g": 1600,
      "daily_feed_g": 140,
      "cumulative_feed_g": 1900,
      "temperature_c": 21,
      "humidity_percent": 65,
      "mortality_threshold_percent": 0.4
    },
    {
      "week": 5,
      "target_weight_g": 2280,
      "daily_feed_g": 175,
      "cumulative_feed_g": 3050,
      "temperature_c": 19,
      "humidity_percent": 65,
      "mortality_threshold_percent": 0.4
    },
    {
      "week": 6,
      "target_weight_g": 2900,
      "daily_feed_g": 195,
      "cumulative_feed_g": 4350,
      "temperature_c": 18,
      "humidity_percent": 65,
      "mortality_threshold_percent": 0.4
    }
  ],
  "daily_norms": {
    "1": {
      "weight_g": 42,
      "feed_g": 12,
      "water_ml": 24,
      "temp_c": 32.5,
      "mortality_max_percent": 0.3
    },
    "2": {
      "weight_g": 55,
      "feed_g": 15,
      "water_ml": 30,
      "temp_c": 32,
      "mortality_max_percent": 0.3
    },
    "3": {
      "weight_g": 70,
      "feed_g": 18,
      "water_ml": 36,
      "temp_c": 31.5,
      "mortality_max_percent": 0.25
    },
    "4": {
      "weight_g": 90,
      "feed_g": 22,
      "water_ml": 44,
      "temp_c": 31,
      "mortality_max_percent": 0.25
    },
    "5": {
      "weight_g": 115,
      "feed_g": 27,
      "water_ml": 54,
      "temp_c": 30.5,
      "mortality_max_percent": 0.2
    },
    "6": {
      "weight_g": 145,
      "feed_g": 32,
      "water_ml": 64,
      "temp_c": 30,
      "mortality_max_percent": 0.2
    },
    "7": {
      "weight_g": 185,
      "feed_g": 38,
      "water_ml": 76,
      "temp_c": 29.5,
      "mortality_max_percent": 0.2
    },
    "8": {
      "weight_g": 215,
      "feed_g": 43,
      "water_ml": 86,
      "temp_c": 29,
      "mortality_max_percent": 0.15
    },
    "9": {
      "weight_g": 250,
      "feed_g": 48,
      "water_ml": 96,
      "temp_c": 28.5,
      "mortality_max_percent": 0.15
    },
    "10": {
      "weight_g": 295,
      "feed_g": 53,
      "water_ml": 106,
      "temp_c": 28,
      "mortality_max_percent": 0.15
    },
    "11": {
      "weight_g": 340,
      "feed_g": 59,
      "water_ml": 118,
      "temp_c": 27.5,
      "mortality_max_percent": 0.12
    },
    "12": {
      "weight_g": 395,
      "feed_g": 65,
      "water_ml": 130,
      "temp_c": 27,
      "mortality_max_percent": 0.12
    },
    "13": {
      "weight_g": 450,
      "feed_g": 71,
      "water_ml": 142,
      "temp_c": 26.5,
      "mortality_max_percent": 0.1
    },
    "14": {
      "weight_g": 510,
      "feed_g": 77,
      "water_ml": 154,
      "temp_c": 26,
      "mortality_max_percent": 0.1
    },
    "15": {
      "weight_g": 575,
      "feed_g": 83,
      "water_ml": 166,
      "temp_c": 25.5,
      "mortality_max_percent": 0.1
    },
    "16": {
      "weight_g": 645,
      "feed_g": 89,
      "water_ml": 178,
      "temp_c": 25,
      "mortality_max_percent": 0.08
    },
    "17": {
      "weight_g": 720,
      "feed_g": 95,
      "water_ml": 190,
      "temp_c": 24.5,
      "mortality_max_percent": 0.08
    },
    "18": {
      "weight_g": 800,
      "feed_g": 101,
      "water_ml": 202,
      "temp_c": 24,
      "mortality_max_percent": 0.08
    },
    "19": {
      "weight_g": 880,
      "feed_g": 107,
      "water_ml": 214,
      "temp_c": 23.5,
      "mortality_max_percent": 0.08
    },
    "20": {
      "weight_g": 965,
      "feed_g": 113,
      "water_ml": 226,
      "temp_c": 23,
      "mortality_max_percent": 0.07
    },
    "21": {
      "weight_g": 1055,
      "feed_g": 119,
      "water_ml": 238,
      "temp_c": 22.5,
      "mortality_max_percent": 0.07
    },
    "22": {
      "weight_g": 1145,
      "feed_g": 124,
      "water_ml": 248,
      "temp_c": 22,
      "mortality_max_percent": 0.07
    },
    "23": {
      "weight_g": 1240,
      "feed_g": 130,
      "water_ml": 260,
      "temp_c": 21.8,
      "mortality_max_percent": 0.06
    },
    "24": {
      "weight_g": 1335,
      "feed_g": 135,
      "water_ml": 270,
      "temp_c": 21.5,
      "mortality_max_percent": 0.06
    },
    "25": {
      "weight_g": 1435,
      "feed_g": 140,
      "water_ml": 280,
      "temp_c": 21.2,
      "mortality_max_percent": 0.06
    },
    "26": {
      "weight_g": 1535,
      "feed_g": 145,
      "water_ml": 290,
      "temp_c": 21,
      "mortality_max_percent": 0.06
    },
    "27": {
      "weight_g": 1640,
      "feed_g": 150,
      "water_ml": 300,
      "temp_c": 20.8,
      "mortality_max_percent": 0.05
    },
    "28": {
      "weight_g": 1745,
      "feed_g": 155,
      "water_ml": 310,
      "temp_c": 20.5,
      "mortality_max_percent": 0.05
    },
    "29": {
      "weight_g": 1850,
      "feed_g": 160,
      "water_ml": 320,
      "temp_c": 20.2,
      "mortality_max_percent": 0.05
    },
    "30": {
      "weight_g": 1955,
      "feed_g": 165,
      "water_ml": 330,
      "temp_c": 20,
      "mortality_max_percent": 0.05
    },
    "31": {
      "weight_g": 2060,
      "feed_g": 169,
      "water_ml": 338,
      "temp_c": 19.8,
      "mortality_max_percent": 0.05
    },
    "32": {
      "weight_g": 2165,
      "feed_g": 173,
      "water_ml": 346,
      "temp_c": 19.5,
      "mortality_max_percent": 0.05
    },
    "33": {
      "weight_g": 2270,
      "feed_g": 177,
      "water_ml": 354,
      "temp_c": 19.2,
      "mortality_max_percent": 0.05
    },
    "34": {
      "weight_g": 2375,
      "feed_g": 181,
      "water_ml": 362,
      "temp_c": 19,
      "mortality_max_percent": 0.05
    },
    "35": {
      "weight_g": 2480,
      "feed_g": 184,
      "water_ml": 368,
      "temp_c": 18.8,
      "mortality_max_percent": 0.05
    },
    "36": {
      "weight_g": 2580,
      "feed_g": 187,
      "water_ml": 374,
      "temp_c": 18.6,
      "mortality_max_percent": 0.05
    },
    "37": {
      "weight_g": 2680,
      "feed_g": 190,
      "water_ml": 380,
      "temp_c": 18.4,
      "mortality_max_percent": 0.05
    },
    "38": {
      "weight_g": 2775,
      "feed_g": 193,
      "water_ml": 386,
      "temp_c": 18.2,
      "mortality_max_percent": 0.05
    },
    "39": {
      "weight_g": 2870,
      "feed_g": 195,
      "water_ml": 390,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    },
    "40": {
      "weight_g": 2960,
      "feed_g": 197,
      "water_ml": 394,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    },
    "41": {
      "weight_g": 3045,
      "feed_g": 199,
      "water_ml": 398,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    },
    "42": {
      "weight_g": 3125,
      "feed_g": 200,
      "water_ml": 400,
      "temp_c": 18,
      "mortality_max_percent": 0.05
    }
  }
};

export const BROILER_PLAN_DATA = [
  {
    "day": 1,
    "tasks_ru": "Подготовьте брудер. Проверьте температуру (32-33°C на уровне подстилки). Включите свет 24 часа. Напоите цыплят теплой водой (20-22°C) с глюкозой/витаминами. Через 2 часа насыпьте стартовый комбикорм на лотки/бумагу.",
    "tasks_uz": "Bruderni tayyorlang. Haroratni tekshiring (to'shak sathida 32-33°C). 24 soatlik yorug'likni yoqing. Jo'jalarga glyukoza/vitaminli iliq suv (20-22°C) bering. 2 soatdan so'ng podnos/qog'ozlarga start yemini seping.",
    "video_url": "https://www.youtube.com/watch?v=broiler_day_1"
  },
  {
    "day": 2,
    "tasks_ru": "Контроль температуры (32°C). Проверьте наполненность зобов у 50 цыплят (должно быть 95%+ с мягким кормом и водой). Чистите поилки, обновляйте воду.",
    "tasks_uz": "Harorat nazorati (32°C). 50 ta jo'janing jig'ildonini tekshiring (95%+ yumshoq yem va suv bilan to'lgan bo'lishi kerak). Sug'orgichlarni tozalang, suvni yangilang.",
    "video_url": null
  },
  {
    "day": 3,
    "tasks_ru": "Температура 31-32°C. Влажность 60-70%. Начните приучать к бункерным кормушкам. Осмотрите слабых цыплят. Контролируйте вентиляцию без сквозняков.",
    "tasks_uz": "Harorat 31-32°C. Namlik 60-70%. Bunkyerli yemdonlarga o'rgatishni boshlang. Kuchsiz jo'jalarni ajrating. Qoralamasiz (skvoznyaksiz) shamollatishni nazorat qiling.",
    "video_url": null
  },
  {
    "day": 4,
    "tasks_ru": "Температура 30-31°C. Переход на постоянные кормушки. Контрольное взвешивание выборки цыплят. Запишите расход корма и падёж в дневник.",
    "tasks_uz": "Harorat 30-31°C. Doimiy yemdonlarga o'tish. Namuna jo'jalarni nazorat taroziga tortish. Kunlik yem sarfi va nobudgarchilikni kundalikka yozing.",
    "video_url": null
  },
  {
    "day": 5,
    "tasks_ru": "Температура 30°C. Проверьте подстилку возле поилок, при необходимости подсыпьте сухие опилки. Курс витаминов по схеме ветеринара.",
    "tasks_uz": "Harorat 30°C. Sug'orgichlar atrofidagi to'shakni tekshiring, zarur bo'lsa quruq qipiq seping. Veterinariya sxemasi bo'yicha vitamin berish.",
    "video_url": null
  },
  {
    "day": 6,
    "tasks_ru": "Температура 29-30°C. Подготовка к первой вакцинации (Ньюкасл/Бронхит или Гамборо по региональному календарю). Проверьте чистоту систем поения.",
    "tasks_uz": "Harorat 29-30°C. Birinchi emlashga tayyorgarlik (Nyukasl/Bronxit yoki Gamboro hududiy taqvim bo'yicha). Suv ta'minoti tizimi tozaligini tekshiring.",
    "video_url": null
  },
  {
    "day": 7,
    "tasks_ru": "Конец 1-й недели. Взвешивание цыплят (норма Ross-308/Cobb-500: 180-200 г). Первая плановая вакцинация методом выпаивания. Температура 29°C.",
    "tasks_uz": "1-hafta yakuni. Jo'jalarni tortish (Ross-308/Cobb-500 normasi: 180-200 g). Ichirish usuli bilan birinchi rejali emlash. Harorat 29°C.",
    "video_url": "https://www.youtube.com/watch?v=broiler_week_1"
  },
  {
    "day": 8,
    "tasks_ru": "Температура 28-29°C. Начните расширение зоны содержания цыплят. Введите 1 час темноты в сутки для формирования костяка и иммунитета.",
    "tasks_uz": "Harorat 28-29°C. Jo'jalar saqlanadigan joyni kengaytirishni boshlang. Suyak va immunitet rivojlanishi uchun kuniga 1 soat qorong'ilik kiriting.",
    "video_url": null
  },
  {
    "day": 9,
    "tasks_ru": "Температура 28°C. Проверьте вентиляцию: аммиачный запах не должен ощущаться. Контроль расхода воды (должен быть в 1.8-2 раза больше веса съеденного корма).",
    "tasks_uz": "Harorat 28°C. Shamollatishni tekshiring: ammiak hidi bo'lmasligi kerak. Suv sarfini nazorat qiling (yeyilgan yem og'irligidan 1.8-2 baravar ko'p bo'lishi kerak).",
    "video_url": null
  },
  {
    "day": 10,
    "tasks_ru": "Температура 27-28°C. Проверьте высоту поилок и кормушек — поднимите на уровень спины птицы. Осмотрите помёт на отсутствие кокцидиоза (кровавых следов).",
    "tasks_uz": "Harorat 27-28°C. Sug'orgich va yemdonlar balandligini qushning orqa qismi balandligiga moslang. Axlatni qon izlari (koksidioz) yo'qligiga tekshiring.",
    "video_url": null
  },
  {
    "day": 11,
    "tasks_ru": "Температура 27°C. Увеличение темнового периода до 2 часов. Контроль качества подстилки, рыхление слежавшихся мест.",
    "tasks_uz": "Harorat 27°C. Qorong'i davrni 2 soatga uzaytiring. To'shak sifatini nazorat qiling, qotib qolgan joylarni yumshating.",
    "video_url": null
  },
  {
    "day": 12,
    "tasks_ru": "Температура 26-27°C. Подготовка ко второй вакцинации (болезнь Гамборо). За 2 часа до вакцинации перекройте воду для формирования жажды.",
    "tasks_uz": "Harorat 26-27°C. Ikkinchi emlashga tayyorgarlik (Gamboro kasalligi). Emlashdan 2 soat oldin chanqash hosil qilish uchun suvni to'xtating.",
    "video_url": null
  },
  {
    "day": 13,
    "tasks_ru": "Температура 26°C. План вакцинации Гамборо через воду с нейтрализатором хлора (молочный порошок или спец. таблетка).",
    "tasks_uz": "Harorat 26°C. Gamboro vaksinasini xlor neytrallovchi (sut kukuni yoki maxsus tabletka) qo'shilgan suv orqali berish.",
    "video_url": null
  },
  {
    "day": 14,
    "tasks_ru": "Конец 2-й недели. Взвешивание (норма: 450-480 г). Начало плавного перехода со Стартера на Ростовой комбикорм (75% старт / 25% рост).",
    "tasks_uz": "2-hafta yakuni. Taroziga tortish (norma: 450-480 g). Start yemdan O'sish (Grover) yemiga bosqichma-bosqich o'tish (75% start / 25% o'sish).",
    "video_url": "https://www.youtube.com/watch?v=broiler_week_2"
  },
  {
    "day": 15,
    "tasks_ru": "Температура 25-26°C. Переход корма: 50% Старт / 50% Рост. Проверьте активность стада и однородность поголовья.",
    "tasks_uz": "Harorat 25-26°C. Yem o'tishi: 50% Start / 50% O'sish. Gala faolligi va bir xil o'sayotganini tekshiring.",
    "video_url": null
  },
  {
    "day": 16,
    "tasks_ru": "Температура 25°C. Переход корма: 25% Старт / 75% Рост. Контроль влажности подстилки — удалите мокрые участки.",
    "tasks_uz": "Harorat 25°C. Yem o'tishi: 25% Start / 75% O'sish. To'shak namligini tekshiring — namlangan joylarni olib tashlang.",
    "video_url": null
  },
  {
    "day": 17,
    "tasks_ru": "Температура 24-25°C. Полный переход на 100% Ростовой комбикорм (гранула 2.5-3 мм). Увеличьте вентиляцию по мере роста живой массы.",
    "tasks_uz": "Harorat 24-25°C. To'liq 100% O'sish (Grover) yemiga o'tish (2.5-3 mm granula). Tirik vazn oshishi bilan shamollatish quvvatini oshiring.",
    "video_url": null
  },
  {
    "day": 18,
    "tasks_ru": "Температура 24°C. Темновой режим: 4 часа темноты (для здорового сердца и конечностей). Проверка давления в линии ниппелей.",
    "tasks_uz": "Harorat 24°C. Qorong'ilik rejimi: 4 soat (yurak va oyoq sog'lig'i uchun). Nippel sug'orgichlardagi bosimni tekshirish.",
    "video_url": null
  },
  {
    "day": 19,
    "tasks_ru": "Температура 23-24°C. Профилактика респираторных болезней (эфирные масла или щадящая аэрозольная дезинфекция в присутствии птицы).",
    "tasks_uz": "Harorat 23-24°C. Nafas yo'llari kasalliklarining oldini olish (efir moylari yoki parrandalar borligida yumshoq aerozol dezinfeksiya).",
    "video_url": null
  },
  {
    "day": 20,
    "tasks_ru": "Температура 23°C. Проверьте плотность посадки. Если птичник позволяет, откройте всю оставшуюся площадь помещения.",
    "tasks_uz": "Harorat 23°C. Zichlikni tekshiring. Agar bino imkon bersa, xonaning qolgan barcha maydonini to'liq oching.",
    "video_url": null
  },
  {
    "day": 21,
    "tasks_ru": "Конец 3-й недели. Контрольное взвешивание (норма: 900-1000 г). Ревакцинация против Ньюкасла (по рекомендации ветврача).",
    "tasks_uz": "3-hafta yakuni. Nazorat tortish (norma: 900-1000 g). Nyukaslga qarshi qayta emlash (veterinar tavsiyasiga ko'ra).",
    "video_url": "https://www.youtube.com/watch?v=broiler_week_3"
  },
  {
    "day": 22,
    "tasks_ru": "Температура 22-23°C. Контроль потребления воды. В жаркую погоду охлаждайте поступающую воду (оптимум 16-18°C).",
    "tasks_uz": "Harorat 22-23°C. Suv ichilishini nazorat qiling. Issiq havoda berilayotgan suvni salqin tuting (optimal 16-18°C).",
    "video_url": null
  },
  {
    "day": 23,
    "tasks_ru": "Температура 22°C. Проверка лап птицы на пододерматит (натоптыши). Если влажно под ногами — добавьте известь-пушонку и свежую подстилку.",
    "tasks_uz": "Harorat 22°C. Oyoq panjalarini pododermatitga tekshiring. Agar to'shak nam bo'lsa — so'ndirilgan ohak va yangi to'shak seping.",
    "video_url": null
  },
  {
    "day": 24,
    "tasks_ru": "Температура 21-22°C. Контроль скорости воздуха на уровне птицы: не допускать прямого обдува холодным воздухом.",
    "tasks_uz": "Harorat 21-22°C. Qushlar sathida havo harakati tezligini nazorat qiling: sovuq havo to'g'ridan-to'g'ri urilishiga yo'l qo'ymang.",
    "video_url": null
  },
  {
    "day": 25,
    "tasks_ru": "Температура 21°C. Проверьте конверсию корма (FCR). Очистка ламп и плафонов от птичьей пыли для поддержания светового потока.",
    "tasks_uz": "Harorat 21°C. Yem konversiyasini (FCR) hisoblang. Yorug'lik tushishini ta'minlash uchun chiroqlarni changdan tozalang.",
    "video_url": null
  },
  {
    "day": 26,
    "tasks_ru": "Температура 21°C. Осмотр птиц: проверьте дыхание (хрипы, вытягивание шеи). При признаках болезни обратитесь к ветеринару.",
    "tasks_uz": "Harorat 21°C. Qushlarni ko'zdan kechiring: nafas olishni tekshiring (xirillash, bo'yin cho'zish). Kasallik belgilarida veterinar chaqiring.",
    "video_url": null
  },
  {
    "day": 27,
    "tasks_ru": "Температура 20-21°C. Подготовка к переходу на Финишный комбикорм. Проверьте запасы корма на складе.",
    "tasks_uz": "Harorat 20-21°C. Finish yemiga o'tishga tayyorgarlik. Omborxonada yem zaxirasini tekshiring.",
    "video_url": null
  },
  {
    "day": 28,
    "tasks_ru": "Конец 4-й недели. Взвешивание (норма: 1500-1600 г). Начало перехода с Роста на Финиш (гранула 3.5-4 мм, 70% Рост / 30% Финиш).",
    "tasks_uz": "4-hafta yakuni. Taroziga tortish (norma: 1500-1600 g). Groverdan Finishga o'tishni boshlash (granula 3.5-4 mm, 70% O'sish / 30% Finish).",
    "video_url": "https://www.youtube.com/watch?v=broiler_week_4"
  },
  {
    "day": 29,
    "tasks_ru": "Температура 20°C. Переход корма: 50% Рост / 50% Финиш. Обеспечьте бесперебойную подачу свежей воды.",
    "tasks_uz": "Harorat 20°C. Yem o'tishi: 50% O'sish / 50% Finish. Toza suvning to'xtovsiz berilishini ta'minlang.",
    "video_url": null
  },
  {
    "day": 30,
    "tasks_ru": "Температура 20°C. Переход корма: 25% Рост / 75% Финиш. Проверьте работу аварийных вентиляторов или генератора.",
    "tasks_uz": "Harorat 20°C. Yem o'tishi: 25% O'sish / 75% Finish. Avariya ventilyatorlari va generatorning ishlashini tekshiring.",
    "video_url": null
  },
  {
    "day": 31,
    "tasks_ru": "Температура 19-20°C. 100% Финишный комбикорм. Прекращение выпойки антибиотиков и кокцидиостатиков (период выведения до убоя).",
    "tasks_uz": "Harorat 19-20°C. 100% Finish yemi. Antibiotik va koksidiostatiklarni ichirishni to'xtatish (so'yishdan oldingi tozalanish davri).",
    "video_url": null
  },
  {
    "day": 32,
    "tasks_ru": "Температура 19°C. Контроль перегрева: если на улице жара >30°C, включайте туманообразование или смачивание крыши.",
    "tasks_uz": "Harorat 19°C. Qizib ketishdan saqlash: tashqarida havo >30°C bo'lsa, tumanlagichlar yoki tomga suv sepishni yoqing.",
    "video_url": null
  },
  {
    "day": 33,
    "tasks_ru": "Температура 19°C. Проверьте состояние перьевого покрова и кожных покровов. Не допускайте столпотворения птицы у кормушек.",
    "tasks_uz": "Harorat 19°C. Pat qoplami va teri holatini tekshiring. Yemdonlar atrofida qushlar tiqilinchini oldini oling.",
    "video_url": null
  },
  {
    "day": 34,
    "tasks_ru": "Температура 18-19°C. Поднимите кормушки до уровня груди птицы, чтобы минимизировать рассыпание корма.",
    "tasks_uz": "Harorat 18-19°C. Yem isrof bo'lishini kamaytirish uchun yemdonlarni qushning ko'krak sathigacha ko'taring.",
    "video_url": null
  },
  {
    "day": 35,
    "tasks_ru": "Конец 5-й недели. Контрольное взвешивание (норма: 2100-2300 г). Оценка готовности к первому прореживанию стада (если планируется).",
    "tasks_uz": "5-hafta yakuni. Nazorat tortish (norma: 2100-2300 g). Podani birinchi siyraklatishga tayyorligini baholang (agar rejalashtirilgan bo'lsa).",
    "video_url": "https://www.youtube.com/watch?v=broiler_week_5"
  },
  {
    "day": 36,
    "tasks_ru": "Температура 18-19°C. Контроль влажности воздуха (оптимум 55-65%). Максимальное проветривание в дневное время.",
    "tasks_uz": "Harorat 18-19°C. Havo namligini nazorat qilish (optimal 55-65%). Kunduzgi vaqtda maksimal shamollatish.",
    "video_url": null
  },
  {
    "day": 37,
    "tasks_ru": "Температура 18°C. Проверка чистоты воды. Подготовка тары/ящиков для будущей отгрузки и дезинфекция транспорта.",
    "tasks_uz": "Harorat 18°C. Suv tozaligini tekshiring. Bo'lajak sotish/tashish uchun yashiklarni tayyorlash va transportni dezinfeksiya qilish.",
    "video_url": null
  },
  {
    "day": 38,
    "tasks_ru": "Температура 18°C. Мониторинг аппетита и подвижности. Запись данных по приросту и расходу корма в дневник.",
    "tasks_uz": "Harorat 18°C. Ishtaha va harakatchanlikni kuzatish. Kundalikka vazn qo'shilishi va yem sarfini qayd etish.",
    "video_url": null
  },
  {
    "day": 39,
    "tasks_ru": "Температура 18°C. Проверьте соответствие веса рыночным требованиям покупателей (оптимум 2.5 - 2.8 кг).",
    "tasks_uz": "Harorat 18°C. Qushlar vazni xaridorlarning bozor talabiga mosligini tekshiring (optimal 2.5 - 2.8 kg).",
    "video_url": null
  },
  {
    "day": 40,
    "tasks_ru": "Температура 18°C. Подготовка к завершению цикла: согласуйте график отгрузки с закупщиками или убойным цехом.",
    "tasks_uz": "Harorat 18°C. Siklni yakunlashga tayyorgarlik: xaridorlar yoki kushxona bilan topshirish vaqtini kelishib oling.",
    "video_url": null
  },
  {
    "day": 41,
    "tasks_ru": "Температура 18°C. За 8-10 часов до отлова прекратите подачу корма для опорожнения кишечника. Воду НЕ отключать до самого начала отлова!",
    "tasks_uz": "Harorat 18°C. Qushlarni ushlashdan 8-10 soat oldin ichaklarni bo'shatish uchun yem berishni to'xtating. Suvni ushlash boshlanguncha UZMANG!",
    "video_url": null
  },
  {
    "day": 42,
    "tasks_ru": "Финальный день (42 дня). Отлов при синем/приглушенном свете без травм. Итоговое взвешивание, фиксация FCR и сохранности партии в AgroZen.",
    "tasks_uz": "Yakuniy kun (42 kun). Shikast yetkazmaslik uchun ko'k/xira chiroqda ushlash. Yakuniy taroziga tortish, AgroZen ilovasida partiyani yakunlash.",
    "video_url": "https://www.youtube.com/watch?v=broiler_finish"
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
  const articles = language === 'ru' ? KNOWLEDGE_ARTICLES_RU : (language === 'en' ? KNOWLEDGE_ARTICLES_RU : KNOWLEDGE_ARTICLES_UZ);
  const queryTokens = tokenize(query);

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
  const queryLower = query.toLowerCase();
  const normsKeywords = [
    'norma', 'normasi', 'ogirlik', 'vazn', 'harorat', 'temperatura', 'gradus',
    'yem', 'sarfi', 'suv', 'hafta', 'kun', 'jadval', 'ross', 'cobb',
    'норма', 'вес', 'масса', 'температура', 'градус', 'корм', 'расход', 'вода', 'неделя', 'день',
    'norm', 'norms', 'weight', 'target', 'temperature', 'feed', 'consumption', 'water', 'week', 'day'
  ];

  const mentionsNorms = normsKeywords.some((kw) => queryLower.includes(kw));
  if (mentionsNorms) {
    topics.push('norms.json');
    contextParts.push(
      '### Ross-308 / Cobb-500 normolari jadvali (Weekly Norms):\n' +
      JSON.stringify(NORMS_DATA.weekly_norms, null, 2)
    );
  }

  return {
    topics,
    contextText: contextParts.join('\n\n---\n\n'),
  };
}
