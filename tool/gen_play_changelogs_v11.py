#!/usr/bin/env python3
"""Write the v1.3.1 (versionCode 11) Play release notes into every locale's
changelogs/11.txt. en-US stays the canonical approved text; the rest are
translations that keep brand/tech terms in Latin (Custom RR, OpenDesktop, ROM,
QR, Play).

Each file is written WITHOUT a trailing newline and validated to stay within
Play's 500 code-point per-language release-notes limit. v1.3.1 is a small patch
(community ROMs discoverability + smoother Google Play early access sign-up), so the note is
short and every translation fits comfortably.
"""
import os
import sys

ROOT = "fastlane/metadata/android"
OUT = "11.txt"

EN = (
    "- Community ROMs are easier to find, with a shortcut from the ROMs list.\n"
    "- Joining the Google Play early access is faster, with a QR code and a share button.\n"
)

LANG = {
    "af": (
        "- Gemeenskaps-ROM's is makliker om te vind, met 'n kortpad vanaf die ROM-lys.\n"
        "- Aansluit by die Play-beta is vinniger, met 'n QR-kode en 'n deelknoppie.\n"
    ),
    "am": (
        "- የማኅበረሰብ ROMዎችን ማግኘት ቀለል ብሏል፣ ከROM ዝርዝር አቋራጭ ጋር።\n"
        "- ወደ Play ቤታ መቀላቀል ፈጣን ሆኗል፣ በQR ኮድና በማጋሪያ አዝራር።\n"
    ),
    "ar": (
        "- أصبح العثور على ROMات المجتمع أسهل، مع اختصار من قائمة ROM.\n"
        "- الانضمام إلى نسخة Play التجريبية أسرع، مع رمز QR وزر مشاركة.\n"
    ),
    "az": (
        "- İcma ROM-larını tapmaq asanlaşdı, ROM siyahısından qısayol ilə.\n"
        "- Google Play-ə qoşulmaq daha sürətlidir, QR kodu və paylaşma düyməsi ilə.\n"
    ),
    "be": (
        "- Супольнасныя ROM прасцей знайсці дзякуючы цэтліку са спіса ROM.\n"
        "- Далучэнне да бэта-версіі Play стала хутчэйшым: QR-код і кнопка абагульвання.\n"
    ),
    "bg": (
        "- Общностните ROM са по-лесни за намиране, с пряк път от списъка с ROM.\n"
        "- Присъединяването към бета на Play е по-бързо, с QR код и бутон за споделяне.\n"
    ),
    "bn": (
        "- কমিউনিটি ROM খুঁজে পাওয়া সহজ হয়েছে, ROM তালিকা থেকে একটি শর্টকাট সহ।\n"
        "- Play বিটায় যোগ দেওয়া দ্রুততর হয়েছে, একটি QR কোড এবং শেয়ার বোতাম সহ।\n"
    ),
    "ca": (
        "- Les ROM de la comunitat són més fàcils de trobar, amb una drecera des de la llista de ROM.\n"
        "- Unir-se a la beta de Play és més ràpid, amb un codi QR i un botó de compartir.\n"
    ),
    "cs": (
        "- Komunitní ROM se snáze hledají díky zkratce ze seznamu ROM.\n"
        "- Připojení k beta verzi Play je rychlejší, s QR kódem a tlačítkem sdílení.\n"
    ),
    "da": (
        "- Fællesskabs-ROM'er er nemmere at finde med en genvej fra ROM-listen.\n"
        "- Det er hurtigere at tilmelde sig Play-betaen, med en QR-kode og en deleknap.\n"
    ),
    "de": (
        "- Community-ROMs sind leichter zu finden, mit einer Verknüpfung aus der ROM-Liste.\n"
        "- Der Beitritt zur Play-Beta geht schneller, mit QR-Code und Teilen-Schaltfläche.\n"
    ),
    "el": (
        "- Τα ROM της κοινότητας βρίσκονται πιο εύκολα, με συντόμευση από τη λίστα ROM.\n"
        "- Η εγγραφή στη beta του Play είναι πιο γρήγορη, με κωδικό QR και κουμπί κοινοποίησης.\n"
    ),
    "es": (
        "- Las ROM de la comunidad son más fáciles de encontrar, con un acceso directo desde la lista de ROM.\n"
        "- Unirse a la beta de Play es más rápido, con un código QR y un botón de compartir.\n"
    ),
    "et": (
        "- Kogukonna ROM-e on lihtsam leida, otsetee abil ROM-ide loendist.\n"
        "- Play beetaga liitumine on kiirem, QR-koodi ja jagamisnupuga.\n"
    ),
    "eu": (
        "- Komunitateko ROMak errazago aurkitzen dira, ROM zerrendako lasterbide batekin.\n"
        "- Google Play early accessrekin bat egitea azkarragoa da, QR kode eta partekatze botoi batekin.\n"
    ),
    "fa": (
        "- یافتن ROMهای جامعه آسان‌تر شد، با میان‌بری از فهرست ROM.\n"
        "- پیوستن به نسخه بتای Play سریع‌تر است، با کد QR و دکمه اشتراک‌گذاری.\n"
    ),
    "fi": (
        "- Yhteisön ROMit on helpompi löytää ROM-luettelon pikakuvakkeella.\n"
        "- Play-betaan liittyminen on nopeampaa QR-koodin ja jakopainikkeen avulla.\n"
    ),
    "fil": (
        "- Mas madaling hanapin ang mga community ROM, may shortcut mula sa listahan ng ROM.\n"
        "- Mas mabilis sumali sa Google Play early access, may QR code at share button.\n"
    ),
    "fr": (
        "- Les ROM de la communauté sont plus faciles à trouver, avec un raccourci depuis la liste des ROM.\n"
        "- Rejoindre la bêta Play est plus rapide, avec un code QR et un bouton de partage.\n"
    ),
    "gl": (
        "- As ROM da comunidade son máis fáciles de atopar, cun atallo dende a lista de ROM.\n"
        "- Unirse á beta de Play é máis rápido, cun código QR e un botón de compartir.\n"
    ),
    "gu": (
        "- સમુદાય ROM શોધવા સરળ બન્યા છે, ROM સૂચિમાંથી શૉર્ટકટ સાથે.\n"
        "- Play બીટામાં જોડાવું ઝડપી છે, QR કોડ અને શેર બટન સાથે.\n"
    ),
    "hi": (
        "- कम्युनिटी ROM ढूँढना आसान हो गया है, ROM सूची से एक शॉर्टकट के साथ।\n"
        "- Play बीटा में शामिल होना तेज़ है, QR कोड और शेयर बटन के साथ।\n"
    ),
    "hr": (
        "- ROM-ove zajednice lakše je pronaći, uz prečac s popisa ROM-ova.\n"
        "- Pridruživanje Play beti brže je, uz QR kod i gumb za dijeljenje.\n"
    ),
    "hu": (
        "- A közösségi ROM-okat könnyebb megtalálni a ROM-listából elérhető parancsikonnal.\n"
        "- A Play bétához csatlakozás gyorsabb, QR-kóddal és megosztás gombbal.\n"
    ),
    "hy": (
        "- Համայնքի ROM-երն ավելի հեշտ է գտնել՝ ROM-ների ցանկից դյուրանցումով։\n"
        "- Play բետային միանալն ավելի արագ է՝ QR կոդով և տարածման կոճակով։\n"
    ),
    "id": (
        "- ROM komunitas lebih mudah ditemukan, dengan pintasan dari daftar ROM.\n"
        "- Bergabung ke beta Play lebih cepat, dengan kode QR dan tombol bagikan.\n"
    ),
    "is": (
        "- Auðveldara er að finna samfélags-ROM með flýtileið úr ROM-listanum.\n"
        "- Það er fljótlegra að ganga í Play-betuna, með QR-kóða og deilihnappi.\n"
    ),
    "it": (
        "- Le ROM della community sono più facili da trovare, con una scorciatoia dall'elenco ROM.\n"
        "- Iscriversi alla beta di Play è più veloce, con un codice QR e un pulsante di condivisione.\n"
    ),
    "iw": (
        "- קל יותר למצוא ROM של הקהילה, עם קיצור דרך מרשימת ה-ROM.\n"
        "- ההצטרפות לגרסת הבטא של Play מהירה יותר, עם קוד QR וכפתור שיתוף.\n"
    ),
    "ja": (
        "- コミュニティ ROM が見つけやすくなりました。ROM 一覧からのショートカット付き。\n"
        "- Play ベータへの参加が速くなりました。QR コードと共有ボタン付き。\n"
    ),
    "ka": (
        "- საზოგადოების ROM-ების პოვნა გაიოლდა, ROM-ების სიიდან მალსახმობით.\n"
        "- Play-ის ბეტაში გაწევრიანება უფრო სწრაფია, QR კოდითა და გაზიარების ღილაკით.\n"
    ),
    "kk": (
        "- Қауымдастық ROM-дарын табу оңайырақ болды, ROM тізімінен таңбаша арқылы.\n"
        "- Play бетасына қосылу жылдамырақ, QR коды мен бөлісу түймесі арқылы.\n"
    ),
    "km": (
        "- ROM សហគមន៍ងាយស្រួលរកជាងមុន ដោយមានផ្លូវកាត់ពីបញ្ជី ROM។\n"
        "- ការចូលរួម Google Play early access លឿនជាងមុន ដោយមានកូដ QR និងប៊ូតុងចែករំលែក។\n"
    ),
    "kn": (
        "- ಸಮುದಾಯ ROM ಗಳನ್ನು ಹುಡುಕುವುದು ಸುಲಭವಾಗಿದೆ, ROM ಪಟ್ಟಿಯಿಂದ ಶಾರ್ಟ್‌ಕಟ್ ಜೊತೆಗೆ.\n"
        "- Play ಬೀಟಾಗೆ ಸೇರುವುದು ವೇಗವಾಗಿದೆ, QR ಕೋಡ್ ಮತ್ತು ಹಂಚಿಕೆ ಬಟನ್ ಜೊತೆಗೆ.\n"
    ),
    "ko": (
        "- 커뮤니티 ROM을 더 쉽게 찾을 수 있습니다. ROM 목록에서 바로가기를 제공합니다.\n"
        "- Play 베타 참여가 더 빨라졌습니다. QR 코드와 공유 버튼을 제공합니다.\n"
    ),
    "ky": (
        "- Коомдук ROM'дорду табуу оңоюраак болду, ROM тизмесинен кыска жол менен.\n"
        "- Play бетасына кошулуу тезирээк, QR коду жана бөлүшүү баскычы менен.\n"
    ),
    "lo": (
        "- ROM ຂອງຊຸມຊົນຫາງ່າຍຂຶ້ນ, ດ້ວຍທາງລັດຈາກລາຍຊື່ ROM.\n"
        "- ການເຂົ້າຮ່ວມ Google Play early access ໄວຂຶ້ນ, ດ້ວຍລະຫັດ QR ແລະ ປຸ່ມແບ່ງປັນ.\n"
    ),
    "lt": (
        "- Bendruomenės ROM lengviau rasti naudojant nuorodą iš ROM sąrašo.\n"
        "- Prisijungti prie Google Play early access versijos greičiau, su QR kodu ir bendrinimo mygtuku.\n"
    ),
    "lv": (
        "- Kopienas ROM ir vieglāk atrast, izmantojot saīsni no ROM saraksta.\n"
        "- Pievienoties Google Play early access versijai ir ātrāk, ar QR kodu un kopīgošanas pogu.\n"
    ),
    "mk": (
        "- ROM-овите од заедницата полесно се наоѓаат, со кратенка од списокот со ROM.\n"
        "- Приклучувањето кон бета на Play е побрзо, со QR код и копче за споделување.\n"
    ),
    "ml": (
        "- കമ്മ്യൂണിറ്റി ROM-കൾ കണ്ടെത്താൻ എളുപ്പമായി, ROM പട്ടികയിൽ നിന്ന് ഒരു കുറുക്കുവഴിയോടെ.\n"
        "- Play ബീറ്റയിൽ ചേരുന്നത് വേഗത്തിലായി, QR കോഡും ഷെയർ ബട്ടണും ഉപയോഗിച്ച്.\n"
    ),
    "mn": (
        "- Олон нийтийн ROM-уудыг олоход хялбар боллоо, ROM жагсаалтаас товчлолтой.\n"
        "- Play бетад нэгдэх нь хурдан болсон, QR код болон хуваалцах товчтой.\n"
    ),
    "mr": (
        "- समुदाय ROM शोधणे सोपे झाले आहे, ROM यादीतून शॉर्टकटसह.\n"
        "- Play बीटामध्ये सामील होणे जलद आहे, QR कोड आणि शेअर बटणासह.\n"
    ),
    "ms": (
        "- ROM komuniti lebih mudah dicari, dengan pintasan daripada senarai ROM.\n"
        "- Menyertai beta Play lebih pantas, dengan kod QR dan butang kongsi.\n"
    ),
    "my": (
        "- အသိုက်အဝန်း ROM များကို ရှာရလွယ်လာသည်၊ ROM စာရင်းမှ ဖြတ်လမ်းနှင့်အတူ။\n"
        "- Google Play early access သို့ ပါဝင်ခြင်း ပိုမြန်လာသည်၊ QR ကုဒ်နှင့် မျှဝေခလုတ်ဖြင့်။\n"
    ),
    "ne": (
        "- समुदाय ROM फेला पार्न सजिलो भयो, ROM सूचीबाट सर्टकटसहित।\n"
        "- Play बिटामा सामेल हुन छिटो भयो, QR कोड र सेयर बटनसहित।\n"
    ),
    "nl": (
        "- Community-ROM's zijn makkelijker te vinden, met een snelkoppeling vanuit de ROM-lijst.\n"
        "- Deelnemen aan de Play-bèta gaat sneller, met een QR-code en een deelknop.\n"
    ),
    "no": (
        "- Fellesskaps-ROM-er er lettere å finne, med en snarvei fra ROM-listen.\n"
        "- Det går raskere å bli med i Play-betaen, med en QR-kode og en deleknapp.\n"
    ),
    "pa": (
        "- ਕਮਿਊਨਿਟੀ ROM ਲੱਭਣੇ ਸੌਖੇ ਹੋ ਗਏ ਹਨ, ROM ਸੂਚੀ ਤੋਂ ਸ਼ਾਰਟਕੱਟ ਨਾਲ।\n"
        "- Play ਬੀਟਾ ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਣਾ ਤੇਜ਼ ਹੈ, QR ਕੋਡ ਅਤੇ ਸ਼ੇਅਰ ਬਟਨ ਨਾਲ।\n"
    ),
    "pl": (
        "- Społecznościowe ROM-y łatwiej znaleźć dzięki skrótowi z listy ROM-ów.\n"
        "- Dołączanie do bety Play jest szybsze, z kodem QR i przyciskiem udostępniania.\n"
    ),
    "pt": (
        "- As ROMs da comunidade ficam mais fáceis de encontrar, com um atalho na lista de ROMs.\n"
        "- Entrar no beta do Play ficou mais rápido, com um código QR e um botão de compartilhar.\n"
    ),
    "pt-PT": (
        "- As ROM da comunidade são mais fáceis de encontrar, com um atalho na lista de ROM.\n"
        "- Aderir à beta do Play é mais rápido, com um código QR e um botão de partilha.\n"
    ),
    "rm": (
        "- Las ROM da la communitad èn pli simpel da chattar, cun ina scursanida da la glista da ROM.\n"
        "- S'associar a la beta da Play va pli svelt, cun in code QR ed in buttun da cundivider.\n"
    ),
    "ro": (
        "- ROM-urile comunității sunt mai ușor de găsit, cu o scurtătură din lista de ROM-uri.\n"
        "- Înscrierea în beta Play este mai rapidă, cu un cod QR și un buton de partajare.\n"
    ),
    "ru": (
        "- ROM сообщества проще найти благодаря ярлыку из списка ROM.\n"
        "- Присоединиться к бета-версии Play стало быстрее: QR-код и кнопка «Поделиться».\n"
    ),
    "si": (
        "- ප්‍රජා ROM සොයා ගැනීම පහසු වී ඇත, ROM ලැයිස්තුවෙන් කෙටිමඟක් සමඟ.\n"
        "- Play බීටාවට එක්වීම වේගවත් ය, QR කේතයක් සහ බෙදාගැනීමේ බොත්තමක් සමඟ.\n"
    ),
    "sk": (
        "- Komunitné ROM sa ľahšie hľadajú vďaka skratke zo zoznamu ROM.\n"
        "- Pripojenie k beta verzii Play je rýchlejšie, s QR kódom a tlačidlom zdieľania.\n"
    ),
    "sl": (
        "- Skupnostne ROM-e je lažje najti z bližnjico s seznama ROM-ov.\n"
        "- Pridružitev beti Play je hitrejša, s kodo QR in gumbom za deljenje.\n"
    ),
    "sq": (
        "- ROM-et e komunitetit gjenden më lehtë, me një shkurtore nga lista e ROM-eve.\n"
        "- Bashkimi në beta-n e Play është më i shpejtë, me një kod QR dhe një buton ndarjeje.\n"
    ),
    "sr": (
        "- ROM-ове заједнице лакше је пронаћи, уз пречицу са листе ROM-ова.\n"
        "- Придруживање Play бети је брже, уз QR код и дугме за дељење.\n"
    ),
    "sv": (
        "- Community-ROM:ar är lättare att hitta, med en genväg från ROM-listan.\n"
        "- Att gå med i Play-betan går snabbare, med en QR-kod och en delningsknapp.\n"
    ),
    "sw": (
        "- ROM za jamii ni rahisi kupata, kwa njia ya mkato kutoka kwenye orodha ya ROM.\n"
        "- Kujiunga na beta ya Play ni haraka zaidi, kwa msimbo wa QR na kitufe cha kushiriki.\n"
    ),
    "ta": (
        "- சமூக ROM-களைக் கண்டறிவது எளிதாகிவிட்டது, ROM பட்டியலில் இருந்து ஒரு குறுக்குவழியுடன்.\n"
        "- Play பீட்டாவில் சேருவது வேகமாகிவிட்டது, QR குறியீடு மற்றும் பகிர் பொத்தானுடன்.\n"
    ),
    "te": (
        "- సంఘం ROM లను కనుగొనడం సులభమైంది, ROM జాబితా నుండి షార్ట్‌కట్‌తో.\n"
        "- Play బీటాలో చేరడం వేగవంతమైంది, QR కోడ్ మరియు షేర్ బటన్‌తో.\n"
    ),
    "th": (
        "- ค้นหา ROM ของชุมชนได้ง่ายขึ้น พร้อมทางลัดจากรายการ ROM\n"
        "- เข้าร่วม Play เบต้าได้เร็วขึ้น ด้วยรหัส QR และปุ่มแชร์\n"
    ),
    "tr": (
        "- Topluluk ROM'larını bulmak artık daha kolay, ROM listesinden bir kısayolla.\n"
        "- Google Play'e katılmak daha hızlı, QR kodu ve paylaş düğmesiyle.\n"
    ),
    "uk": (
        "- Громадські ROM простіше знайти завдяки ярлику зі списку ROM.\n"
        "- Приєднатися до бета-версії Play стало швидше: QR-код і кнопка поширення.\n"
    ),
    "ur": (
        "- کمیونٹی ROM تلاش کرنا آسان ہو گیا ہے، ROM فہرست سے شارٹ کٹ کے ساتھ۔\n"
        "- Play بیٹا میں شامل ہونا تیز ہو گیا ہے، QR کوڈ اور شیئر بٹن کے ساتھ۔\n"
    ),
    "vi": (
        "- ROM cộng đồng dễ tìm hơn, với lối tắt từ danh sách ROM.\n"
        "- Tham gia bản beta của Play nhanh hơn, với mã QR và nút chia sẻ.\n"
    ),
    "zh-CN": (
        "- 社区 ROM 更易查找，可从 ROM 列表快捷进入。\n"
        "- 加入 Play 测试版更快捷，带二维码和分享按钮。\n"
    ),
    "zh-TW": (
        "- 社群 ROM 更容易尋找，可從 ROM 清單快速進入。\n"
        "- 加入 Play 測試版更快速，附 QR Code 與分享按鈕。\n"
    ),
    "zu": (
        "- Ama-ROM omphakathi kulula ukuwathola, ngesinqamuleli kusuka ohlwini lwama-ROM.\n"
        "- Ukujoyina i-beta ye-Play kushesha kakhulu, ngekhodi ye-QR nenkinobho yokwabelana.\n"
    ),
}

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
