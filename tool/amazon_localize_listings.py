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
    _read_notes,
    _request,
    app_url,
    commit_edit,
    fail,
    get_clean_edit,
    get_token,
    log,
    validate_edit,
)

# Amazon field limits in BYTES (the API enforces UTF-8 byte length, not code
# points, so multibyte scripts overflow a character-count limit). Verified
# against the live API: shortDescription caps at 1200 bytes; fullDescription is
# stricter for CJK than for Latin (fr-FR's 3104-byte description is accepted but
# an equivalent Japanese one is rejected above ~3000 bytes), so 3000 is the safe
# fullDescription cap -- it only lightly trims the two longest Latin locales and
# lets Japanese through. Overridable via env for future tuning.
MAX_TITLE = int(os.environ.get("AMZ_MAX_TITLE", "200"))
MAX_SHORT = int(os.environ.get("AMZ_MAX_SHORT", "1200"))
MAX_FULL = int(os.environ.get("AMZ_MAX_FULL", "3000"))
MAX_BULLET = int(os.environ.get("AMZ_MAX_BULLET", "200"))
MAX_RECENT = int(os.environ.get("AMZ_MAX_RECENT", "600"))

# Amazon listing language (its hyphenated locale code, which is also our fastlane
# metadata locale) -> Google Translate target code. English variants map to None
# (keep the en-US source verbatim, no translation). Amazon does not accept any
# Chinese listing code for this app (zh-CN / zh-Hans / zh / zh-TW all return
# "Invalid language"), so Chinese is intentionally omitted.
LANG_TO_TRANSLATE = {
    "en-US": None, "en-GB": None, "en-AU": None, "en-IN": None,
    "de-DE": "de", "fr-FR": "fr", "it-IT": "it", "ja-JP": "ja",
    "es-ES": "es", "pt-BR": "pt",
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
    """Trim `text` so its UTF-8 byte length is at most `limit`, at a word
    boundary when possible. Amazon enforces its listing field limits in BYTES,
    so a code-point trim is not enough for multibyte scripts (CJK etc.)."""
    if text is None or len(text.encode("utf-8")) <= limit:
        return text
    cut = text.encode("utf-8")[:limit].decode("utf-8", "ignore")
    sp = cut.rfind(" ")
    if sp > 0 and len(cut[:sp].encode("utf-8")) >= limit * 0.6:
        cut = cut[:sp]
    return cut.rstrip()


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


def _images_etag(token, app_id, edit_id, lang, image_type):
    """Current ETag of a language's image collection of `image_type`, needed as
    the If-Match header on every mutating image call, or None if unreadable."""
    base = app_url(app_id, f"/{edit_id}/listings/{lang}/{image_type}")
    status, headers, _b = _request("GET", base, token=token, allow_errors=True)
    return headers.get("ETag") if status == 200 else None


# Icons are language-agnostic (the app icon); Amazon requires each listing
# language to carry a small (114x114) and large (512x512) icon, shared from the
# en-US image assets.
ICON_TYPES = (("small-icons", "icon-small.png"), ("large-icons", "icon.png"))


def upload_icons(token, app_id, edit_id, lang, metadata_dir) -> None:
    """Upload (replace) the small + large icons for a language so a newly
    created language listing passes validate."""
    icon_dir = os.path.join(metadata_dir, "en-US", "images")
    for image_type, fname in ICON_TYPES:
        path = os.path.join(icon_dir, fname)
        if not os.path.isfile(path):
            log(f"::warning::icon file missing: {path}")
            continue
        with open(path, "rb") as fh:
            data = fh.read()
        etag = _images_etag(token, app_id, edit_id, lang, image_type)
        up, _h, body = _request(
            "POST", app_url(app_id, f"/{edit_id}/listings/{lang}/{image_type}/upload"),
            token=token, data=data, content_type="image/png", etag=etag,
            want_json=False, allow_errors=True)
        if up not in (200, 201, 204):
            detail = body.decode("utf-8", "replace")[:200] if isinstance(body, bytes) else str(body)
            log(f"::warning::icon upload failed for {lang} {image_type} (HTTP {up}): {detail}")


def upload_screenshots(token, app_id, edit_id, lang, locale, metadata_dir) -> int:
    """Replace a language's Amazon screenshots with the localized set, in order.

    Amazon adds each uploaded image to the set, so display order follows upload
    order; existing screenshots are deleted first so the new set fully replaces
    them. Every mutating call must carry the collection's current ETag as the
    If-Match header, and each call changes that ETag, so it is re-read before
    each one. Returns how many were uploaded (0 when this locale has no files,
    e.g. the gitignored localized sets are absent in a CI checkout).
    """
    files = screenshot_files(metadata_dir, locale)
    if not files:
        return 0
    base = app_url(app_id, f"/{edit_id}/listings/{lang}/{SCREENSHOT_TYPE}")
    # Clear the existing screenshots first (DELETE needs the current ETag).
    etag = _images_etag(token, app_id, edit_id, lang, SCREENSHOT_TYPE)
    if etag:
        _request("DELETE", base, token=token, etag=etag,
                 want_json=False, allow_errors=True)
    uploaded = 0
    for path in files:
        with open(path, "rb") as fh:
            data = fh.read()
        # Each upload mutates the set, so fetch the fresh ETag right before it.
        etag = _images_etag(token, app_id, edit_id, lang, SCREENSHOT_TYPE)
        up, _h, body = _request(
            "POST", f"{base}/upload", token=token, data=data,
            content_type="image/png", etag=etag,
            want_json=False, allow_errors=True)
        if up in (200, 201, 204):
            uploaded += 1
        else:
            detail = body.decode("utf-8", "replace")[:200] if isinstance(body, bytes) else str(body)
            log(f"::warning::uploadImage failed for {lang} {os.path.basename(path)} (HTTP {up}): {detail}")
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
    version_code = os.environ.get("AMAZON_VERSION_CODE", "").strip()

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
    en_listing, _etag = get_listing(token, app_id, edit_id, "en-US")
    if not en_listing:
        fail("Could not read the live en-US listing; nothing to localize from.")
    src_short = (en_listing.get("shortDescription") or "").strip()
    src_bullets = [b for b in (en_listing.get("featureBullets") or []) if b and b.strip()]
    src_title = (en_listing.get("title") or "").strip()
    src_full = (en_listing.get("fullDescription") or "").strip()
    # Amazon requires non-empty recentChanges to save any listing; the en-US
    # notes are the fallback when a locale has no translated changelog.
    default_notes = _read_notes(metadata_dir, "en-US", version_code)
    log(f"Source en-US: shortDescription {len(src_short)} chars, "
        f"{len(src_bullets)} feature bullets.")

    changed = 0
    for lang in LANG_TO_TRANSLATE:
        # Amazon's hyphenated listing code doubles as our fastlane metadata locale.
        locale = lang
        tlang = LANG_TO_TRANSLATE.get(lang)

        # Listing text. en-US is the curated source of truth, never overwritten.
        if do_text and lang != "en-US":
            listing, etag = get_listing(token, app_id, edit_id, lang)
            payload = dict(listing) if listing else {"language": lang}

            # Title + full description: reuse the already-localized Play copy,
            # falling back to the en-US text so a new listing always has them.
            title = read_play_meta(metadata_dir, locale, "title.txt") or src_title
            full = read_play_meta(metadata_dir, locale, "full_description.txt") or src_full
            if title:
                payload["title"] = clamp(title, MAX_TITLE)
            if full:
                payload["fullDescription"] = clamp(full, MAX_FULL)

            # Short description + bullets: translate the bespoke Amazon en-US copy.
            try:
                if src_short:
                    payload["shortDescription"] = clamp(translate(src_short, tlang), MAX_SHORT)
                if src_bullets:
                    payload["featureBullets"] = [clamp(translate(b, tlang), MAX_BULLET) for b in src_bullets]
            except Exception as err:  # noqa: BLE001
                log(f"::warning::translation failed for {lang} ({err}); "
                    f"keeping its existing short description and bullets.")

            # Amazon requires non-empty recentChanges to save a listing. Use the
            # locale's own release notes from the changelog files, falling back
            # to the en-US notes.
            notes = _read_notes(metadata_dir, locale, version_code) or default_notes
            if notes:
                payload["recentChanges"] = clamp(notes, MAX_RECENT)

            status, _h, body = _request(
                "PUT", app_url(app_id, f"/{edit_id}/listings/{lang}"),
                token=token, data=json.dumps(payload).encode("utf-8"),
                content_type="application/json", etag=etag,
                want_json=False, allow_errors=True)
            if status in (200, 204):
                changed += 1
                log(f"Localized text for {lang}.")
                # A new-language listing also needs its icons to pass validate.
                upload_icons(token, app_id, edit_id, lang, metadata_dir)
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
                    log(f"Uploaded {n} screenshots for {lang}.")
            except Exception as err:  # noqa: BLE001
                log(f"::warning::screenshot upload failed for {lang}: {err}")

    if changed == 0:
        fail("Nothing was localized (no text changes and no screenshot files found).")

    # validate requires every language (including the untouched en-US source) to
    # carry recentChanges; the live en-US has none, so set it from the en-US
    # changelog without disturbing en-US's curated title/description/bullets.
    if do_text and default_notes:
        en_now, en_etag = get_listing(token, app_id, edit_id, "en-US")
        if en_now is not None and not (en_now.get("recentChanges") or "").strip():
            en_now["recentChanges"] = clamp(default_notes, MAX_RECENT)
            st, _h, _b = _request(
                "PUT", app_url(app_id, f"/{edit_id}/listings/en-US"), token=token,
                data=json.dumps(en_now).encode("utf-8"),
                content_type="application/json", etag=en_etag,
                want_json=False, allow_errors=True)
            log(f"Set en-US recentChanges (required by validate): HTTP {st}.")

    validate_edit(token, app_id, edit_id)
    if submit:
        commit_edit(token, app_id, edit_id)
    else:
        log("AMAZON_SUBMIT=false: localized Edit prepared and validated but NOT "
            "committed. Inspect it in the Developer Console, or re-run with "
            "AMAZON_SUBMIT=true to submit.")


if __name__ == "__main__":
    main()
