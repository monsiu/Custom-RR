#!/usr/bin/env python3
"""Write the v1.3.0 (versionCode 10) Play release notes into every locale's
changelogs/10.txt. en-US stays the canonical approved text; the rest are
translations that keep brand/tech terms in Latin (Custom RR, OpenDesktop,
AXP.OS, DivestOS, GSI, Treble, TWRP, ROM).

Each file is written WITHOUT a trailing newline and validated to stay within
Play's 500 code-point per-language release-notes limit. Bullet 1 is kept short
(the OpenDesktop browse line only) so every translation fits; the device/brand
page detail lives in the unlimited in-app/GitHub release notes.
"""
import os
import sys

ROOT = "fastlane/metadata/android"
OUT = "10.txt"

EN = (
    "- Community builds: browse thousands of community ROM uploads from "
    "OpenDesktop, with search and sorting.\n"
    "- Added AXP.OS, a privacy and security hardened ROM (the successor to "
    "DivestOS).\n"
    "- New GSI / Treble mode in the flash script generator.\n"
    "- Added the full official TWRP device list and more brand logos.\n"
    "- Filter ROMs and recoveries by your selected device.\n"
    "- Logos now load and update from the catalog, with smoother image loading.\n"
)

LANG = {
    "af": (
        "- Gemeenskapbouwerke: blaai deur duisende ROM-oplaaie van OpenDesktop, met soek en sorteer.\n"
        "- AXP.OS bygevoeg, 'n privaatheid- en sekuriteitsgeharde ROM (opvolger van DivestOS).\n"
        "- Nuwe GSI / Treble-modus in die flits-skripgenerator.\n"
        "- Volledige amptelike TWRP-toestellys en meer handelsmerklogo's bygevoeg.\n"
        "- Filtreer ROM's en herstelware volgens jou gekose toestel.\n"
        "- Logo's laai en werk nou by vanaf die katalogus, met gladder beeldlaai.\n"
    ),
    "am": (
        "- የማኅበረሰብ ግንባታዎች፦ ከOpenDesktop በሺዎች የሚቆጠሩ ROM ስቀላዎችን በፍለጋና በማደራጀት ያስሱ።\n"
        "- AXP.OS ታክሏል፣ ግላዊነትና ደኅንነት የተጠናከረ ROM (የDivestOS ተተኪ)።\n"
        "- በflash ስክሪፕት ጀነሬተር ውስጥ አዲስ GSI / Treble ሁነታ።\n"
        "- ሙሉ ይፋዊ የTWRP መሣሪያ ዝርዝርና ተጨማሪ የብራንድ ዓርማዎች ታክለዋል።\n"
        "- ROMዎችንና ማገገሚያዎችን በመረጡት መሣሪያ ያጣሩ።\n"
        "- ዓርማዎች አሁን ከካታሎግ ይጫናሉ፤ ይዘምናሉ፤ የተሻለ የምስል ጭነት።\n"
    ),
    "ar": (
        "- إصدارات المجتمع: تصفح آلاف ملفات ROM من OpenDesktop مع بحث وفرز.\n"
        "- إضافة AXP.OS، وهو ROM معزز للخصوصية والأمان (خلف DivestOS).\n"
        "- وضع GSI / Treble جديد في مولّد سكربت التفليش.\n"
        "- إضافة قائمة أجهزة TWRP الرسمية الكاملة والمزيد من شعارات العلامات.\n"
        "- تصفية ROM وأدوات الاسترداد حسب جهازك المحدد.\n"
        "- الشعارات تُحمّل وتُحدّث الآن من الكتالوج مع تحميل صور أكثر سلاسة.\n"
    ),
    "az": (
        "- Cəmiyyət versiyaları: OpenDesktop-dan minlərlə ROM-a axtarış və çeşidləmə ilə baxın.\n"
        "- Məxfilik və təhlükəsizliyi gücləndirilmiş AXP.OS (DivestOS-un davamçısı) əlavə edildi.\n"
        "- Flaş skript generatorunda yeni GSI / Treble rejimi.\n"
        "- Tam rəsmi TWRP cihaz siyahısı və daha çox brend logosu əlavə edildi.\n"
        "- ROM və bərpa vasitələrini seçdiyiniz cihaza görə süzün.\n"
        "- Loqolar artıq kataloqdan yüklənir və yenilənir, daha hamar şəkil yüklənməsi ilə.\n"
    ),
    "be": (
        "- Зборкі супольнасці: праглядайце тысячы ROM з OpenDesktop з пошукам і сартаваннем.\n"
        "- Дададзены AXP.OS, ROM з узмоцненай прыватнасцю і бяспекай (пераемнік DivestOS).\n"
        "- Новы рэжым GSI / Treble у генератары скрыптоў прашыўкі.\n"
        "- Дададзены поўны афіцыйны спіс прылад TWRP і больш лагатыпаў брэндаў.\n"
        "- Фільтруйце ROM і рэкаверы паводле выбранай прылады.\n"
        "- Лагатыпы цяпер загружаюцца і абнаўляюцца з каталога, з больш плаўнай загрузкай.\n"
    ),
    "bg": (
        "- Версии на общността: разгледайте хиляди ROM от OpenDesktop с търсене и сортиране.\n"
        "- Добавен AXP.OS, ROM с подсилена поверителност и сигурност (наследник на DivestOS).\n"
        "- Нов режим GSI / Treble в генератора на flash скриптове.\n"
        "- Добавен пълният официален списък с устройства на TWRP и още лога на марки.\n"
        "- Филтрирайте ROM и възстановявания по избраното устройство.\n"
        "- Логата вече се зареждат и обновяват от каталога, с по-плавно зареждане.\n"
    ),
    "bn": (
        "- কমিউনিটি বিল্ড: OpenDesktop থেকে হাজারো ROM খুঁজুন ও সাজান।\n"
        "- যোগ হলো AXP.OS, গোপনীয়তা ও নিরাপত্তা-সুদৃঢ় একটি ROM (DivestOS-এর উত্তরসূরি)।\n"
        "- ফ্ল্যাশ স্ক্রিপ্ট জেনারেটরে নতুন GSI / Treble মোড।\n"
        "- সম্পূর্ণ অফিসিয়াল TWRP ডিভাইস তালিকা ও আরও ব্র্যান্ড লোগো যোগ হলো।\n"
        "- নির্বাচিত ডিভাইস অনুযায়ী ROM ও রিকভারি ফিল্টার করুন।\n"
        "- লোগো এখন ক্যাটালগ থেকে লোড ও আপডেট হয়, মসৃণ ছবি লোডিংসহ।\n"
    ),
    "ca": (
        "- Compilacions de la comunitat: explora milers de ROM d'OpenDesktop amb cerca i ordenació.\n"
        "- S'ha afegit AXP.OS, una ROM amb privadesa i seguretat reforçades (successora de DivestOS).\n"
        "- Nou mode GSI / Treble al generador d'scripts de flaix.\n"
        "- S'ha afegit la llista oficial completa de dispositius TWRP i més logotips de marca.\n"
        "- Filtra ROM i recuperacions segons el dispositiu seleccionat.\n"
        "- Els logotips ara es carreguen i s'actualitzen des del catàleg, amb càrrega més fluida.\n"
    ),
    "cs": (
        "- Komunitní sestavení: procházejte tisíce ROM z OpenDesktopu s hledáním a řazením.\n"
        "- Přidán AXP.OS, ROM se zesíleným soukromím a zabezpečením (nástupce DivestOS).\n"
        "- Nový režim GSI / Treble v generátoru flash skriptů.\n"
        "- Přidán úplný oficiální seznam zařízení TWRP a další loga značek.\n"
        "- Filtrujte ROM a recovery podle vybraného zařízení.\n"
        "- Loga se nyní načítají a aktualizují z katalogu, s plynulejším načítáním obrázků.\n"
    ),
    "da": (
        "- Community-builds: gennemse tusindvis af ROM-uploads fra OpenDesktop med søgning og sortering.\n"
        "- Tilføjet AXP.OS, en privatlivs- og sikkerhedshærdet ROM (efterfølgeren til DivestOS).\n"
        "- Ny GSI / Treble-tilstand i flash-scriptgeneratoren.\n"
        "- Tilføjet den fulde officielle TWRP-enhedsliste og flere mærkelogoer.\n"
        "- Filtrér ROM'er og recoveries efter din valgte enhed.\n"
        "- Logoer indlæses og opdateres nu fra kataloget, med jævnere billedindlæsning.\n"
    ),
    "de": (
        "- Community-Builds: Tausende ROM-Uploads von OpenDesktop durchsuchen und sortieren.\n"
        "- AXP.OS hinzugefügt, eine datenschutz- und sicherheitsgehärtete ROM (Nachfolger von DivestOS).\n"
        "- Neuer GSI / Treble-Modus im Flash-Skript-Generator.\n"
        "- Vollständige offizielle TWRP-Geräteliste und mehr Markenlogos hinzugefügt.\n"
        "- ROMs und Recoveries nach deinem gewählten Gerät filtern.\n"
        "- Logos werden jetzt aus dem Katalog geladen und aktualisiert, mit flüssigerem Laden.\n"
    ),
    "el": (
        "- Εκδόσεις κοινότητας: περιηγηθείτε σε χιλιάδες ROM από το OpenDesktop με αναζήτηση και ταξινόμηση.\n"
        "- Προστέθηκε το AXP.OS, μια ROM ενισχυμένης ιδιωτικότητας και ασφάλειας (διάδοχος του DivestOS).\n"
        "- Νέα λειτουργία GSI / Treble στη γεννήτρια σεναρίων flash.\n"
        "- Προστέθηκε η πλήρης επίσημη λίστα συσκευών TWRP και περισσότερα λογότυπα.\n"
        "- Φιλτράρετε ROM και recovery ανά επιλεγμένη συσκευή.\n"
        "- Τα λογότυπα φορτώνονται και ενημερώνονται από τον κατάλογο, με ομαλότερη φόρτωση.\n"
    ),
    "es": (
        "- Compilaciones de la comunidad: explora miles de ROM de OpenDesktop con búsqueda y orden.\n"
        "- Se añadió AXP.OS, una ROM con privacidad y seguridad reforzadas (sucesora de DivestOS).\n"
        "- Nuevo modo GSI / Treble en el generador de scripts de flasheo.\n"
        "- Se añadió la lista oficial completa de dispositivos TWRP y más logotipos de marca.\n"
        "- Filtra ROM y recuperaciones según el dispositivo seleccionado.\n"
        "- Los logotipos ahora se cargan y actualizan desde el catálogo, con carga más fluida.\n"
    ),
    "et": (
        "- Kogukonna järgud: sirvi tuhandeid OpenDesktopi ROM-e otsingu ja sortimisega.\n"
        "- Lisatud AXP.OS, privaatsuse ja turvalisusega tugevdatud ROM (DivestOS-i järglane).\n"
        "- Uus GSI / Treble režiim välkkirja generaatoris.\n"
        "- Lisatud täielik ametlik TWRP seadmete loend ja rohkem brändilogosid.\n"
        "- Filtreeri ROM-e ja taasteid valitud seadme järgi.\n"
        "- Logod laaditakse ja uuendatakse nüüd kataloogist, sujuvama pildilaadimisega.\n"
    ),
    "eu": (
        "- Komunitatearen konpilazioak: arakatu OpenDesktop-eko milaka ROM bilaketa eta ordenarekin.\n"
        "- AXP.OS gehitu da, pribatutasun eta segurtasun sendotuko ROM bat (DivestOS-en oinordekoa).\n"
        "- GSI / Treble modu berria flash-script sortzailean.\n"
        "- TWRP gailuen zerrenda ofizial osoa eta marka-logotipo gehiago gehitu dira.\n"
        "- Iragazi ROMak eta berreskuratzeak hautatutako gailuaren arabera.\n"
        "- Logotipoak katalogotik kargatzen eta eguneratzen dira orain, irudi-karga leunagoarekin.\n"
    ),
    "fa": (
        "- ساخت‌های انجمن: هزاران ROM از OpenDesktop را با جستجو و مرتب‌سازی مرور کنید.\n"
        "- افزودن AXP.OS، یک ROM با حریم خصوصی و امنیت تقویت‌شده (جانشین DivestOS).\n"
        "- حالت جدید GSI / Treble در سازنده اسکریپت فلش.\n"
        "- افزودن فهرست کامل دستگاه‌های رسمی TWRP و لوگوهای برند بیشتر.\n"
        "- فیلتر ROM و ریکاوری بر اساس دستگاه انتخابی شما.\n"
        "- لوگوها اکنون از کاتالوگ بارگذاری و به‌روز می‌شوند، با بارگذاری روان‌تر تصویر.\n"
    ),
    "fr": (
        "- Builds de la communauté : parcourez des milliers de ROM d'OpenDesktop avec recherche et tri.\n"
        "- Ajout d'AXP.OS, une ROM renforcée en confidentialité et sécurité (successeur de DivestOS).\n"
        "- Nouveau mode GSI / Treble dans le générateur de scripts de flash.\n"
        "- Ajout de la liste officielle complète des appareils TWRP et de plus de logos de marque.\n"
        "- Filtrez les ROM et recoveries selon l'appareil sélectionné.\n"
        "- Les logos se chargent et se mettent à jour depuis le catalogue, plus fluidement.\n"
    ),
    "fi": (
        "- Yhteisön koonnit: selaa tuhansia ROM-latauksia OpenDesktopista haulla ja lajittelulla.\n"
        "- Lisätty AXP.OS, yksityisyyttä ja tietoturvaa vahvistettu ROM (DivestOSin seuraaja).\n"
        "- Uusi GSI / Treble -tila flash-skriptien generaattorissa.\n"
        "- Lisätty täydellinen virallinen TWRP-laiteluettelo ja lisää merkkilogoja.\n"
        "- Suodata ROMit ja recoveryt valitsemasi laitteen mukaan.\n"
        "- Logot ladataan ja päivitetään nyt luettelosta, sujuvammalla kuvien latauksella.\n"
    ),
    "fil": (
        "- Mga community build: tingnan ang libo-libong ROM mula sa OpenDesktop na may paghahanap at pag-uuri.\n"
        "- Idinagdag ang AXP.OS, isang ROM na pinatibay sa privacy at seguridad (kahalili ng DivestOS).\n"
        "- Bagong GSI / Treble mode sa flash script generator.\n"
        "- Idinagdag ang buong opisyal na listahan ng device ng TWRP at mas maraming brand logo.\n"
        "- I-filter ang ROM at recovery ayon sa napiling device.\n"
        "- Ang mga logo ay naglo-load at nag-a-update na mula sa catalog, na mas maayos.\n"
    ),
    "gl": (
        "- Compilacións da comunidade: explora milleiros de ROM de OpenDesktop con busca e orde.\n"
        "- Engadiuse AXP.OS, unha ROM con privacidade e seguridade reforzadas (sucesora de DivestOS).\n"
        "- Novo modo GSI / Treble no xerador de scripts de flasheo.\n"
        "- Engadiuse a lista oficial completa de dispositivos TWRP e máis logotipos de marca.\n"
        "- Filtra ROM e recuperacións segundo o dispositivo seleccionado.\n"
        "- Os logotipos cárganse e actualízanse desde o catálogo, cunha carga máis fluída.\n"
    ),
    "gu": (
        "- સમુદાય બિલ્ડ: OpenDesktop માંથી હજારો ROM શોધ અને ક્રમ સાથે જુઓ.\n"
        "- AXP.OS ઉમેર્યું, ગોપનીયતા અને સુરક્ષા-મજબૂત ROM (DivestOS નો અનુગામી).\n"
        "- ફ્લેશ સ્ક્રિપ્ટ જનરેટરમાં નવો GSI / Treble મોડ.\n"
        "- સંપૂર્ણ સત્તાવાર TWRP ઉપકરણ યાદી અને વધુ બ્રાન્ડ લોગો ઉમેર્યા.\n"
        "- પસંદ કરેલા ઉપકરણ પ્રમાણે ROM અને રિકવરી ફિલ્ટર કરો.\n"
        "- લોગો હવે કૅટલૉગમાંથી લોડ અને અપડેટ થાય છે, સરળ ઇમેજ લોડિંગ સાથે.\n"
    ),
    "hi": (
        "- कम्युनिटी बिल्ड: OpenDesktop से हज़ारों ROM खोज और क्रम के साथ देखें।\n"
        "- AXP.OS जोड़ा गया, एक गोपनीयता और सुरक्षा-सशक्त ROM (DivestOS का उत्तराधिकारी)।\n"
        "- फ्लैश स्क्रिप्ट जनरेटर में नया GSI / Treble मोड।\n"
        "- पूरी आधिकारिक TWRP डिवाइस सूची और अधिक ब्रांड लोगो जोड़े गए।\n"
        "- चुने गए डिवाइस के अनुसार ROM और रिकवरी फ़िल्टर करें।\n"
        "- लोगो अब कैटलॉग से लोड और अपडेट होते हैं, सहज इमेज लोडिंग के साथ।\n"
    ),
    "hr": (
        "- Zajednička izdanja: pregledajte tisuće ROM-ova s OpenDesktopa uz pretraživanje i razvrstavanje.\n"
        "- Dodan AXP.OS, ROM ojačan za privatnost i sigurnost (nasljednik DivestOS-a).\n"
        "- Novi GSI / Treble način u generatoru flash skripti.\n"
        "- Dodan potpuni službeni popis TWRP uređaja i više logotipa marki.\n"
        "- Filtrirajte ROM-ove i recovery prema odabranom uređaju.\n"
        "- Logotipi se sada učitavaju i ažuriraju iz kataloga, uz glatkije učitavanje slika.\n"
    ),
    "hu": (
        "- Közösségi build-ek: böngéssz több ezer ROM-ot az OpenDesktopról kereséssel és rendezéssel.\n"
        "- Új AXP.OS, adatvédelmi és biztonsági szempontból megerősített ROM (a DivestOS utódja).\n"
        "- Új GSI / Treble mód a flash-szkript generátorban.\n"
        "- Hozzáadtuk a teljes hivatalos TWRP eszközlistát és több márkalogót.\n"
        "- Szűrd a ROM-okat és recovery-ket a kiválasztott eszköz szerint.\n"
        "- A logók most a katalógusból töltődnek és frissülnek, simább képbetöltéssel.\n"
    ),
    "hy": (
        "- Համայնքի կառուցումներ. դիտեք հազարավոր ROM-ներ OpenDesktop-ից որոնմամբ և դասավորմամբ.\n"
        "- Ավելացվեց AXP.OS՝ գաղտնիության և անվտանգության ամրապնդված ROM (DivestOS-ի հաջորդը).\n"
        "- Նոր GSI / Treble ռեժիմ flash սկրիպտի գեներատորում.\n"
        "- Ավելացվեց TWRP սարքերի ամբողջական պաշտոնական ցանկը և ավելի շատ լոգոներ.\n"
        "- Զտեք ROM-ներն ու recovery-ները ըստ ընտրված սարքի.\n"
        "- Լոգոներն այժմ բեռնվում և թարմացվում են կատալոգից՝ ավելի սահուն բեռնմամբ.\n"
    ),
    "id": (
        "- Build komunitas: jelajahi ribuan unggahan ROM dari OpenDesktop dengan pencarian dan pengurutan.\n"
        "- Menambahkan AXP.OS, ROM dengan privasi dan keamanan yang diperkuat (penerus DivestOS).\n"
        "- Mode GSI / Treble baru di generator skrip flash.\n"
        "- Menambahkan daftar perangkat resmi TWRP lengkap dan lebih banyak logo merek.\n"
        "- Saring ROM dan recovery berdasarkan perangkat yang Anda pilih.\n"
        "- Logo kini dimuat dan diperbarui dari katalog, dengan pemuatan gambar lebih mulus.\n"
    ),
    "is": (
        "- Samfélagsútgáfur: skoðaðu þúsundir ROM frá OpenDesktop með leit og röðun.\n"
        "- Bætt við AXP.OS, ROM með aukinni persónuvernd og öryggi (arftaki DivestOS).\n"
        "- Nýr GSI / Treble hamur í flash-skriftugerðinni.\n"
        "- Bætt við fullum opinberum TWRP tækjalista og fleiri vörumerkjamerkjum.\n"
        "- Síaðu ROM og recovery eftir völdu tæki.\n"
        "- Merki hlaðast nú og uppfærast úr safninu, með mýkri myndahleðslu.\n"
    ),
    "it": (
        "- Build della community: esplora migliaia di ROM da OpenDesktop con ricerca e ordinamento.\n"
        "- Aggiunto AXP.OS, una ROM con privacy e sicurezza rafforzate (successore di DivestOS).\n"
        "- Nuova modalità GSI / Treble nel generatore di script di flash.\n"
        "- Aggiunto l'elenco ufficiale completo dei dispositivi TWRP e altri loghi di marca.\n"
        "- Filtra ROM e recovery in base al dispositivo selezionato.\n"
        "- I loghi ora si caricano e si aggiornano dal catalogo, con un caricamento più fluido.\n"
    ),
    "iw": (
        "- גרסאות קהילה: עיינו באלפי קובצי ROM מ-OpenDesktop עם חיפוש ומיון.\n"
        "- נוסף AXP.OS, ROM מוקשח לפרטיות ואבטחה (היורש של DivestOS).\n"
        "- מצב GSI / Treble חדש במחולל סקריפט הצריבה.\n"
        "- נוספה רשימת מכשירי TWRP הרשמית המלאה ועוד לוגואים של מותגים.\n"
        "- סננו ROM ושחזורים לפי המכשיר שבחרתם.\n"
        "- הלוגואים נטענים ומתעדכנים כעת מהקטלוג, עם טעינת תמונה חלקה יותר.\n"
    ),
    "ja": (
        "- コミュニティビルド: OpenDesktop の数千の ROM を検索・並べ替えで閲覧できます。\n"
        "- プライバシーとセキュリティを強化した ROM「AXP.OS」(DivestOS の後継) を追加。\n"
        "- フラッシュスクリプト生成に新しい GSI / Treble モードを追加。\n"
        "- 公式 TWRP デバイス一覧の完全版と、より多くのブランドロゴを追加。\n"
        "- 選択したデバイスで ROM とリカバリーを絞り込み。\n"
        "- ロゴはカタログから読み込み・更新されるようになり、画像表示が滑らかに。\n"
    ),
    "ka": (
        "- საზოგადოების ბილდები: დაათვალიერეთ OpenDesktop-ის ათასობით ROM ძიებითა და დახარისხებით.\n"
        "- დაემატა AXP.OS, კონფიდენციალურობითა და უსაფრთხოებით გაძლიერებული ROM (DivestOS-ის მემკვიდრე).\n"
        "- ახალი GSI / Treble რეჟიმი flash-სკრიპტის გენერატორში.\n"
        "- დაემატა TWRP მოწყობილობების სრული ოფიციალური სია და მეტი ბრენდის ლოგო.\n"
        "- გაფილტრეთ ROM და recovery არჩეული მოწყობილობის მიხედვით.\n"
        "- ლოგოები ახლა იტვირთება და განახლდება კატალოგიდან, უფრო გლუვი ჩატვირთვით.\n"
    ),
    "kk": (
        "- Қауымдастық құрастырмалары: OpenDesktop-тан мыңдаған ROM іздеу мен сұрыптаумен қараңыз.\n"
        "- Құпиялылық пен қауіпсіздігі күшейтілген AXP.OS қосылды (DivestOS мұрагері).\n"
        "- Flash скрипт генераторында жаңа GSI / Treble режимі.\n"
        "- Толық ресми TWRP құрылғылар тізімі мен қосымша бренд логотиптері қосылды.\n"
        "- ROM мен recovery-ді таңдаған құрылғыңыз бойынша сүзіңіз.\n"
        "- Логотиптер енді каталогтан жүктеліп, жаңарады, суреттер тегіс жүктеледі.\n"
    ),
    "km": (
        "- កំណែសហគមន៍៖ រកមើល ROM រាប់ពាន់ពី OpenDesktop ដោយស្វែងរក និងតម្រៀប។\n"
        "- បានបន្ថែម AXP.OS ដែលជា ROM ពង្រឹងឯកជនភាព និងសុវត្ថិភាព (អ្នកស្នង DivestOS)។\n"
        "- របៀប GSI / Treble ថ្មីនៅក្នុងកម្មវិធីបង្កើតស្គ្រីប flash។\n"
        "- បានបន្ថែមបញ្ជីឧបករណ៍ TWRP ផ្លូវការពេញលេញ និងឡូហ្គោម៉ាកបន្ថែម។\n"
        "- ច្រោះ ROM និង recovery តាមឧបករណ៍ដែលអ្នកជ្រើស។\n"
        "- ឡូហ្គោឥឡូវផ្ទុក និងធ្វើបច្ចុប្បន្នភាពពីកាតាឡុក ជាមួយការផ្ទុករូបភាពរលូន។\n"
    ),
    "kn": (
        "- ಸಮುದಾಯ ಬಿಲ್ಡ್‌ಗಳು: OpenDesktop ನಿಂದ ಸಾವಿರಾರು ROM ಗಳನ್ನು ಹುಡುಕಾಟ ಮತ್ತು ವಿಂಗಡಣೆಯೊಂದಿಗೆ ನೋಡಿ.\n"
        "- AXP.OS ಸೇರಿಸಲಾಗಿದೆ, ಗೌಪ್ಯತೆ ಮತ್ತು ಭದ್ರತೆ-ಬಲಪಡಿಸಿದ ROM (DivestOS ನ ಉತ್ತರಾಧಿಕಾರಿ).\n"
        "- ಫ್ಲ್ಯಾಶ್ ಸ್ಕ್ರಿಪ್ಟ್ ಜನರೇಟರ್‌ನಲ್ಲಿ ಹೊಸ GSI / Treble ಮೋಡ್.\n"
        "- ಸಂಪೂರ್ಣ ಅಧಿಕೃತ TWRP ಸಾಧನ ಪಟ್ಟಿ ಮತ್ತು ಹೆಚ್ಚಿನ ಬ್ರ್ಯಾಂಡ್ ಲೋಗೋಗಳನ್ನು ಸೇರಿಸಲಾಗಿದೆ.\n"
        "- ಆಯ್ದ ಸಾಧನದ ಪ್ರಕಾರ ROM ಮತ್ತು recovery ಫಿಲ್ಟರ್ ಮಾಡಿ.\n"
        "- ಲೋಗೋಗಳು ಈಗ ಕ್ಯಾಟಲಾಗ್‌ನಿಂದ ಲೋಡ್ ಮತ್ತು ಅಪ್‌ಡೇಟ್ ಆಗುತ್ತವೆ, ಸುಗಮ ಚಿತ್ರ ಲೋಡಿಂಗ್‌ನೊಂದಿಗೆ.\n"
    ),
    "ko": (
        "- 커뮤니티 빌드: OpenDesktop의 수천 개 ROM을 검색·정렬로 둘러봅니다.\n"
        "- 개인정보와 보안을 강화한 ROM인 AXP.OS(DivestOS의 후속작)를 추가했습니다.\n"
        "- 플래시 스크립트 생성기에 새로운 GSI / Treble 모드를 추가했습니다.\n"
        "- 전체 공식 TWRP 기기 목록과 더 많은 브랜드 로고를 추가했습니다.\n"
        "- 선택한 기기로 ROM과 리커버리를 필터링합니다.\n"
        "- 로고가 이제 카탈로그에서 로드·업데이트되며 이미지 로딩이 더 부드러워졌습니다.\n"
    ),
    "ky": (
        "- Коомдук курулмалар: OpenDesktop'тон миңдеген ROM'ду издөө жана иргөө менен карагыла.\n"
        "- Купуялык жана коопсуздугу күчөтүлгөн AXP.OS кошулду (DivestOS'тун мураскери).\n"
        "- Flash скрипт генераторунда жаңы GSI / Treble режими.\n"
        "- Толук расмий TWRP түзмөктөр тизмеси жана көбүрөөк бренд логотиптери кошулду.\n"
        "- ROM жана recovery'лерди тандалган түзмөгүңүз боюнча чыпкалаңыз.\n"
        "- Логотиптер эми каталогдон жүктөлүп, жаңырат, сүрөттөр тегиз жүктөлөт.\n"
    ),
    "lo": (
        "- ການສ້າງຂອງຊຸມຊົນ: ເບິ່ງ ROM ນັບພັນຈາກ OpenDesktop ດ້ວຍການຄົ້ນຫາ ແລະ ຈັດລຽງ.\n"
        "- ເພີ່ມ AXP.OS, ROM ທີ່ເສີມຄວາມເປັນສ່ວນຕົວ ແລະ ຄວາມປອດໄພ (ຜູ້ສືບທອດ DivestOS).\n"
        "- ໂໝດ GSI / Treble ໃໝ່ໃນຕົວສ້າງສະຄຣິບ flash.\n"
        "- ເພີ່ມລາຍຊື່ອຸປະກອນ TWRP ທາງການຄົບຖ້ວນ ແລະ ໂລໂກ້ຍີ່ຫໍ້ເພີ່ມເຕີມ.\n"
        "- ກັ່ນຕອງ ROM ແລະ recovery ຕາມອຸປະກອນທີ່ທ່ານເລືອກ.\n"
        "- ໂລໂກ້ດຽວນີ້ໂຫຼດ ແລະ ອັບເດດຈາກລາຍການ, ດ້ວຍການໂຫຼດຮູບທີ່ລຽບງ່າຍຂຶ້ນ.\n"
    ),
    "lt": (
        "- Bendruomenės darymai: naršykite tūkstančius ROM iš OpenDesktop su paieška ir rūšiavimu.\n"
        "- Pridėta AXP.OS, privatumo ir saugumo požiūriu sustiprinta ROM (DivestOS įpėdinė).\n"
        "- Naujas GSI / Treble režimas flash skripto generatoriuje.\n"
        "- Pridėtas visas oficialus TWRP įrenginių sąrašas ir daugiau prekių ženklų logotipų.\n"
        "- Filtruokite ROM ir recovery pagal pasirinktą įrenginį.\n"
        "- Logotipai dabar įkeliami ir atnaujinami iš katalogo, sklandžiau įkeliant vaizdus.\n"
    ),
    "lv": (
        "- Kopienas būvējumi: pārlūkojiet tūkstošiem ROM no OpenDesktop ar meklēšanu un kārtošanu.\n"
        "- Pievienots AXP.OS, privātumam un drošībai nostiprināta ROM (DivestOS pēctece).\n"
        "- Jauns GSI / Treble režīms zibatmiņas skriptu ģeneratorā.\n"
        "- Pievienots pilns oficiālais TWRP ierīču saraksts un vairāk zīmolu logotipu.\n"
        "- Filtrējiet ROM un atkopšanas pēc izvēlētās ierīces.\n"
        "- Logotipi tagad tiek ielādēti un atjaunināti no kataloga, ar plūstošāku ielādi.\n"
    ),
    "mk": (
        "- Изданија на заедницата: прелистувајте илјадници ROM од OpenDesktop со пребарување и подредување.\n"
        "- Додаден AXP.OS, ROM зајакнат за приватност и безбедност (наследник на DivestOS).\n"
        "- Нов GSI / Treble режим во генераторот на flash скрипти.\n"
        "- Додадена целосната официјална листа на TWRP уреди и повеќе логоа на брендови.\n"
        "- Филтрирајте ROM и recovery според избраниот уред.\n"
        "- Логоата сега се вчитуваат и ажурираат од каталогот, со помазно вчитување слики.\n"
    ),
    "ml": (
        "- കമ്മ്യൂണിറ്റി ബിൽഡുകൾ: OpenDesktop-ൽ നിന്ന് ആയിരക്കണക്കിന് ROM തിരയലും ക്രമീകരണവുമായി കാണുക.\n"
        "- AXP.OS ചേർത്തു, സ്വകാര്യതയും സുരക്ഷയും ശക്തമാക്കിയ ROM (DivestOS-ന്റെ പിൻഗാമി).\n"
        "- ഫ്ലാഷ് സ്ക്രിപ്റ്റ് ജനറേറ്ററിൽ പുതിയ GSI / Treble മോഡ്.\n"
        "- പൂർണ്ണ ഔദ്യോഗിക TWRP ഉപകരണ പട്ടികയും കൂടുതൽ ബ്രാൻഡ് ലോഗോകളും ചേർത്തു.\n"
        "- തിരഞ്ഞെടുത്ത ഉപകരണം അനുസരിച്ച് ROM, recovery എന്നിവ ഫിൽട്ടർ ചെയ്യുക.\n"
        "- ലോഗോകൾ ഇപ്പോൾ കാറ്റലോഗിൽ നിന്ന് ലോഡ് ചെയ്യുകയും അപ്ഡേറ്റ് ചെയ്യുകയും ചെയ്യുന്നു.\n"
    ),
    "mn": (
        "- Хамтын нийгэмлэгийн бүтээцүүд: OpenDesktop-оос мянга мянган ROM-ыг хайлт, эрэмбэлэлтээр үзээрэй.\n"
        "- Нууцлал, аюулгүй байдлыг бэхжүүлсэн AXP.OS нэмлээ (DivestOS-ийн залгамжлагч).\n"
        "- Flash скрипт үүсгэгчид шинэ GSI / Treble горим.\n"
        "- Бүрэн албан ёсны TWRP төхөөрөмжийн жагсаалт болон илүү олон брэндийн лого нэмлээ.\n"
        "- Сонгосон төхөөрөмжөөрөө ROM, recovery-г шүүнэ үү.\n"
        "- Лого одоо каталогоос ачаалж, шинэчлэгдэх ба зураг илүү жигд ачаална.\n"
    ),
    "mr": (
        "- समुदाय बिल्ड: OpenDesktop वरून हजारो ROM शोध व क्रमवारीसह पाहा.\n"
        "- AXP.OS जोडले, गोपनीयता व सुरक्षा-मजबूत ROM (DivestOS चा वारसदार).\n"
        "- फ्लॅश स्क्रिप्ट जनरेटरमध्ये नवीन GSI / Treble मोड.\n"
        "- संपूर्ण अधिकृत TWRP डिव्हाइस यादी व अधिक ब्रँड लोगो जोडले.\n"
        "- निवडलेल्या डिव्हाइसनुसार ROM व recovery फिल्टर करा.\n"
        "- लोगो आता कॅटलॉगमधून लोड व अपडेट होतात, अधिक सहज प्रतिमा लोडिंगसह.\n"
    ),
    "ms": (
        "- Binaan komuniti: layari ribuan muat naik ROM dari OpenDesktop dengan carian dan isihan.\n"
        "- Menambah AXP.OS, ROM diperkukuh privasi dan keselamatan (pengganti DivestOS).\n"
        "- Mod GSI / Treble baharu dalam penjana skrip flash.\n"
        "- Menambah senarai peranti TWRP rasmi penuh dan lebih banyak logo jenama.\n"
        "- Tapis ROM dan recovery mengikut peranti pilihan anda.\n"
        "- Logo kini dimuatkan dan dikemas kini daripada katalog, dengan pemuatan imej lebih lancar.\n"
    ),
    "my": (
        "- အသိုက်အဝန်း build များ - OpenDesktop မှ ROM ထောင်ပေါင်းများစွာကို ရှာဖွေ၊ စီစဉ်၍ ကြည့်ပါ။\n"
        "- ကိုယ်ရေးလုံခြုံမှုနှင့် လုံခြုံရေး ခိုင်မာသော AXP.OS (DivestOS ၏ ဆက်ခံသူ) ထည့်သွင်းသည်။\n"
        "- flash script generator တွင် GSI / Treble မုဒ်အသစ်။\n"
        "- တရားဝင် TWRP စက်စာရင်းအပြည့်အစုံနှင့် ဘရန်းလိုဂိုများ ပိုထည့်သည်။\n"
        "- ရွေးချယ်ထားသော စက်အလိုက် ROM နှင့် recovery ကို စစ်ထုတ်ပါ။\n"
        "- လိုဂိုများကို ယခု catalog မှ တင်ပြီး အပ်ဒိတ်လုပ်ကာ ပုံတင်ခြင်း ချောမွေ့လာသည်။\n"
    ),
    "ne": (
        "- सामुदायिक बिल्ड: OpenDesktop बाट हजारौं ROM खोज र क्रमसहित हेर्नुहोस्।\n"
        "- AXP.OS थपियो, गोपनीयता र सुरक्षा-सुदृढ ROM (DivestOS को उत्तराधिकारी)।\n"
        "- फ्ल्यास स्क्रिप्ट जेनेरेटरमा नयाँ GSI / Treble मोड।\n"
        "- पूर्ण आधिकारिक TWRP उपकरण सूची र थप ब्रान्ड लोगो थपियो।\n"
        "- छानिएको उपकरण अनुसार ROM र recovery फिल्टर गर्नुहोस्।\n"
        "- लोगोहरू अब क्याटलगबाट लोड र अपडेट हुन्छन्, सहज छवि लोडिङसहित।\n"
    ),
    "nl": (
        "- Community-builds: blader door duizenden ROM-uploads van OpenDesktop met zoeken en sorteren.\n"
        "- AXP.OS toegevoegd, een ROM met versterkte privacy en beveiliging (opvolger van DivestOS).\n"
        "- Nieuwe GSI / Treble-modus in de flash-scriptgenerator.\n"
        "- Volledige officiële TWRP-apparaatlijst en meer merklogo's toegevoegd.\n"
        "- Filter ROM's en recoveries op je gekozen apparaat.\n"
        "- Logo's worden nu uit de catalogus geladen en bijgewerkt, met soepeler laden.\n"
    ),
    "no": (
        "- Fellesskapsbygg: bla gjennom tusenvis av ROM-er fra OpenDesktop med søk og sortering.\n"
        "- Lagt til AXP.OS, en ROM med styrket personvern og sikkerhet (etterfølgeren til DivestOS).\n"
        "- Ny GSI / Treble-modus i flash-skriptgeneratoren.\n"
        "- Lagt til den fullstendige offisielle TWRP-enhetslisten og flere merkelogoer.\n"
        "- Filtrer ROM-er og recovery etter valgt enhet.\n"
        "- Logoer lastes og oppdateres nå fra katalogen, med jevnere bildelasting.\n"
    ),
    "pa": (
        "- ਕਮਿਊਨਿਟੀ ਬਿਲਡ: OpenDesktop ਤੋਂ ਹਜ਼ਾਰਾਂ ROM ਖੋਜ ਅਤੇ ਛਾਂਟੀ ਨਾਲ ਵੇਖੋ।\n"
        "- AXP.OS ਸ਼ਾਮਲ ਕੀਤਾ, ਇੱਕ ਨਿੱਜਤਾ ਅਤੇ ਸੁਰੱਖਿਆ-ਮਜ਼ਬੂਤ ROM (DivestOS ਦਾ ਵਾਰਸ)।\n"
        "- ਫਲੈਸ਼ ਸਕ੍ਰਿਪਟ ਜਨਰੇਟਰ ਵਿੱਚ ਨਵਾਂ GSI / Treble ਮੋਡ।\n"
        "- ਪੂਰੀ ਅਧਿਕਾਰਤ TWRP ਡਿਵਾਈਸ ਸੂਚੀ ਅਤੇ ਹੋਰ ਬ੍ਰਾਂਡ ਲੋਗੋ ਸ਼ਾਮਲ ਕੀਤੇ।\n"
        "- ਚੁਣੇ ਡਿਵਾਈਸ ਅਨੁਸਾਰ ROM ਅਤੇ recovery ਫਿਲਟਰ ਕਰੋ।\n"
        "- ਲੋਗੋ ਹੁਣ ਕੈਟਾਲਾਗ ਤੋਂ ਲੋਡ ਅਤੇ ਅੱਪਡੇਟ ਹੁੰਦੇ ਹਨ, ਸੁਚਾਰੂ ਚਿੱਤਰ ਲੋਡਿੰਗ ਨਾਲ।\n"
    ),
    "pl": (
        "- Kompilacje społeczności: przeglądaj tysiące ROM-ów z OpenDesktop z wyszukiwaniem i sortowaniem.\n"
        "- Dodano AXP.OS, ROM ze wzmocnioną prywatnością i bezpieczeństwem (następca DivestOS).\n"
        "- Nowy tryb GSI / Treble w generatorze skryptów flash.\n"
        "- Dodano pełną oficjalną listę urządzeń TWRP i więcej logotypów marek.\n"
        "- Filtruj ROM-y i recovery według wybranego urządzenia.\n"
        "- Logo są teraz wczytywane i aktualizowane z katalogu, z płynniejszym ładowaniem.\n"
    ),
    "pt": (
        "- Builds da comunidade: explore milhares de ROMs do OpenDesktop com busca e ordenação.\n"
        "- Adicionado o AXP.OS, uma ROM reforçada em privacidade e segurança (sucessora do DivestOS).\n"
        "- Novo modo GSI / Treble no gerador de scripts de flash.\n"
        "- Adicionada a lista oficial completa de aparelhos TWRP e mais logotipos de marcas.\n"
        "- Filtre ROMs e recoveries pelo aparelho selecionado.\n"
        "- Os logotipos agora carregam e atualizam pelo catálogo, com carregamento mais suave.\n"
    ),
    "pt-PT": (
        "- Compilações da comunidade: explore milhares de ROMs do OpenDesktop com procura e ordenação.\n"
        "- Adicionado o AXP.OS, uma ROM reforçada em privacidade e segurança (sucessora do DivestOS).\n"
        "- Novo modo GSI / Treble no gerador de scripts de flash.\n"
        "- Adicionada a lista oficial completa de dispositivos TWRP e mais logótipos de marcas.\n"
        "- Filtre ROMs e recoveries pelo dispositivo selecionado.\n"
        "- Os logótipos agora carregam e atualizam pelo catálogo, com carregamento mais suave.\n"
    ),
    "rm": (
        "- Versiuns da communitad: dasguard millis da ROM da OpenDesktop cun tschertgar e zavrar.\n"
        "- Agiuntà AXP.OS, ina ROM rinforzada per protecziun da datas e segirezza (successur da DivestOS).\n"
        "- Nov modus GSI / Treble en il generatur da scripts flash.\n"
        "- Agiuntà la glista uffiziala cumpletta d'apparats TWRP e dapli logos da marcas.\n"
        "- Filtrar ROM e recovery tenor tes apparat tschernì.\n"
        "- Ils logos vegnan ussa chargiads ed actualisads dal catalog, pli flot.\n"
    ),
    "ro": (
        "- Versiuni ale comunității: răsfoiește mii de ROM-uri de pe OpenDesktop cu căutare și sortare.\n"
        "- Adăugat AXP.OS, un ROM consolidat pentru confidențialitate și securitate (succesorul DivestOS).\n"
        "- Mod nou GSI / Treble în generatorul de scripturi de flash.\n"
        "- Adăugată lista oficială completă de dispozitive TWRP și mai multe logouri de marcă.\n"
        "- Filtrează ROM-uri și recovery după dispozitivul selectat.\n"
        "- Logourile se încarcă și se actualizează acum din catalog, mai fluid.\n"
    ),
    "ru": (
        "- Сборки сообщества: просматривайте тысячи ROM из OpenDesktop с поиском и сортировкой.\n"
        "- Добавлен AXP.OS, ROM с усиленной приватностью и безопасностью (преемник DivestOS).\n"
        "- Новый режим GSI / Treble в генераторе скриптов прошивки.\n"
        "- Добавлен полный официальный список устройств TWRP и больше логотипов брендов.\n"
        "- Фильтруйте ROM и recovery по выбранному устройству.\n"
        "- Логотипы теперь загружаются и обновляются из каталога, с более плавной загрузкой.\n"
    ),
    "si": (
        "- ප්‍රජා නිර්මාණ: OpenDesktop වෙතින් ROM දහස් ගණනක් සෙවීම් හා වර්ග කිරීම් සමඟ බලන්න.\n"
        "- AXP.OS එක් කළා, පෞද්ගලිකත්වය හා ආරක්ෂාව ශක්තිමත් ROM එකක් (DivestOS හි අනුප්‍රාප්තිකයා).\n"
        "- flash ස්ක්‍රිප්ට් උත්පාදකයේ නව GSI / Treble ආකාරය.\n"
        "- සම්පූර්ණ නිල TWRP උපාංග ලැයිස්තුව හා තවත් වෙළඳ නාම ලාංඡන එක් කළා.\n"
        "- තෝරාගත් උපාංගය අනුව ROM හා recovery පෙරහන් කරන්න.\n"
        "- ලාංඡන දැන් නාමාවලියෙන් පූරණය වී යාවත්කාලීන වේ, සුමට රූප පූරණයක් සමඟ.\n"
    ),
    "sk": (
        "- Komunitné zostavy: prehliadajte tisíce ROM z OpenDesktopu s vyhľadávaním a triedením.\n"
        "- Pridaný AXP.OS, ROM so zosilneným súkromím a zabezpečením (nástupca DivestOS).\n"
        "- Nový režim GSI / Treble v generátore flash skriptov.\n"
        "- Pridaný úplný oficiálny zoznam zariadení TWRP a viac log značiek.\n"
        "- Filtrujte ROM a recovery podľa vybraného zariadenia.\n"
        "- Logá sa teraz načítavajú a aktualizujú z katalógu, s plynulejším načítaním obrázkov.\n"
    ),
    "sl": (
        "- Skupnostne zgradbe: prebrskajte tisoče ROM-ov iz OpenDesktopa z iskanjem in razvrščanjem.\n"
        "- Dodan AXP.OS, ROM z okrepljeno zasebnostjo in varnostjo (naslednik DivestOS).\n"
        "- Nov način GSI / Treble v generatorju skript flash.\n"
        "- Dodan celoten uradni seznam naprav TWRP in več logotipov znamk.\n"
        "- Filtrirajte ROM-e in recovery glede na izbrano napravo.\n"
        "- Logotipi se zdaj nalagajo in posodabljajo iz kataloga, z bolj gladkim nalaganjem.\n"
    ),
    "sq": (
        "- Ndërtime të komunitetit: shfletoni mijëra ROM nga OpenDesktop me kërkim dhe renditje.\n"
        "- U shtua AXP.OS, një ROM e forcuar për privatësi dhe siguri (pasardhësja e DivestOS).\n"
        "- Modalitet i ri GSI / Treble në gjeneratorin e skripteve të flash.\n"
        "- U shtua lista zyrtare e plotë e pajisjeve TWRP dhe më shumë logo markash.\n"
        "- Filtroni ROM dhe recovery sipas pajisjes së zgjedhur.\n"
        "- Logot tani ngarkohen dhe përditësohen nga katalogu, me ngarkim më të qetë.\n"
    ),
    "sr": (
        "- Изградње заједнице: прегледајте хиљаде ROM-ова са OpenDesktop-а уз претрагу и сортирање.\n"
        "- Додат AXP.OS, ROM појачане приватности и безбедности (наследник DivestOS-а).\n"
        "- Нови GSI / Treble режим у генератору flash скрипти.\n"
        "- Додата потпуна званична листа TWRP уређаја и још логотипа брендова.\n"
        "- Филтрирајте ROM и recovery према изабраном уређају.\n"
        "- Логотипи се сада учитавају и ажурирају из каталога, уз глаткије учитавање слика.\n"
    ),
    "sv": (
        "- Communitybyggen: bläddra bland tusentals ROM-uppladdningar från OpenDesktop med sök och sortering.\n"
        "- Lade till AXP.OS, en integritets- och säkerhetshärdad ROM (efterföljaren till DivestOS).\n"
        "- Nytt GSI / Treble-läge i flash-skriptgeneratorn.\n"
        "- Lade till den fullständiga officiella TWRP-enhetslistan och fler varumärkesloggor.\n"
        "- Filtrera ROM och recovery efter din valda enhet.\n"
        "- Loggor laddas och uppdateras nu från katalogen, med jämnare bildladdning.\n"
    ),
    "sw": (
        "- Miundo ya jamii: vinjari maelfu ya ROM kutoka OpenDesktop kwa utafutaji na upangaji.\n"
        "- Imeongezwa AXP.OS, ROM iliyoimarishwa faragha na usalama (mrithi wa DivestOS).\n"
        "- Hali mpya ya GSI / Treble katika kitengeneza skripti za flash.\n"
        "- Imeongezwa orodha kamili rasmi ya vifaa vya TWRP na nembo zaidi za chapa.\n"
        "- Chuja ROM na recovery kulingana na kifaa ulichochagua.\n"
        "- Nembo sasa hupakiwa na kusasishwa kutoka katalogi, kwa upakiaji laini wa picha.\n"
    ),
    "ta": (
        "- சமூக பதிப்புகள்: OpenDesktop இல் இருந்து ஆயிரக்கணக்கான ROM-களைத் தேடல், வரிசைப்படுத்தலுடன் பாருங்கள்.\n"
        "- AXP.OS சேர்க்கப்பட்டது, தனியுரிமை மற்றும் பாதுகாப்பு வலுப்படுத்திய ROM (DivestOS இன் வாரிசு).\n"
        "- flash ஸ்கிரிப்ட் ஜெனரேட்டரில் புதிய GSI / Treble பயன்முறை.\n"
        "- முழு அதிகாரப்பூர்வ TWRP சாதனப் பட்டியல் மற்றும் கூடுதல் பிராண்ட் லோகோக்கள் சேர்க்கப்பட்டன.\n"
        "- தேர்ந்தெடுத்த சாதனத்தின்படி ROM, recovery வடிகட்டுங்கள்.\n"
        "- லோகோக்கள் இப்போது பட்டியலில் இருந்து ஏற்றப்பட்டு புதுப்பிக்கப்படுகின்றன.\n"
    ),
    "te": (
        "- సముదాయ బిల్డ్‌లు: OpenDesktop నుండి వేలాది ROM-లను శోధన, క్రమబద్ధీకరణతో చూడండి.\n"
        "- AXP.OS జోడించబడింది, గోప్యత, భద్రత బలోపేతం చేసిన ROM (DivestOS వారసుడు).\n"
        "- flash స్క్రిప్ట్ జనరేటర్‌లో కొత్త GSI / Treble మోడ్.\n"
        "- పూర్తి అధికారిక TWRP పరికర జాబితా, మరిన్ని బ్రాండ్ లోగోలు జోడించబడ్డాయి.\n"
        "- ఎంచుకున్న పరికరం ప్రకారం ROM, recovery ఫిల్టర్ చేయండి.\n"
        "- లోగోలు ఇప్పుడు కేటలాగ్ నుండి లోడ్, నవీకరణ అవుతాయి, సున్నితమైన చిత్ర లోడింగ్‌తో.\n"
    ),
    "th": (
        "- บิลด์ของชุมชน: เรียกดู ROM นับพันจาก OpenDesktop พร้อมค้นหาและจัดเรียง\n"
        "- เพิ่ม AXP.OS ซึ่งเป็น ROM ที่เสริมความเป็นส่วนตัวและความปลอดภัย (ผู้สืบทอด DivestOS)\n"
        "- โหมด GSI / Treble ใหม่ในตัวสร้างสคริปต์ flash\n"
        "- เพิ่มรายการอุปกรณ์ TWRP อย่างเป็นทางการครบถ้วนและโลโก้แบรนด์เพิ่มเติม\n"
        "- กรอง ROM และ recovery ตามอุปกรณ์ที่คุณเลือก\n"
        "- ตอนนี้โลโก้โหลดและอัปเดตจากแคตตาล็อก พร้อมการโหลดภาพที่ลื่นไหลขึ้น\n"
    ),
    "tr": (
        "- Topluluk yapıları: OpenDesktop'tan binlerce ROM'u arama ve sıralamayla göz atın.\n"
        "- Gizlilik ve güvenliği güçlendirilmiş AXP.OS eklendi (DivestOS'un halefi).\n"
        "- Flash betiği oluşturucuda yeni GSI / Treble modu.\n"
        "- Tam resmi TWRP cihaz listesi ve daha fazla marka logosu eklendi.\n"
        "- ROM ve recovery'leri seçtiğiniz cihaza göre süzün.\n"
        "- Logolar artık katalogdan yüklenip güncelleniyor, daha akıcı görsel yüklemeyle.\n"
    ),
    "uk": (
        "- Збірки спільноти: переглядайте тисячі ROM з OpenDesktop із пошуком і сортуванням.\n"
        "- Додано AXP.OS, ROM із посиленою приватністю та безпекою (наступник DivestOS).\n"
        "- Новий режим GSI / Treble у генераторі скриптів прошивки.\n"
        "- Додано повний офіційний список пристроїв TWRP і більше логотипів брендів.\n"
        "- Фільтруйте ROM і recovery за вибраним пристроєм.\n"
        "- Логотипи тепер завантажуються й оновлюються з каталогу, з плавнішим завантаженням.\n"
    ),
    "ur": (
        "- کمیونٹی بلڈز: OpenDesktop سے ہزاروں ROM تلاش اور ترتیب کے ساتھ دیکھیں۔\n"
        "- AXP.OS شامل کیا گیا، رازداری اور سیکیورٹی میں مضبوط ROM (DivestOS کا جانشین)۔\n"
        "- فلیش اسکرپٹ جنریٹر میں نیا GSI / Treble موڈ۔\n"
        "- مکمل سرکاری TWRP ڈیوائس فہرست اور مزید برانڈ لوگو شامل کیے گئے۔\n"
        "- منتخب ڈیوائس کے مطابق ROM اور recovery فلٹر کریں۔\n"
        "- لوگو اب کیٹلاگ سے لوڈ اور اپ ڈیٹ ہوتے ہیں، ہموار تصویر لوڈنگ کے ساتھ۔\n"
    ),
    "vi": (
        "- Bản dựng cộng đồng: duyệt hàng nghìn ROM từ OpenDesktop với tìm kiếm và sắp xếp.\n"
        "- Thêm AXP.OS, một ROM tăng cường quyền riêng tư và bảo mật (kế nhiệm DivestOS).\n"
        "- Chế độ GSI / Treble mới trong trình tạo tập lệnh flash.\n"
        "- Thêm danh sách thiết bị TWRP chính thức đầy đủ và nhiều logo thương hiệu hơn.\n"
        "- Lọc ROM và recovery theo thiết bị bạn đã chọn.\n"
        "- Logo nay được tải và cập nhật từ danh mục, với việc tải hình ảnh mượt hơn.\n"
    ),
    "zh-CN": (
        "- 社区版本：浏览来自 OpenDesktop 的数千个 ROM，支持搜索和排序。\n"
        "- 新增 AXP.OS，一款强化隐私与安全的 ROM（DivestOS 的继任者）。\n"
        "- 刷机脚本生成器新增 GSI / Treble 模式。\n"
        "- 新增完整的官方 TWRP 设备列表和更多品牌徽标。\n"
        "- 按所选设备筛选 ROM 和 recovery。\n"
        "- 徽标现在从目录加载并更新，图片加载更流畅。\n"
    ),
    "zh-TW": (
        "- 社群版本：瀏覽來自 OpenDesktop 的數千個 ROM，支援搜尋與排序。\n"
        "- 新增 AXP.OS，一款強化隱私與安全的 ROM（DivestOS 的後繼者）。\n"
        "- 刷機指令稿產生器新增 GSI / Treble 模式。\n"
        "- 新增完整的官方 TWRP 裝置清單和更多品牌標誌。\n"
        "- 依所選裝置篩選 ROM 和 recovery。\n"
        "- 標誌現在會從目錄載入並更新，圖片載入更流暢。\n"
    ),
    "zu": (
        "- Ukwakhiwa komphakathi: phequlula izinkulungwane ze-ROM ezivela ku-OpenDesktop ngosesho nokuhlunga.\n"
        "- Kungezwe i-AXP.OS, i-ROM eqiniswe ubumfihlo nokuvikeleka (ozolandela i-DivestOS).\n"
        "- Imodi entsha ye-GSI / Treble kumdali wescript se-flash.\n"
        "- Kungezwe uhlu olugcwele olusemthethweni lwamadivayisi e-TWRP namalogo amaningi ebhrendi.\n"
        "- Hlunga ama-ROM ne-recovery ngedivayisi oyikhethile.\n"
        "- Amalogo manje alayisha futhi abuyekezwe ekhethelogini, ngokulayisha izithombe okushelelayo.\n"
    ),
}

