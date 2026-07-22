#!/usr/bin/env python3
"""Write v1.3.2 (versionCode 12) Play release notes into every locale's
changelogs/12.txt.

This script keeps the same locale coverage model as prior releases, but uses a
translation API at generation time so all locales stay populated for this
version without manually curating a huge map.

Rules:
- Every on-disk locale folder under fastlane/metadata/android must be mapped.
- English locales reuse the canonical English note.
- Non-English locales are translated from English.
- Files are written without a trailing newline.
- Each locale note must be <= 500 code points (Play limit).
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.parse
import urllib.request

ROOT = "fastlane/metadata/android"
OUT = "12.txt"

# Keep this short and user-facing so all locales fit safely under 500 chars.
EN_LINES = [
    "Old onboarding has been removed from the app.",
    "About and store messaging now reflect Google Play production access.",
]

# Matches the proven locale matrix used in prior release generators.
LOCALE_TO_LANG = {
    "en-US": None,
    "en-AU": None,
    "en-CA": None,
    "en-GB": None,
    "en-IN": None,
    "en-SG": None,
    "en-ZA": None,
    "es-419": "es",
    "es-ES": "es",
    "es-US": "es",
    "fa": "fa",
    "fa-AE": "fa",
    "fa-AF": "fa",
    "fa-IR": "fa",
    "fr-CA": "fr",
    "fr-FR": "fr",
    "pt-BR": "pt",
    "pt-PT": "pt-PT",
    "zh-CN": "zh-CN",
    "zh-HK": "zh-TW",
    "zh-TW": "zh-TW",
    "ms": "ms",
    "ms-MY": "ms",
    "af": "af",
    "am": "am",
    "ar": "ar",
    "az-AZ": "az",
    "be": "be",
    "bg": "bg",
    "bn-BD": "bn",
    "ca": "ca",
    "cs-CZ": "cs",
    "da-DK": "da",
    "de-DE": "de",
    "el-GR": "el",
    "et": "et",
    "eu-ES": "eu",
    "fi-FI": "fi",
    "fil": "fil",
    "gl-ES": "gl",
    "gu": "gu",
    "hi-IN": "hi",
    "hr": "hr",
    "hu-HU": "hu",
    "hy-AM": "hy",
    "id": "id",
    "is-IS": "is",
    "it-IT": "it",
    "iw-IL": "iw",
    "ja-JP": "ja",
    "ka-GE": "ka",
    "kk": "kk",
    "km-KH": "km",
    "kn-IN": "kn",
    "ko-KR": "ko",
    "ky-KG": "ky",
    "lo-LA": "lo",
    "lt": "lt",
    "lv": "lv",
    "mk-MK": "mk",
    "ml-IN": "ml",
    "mn-MN": "mn",
    "mr-IN": "mr",
    "my-MM": "my",
    "ne-NP": "ne",
    "nl-NL": "nl",
    "no-NO": "no",
    "pa": "pa",
    "pl-PL": "pl",
    "rm": "rm",
    "ro": "ro",
    "ru-RU": "ru",
    "si-LK": "si",
    "sk": "sk",
    "sl": "sl",
    "sq": "sq",
    "sr": "sr",
    "sv-SE": "sv",
    "sw": "sw",
    "ta-IN": "ta",
    "te-IN": "te",
    "th": "th",
    "tr-TR": "tr",
    "uk": "uk",
    "ur": "ur",
    "vi": "vi",
    "zu": "zu",
}

TRANSLATE_URL = "https://translate.googleapis.com/translate_a/single"

# Endpoint compatibility aliases (generation language code -> API language code).
TRANSLATE_LANG_ALIAS = {
    "iw": "he",
}

# Manual translations for languages not supported by the API endpoint.
MANUAL_LANG_LINES = {
    "rm": [
        "L'onboarding vegl è vegnì allontanà da l'app.",
        "Ils texts en About e sin la pagina dal Store reflectan ussa l'access da producziun da Google Play.",
    ],
}

# Keep brand/product terms stable across locales.
TERM_GUARD = {
    "Custom RR": "ZZTERM0",
    "Google Play": "ZZTERM1",
    "ROM": "ZZTERM3",
    "About": "ZZTERM4",
}

# Some language outputs (for example Cyrillic scripts) transliterate ZZTERM
# placeholders. Handle those variants so branded terms are always restored.
ALT_TERM_TOKENS = {
    "ЗЗТЕРМ0": "Custom RR",
    "ЗЗТЕРМ1": "Google Play",
    "ЗЗТЕРМ3": "ROM",
    "ЗЗТЕРМ4": "About",
}


def guard_terms(text: str) -> str:
    out = text
    for term, token in TERM_GUARD.items():
        out = out.replace(term, token)
    return out


def restore_terms(text: str) -> str:
    out = text
    for term, token in TERM_GUARD.items():
        out = out.replace(token, term)
    for token, term in ALT_TERM_TOKENS.items():
        out = out.replace(token, term)
    return out


def translate_text(text: str, lang: str) -> str:
    target_lang = TRANSLATE_LANG_ALIAS.get(lang, lang)
    query = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "en",
            "tl": target_lang,
            "dt": "t",
            "q": guard_terms(text),
        }
    )
    url = f"{TRANSLATE_URL}?{query}"

    last_err = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=20) as resp:
                raw = resp.read().decode("utf-8")
            payload = json.loads(raw)
            # payload[0] is a list of translated chunks.
            translated = "".join(chunk[0] for chunk in payload[0] if chunk and chunk[0])
            translated = restore_terms(translated).strip()
            if not translated:
                raise ValueError("empty translation")
            return translated
        except Exception as err:  # noqa: BLE001
            last_err = err
            # Small backoff helps with occasional endpoint hiccups.
            time.sleep(0.7 * (attempt + 1))

    raise RuntimeError(f"translation failed for lang={lang}: {last_err}")


def build_text_for_lang(lang: str | None) -> str:
    if lang is None:
        lines = EN_LINES
    elif lang in MANUAL_LANG_LINES:
        lines = MANUAL_LANG_LINES[lang]
    else:
        lines = [translate_text(line, lang) for line in EN_LINES]
    return "\n".join(f"- {line}" for line in lines)


def main() -> None:
    existing = sorted(
        d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))
    )

    missing_map = [d for d in existing if d not in LOCALE_TO_LANG]
    if missing_map:
        print("ERROR: on-disk locales with no mapping:", missing_map)
        sys.exit(1)

    over = []
    written = 0

    cache_by_lang: dict[str, str] = {}

    for locale, lang in LOCALE_TO_LANG.items():
        locale_dir = os.path.join(ROOT, locale)
        if not os.path.isdir(locale_dir):
            print("WARN: locale folder missing on disk, skipping:", locale)
            continue

        if lang is None:
            text = build_text_for_lang(None)
        else:
            if lang not in cache_by_lang:
                cache_by_lang[lang] = build_text_for_lang(lang)
            text = cache_by_lang[lang]

        text = text.rstrip("\n")

        changelog_dir = os.path.join(locale_dir, "changelogs")
        os.makedirs(changelog_dir, exist_ok=True)
        out_path = os.path.join(changelog_dir, OUT)
        with open(out_path, "w", encoding="utf-8") as handle:
            handle.write(text)

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
