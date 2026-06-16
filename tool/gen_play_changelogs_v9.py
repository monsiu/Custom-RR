#!/usr/bin/env python3
"""Write the v1.2.0 (versionCode 9) Play release notes into every locale's
changelogs/9.txt. en-US stays the canonical approved text; the rest are
translations that keep brand/tech terms in Latin (Custom RR, GitHub
Discussions, Discord, Twitter/X, Telegram, PixelOS, Paranoid Android, ROM),
matching the style of the existing localized store listings.
"""
import os
import sys

ROOT = "fastlane/metadata/android"

# Canonical English (already on disk as en-US/changelogs/9.txt). Used for
# en-US plus every regional English variant.
EN = (
    "- Added a Community section that links to the project's GitHub Discussions "
    "(announcements, Q&A, ideas, polls, and more).\n"
    "- The Community screen shows recent discussions and a Discord invite to reach "
    "out directly and get updates.\n"
    "- Added a Socials option in About for Twitter/X and Telegram.\n"
    "- Added richer ROM screenshots: PixelOS gallery and full-size Paranoid Android shots.\n"
    "- Desktop builds now show the donation thank-you message.\n"
    "- Refreshed copy and fixed unreliable screenshots.\n"
)

# Translations keyed by base language. Regional variants are mapped below.
LANG = {
    "af": (
        "- Nuwe Gemeenskap-afdeling wat na die projek se GitHub Discussions skakel "
        "(aankondigings, V&A, idees, peilings en meer).\n"
        "- Die Gemeenskap-skerm wys onlangse besprekings en 'n Discord-uitnodiging vir "
        "direkte opdaterings.\n"
        "- Nuwe Sosiale-opsie in Aangaande vir Twitter/X en Telegram.\n"
        "- Ryker ROM-skermkiekies: PixelOS-galery en volgrootte Paranoid Android.\n"
        "- Rekenaarbouwerke wys nou die skenkingsdankie-boodskap.\n"
        "- Teks opgefris en onbetroubare skermkiekies reggemaak.\n"
    ),
    "am": (
        "- ከፕሮጀክቱ GitHub Discussions ጋር የሚያገናኝ አዲስ የማኅበረሰብ ክፍል (ማስታወቂያዎች፣ ጥያቄና መልስ፣ ሐሳቦች፣ ምርጫዎች)።\n"
        "- የማኅበረሰብ ማያ ገጽ የቅርብ ውይይቶችን እና ቀጥተኛ ዝመናዎችን ለማግኘት የDiscord ግብዣ ያሳያል።\n"
        "- በ«ስለ» ውስጥ ለTwitter/X እና Telegram አዲስ የSocials አማራጭ።\n"
        "- የበለጸጉ የROM ቅጽበታዊ ገጽ እይታዎች፦ PixelOS ማዕከለ-ስዕላት እና ሙሉ መጠን Paranoid Android።\n"
        "- የዴስክቶፕ ግንባታዎች አሁን የልገሳ ምስጋና መልእክት ያሳያሉ።\n"
        "- ጽሑፍ ታድሷል፤ አስተማማኝ ያልሆኑ ቅጽበታዊ እይታዎች ተስተካክለዋል።\n"
    ),
    "ar": (
        "- قسم Community جديد يرتبط بـ GitHub Discussions (إعلانات، أسئلة وأجوبة، أفكار، استطلاعات).\n"
        "- تعرض شاشة Community أحدث النقاشات ودعوة Discord للتواصل المباشر والحصول على التحديثات.\n"
        "- خيار Socials جديد في «حول» لـ Twitter/X و Telegram.\n"
        "- لقطات ROM أغنى: معرض PixelOS ولقطات Paranoid Android بالحجم الكامل.\n"
        "- إصدارات سطح المكتب تعرض الآن رسالة شكر التبرع.\n"
        "- تحديث النصوص وإصلاح اللقطات غير الموثوقة.\n"
    ),
    "az": (
        "- GitHub Discussions ilə əlaqələndirən yeni Community bölməsi (elanlar, sual-cavab, ideyalar, sorğular).\n"
        "- Community ekranı son müzakirələri və birbaşa yeniliklər üçün Discord dəvətini göstərir.\n"
        "- «Haqqında» bölməsində Twitter/X və Telegram üçün yeni Socials seçimi.\n"
        "- Daha zəngin ROM ekran görüntüləri: PixelOS qalereyası və tam ölçülü Paranoid Android.\n"
        "- Masaüstü versiyaları artıq ianə təşəkkür mesajını göstərir.\n"
        "- Mətn yeniləndi və etibarsız ekran görüntüləri düzəldildi.\n"
    ),
    "be": (
        "- Новы раздзел Community са спасылкай на GitHub Discussions (анонсы, пытанні і адказы, ідэі, апытанні).\n"
        "- Экран Community паказвае апошнія абмеркаванні і запрашэнне ў Discord для прамой сувязі і навін.\n"
        "- Новы пункт Socials у «Пра праграму» для Twitter/X і Telegram.\n"
        "- Багацейшыя здымкі ROM: галерэя PixelOS і поўнапамерныя здымкі Paranoid Android.\n"
        "- Зборкі для ПК цяпер паказваюць паведамленне з падзякай за ахвяраванне.\n"
        "- Абноўлены тэкст і выпраўлены ненадзейныя здымкі экрана.\n"
    ),
    "bg": (
        "- Нов раздел Community с връзка към GitHub Discussions (съобщения, въпроси и отговори, идеи, анкети).\n"
        "- Екранът Community показва скорошни обсъждания и покана в Discord за директна връзка и новини.\n"
        "- Нова опция Socials в «Относно» за Twitter/X и Telegram.\n"
        "- По-богати ROM екранни снимки: галерия PixelOS и пълноразмерни кадри на Paranoid Android.\n"
        "- Версиите за настолен компютър вече показват благодарственото съобщение за дарение.\n"
        "- Обновен текст и поправени ненадеждни екранни снимки.\n"
    ),
    "bn": (
        "- প্রজেক্টের GitHub Discussions-এর সাথে যুক্ত নতুন Community বিভাগ (ঘোষণা, প্রশ্নোত্তর, আইডিয়া, পোল)।\n"
        "- Community স্ক্রিন সাম্প্রতিক আলোচনা ও সরাসরি আপডেটের জন্য একটি Discord আমন্ত্রণ দেখায়।\n"
        "- «About»-এ Twitter/X ও Telegram-এর জন্য নতুন Socials অপশন।\n"
        "- আরও সমৃদ্ধ ROM স্ক্রিনশট: PixelOS গ্যালারি ও পূর্ণ আকারের Paranoid Android।\n"
        "- ডেস্কটপ বিল্ড এখন অনুদানের ধন্যবাদ বার্তা দেখায়।\n"
        "- লেখা হালনাগাদ এবং অনির্ভরযোগ্য স্ক্রিনশট ঠিক করা হয়েছে।\n"
    ),
    "ca": (
        "- Nova secció Community que enllaça amb GitHub Discussions (anuncis, preguntes, idees, enquestes).\n"
        "- La pantalla Community mostra debats recents i una invitació a Discord per contactar i rebre novetats.\n"
        "- Nova opció Socials a «Quant a» per a Twitter/X i Telegram.\n"
        "- Captures de ROM més riques: galeria PixelOS i imatges de Paranoid Android a mida completa.\n"
        "- Les versions d'escriptori ara mostren el missatge d'agraïment per la donació.\n"
        "- Textos renovats i captures poc fiables corregides.\n"
    ),
    "cs": (
        "- Nová sekce Community s odkazem na GitHub Discussions (oznámení, dotazy, nápady, ankety).\n"
        "- Obrazovka Community zobrazuje nedávné diskuze a pozvánku na Discord pro přímý kontakt a novinky.\n"
        "- Nová volba Socials v sekci «O aplikaci» pro Twitter/X a Telegram.\n"
        "- Bohatší snímky ROM: galerie PixelOS a snímky Paranoid Android v plné velikosti.\n"
        "- Sestavení pro počítač nyní zobrazují děkovnou zprávu za dar.\n"
        "- Aktualizované texty a opravené nespolehlivé snímky obrazovky.\n"
    ),
    "da": (
        "- Ny Community-sektion med link til GitHub Discussions (meddelelser, spørgsmål, idéer, afstemninger).\n"
        "- Community-skærmen viser seneste diskussioner og en Discord-invitation til direkte kontakt og opdateringer.\n"
        "- Ny Socials-mulighed i «Om» til Twitter/X og Telegram.\n"
        "- Rigere ROM-skærmbilleder: PixelOS-galleri og Paranoid Android i fuld størrelse.\n"
        "- Computerudgaver viser nu takkebeskeden for donation.\n"
        "- Opfrisket tekst og rettede upålidelige skærmbilleder.\n"
    ),
    "de": (
        "- Neuer Community-Bereich mit Link zu GitHub Discussions (Ankündigungen, Fragen, Ideen, Umfragen).\n"
        "- Der Community-Bildschirm zeigt aktuelle Diskussionen und eine Discord-Einladung für direkten Kontakt und Neuigkeiten.\n"
        "- Neue Socials-Option unter «Über» für Twitter/X und Telegram.\n"
        "- Reichere ROM-Screenshots: PixelOS-Galerie und Paranoid Android in voller Größe.\n"
        "- Desktop-Builds zeigen jetzt die Spenden-Dankesnachricht.\n"
        "- Texte überarbeitet und unzuverlässige Screenshots behoben.\n"
    ),
    "el": (
        "- Νέα ενότητα Community με σύνδεσμο στο GitHub Discussions (ανακοινώσεις, ερωτήσεις, ιδέες, ψηφοφορίες).\n"
        "- Η οθόνη Community δείχνει πρόσφατες συζητήσεις και πρόσκληση Discord για άμεση επαφή και ενημερώσεις.\n"
        "- Νέα επιλογή Socials στο «Σχετικά» για Twitter/X και Telegram.\n"
        "- Πλουσιότερα στιγμιότυπα ROM: συλλογή PixelOS και Paranoid Android πλήρους μεγέθους.\n"
        "- Οι εκδόσεις υπολογιστή δείχνουν τώρα μήνυμα ευχαριστίας για τη δωρεά.\n"
        "- Ανανεωμένα κείμενα και διόρθωση αναξιόπιστων στιγμιότυπων.\n"
    ),
    "es": (
        "- Nueva sección Community enlazada con GitHub Discussions (anuncios, preguntas, ideas, encuestas).\n"
        "- La pantalla Community muestra debates recientes y una invitación a Discord para contacto y novedades.\n"
        "- Nueva opción Socials en «Acerca de» para Twitter/X y Telegram.\n"
        "- Capturas de ROM más completas: galería PixelOS y Paranoid Android a tamaño completo.\n"
        "- El escritorio ya muestra el mensaje de agradecimiento por la donación.\n"
        "- Textos renovados y capturas poco fiables corregidas.\n"
    ),
    "et": (
        "- Uus Community jaotis, mis viib GitHub Discussionsisse (teated, küsimused-vastused, ideed, küsitlused).\n"
        "- Community ekraan näitab hiljutisi arutelusid ja Discordi kutset otsekontaktiks ja uudisteks.\n"
        "- Uus Socials valik jaotises «Teave» Twitter/X ja Telegram jaoks.\n"
        "- Rikkalikumad ROM ekraanipildid: PixelOS galerii ja täismõõdus Paranoid Android.\n"
        "- Lauaarvuti versioonid näitavad nüüd annetuse tänusõnumit.\n"
        "- Värskendatud tekst ja parandatud ebausaldusväärsed ekraanipildid.\n"
    ),
    "eu": (
        "- Community atal berria, GitHub Discussions-era estekatua (iragarpenak, galde-erantzunak, ideiak, inkestak).\n"
        "- Community pantailak azken eztabaidak eta Discord gonbidapena erakusten ditu, berrietarako.\n"
        "- Socials aukera berria «Honi buruz» atalean Twitter/X eta Telegram-erako.\n"
        "- ROM pantaila-argazki aberatsagoak: PixelOS galeria eta Paranoid Android tamaina osoan.\n"
        "- Mahaigainekoek orain dohaintzaren esker-mezua erakusten dute.\n"
        "- Testua freskatu eta pantaila-argazki ezegonkorrak konpondu dira.\n"
    ),
    "fa": (
        "- بخش جدید Community با پیوند به GitHub Discussions (اعلان‌ها، پرسش و پاسخ، ایده‌ها، نظرسنجی‌ها).\n"
        "- صفحه Community گفت‌وگوهای اخیر و دعوت Discord برای ارتباط مستقیم و دریافت به‌روزرسانی‌ها را نشان می‌دهد.\n"
        "- گزینه Socials جدید در «درباره» برای Twitter/X و Telegram.\n"
        "- اسکرین‌شات‌های غنی‌تر ROM: گالری PixelOS و تصاویر تمام‌اندازه Paranoid Android.\n"
        "- نسخه‌های دسکتاپ اکنون پیام تشکر برای کمک مالی را نشان می‌دهند.\n"
        "- بازنویسی متن‌ها و رفع اسکرین‌شات‌های نامطمئن.\n"
    ),
    "fi": (
        "- Uusi Community-osio, joka linkittää GitHub Discussionsiin (ilmoitukset, kysymykset, ideat, äänestykset).\n"
        "- Community-näyttö esittää tuoreet keskustelut ja Discord-kutsun yhteydenpitoon ja päivityksiin.\n"
        "- Uusi Socials-valinta kohdassa «Tietoja» Twitter/X:lle ja Telegramille.\n"
        "- Rikkaammat ROM-kuvakaappaukset: PixelOS-galleria ja täysikokoinen Paranoid Android.\n"
        "- Työpöytäversiot näyttävät nyt lahjoituksen kiitosviestin.\n"
        "- Tekstit päivitetty ja epäluotettavat kuvakaappaukset korjattu.\n"
    ),
    "fil": (
        "- Bagong Community section na naka-link sa GitHub Discussions (mga anunsyo, Q&A, ideya, poll).\n"
        "- Ipinapakita ng Community screen ang mga kamakailang talakayan at isang Discord invite para sa direktang updates.\n"
        "- Bagong Socials option sa «About» para sa Twitter/X at Telegram.\n"
        "- Mas mayamang ROM screenshots: PixelOS gallery at full-size na Paranoid Android.\n"
        "- Ipinapakita na ng desktop builds ang mensahe ng pasasalamat sa donasyon.\n"
        "- Na-refresh na teksto at naayos na hindi maaasahang screenshots.\n"
    ),
    "fr": (
        "- Nouvelle section Community reliée aux GitHub Discussions (annonces, questions, idées, sondages).\n"
        "- L'écran Community montre les discussions récentes et une invitation Discord pour contact direct et mises à jour.\n"
        "- Nouvelle option Socials dans « À propos » pour Twitter/X et Telegram.\n"
        "- Captures de ROM enrichies : galerie PixelOS et Paranoid Android en taille réelle.\n"
        "- Les versions de bureau affichent le remerciement pour les dons.\n"
        "- Textes rafraîchis et captures peu fiables corrigées.\n"
    ),
    "gl": (
        "- Nova sección Community enlazada con GitHub Discussions (anuncios, preguntas, ideas, enquisas).\n"
        "- A pantalla Community amosa debates recentes e unha invitación a Discord para contacto e novidades.\n"
        "- Nova opción Socials en «Acerca de» para Twitter/X e Telegram.\n"
        "- Capturas de ROM máis completas: galería PixelOS e Paranoid Android a tamaño completo.\n"
        "- O escritorio amosa agora a mensaxe de agradecemento pola doazón.\n"
        "- Textos renovados e capturas pouco fiables corrixidas.\n"
    ),
    "gu": (
        "- પ્રોજેક્ટના GitHub Discussions સાથે જોડતો નવો Community વિભાગ (જાહેરાતો, પ્રશ્નોત્તર, વિચારો, મતદાન).\n"
        "- Community સ્ક્રીન તાજેતરની ચર્ચાઓ અને સીધા અપડેટ માટે Discord આમંત્રણ બતાવે છે.\n"
        "- «About»માં Twitter/X અને Telegram માટે નવો Socials વિકલ્પ.\n"
        "- વધુ સમૃદ્ધ ROM સ્ક્રીનશોટ: PixelOS ગૅલેરી અને પૂર્ણ કદના Paranoid Android.\n"
        "- ડેસ્કટોપ બિલ્ડ હવે દાન બદલ આભારનો સંદેશ બતાવે છે.\n"
        "- લખાણ તાજું કર્યું અને અવિશ્વસનીય સ્ક્રીનશોટ સુધાર્યા.\n"
    ),
    "hi": (
        "- प्रोजेक्ट के GitHub Discussions से जुड़ा नया Community सेक्शन (घोषणाएँ, प्रश्नोत्तर, विचार, पोल)।\n"
        "- Community स्क्रीन हाल की चर्चाएँ और सीधे अपडेट पाने के लिए Discord आमंत्रण दिखाती है।\n"
        "- «About» में Twitter/X और Telegram के लिए नया Socials विकल्प।\n"
        "- अधिक समृद्ध ROM स्क्रीनशॉट: PixelOS गैलरी और पूर्ण आकार के Paranoid Android।\n"
        "- डेस्कटॉप बिल्ड अब दान के लिए धन्यवाद संदेश दिखाते हैं।\n"
        "- टेक्स्ट ताज़ा किया और अविश्वसनीय स्क्रीनशॉट ठीक किए।\n"
    ),
    "hr": (
        "- Novi odjeljak Community s poveznicom na GitHub Discussions (objave, pitanja, ideje, ankete).\n"
        "- Zaslon Community prikazuje nedavne rasprave i Discord pozivnicu za izravan kontakt i novosti.\n"
        "- Nova opcija Socials u «O aplikaciji» za Twitter/X i Telegram.\n"
        "- Bogatije ROM snimke zaslona: PixelOS galerija i Paranoid Android u punoj veličini.\n"
        "- Verzije za računalo sada prikazuju poruku zahvale za donaciju.\n"
        "- Osvježen tekst i ispravljene nepouzdane snimke zaslona.\n"
    ),
    "hu": (
        "- Új Community szakasz, amely a GitHub Discussionsra hivatkozik (bejelentések, kérdések, ötletek, szavazások).\n"
        "- A Community képernyő friss beszélgetéseket és Discord-meghívót mutat kapcsolathoz és hírekhez.\n"
        "- Új Socials lehetőség a «Névjegy» alatt a Twitter/X és Telegram számára.\n"
        "- Gazdagabb ROM képernyőképek: PixelOS galéria és teljes méretű Paranoid Android.\n"
        "- Az asztali változatok már megjelenítik az adományért járó köszönetet.\n"
        "- Frissített szövegek és javított megbízhatatlan képernyőképek.\n"
    ),
    "hy": (
        "- Նոր Community բաժին՝ կապված GitHub Discussions-ի հետ (հայտարարություններ, հարցեր, գաղափարներ, հարցումներ)։\n"
        "- Community էկրանը ցույց է տալիս վերջին քննարկումները և Discord-ի հրավեր՝ կապի ու թարմացումների համար։\n"
        "- Նոր Socials տարբերակ «Մասին»-ում՝ Twitter/X-ի և Telegram-ի համար։\n"
        "- Ավելի հարուստ ROM սքրինշոթներ՝ PixelOS պատկերասրահ և լրիվ չափի Paranoid Android։\n"
        "- Աշխատասեղանի տարբերակներն այժմ ցույց են տալիս նվիրատվության շնորհակալությունը։\n"
        "- Թարմացված տեքստ և ուղղված անվստահելի սքրինշոթներ։\n"
    ),
    "id": (
        "- Bagian Community baru yang menautkan ke GitHub Discussions (pengumuman, tanya jawab, ide, jajak pendapat).\n"
        "- Layar Community menampilkan diskusi terbaru dan undangan Discord untuk kontak langsung dan pembaruan.\n"
        "- Opsi Socials baru di «Tentang» untuk Twitter/X dan Telegram.\n"
        "- Tangkapan layar ROM lebih kaya: galeri PixelOS dan Paranoid Android ukuran penuh.\n"
        "- Versi desktop kini menampilkan pesan terima kasih donasi.\n"
        "- Teks disegarkan dan tangkapan layar yang tidak andal diperbaiki.\n"
    ),
    "is": (
        "- Nýr Community hluti sem tengist GitHub Discussions (tilkynningar, spurningar, hugmyndir, kannanir).\n"
        "- Community skjárinn sýnir nýlegar umræður og Discord boð fyrir beint samband og uppfærslur.\n"
        "- Nýr Socials valkostur í «Um» fyrir Twitter/X og Telegram.\n"
        "- Ríkari ROM skjámyndir: PixelOS safn og Paranoid Android í fullri stærð.\n"
        "- Skjáborðsútgáfur sýna nú þakkarskilaboð fyrir framlag.\n"
        "- Endurnýjaður texti og lagaðar óáreiðanlegar skjámyndir.\n"
    ),
    "it": (
        "- Nuova sezione Community collegata alle GitHub Discussions (annunci, domande, idee, sondaggi).\n"
        "- La schermata Community mostra le discussioni recenti e un invito Discord per contatto e aggiornamenti.\n"
        "- Nuova opzione Socials in «Informazioni» per Twitter/X e Telegram.\n"
        "- Screenshot ROM più ricchi: galleria PixelOS e Paranoid Android a grandezza naturale.\n"
        "- Le versioni desktop ora mostrano il ringraziamento per la donazione.\n"
        "- Testi aggiornati e screenshot poco affidabili corretti.\n"
    ),
    "iw": (
        "- מקטע Community חדש המקושר ל-GitHub Discussions (הכרזות, שאלות ותשובות, רעיונות, סקרים).\n"
        "- מסך Community מציג דיונים אחרונים והזמנה ל-Discord ליצירת קשר ישיר וקבלת עדכונים.\n"
        "- אפשרות Socials חדשה ב«אודות» עבור Twitter/X ו-Telegram.\n"
        "- צילומי מסך עשירים יותר של ROM: גלריית PixelOS ותמונות Paranoid Android בגודל מלא.\n"
        "- גרסאות שולחן העבודה מציגות כעת את הודעת התודה על התרומה.\n"
        "- טקסט רענן וצילומי מסך לא אמינים תוקנו.\n"
    ),
    "ja": (
        "- プロジェクトの GitHub Discussions にリンクする新しい Community セクション（お知らせ、Q&A、アイデア、投票など）。\n"
        "- Community 画面に最近の議論と、直接連絡して更新を受け取れる Discord 招待を表示。\n"
        "- 「情報」に Twitter/X と Telegram 向けの Socials オプションを追加。\n"
        "- より充実した ROM のスクリーンショット: PixelOS ギャラリーとフルサイズの Paranoid Android。\n"
        "- デスクトップ版で寄付へのお礼メッセージを表示するようになりました。\n"
        "- 文言を刷新し、不安定なスクリーンショットを修正。\n"
    ),
    "ka": (
        "- ახალი Community განყოფილება GitHub Discussions-თან კავშირით (განცხადებები, კითხვა-პასუხი, იდეები, გამოკითხვები).\n"
        "- Community ეკრანი აჩვენებს ბოლო განხილვებს და Discord-მოწვევას პირდაპირი კავშირისა და სიახლეებისთვის.\n"
        "- ახალი Socials პარამეტრი «შესახებ»-ში Twitter/X-ისა და Telegram-ისთვის.\n"
        "- უფრო მდიდარი ROM ეკრანის სურათები: PixelOS გალერეა და სრული ზომის Paranoid Android.\n"
        "- დესკტოპ ვერსიები ახლა აჩვენებენ შემოწირულობის მადლობას.\n"
        "- განახლებული ტექსტი და გასწორებული არასანდო ეკრანის სურათები.\n"
    ),
    "kk": (
        "- GitHub Discussions-пен байланыстыратын жаңа Community бөлімі (хабарландырулар, сұрақ-жауап, идеялар, сауалнамалар).\n"
        "- Community экраны соңғы талқылаулар мен тікелей байланыс әрі жаңартулар үшін Discord шақыруын көрсетеді.\n"
        "- «Қолданба туралы» бөлімінде Twitter/X пен Telegram үшін жаңа Socials опциясы.\n"
        "- Бай ROM скриншоттары: PixelOS галереясы және толық өлшемді Paranoid Android.\n"
        "- Десктоп нұсқалары енді қайырымдылық алғысын көрсетеді.\n"
        "- Мәтін жаңартылды және сенімсіз скриншоттар түзетілді.\n"
    ),
    "km": (
        "- ផ្នែក Community ថ្មីដែលភ្ជាប់ទៅ GitHub Discussions (សេចក្ដីប្រកាស សំណួរ-ចម្លើយ គំនិត ការស្ទង់មតិ)។\n"
        "- អេក្រង់ Community បង្ហាញការពិភាក្សាថ្មីៗ និងការអញ្ជើញ Discord សម្រាប់ទំនាក់ទំនងផ្ទាល់ និងព័ត៌មានថ្មី។\n"
        "- ជម្រើស Socials ថ្មីនៅក្នុង «អំពី» សម្រាប់ Twitter/X និង Telegram។\n"
        "- រូបថតអេក្រង់ ROM សម្បូរបែប៖ វិចិត្រសាល PixelOS និង Paranoid Android ទំហំពេញ។\n"
        "- កំណែ Desktop ឥឡូវនេះបង្ហាញសារអរគុណចំពោះការបរិច្ចាគ។\n"
        "- ធ្វើបច្ចុប្បន្នភាពអក្សរ និងជួសជុលរូបថតអេក្រង់ដែលមិនអាចទុកចិត្តបាន។\n"
    ),
    "kn": (
        "- ಪ್ರಾಜೆಕ್ಟ್‌ನ GitHub Discussions ಗೆ ಲಿಂಕ್ ಮಾಡುವ ಹೊಸ Community ವಿಭಾಗ (ಪ್ರಕಟಣೆಗಳು, ಪ್ರಶ್ನೋತ್ತರ, ಆಲೋಚನೆಗಳು, ಸಮೀಕ್ಷೆಗಳು).\n"
        "- Community ಪರದೆ ಇತ್ತೀಚಿನ ಚರ್ಚೆಗಳನ್ನು ಮತ್ತು ನೇರ ಸಂಪರ್ಕ ಹಾಗೂ ಅಪ್‌ಡೇಟ್‌ಗೆ Discord ಆಹ್ವಾನ ತೋರಿಸುತ್ತದೆ.\n"
        "- «About» ನಲ್ಲಿ Twitter/X ಮತ್ತು Telegram ಗಾಗಿ ಹೊಸ Socials ಆಯ್ಕೆ.\n"
        "- ಶ್ರೀಮಂತ ROM ಸ್ಕ್ರೀನ್‌ಶಾಟ್: PixelOS ಗ್ಯಾಲರಿ ಮತ್ತು ಪೂರ್ಣ ಗಾತ್ರದ Paranoid Android.\n"
        "- ಡೆಸ್ಕ್‌ಟಾಪ್ ಬಿಲ್ಡ್‌ಗಳು ಈಗ ದೇಣಿಗೆ ಧನ್ಯವಾದ ಸಂದೇಶ ತೋರಿಸುತ್ತವೆ.\n"
        "- ಪಠ್ಯ ನವೀಕರಿಸಲಾಗಿದೆ ಮತ್ತು ಅವಿಶ್ವಾಸಾರ್ಹ ಸ್ಕ್ರೀನ್‌ಶಾಟ್ ಸರಿಪಡಿಸಲಾಗಿದೆ.\n"
    ),
    "ko": (
        "- 프로젝트의 GitHub Discussions로 연결되는 새 Community 섹션(공지, Q&A, 아이디어, 투표 등).\n"
        "- Community 화면에 최근 토론과 직접 연락해 업데이트를 받을 수 있는 Discord 초대가 표시됩니다.\n"
        "- 「정보」에 Twitter/X 및 Telegram용 Socials 옵션 추가.\n"
        "- 더 풍부한 ROM 스크린샷: PixelOS 갤러리와 전체 크기 Paranoid Android.\n"
        "- 데스크톱 빌드에서 이제 기부 감사 메시지를 표시합니다.\n"
        "- 문구를 새로 다듬고 불안정한 스크린샷을 수정했습니다.\n"
    ),
    "ky": (
        "- GitHub Discussions менен байланыштырган жаңы Community бөлүмү (жарыялар, суроо-жооп, идеялар, сурамжылоо).\n"
        "- Community экраны акыркы талкуу жана түз байланыш, жаңылыктар үчүн Discord чакыруусун көрсөтөт.\n"
        "- «Тиркеме жөнүндө» бөлүмүндө Twitter/X жана Telegram үчүн жаңы Socials опциясы.\n"
        "- Бай ROM скриншоттору: PixelOS галереясы жана толук өлчөмдөгү Paranoid Android.\n"
        "- Десктоп версиялары эми кайрымдуулук үчүн ыраазычылык көрсөтөт.\n"
        "- Текст жаңыланды жана ишенимсиз скриншоттор оңдолду.\n"
    ),
    "lo": (
        "- ພາກສ່ວນ Community ໃໝ່ ທີ່ເຊື່ອມຕໍ່ກັບ GitHub Discussions (ປະກາດ, ຖາມ-ຕອບ, ແນວຄິດ, ໂພລ).\n"
        "- ໜ້າຈໍ Community ສະແດງການສົນທະນາລ່າສຸດ ແລະ ຄຳເຊີນ Discord ສຳລັບການຕິດຕໍ່ໂດຍກົງ ແລະ ການອັບເດດ.\n"
        "- ຕົວເລືອກ Socials ໃໝ່ໃນ «ກ່ຽວກັບ» ສຳລັບ Twitter/X ແລະ Telegram.\n"
        "- ພາບໜ້າຈໍ ROM ທີ່ອຸດົມສົມບູນຂຶ້ນ: ຄັງຮູບ PixelOS ແລະ Paranoid Android ຂະໜາດເຕັມ.\n"
        "- ເວີຊັນເດສ໌ທັອບ ຕອນນີ້ສະແດງຂໍ້ຄວາມຂອບໃຈສຳລັບການບໍລິຈາກ.\n"
        "- ປັບປຸງຂໍ້ຄວາມ ແລະ ແກ້ໄຂພາບໜ້າຈໍທີ່ບໍ່ໜ້າເຊື່ອຖື.\n"
    ),
    "lt": (
        "- Naujas Community skyrius, susietas su GitHub Discussions (skelbimai, klausimai, idėjos, apklausos).\n"
        "- Community ekranas rodo naujausias diskusijas ir Discord kvietimą tiesioginiam ryšiui bei naujienoms.\n"
        "- Nauja Socials parinktis skiltyje «Apie» Twitter/X ir Telegram.\n"
        "- Turtingesnės ROM ekrano nuotraukos: PixelOS galerija ir viso dydžio Paranoid Android.\n"
        "- Kompiuterio versijos dabar rodo padėkos už auką pranešimą.\n"
        "- Atnaujinti tekstai ir pataisytos nepatikimos ekrano nuotraukos.\n"
    ),
    "lv": (
        "- Jauna Community sadaļa, kas saistīta ar GitHub Discussions (paziņojumi, jautājumi, idejas, aptaujas).\n"
        "- Community ekrāns rāda nesenās diskusijas un Discord ielūgumu tiešam kontaktam un jaunumiem.\n"
        "- Jauna Socials iespēja sadaļā «Par» Twitter/X un Telegram.\n"
        "- Bagātīgāki ROM ekrānuzņēmumi: PixelOS galerija un pilna izmēra Paranoid Android.\n"
        "- Datora versijas tagad rāda pateicības ziņojumu par ziedojumu.\n"
        "- Atsvaidzināts teksts un izlaboti neuzticami ekrānuzņēmumi.\n"
    ),
    "mk": (
        "- Нов Community дел поврзан со GitHub Discussions (објави, прашања и одговори, идеи, анкети).\n"
        "- Екранот Community прикажува неодамнешни дискусии и Discord покана за директен контакт и новости.\n"
        "- Нова Socials опција во «За апликацијата» за Twitter/X и Telegram.\n"
        "- Побогати ROM слики од екран: PixelOS галерија и Paranoid Android во целосна големина.\n"
        "- Верзиите за компјутер сега ја прикажуваат пораката за благодарност за донација.\n"
        "- Освежен текст и поправени несигурни слики од екран.\n"
    ),
    "ml": (
        "- GitHub Discussions-ലേക്ക് ലിങ്ക് ചെയ്യുന്ന പുതിയ Community വിഭാഗം (അറിയിപ്പുകൾ, ചോദ്യോത്തരം, ആശയങ്ങൾ, പോളുകൾ).\n"
        "- Community സ്ക്രീൻ സമീപകാല ചർച്ചകളും നേരിട്ടുള്ള ബന്ധത്തിനായി Discord ക്ഷണവും കാണിക്കുന്നു.\n"
        "- «About»-ൽ Twitter/X-നും Telegram-നും പുതിയ Socials ഓപ്ഷൻ.\n"
        "- സമ്പന്നമായ ROM സ്ക്രീൻഷോട്ടുകൾ: PixelOS ഗാലറിയും പൂർണ്ണ വലുപ്പത്തിലെ Paranoid Android-ഉം.\n"
        "- ഡെസ്ക്ടോപ്പ് ബിൽഡുകൾ ഇപ്പോൾ സംഭാവനയ്ക്കുള്ള നന്ദി സന്ദേശം കാണിക്കുന്നു.\n"
        "- ടെക്സ്റ്റ് പുതുക്കി, വിശ്വസനീയമല്ലാത്ത സ്ക്രീൻഷോട്ടുകൾ ശരിയാക്കി.\n"
    ),
    "mn": (
        "- GitHub Discussions-тэй холбосон шинэ Community хэсэг (зарлал, асуулт хариулт, санаа, санал асуулга).\n"
        "- Community дэлгэц сүүлийн хэлэлцүүлэг болон шууд холбоо, шинэчлэл авах Discord урилгыг харуулна.\n"
        "- «Тухай» хэсэгт Twitter/X болон Telegram-д зориулсан шинэ Socials сонголт.\n"
        "- Илүү баялаг ROM дэлгэцийн зураг: PixelOS галерей болон бүтэн хэмжээтэй Paranoid Android.\n"
        "- Десктоп хувилбарууд одоо хандивын талархлын мессежийг харуулдаг.\n"
        "- Текстийг шинэчилж, найдваргүй дэлгэцийн зургуудыг засварлав.\n"
    ),
    "mr": (
        "- प्रकल्पाच्या GitHub Discussions ला जोडणारा नवीन Community विभाग (घोषणा, प्रश्नोत्तरे, कल्पना, मतदान).\n"
        "- Community स्क्रीन अलीकडील चर्चा आणि थेट संपर्क व अपडेट्ससाठी Discord आमंत्रण दाखवते.\n"
        "- «About» मध्ये Twitter/X आणि Telegram साठी नवीन Socials पर्याय.\n"
        "- अधिक समृद्ध ROM स्क्रीनशॉट: PixelOS गॅलरी आणि पूर्ण आकाराचे Paranoid Android.\n"
        "- डेस्कटॉप बिल्ड आता देणगीबद्दल धन्यवाद संदेश दाखवतात.\n"
        "- मजकूर ताजेतवाने केला आणि अविश्वसनीय स्क्रीनशॉट दुरुस्त केले.\n"
    ),
    "ms": (
        "- Bahagian Community baharu yang memaut ke GitHub Discussions (pengumuman, soal jawab, idea, undian).\n"
        "- Skrin Community memaparkan perbincangan terkini dan jemputan Discord untuk hubungan terus dan kemas kini.\n"
        "- Pilihan Socials baharu dalam «Perihal» untuk Twitter/X dan Telegram.\n"
        "- Tangkapan skrin ROM lebih kaya: galeri PixelOS dan Paranoid Android saiz penuh.\n"
        "- Binaan desktop kini memaparkan mesej terima kasih derma.\n"
        "- Teks disegarkan dan tangkapan skrin tidak boleh dipercayai dibaiki.\n"
    ),
    "my": (
        "- GitHub Discussions သို့ ချိတ်ဆက်ပေးသော Community အပိုင်းအသစ် (ကြေညာချက်၊ မေးခွန်းအဖြေ၊ အကြံဉာဏ်၊ စစ်တမ်း)။\n"
        "- Community ဖန်သားပြင်က မကြာသေးမီ ဆွေးနွေးချက်များနှင့် Discord ဖိတ်ကြားချက်ကို ပြသသည်။\n"
        "- «About» တွင် Twitter/X နှင့် Telegram အတွက် Socials ရွေးချယ်မှုအသစ်။\n"
        "- ကြွယ်ဝသော ROM ဖန်သားပြင်ဓာတ်ပုံ- PixelOS ပြခန်းနှင့် အရွယ်အပြည့် Paranoid Android။\n"
        "- Desktop ဗားရှင်းများ ယခု လှူဒါန်းမှု ကျေးဇူးတင်စကား ပြသသည်။\n"
        "- စာသားကို ပြင်ပြီး မယုံကြည်ရသော ဖန်သားပြင်ဓာတ်ပုံများကို ပြင်ဆင်ထားသည်။\n"
    ),
    "ne": (
        "- परियोजनाको GitHub Discussions सँग जोड्ने नयाँ Community खण्ड (घोषणा, प्रश्नोत्तर, विचार, मतदान)।\n"
        "- Community स्क्रिनले हालैका छलफल र प्रत्यक्ष सम्पर्क तथा अपडेटका लागि Discord निमन्त्रणा देखाउँछ।\n"
        "- «About» मा Twitter/X र Telegram का लागि नयाँ Socials विकल्प।\n"
        "- थप समृद्ध ROM स्क्रिनसट: PixelOS ग्यालरी र पूर्ण आकारको Paranoid Android।\n"
        "- डेस्कटप बिल्डहरूले अब दानका लागि धन्यवाद सन्देश देखाउँछन्।\n"
        "- पाठ ताजा गरियो र अविश्वसनीय स्क्रिनसट सच्याइयो।\n"
    ),
    "nl": (
        "- Nieuw Community-gedeelte met een link naar GitHub Discussions (aankondigingen, vragen, ideeën, polls).\n"
        "- Het Community-scherm toont recente discussies en een Discord-uitnodiging voor direct contact en updates.\n"
        "- Nieuwe Socials-optie in «Over» voor Twitter/X en Telegram.\n"
        "- Rijkere ROM-schermafbeeldingen: PixelOS-galerij en Paranoid Android op volledige grootte.\n"
        "- Desktopversies tonen nu het bedankbericht voor donaties.\n"
        "- Teksten vernieuwd en onbetrouwbare schermafbeeldingen hersteld.\n"
    ),
    "no": (
        "- Ny Community-seksjon som lenker til GitHub Discussions (kunngjøringer, spørsmål, idéer, avstemninger).\n"
        "- Community-skjermen viser nylige diskusjoner og en Discord-invitasjon for direkte kontakt og oppdateringer.\n"
        "- Nytt Socials-valg i «Om» for Twitter/X og Telegram.\n"
        "- Rikere ROM-skjermbilder: PixelOS-galleri og Paranoid Android i full størrelse.\n"
        "- Skrivebordsversjoner viser nå takkemeldingen for donasjon.\n"
        "- Oppfrisket tekst og rettet upålitelige skjermbilder.\n"
    ),
    "pa": (
        "- ਪ੍ਰੋਜੈਕਟ ਦੇ GitHub Discussions ਨਾਲ ਜੋੜਨ ਵਾਲਾ ਨਵਾਂ Community ਭਾਗ (ਐਲਾਨ, ਸਵਾਲ-ਜਵਾਬ, ਵਿਚਾਰ, ਪੋਲ)।\n"
        "- Community ਸਕਰੀਨ ਤਾਜ਼ਾ ਚਰਚਾਵਾਂ ਅਤੇ ਸਿੱਧੇ ਸੰਪਰਕ ਤੇ ਅੱਪਡੇਟ ਲਈ Discord ਸੱਦਾ ਵਿਖਾਉਂਦੀ ਹੈ।\n"
        "- «About» ਵਿੱਚ Twitter/X ਅਤੇ Telegram ਲਈ ਨਵਾਂ Socials ਵਿਕਲਪ।\n"
        "- ਅਮੀਰ ROM ਸਕਰੀਨਸ਼ਾਟ: PixelOS ਗੈਲਰੀ ਅਤੇ ਪੂਰੇ ਆਕਾਰ ਦੇ Paranoid Android।\n"
        "- ਡੈਸਕਟਾਪ ਬਿਲਡ ਹੁਣ ਦਾਨ ਲਈ ਧੰਨਵਾਦ ਸੁਨੇਹਾ ਵਿਖਾਉਂਦੇ ਹਨ।\n"
        "- ਲਿਖਤ ਤਾਜ਼ਾ ਕੀਤੀ ਅਤੇ ਭਰੋਸੇਯੋਗ ਨਾ ਹੋਣ ਵਾਲੇ ਸਕਰੀਨਸ਼ਾਟ ਠੀਕ ਕੀਤੇ।\n"
    ),
    "pl": (
        "- Nowa sekcja Community z odnośnikiem do GitHub Discussions (ogłoszenia, pytania, pomysły, ankiety).\n"
        "- Ekran Community pokazuje ostatnie dyskusje i zaproszenie na Discord do bezpośredniego kontaktu i nowości.\n"
        "- Nowa opcja Socials w «O aplikacji» dla Twitter/X i Telegram.\n"
        "- Bogatsze zrzuty ekranu ROM: galeria PixelOS i pełnowymiarowe Paranoid Android.\n"
        "- Wersje na komputer pokazują teraz podziękowanie za darowiznę.\n"
        "- Odświeżone teksty i poprawione zawodne zrzuty ekranu.\n"
    ),
    "pt": (
        "- Nova seção Community com link para as GitHub Discussions (anúncios, perguntas, ideias, enquetes).\n"
        "- A tela Community mostra discussões recentes e um convite do Discord para contato direto e novidades.\n"
        "- Nova opção Socials em «Sobre» para Twitter/X e Telegram.\n"
        "- Capturas de ROM mais ricas: galeria PixelOS e imagens do Paranoid Android em tamanho real.\n"
        "- As versões para computador agora mostram a mensagem de agradecimento pela doação.\n"
        "- Textos renovados e capturas pouco confiáveis corrigidas.\n"
    ),
    "pt-PT": (
        "- Nova secção Community com ligação às GitHub Discussions (anúncios, perguntas, ideias, sondagens).\n"
        "- O ecrã Community mostra discussões recentes e um convite do Discord para contacto direto e novidades.\n"
        "- Nova opção Socials em «Acerca» para Twitter/X e Telegram.\n"
        "- Capturas de ROM mais ricas: galeria PixelOS e imagens do Paranoid Android em tamanho real.\n"
        "- As versões para computador mostram agora a mensagem de agradecimento pelo donativo.\n"
        "- Textos renovados e capturas pouco fiáveis corrigidas.\n"
    ),
    "rm": (
        "- Nova secziun Community cun colliaziun a las GitHub Discussions (annunzias, dumondas, ideas, sondaschis).\n"
        "- La pagina Community mussa discussiuns actualas ed ina invitaziun Discord per contact ed actualisaziuns.\n"
        "- Nova opziun Socials en «Davart» per Twitter/X e Telegram.\n"
        "- Maletgs da visch ROM pli ritgs: galaria PixelOS e Paranoid Android en grondezza cumpletta.\n"
        "- Las versiuns per computer mussan ussa l'engraziament per la donaziun.\n"
        "- Tests renovads e maletgs da visch betg fidaivels reparads.\n"
    ),
    "ro": (
        "- Secțiune Community nouă, conectată la GitHub Discussions (anunțuri, întrebări, idei, sondaje).\n"
        "- Ecranul Community arată discuții recente și o invitație Discord pentru contact direct și noutăți.\n"
        "- Opțiune Socials nouă în «Despre» pentru Twitter/X și Telegram.\n"
        "- Capturi ROM mai bogate: galerie PixelOS și imagini Paranoid Android la dimensiune completă.\n"
        "- Versiunile pentru desktop afișează acum mesajul de mulțumire pentru donație.\n"
        "- Text reîmprospătat și capturi de ecran nesigure corectate.\n"
    ),
    "ru": (
        "- Новый раздел Community со ссылкой на GitHub Discussions (анонсы, вопросы и ответы, идеи, опросы).\n"
        "- Экран Community показывает недавние обсуждения и приглашение в Discord для прямой связи и обновлений.\n"
        "- Новая опция Socials в разделе «О приложении» для Twitter/X и Telegram.\n"
        "- Более насыщенные снимки ROM: галерея PixelOS и полноразмерные кадры Paranoid Android.\n"
        "- Версии для ПК теперь показывают сообщение с благодарностью за пожертвование.\n"
        "- Обновлён текст и исправлены ненадёжные снимки экрана.\n"
    ),
    "si": (
        "- ව්‍යාපෘතියේ GitHub Discussions වෙත සම්බන්ධ වන නව Community කොටස (නිවේදන, ප්‍රශ්නෝත්තර, අදහස්, ඡන්ද විමසුම්).\n"
        "- Community තිරය මෑත සාකච්ඡා සහ සෘජු සම්බන්ධතා හා යාවත්කාලීන සඳහා Discord ආරාධනයක් පෙන්වයි.\n"
        "- «About» හි Twitter/X සහ Telegram සඳහා නව Socials විකල්පය.\n"
        "- වඩාත් පොහොසත් ROM තිර රූප: PixelOS ගැලරිය සහ පූර්ණ ප්‍රමාණයේ Paranoid Android.\n"
        "- Desktop නිකුතු දැන් පරිත්‍යාගය සඳහා ස්තුති පණිවිඩය පෙන්වයි.\n"
        "- පෙළ අලුත් කර, විශ්වාස කළ නොහැකි තිර රූප නිවැරදි කරන ලදී.\n"
    ),
    "sk": (
        "- Nová sekcia Community s odkazom na GitHub Discussions (oznámenia, otázky, nápady, ankety).\n"
        "- Obrazovka Community zobrazuje nedávne diskusie a pozvánku na Discord pre priamy kontakt a novinky.\n"
        "- Nová možnosť Socials v sekcii «O aplikácii» pre Twitter/X a Telegram.\n"
        "- Bohatšie snímky ROM: galéria PixelOS a Paranoid Android v plnej veľkosti.\n"
        "- Verzie pre počítač teraz zobrazujú ďakovnú správu za dar.\n"
        "- Obnovené texty a opravené nespoľahlivé snímky obrazovky.\n"
    ),
    "sl": (
        "- Nov razdelek Community s povezavo do GitHub Discussions (obvestila, vprašanja, ideje, ankete).\n"
        "- Zaslon Community prikazuje nedavne razprave in povabilo na Discord za neposreden stik in posodobitve.\n"
        "- Nova možnost Socials v razdelku «O aplikaciji» za Twitter/X in Telegram.\n"
        "- Bogatejši posnetki ROM: galerija PixelOS in Paranoid Android v polni velikosti.\n"
        "- Namizne različice zdaj prikazujejo zahvalno sporočilo za donacijo.\n"
        "- Osveženo besedilo in popravljeni nezanesljivi posnetki zaslona.\n"
    ),
    "sq": (
        "- Seksion i ri Community që lidhet me GitHub Discussions (njoftime, pyetje-përgjigje, ide, sondazhe).\n"
        "- Ekrani Community shfaq diskutimet e fundit dhe një ftesë Discord për kontakt e përditësime.\n"
        "- Opsion i ri Socials te «Rreth» për Twitter/X dhe Telegram.\n"
        "- Pamje ekrani ROM më të pasura: galeria PixelOS dhe Paranoid Android në madhësi të plotë.\n"
        "- Versionet për kompjuter tani shfaqin mesazhin e falënderimit për donacionin.\n"
        "- Teksti i rifreskuar dhe pamjet e ekranit jo të besueshme u rregulluan.\n"
    ),
    "sr": (
        "- Нови одељак Community повезан са GitHub Discussions (обавештења, питања и одговори, идеје, анкете).\n"
        "- Екран Community приказује недавне дискусије и Discord позивницу за директан контакт и новости.\n"
        "- Нова Socials опција у «О апликацији» за Twitter/X и Telegram.\n"
        "- Богатији ROM снимци екрана: PixelOS галерија и Paranoid Android у пуној величини.\n"
        "- Верзије за рачунар сада приказују поруку захвалности за донацију.\n"
        "- Освежен текст и исправљени непоуздани снимци екрана.\n"
    ),
    "sv": (
        "- Ny Community-sektion som länkar till GitHub Discussions (meddelanden, frågor, idéer, omröstningar).\n"
        "- Community-skärmen visar senaste diskussioner och en Discord-inbjudan för direktkontakt och uppdateringar.\n"
        "- Nytt Socials-alternativ under «Om» för Twitter/X och Telegram.\n"
        "- Rikare ROM-skärmbilder: PixelOS-galleri och Paranoid Android i full storlek.\n"
        "- Skrivbordsversioner visar nu tackmeddelandet för donation.\n"
        "- Uppfräschad text och åtgärdade opålitliga skärmbilder.\n"
    ),
    "sw": (
        "- Sehemu mpya ya Community inayounganisha na GitHub Discussions (matangazo, maswali, mawazo, kura).\n"
        "- Skrini ya Community inaonyesha mijadala ya karibuni na mwaliko wa Discord kwa mawasiliano na masasisho.\n"
        "- Chaguo jipya la Socials katika «Kuhusu» kwa Twitter/X na Telegram.\n"
        "- Picha za ROM tajiri: matunzio ya PixelOS na Paranoid Android ya ukubwa kamili.\n"
        "- Matoleo ya kompyuta sasa yanaonyesha ujumbe wa shukrani kwa mchango.\n"
        "- Maandishi yameboreshwa na picha zisizotegemewa zimerekebishwa.\n"
    ),
    "ta": (
        "- GitHub Discussions உடன் இணைக்கும் புதிய Community பிரிவு (அறிவிப்புகள், கேள்வி-பதில், யோசனைகள், கருத்துக்கணிப்பு).\n"
        "- Community திரை சமீபத்திய விவாதங்களையும் நேரடி தொடர்புக்கான Discord அழைப்பையும் காட்டுகிறது.\n"
        "- «About» இல் Twitter/X மற்றும் Telegram க்கான புதிய Socials விருப்பம்.\n"
        "- வளமான ROM ஸ்கிரீன்ஷாட்: PixelOS தொகுப்பு மற்றும் முழு அளவிலான Paranoid Android.\n"
        "- டெஸ்க்டாப் பதிப்புகள் இப்போது நன்கொடை நன்றியைக் காட்டுகின்றன.\n"
        "- உரை புதுப்பிக்கப்பட்டது, நம்பகமற்ற ஸ்கிரீன்ஷாட்கள் சரிசெய்யப்பட்டன.\n"
    ),
    "te": (
        "- GitHub Discussions కు లింక్ చేసే కొత్త Community విభాగం (ప్రకటనలు, ప్రశ్నోత్తరాలు, ఆలోచనలు, పోల్స్).\n"
        "- Community స్క్రీన్ ఇటీవలి చర్చలను, నేరుగా సంప్రదించేందుకు Discord ఆహ్వానాన్ని చూపుతుంది.\n"
        "- «About» లో Twitter/X మరియు Telegram కోసం కొత్త Socials ఎంపిక.\n"
        "- సమృద్ధమైన ROM స్క్రీన్‌షాట్‌లు: PixelOS గ్యాలరీ మరియు పూర్తి పరిమాణ Paranoid Android.\n"
        "- డెస్క్‌టాప్ బిల్డ్‌లు ఇప్పుడు విరాళానికి కృతజ్ఞతా సందేశాన్ని చూపుతాయి.\n"
        "- వచనం తాజాపరచబడింది, నమ్మదగని స్క్రీన్‌షాట్‌లు సరిచేయబడ్డాయి.\n"
    ),
    "th": (
        "- ส่วน Community ใหม่ที่เชื่อมไปยัง GitHub Discussions (ประกาศ ถาม-ตอบ ไอเดีย โพล)\n"
        "- หน้าจอ Community แสดงการสนทนาล่าสุดและคำเชิญ Discord เพื่อติดต่อโดยตรงและรับอัปเดต\n"
        "- ตัวเลือก Socials ใหม่ใน «เกี่ยวกับ» สำหรับ Twitter/X และ Telegram\n"
        "- ภาพหน้าจอ ROM ที่สมบูรณ์ขึ้น: แกลเลอรี PixelOS และ Paranoid Android ขนาดเต็ม\n"
        "- รุ่นเดสก์ท็อปแสดงข้อความขอบคุณสำหรับการบริจาคแล้ว\n"
        "- ปรับปรุงข้อความและแก้ไขภาพหน้าจอที่ไม่เสถียร\n"
    ),
    "tr": (
        "- GitHub Discussions'a bağlanan yeni Community bölümü (duyurular, soru-cevap, fikirler, anketler).\n"
        "- Community ekranı son tartışmaları ve doğrudan iletişim ile güncellemeler için bir Discord davetini gösterir.\n"
        "- «Hakkında» bölümünde Twitter/X ve Telegram için yeni Socials seçeneği.\n"
        "- Daha zengin ROM ekran görüntüleri: PixelOS galerisi ve tam boyutlu Paranoid Android.\n"
        "- Masaüstü sürümleri artık bağış teşekkür mesajını gösteriyor.\n"
        "- Metinler tazelendi ve güvenilmez ekran görüntüleri düzeltildi.\n"
    ),
    "uk": (
        "- Новий розділ Community з посиланням на GitHub Discussions (анонси, запитання й відповіді, ідеї, опитування).\n"
        "- Екран Community показує нещодавні обговорення та запрошення в Discord для прямого зв'язку й оновлень.\n"
        "- Нова опція Socials у розділі «Про застосунок» для Twitter/X і Telegram.\n"
        "- Багатші знімки ROM: галерея PixelOS і повнорозмірні кадри Paranoid Android.\n"
        "- Версії для ПК тепер показують подяку за пожертву.\n"
        "- Оновлено текст і виправлено ненадійні знімки екрана.\n"
    ),
    "ur": (
        "- پروجیکٹ کے GitHub Discussions سے منسلک نیا Community سیکشن (اعلانات، سوال و جواب، خیالات، پول)۔\n"
        "- Community اسکرین حالیہ مباحثے اور براہِ راست رابطے و اپ ڈیٹس کے لیے Discord دعوت دکھاتی ہے۔\n"
        "- «About» میں Twitter/X اور Telegram کے لیے نیا Socials آپشن۔\n"
        "- بھرپور ROM اسکرین شاٹس: PixelOS گیلری اور مکمل سائز کے Paranoid Android۔\n"
        "- ڈیسک ٹاپ بلڈز اب عطیہ کے لیے شکریہ کا پیغام دکھاتے ہیں۔\n"
        "- متن کو تازہ کیا اور ناقابلِ اعتبار اسکرین شاٹس درست کیے۔\n"
    ),
    "vi": (
        "- Mục Community mới liên kết tới GitHub Discussions (thông báo, hỏi đáp, ý tưởng, thăm dò).\n"
        "- Màn hình Community hiển thị các thảo luận gần đây và lời mời Discord để liên hệ trực tiếp và nhận cập nhật.\n"
        "- Tùy chọn Socials mới trong «Giới thiệu» cho Twitter/X và Telegram.\n"
        "- Ảnh chụp ROM phong phú hơn: thư viện PixelOS và ảnh Paranoid Android kích thước đầy đủ.\n"
        "- Bản dành cho máy tính nay hiển thị thông điệp cảm ơn quyên góp.\n"
        "- Làm mới nội dung và sửa các ảnh chụp màn hình không ổn định.\n"
    ),
    "zh-CN": (
        "- 新增 Community 板块，链接到项目的 GitHub Discussions（公告、问答、创意、投票等）。\n"
        "- Community 界面显示近期讨论，以及可直接联系并获取更新的 Discord 邀请。\n"
        "- 在「关于」中为 Twitter/X 和 Telegram 新增 Socials 选项。\n"
        "- 更丰富的 ROM 截图：PixelOS 图库和全尺寸 Paranoid Android。\n"
        "- 桌面版现在会显示捐赠致谢信息。\n"
        "- 更新文案并修复了不稳定的截图。\n"
    ),
    "zh-TW": (
        "- 新增 Community 區塊，連結到專案的 GitHub Discussions（公告、問答、點子、投票等）。\n"
        "- Community 畫面顯示近期討論，以及可直接聯絡並取得更新的 Discord 邀請。\n"
        "- 在「關於」中為 Twitter/X 和 Telegram 新增 Socials 選項。\n"
        "- 更豐富的 ROM 螢幕截圖：PixelOS 圖庫與全尺寸 Paranoid Android。\n"
        "- 桌面版現在會顯示捐款感謝訊息。\n"
        "- 更新文案並修正了不穩定的螢幕截圖。\n"
    ),
    "zu": (
        "- Isigaba esisha se-Community esixhuma ku-GitHub Discussions (izimemezelo, imibuzo, imibono, izinhlolovo).\n"
        "- Isikrini se-Community sikhombisa izingxoxo zakamuva nesimemo se-Discord sokuxhumana nezibuyekezo.\n"
        "- Inketho entsha ye-Socials ku-«Mayelana» ye-Twitter/X ne-Telegram.\n"
        "- Izithombe-skrini ze-ROM ezicebile: igalari ye-PixelOS ne-Paranoid Android yosayizi ogcwele.\n"
        "- I-desktop manje ikhombisa umlayezo wokubonga ngomnikelo.\n"
        "- Umbhalo uvuselelwe, izithombe-skrini ezingathembekile zilungisiwe.\n"
    ),
}
# Map each on-disk locale folder to a base-language text above. en-US and
# regional English variants use the canonical English (EN).
LOCALE_TO_LANG = {
    # English (canonical) and regional variants
    "en-US": None, "en-AU": None, "en-CA": None, "en-GB": None,
    "en-IN": None, "en-SG": None, "en-ZA": None,
    # Spanish variants
    "es-419": "es", "es-ES": "es", "es-US": "es",
    # Persian variants
    "fa": "fa", "fa-AE": "fa", "fa-AF": "fa", "fa-IR": "fa",
    # French variants
    "fr-CA": "fr", "fr-FR": "fr",
    # Portuguese variants (pt-PT distinct)
    "pt-BR": "pt", "pt-PT": "pt-PT",
    # Chinese variants
    "zh-CN": "zh-CN", "zh-HK": "zh-TW", "zh-TW": "zh-TW",
    # Malay variants
    "ms": "ms", "ms-MY": "ms",
    # Simple one-to-one (folder : lang key)
    "af": "af", "am": "am", "ar": "ar", "az-AZ": "az", "be": "be",
    "bg": "bg", "bn-BD": "bn", "ca": "ca", "cs-CZ": "cs", "da-DK": "da",
    "de-DE": "de", "el-GR": "el", "et": "et", "eu-ES": "eu", "fi-FI": "fi",
    "fil": "fil", "gl-ES": "gl", "gu": "gu", "hi-IN": "hi", "hr": "hr",
    "hu-HU": "hu", "hy-AM": "hy", "id": "id", "is-IS": "is", "it-IT": "it",
    "iw-IL": "iw", "ja-JP": "ja", "ka-GE": "ka", "kk": "kk", "km-KH": "km",
    "kn-IN": "kn", "ko-KR": "ko", "ky-KG": "ky", "lo-LA": "lo", "lt": "lt",
    "lv": "lv", "mk-MK": "mk", "ml-IN": "ml", "mn-MN": "mn", "mr-IN": "mr",
    "my-MM": "my", "ne-NP": "ne", "nl-NL": "nl", "no-NO": "no", "pa": "pa",
    "pl-PL": "pl", "rm": "rm", "ro": "ro", "ru-RU": "ru", "si-LK": "si",
    "sk": "sk", "sl": "sl", "sq": "sq", "sr": "sr", "sv-SE": "sv",
    "sw": "sw", "ta-IN": "ta", "te-IN": "te", "th": "th", "tr-TR": "tr",
    "uk": "uk", "ur": "ur", "vi": "vi", "zu": "zu",
}


def main():
    existing = sorted(d for d in os.listdir(ROOT)
                      if os.path.isdir(os.path.join(ROOT, d)))
    missing_map = [d for d in existing if d not in LOCALE_TO_LANG]
    if missing_map:
        print("ERROR: on-disk locales with no mapping:", missing_map)
        sys.exit(1)

    over = []
    written = 0
    for locale, lang in LOCALE_TO_LANG.items():
        d = os.path.join(ROOT, locale, "changelogs")
        if not os.path.isdir(os.path.join(ROOT, locale)):
            print("WARN: locale folder missing on disk, skipping:", locale)
            continue
        os.makedirs(d, exist_ok=True)
        text = EN if lang is None else LANG[lang]
        path = os.path.join(d, "9.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        n = len(text.rstrip("\n"))
        if n > 500:
            over.append((locale, n))
        written += 1
    print(f"Wrote {written} changelog files.")
    if over:
        print("OVER 500 chars:")
        for loc, n in over:
            print(f"  {loc}: {n}")
        sys.exit(2)
    print("All within 500-char Play limit.")


if __name__ == "__main__":
    main()
