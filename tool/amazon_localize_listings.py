#!/usr/bin/env python3
"""Localize the Custom RR Amazon Appstore listing (title, description, short
description, feature bullets, and screenshots) for the languages Amazon supports.

This is DELIBERATELY separate from tool/amazon_upload.py (the per-release APK
publisher) so it can never break an APK release: listing text changes rarely,
unlike per-release notes, so you run this on its own when the store copy
changes, not on every build.

It reuses amazon_upload.py's LWA auth + Edit plumbing, then for each Amazon
listing language:
  * title and fullDescription come straight from the already-translated Play
    metadata (fastlane/metadata/android/<locale>/title.txt, full_description.txt),
    so Amazon shows the same localized copy as Google Play.
  * shortDescription and featureBullets are Amazon-specific (longer promo text
    and per-line bullets that have no Play equivalent), so they are translated
    from the live en-US listing at run time (brand and project names guarded).
  * en-US is left untouched (it is the human-curated source of truth); only the
    other languages are written.
  * recentChanges is only set on a language listing that does not have one yet
    (a newly created localization), copied from the live en-US notes so it never
    bumps release notes to a version that is not on Amazon yet.
  * screenshots are replaced per language from the localized set in
    fastlane/metadata/android/<locale>/images/phoneScreenshots/ and uploaded in
    order. Those localized sets are gitignored, so screenshots upload only on a
    LOCAL run where the files exist (a CI checkout has en-US only), which is why
    the workflow runs text-only.

Amazon supports listings for a fixed, small set of languages (see
AMAZON_LANG_TO_LOCALE in amazon_upload.py), not Play's 87 locales.

IMPORTANT: like amazon_upload.py, this discards any open Edit before starting
(Amazon allows only one open Edit at a time). Close or submit any Developer
Console edit you have open first, or its unsaved changes are lost.

Config (env):
  AMAZON_CLIENT_ID / AMAZON_CLIENT_SECRET / AMAZON_APP_ID   (required)
  AMAZON_METADATA_DIR   fastlane metadata root (default fastlane/metadata/android)
  AMAZON_LOCALIZE_TEXT         "true" (default) localizes title/description/short/bullets
  AMAZON_LOCALIZE_SCREENSHOTS  "true" (default) replaces screenshots per language
                               (needs the localized files present: a LOCAL run)
  AMAZON_SUBMIT         "true" (default) validates + commits (= review submission);
                        "false" prepares + validates only (dry run, nothing sent)

Exit codes: 0 ok; 2 app is in review (retry later); 1 any other error.
"""

from __future__ import annotations

import glob
import json
import os
import sys
import time
import urllib.parse
import urllib.request

# Reuse the auth + Edit + HTTP plumbing from the release publisher.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from amazon_upload import (  # noqa: E402
    AMAZON_LANG_TO_LOCALE,
    _request,
    app_url,
    commit_edit,
    fail,
    get_clean_edit,
    get_token,
    log,
    validate_edit,
)

# Amazon field limits (from the Developer Console field counters).
MAX_TITLE = 200
MAX_SHORT = 1200
MAX_FULL = 4000

# Amazon listing language -> Google Translate target code. English variants map
# to None (keep the en-US source verbatim, no translation).
LANG_TO_TRANSLATE = {
    "en_US": None, "en_GB": None, "en_AU": None, "en_IN": None,
    "de_DE": "de", "fr_FR": "fr", "it_IT": "it", "ja_JP": "ja",
    "es_ES": "es", "pt_BR": "pt", "zh_CN": "zh-CN",
}

# Brand, project and platform names that must never be translated.
TERM_GUARD = {
    "Custom RR": "ZZT00", "LineageOS": "ZZT01", "crDroid": "ZZT02",
    "PixelOS": "ZZT03", "GrapheneOS": "ZZT04", "CalyxOS": "ZZT05",
    "DivestOS": "ZZT06", "RisingOS": "ZZT07", "VoltageOS": "ZZT08",
    "BlissROMs": "ZZT09", "Evolution X": "ZZT10", "Project Elixir": "ZZT11",
    "DerpFest": "ZZT12", "UN1CA": "ZZT13", "TrebleDroid": "ZZT14",
    "OrangeFox": "ZZT15", "TWRP": "ZZT16", "PBRP": "ZZT17", "SHRP": "ZZT18",
    "Magisk": "ZZT19", "KernelSU": "ZZT20", "APatch": "ZZT21",
    "SourceForge": "ZZT22", "Telegram": "ZZT23", "GitHub": "ZZT24",
    "Play Services": "ZZT25", "GPL-3.0": "ZZT26", "Treble": "ZZT27",
    "GSIs": "ZZT28", "GSI": "ZZT29", "AOSP": "ZZT30", "Android": "ZZT31",
    "ROMs": "ZZT32", "ROM": "ZZT33",
}
TRANSLATE_URL = "https://translate.googleapis.com/translate_a/single"