# Map each on-disk locale folder to a base-language text above. en-US and
# regional English variants use the canonical English (EN).
LOCALE_TO_LANG = {
    "en-US": None, "en-AU": None, "en-CA": None, "en-GB": None,
    "en-IN": None, "en-SG": None, "en-ZA": None,
    "es-419": "es", "es-ES": "es", "es-US": "es",
    "fa": "fa", "fa-AE": "fa", "fa-AF": "fa", "fa-IR": "fa",
    "fr-CA": "fr", "fr-FR": "fr",
    "pt-BR": "pt", "pt-PT": "pt-PT",
    "zh-CN": "zh-CN", "zh-HK": "zh-TW", "zh-TW": "zh-TW",
    "ms": "ms", "ms-MY": "ms",
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
        if not os.path.isdir(os.path.join(ROOT, locale)):
            print("WARN: locale folder missing on disk, skipping:", locale)
            continue
        d = os.path.join(ROOT, locale, "changelogs")
        os.makedirs(d, exist_ok=True)
        text = (EN if lang is None else LANG[lang]).rstrip("\n")
        with open(os.path.join(d, OUT), "w", encoding="utf-8") as f:
            f.write(text)
        n = len(text)
        if n > 500:
            over.append((locale, n))
        written += 1
    print(f"Wrote {written} changelog files ({OUT}).")
    if over:
        print("OVER 500 chars:")
        for loc, n in over:
            print(f"  {loc}: {n}")
        sys.exit(2)
    print("All within 500-char Play limit.")


if __name__ == "__main__":
    main()