def guard(text: str) -> str:
    for term, tok in TERM_GUARD.items():
        text = text.replace(term, tok)
    return text


def unguard(text: str) -> str:
    for term, tok in TERM_GUARD.items():
        text = text.replace(tok, term)
    return text


def translate(text: str, lang: str | None) -> str:
    """Translate English text to `lang` (None keeps it verbatim)."""
    if not lang or not text.strip():
        return text
    query = urllib.parse.urlencode({
        "client": "gtx", "sl": "en", "tl": lang, "dt": "t", "q": guard(text),
    })
    last = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(f"{TRANSLATE_URL}?{query}", timeout=20) as resp:
                payload = json.loads(resp.read().decode("utf-8"))
            out = "".join(chunk[0] for chunk in payload[0] if chunk and chunk[0])
            out = unguard(out).strip()
            if not out:
                raise ValueError("empty translation")
            return out
        except Exception as err:  # noqa: BLE001
            last = err
            time.sleep(0.7 * (attempt + 1))
    raise RuntimeError(f"translation failed for lang={lang}: {last}")


def read_play_meta(metadata_dir: str, locale: str, name: str):
    """Read a Play metadata text file, or None if absent/empty."""
    if not locale:
        return None
    path = os.path.join(metadata_dir, locale, name)
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as fh:
        text = fh.read().strip()
    return text or None


def clamp(text: str, limit: int) -> str:
    """Trim to `limit` code points at a word boundary when possible."""
    if text is None or len(text) <= limit:
        return text
    cut = text[:limit]
    sp = cut.rfind(" ")
    return (cut[:sp] if sp > limit * 0.6 else cut).rstrip()


def get_listing(token, app_id, edit_id, lang):
    """Return (listing_dict_or_None, etag)."""
    status, headers, body = _request(
        "GET", app_url(app_id, f"/{edit_id}/listings/{lang}"),
        token=token, allow_errors=True)
    if status == 200 and isinstance(body, dict):
        return body, headers.get("ETag")
    return None, None


SCREENSHOT_TYPE = "screenshots"


def screenshot_files(metadata_dir: str, locale: str) -> list:
    """Sorted phone screenshots for a locale, or [] if the folder is absent
    (e.g. in CI, where the localized sets are gitignored)."""
    folder = os.path.join(metadata_dir, locale, "images", "phoneScreenshots")
    return sorted(glob.glob(os.path.join(folder, "*.png"))) if os.path.isdir(folder) else []


def upload_screenshots(token, app_id, edit_id, lang, locale, metadata_dir) -> int:
    """Replace a language's Amazon screenshots with the localized set, in order.

    Amazon adds each uploaded image to the set, so display order follows upload
    order; existing screenshots are deleted first so the new set fully replaces
    them. Returns how many were uploaded (0 when this locale has no files, e.g.
    the gitignored localized sets are absent in a CI checkout).
    """
    files = screenshot_files(metadata_dir, locale)
    if not files:
        return 0
    base = app_url(app_id, f"/{edit_id}/listings/{lang}/{SCREENSHOT_TYPE}")
    # Clear the existing screenshots first (DELETE needs the current ETag).
    status, headers, _b = _request("GET", base, token=token, allow_errors=True)
    if status == 200:
        _request("DELETE", base, token=token, etag=headers.get("ETag"),
                 want_json=False, allow_errors=True)
    uploaded = 0
    for path in files:
        with open(path, "rb") as fh:
            data = fh.read()
        up, _h, _b = _request(
            "POST", f"{base}/upload", token=token, data=data,
            content_type="image/png", want_json=False, allow_errors=True)
        if up in (200, 201, 204):
            uploaded += 1
        else:
            log(f"::warning::uploadImage failed for {lang} {os.path.basename(path)} (HTTP {up}).")
    return uploaded


def main() -> None:
    client_id = os.environ.get("AMAZON_CLIENT_ID", "").strip()
    client_secret = os.environ.get("AMAZON_CLIENT_SECRET", "").strip()
    app_id = os.environ.get("AMAZON_APP_ID", "").strip()
    metadata_dir = os.environ.get(
        "AMAZON_METADATA_DIR", "fastlane/metadata/android").strip()
    submit = os.environ.get("AMAZON_SUBMIT", "true").strip().lower() != "false"
    do_text = os.environ.get("AMAZON_LOCALIZE_TEXT", "true").strip().lower() != "false"
    do_shots = os.environ.get("AMAZON_LOCALIZE_SCREENSHOTS", "true").strip().lower() != "false"

    missing = [n for n, v in (
        ("AMAZON_CLIENT_ID", client_id),
        ("AMAZON_CLIENT_SECRET", client_secret),
        ("AMAZON_APP_ID", app_id),
    ) if not v]
    if missing:
        fail(f"missing required env: {', '.join(missing)}")

    token = get_token(client_id, client_secret)
    edit_id = get_clean_edit(token, app_id)

    # The live en-US listing is the source for the Amazon-specific short
    # description and feature bullets (which have no Play equivalent).
    en_listing, _etag = get_listing(token, app_id, edit_id, "en_US")
    if not en_listing:
        fail("Could not read the live en_US listing; nothing to localize from.")
    src_short = (en_listing.get("shortDescription") or "").strip()
    src_bullets = [b for b in (en_listing.get("featureBullets") or []) if b and b.strip()]
    src_recent = (en_listing.get("recentChanges") or "").strip()
    log(f"Source en-US: shortDescription {len(src_short)} chars, "
        f"{len(src_bullets)} feature bullets.")

    changed = 0
    for lang, locale in AMAZON_LANG_TO_LOCALE.items():
        tlang = LANG_TO_TRANSLATE.get(lang)

        # Listing text. en-US is the curated source of truth, never overwritten.
        if do_text and lang != "en_US":
            listing, etag = get_listing(token, app_id, edit_id, lang)
            payload = dict(listing) if listing else {"language": lang}

            # Title + full description: reuse the already-localized Play copy.
            title = read_play_meta(metadata_dir, locale, "title.txt")
            full = read_play_meta(metadata_dir, locale, "full_description.txt")
            if title:
                payload["title"] = clamp(title, MAX_TITLE)
            if full:
                payload["fullDescription"] = clamp(full, MAX_FULL)

            # Short description + bullets: translate the bespoke Amazon en-US copy.
            try:
                if src_short:
                    payload["shortDescription"] = clamp(translate(src_short, tlang), MAX_SHORT)
                if src_bullets:
                    payload["featureBullets"] = [translate(b, tlang) for b in src_bullets]
            except Exception as err:  # noqa: BLE001
                log(f"::warning::translation failed for {lang} ({err}); "
                    f"keeping its existing short description and bullets.")

            # A brand-new language listing needs recentChanges to pass validate.
            # Copy the live en-US notes (translated) so we never post notes for a
            # version that is not on Amazon yet. Existing listings keep their own.
            if not payload.get("recentChanges") and src_recent:
                try:
                    payload["recentChanges"] = translate(src_recent, tlang)
                except Exception:  # noqa: BLE001
                    payload["recentChanges"] = src_recent

            status, _h, body = _request(
                "PUT", app_url(app_id, f"/{edit_id}/listings/{lang}"),
                token=token, data=json.dumps(payload).encode("utf-8"),
                content_type="application/json", etag=etag,
                want_json=False, allow_errors=True)
            if status in (200, 204):
                changed += 1
                log(f"Localized text for {lang} ({locale}).")
            else:
                detail = body.decode("utf-8", "replace")[:200] if isinstance(body, bytes) else str(body)
                log(f"::warning::Could not write listing text for {lang} (HTTP {status}): {detail}")

        # Screenshots, for every language. Skipped automatically when this locale
        # has no screenshot files (the gitignored localized sets are absent in a
        # CI checkout), so run this LOCALLY to push the full localized set.
        if do_shots:
            try:
                n = upload_screenshots(token, app_id, edit_id, lang, locale, metadata_dir)
                if n:
                    changed += 1
                    log(f"Uploaded {n} screenshots for {lang} ({locale}).")
            except Exception as err:  # noqa: BLE001
                log(f"::warning::screenshot upload failed for {lang}: {err}")

    if changed == 0:
        fail("Nothing was localized (no text changes and no screenshot files found).")

    validate_edit(token, app_id, edit_id)
    if submit:
        commit_edit(token, app_id, edit_id)
    else:
        log("AMAZON_SUBMIT=false: localized Edit prepared and validated but NOT "
            "committed. Inspect it in the Developer Console, or re-run with "
            "AMAZON_SUBMIT=true to submit.")


if __name__ == "__main__":
    main()
