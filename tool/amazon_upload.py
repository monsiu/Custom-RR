#!/usr/bin/env python3
"""Upload a new Custom RR version to the Amazon Appstore via the App Submission API.

Amazon's App Submission API is APK-only (it does NOT accept AAB), so CI builds a
universal store APK (the same PLAY_BUILD store variant, just APK output) and this
script pushes it as a new version of the already-live app.

Flow (per https://developer.amazon.com/docs/app-submission-api/flows.html):
  1. Exchange the Security Profile client id/secret for an LWA access token.
  2. Get the open Edit, or create one (an Edit is a copy of the live version).
  3. REPLACE the live APK in place with our new binary (replaceApk), which keeps
     the live version's device targeting AND its DRM / signing choice.
  4. Set the per-language "recent changes" (release notes) on the listings.
  5. validateEdit, then commitEdit (= submit to Amazon review).

Why replaceApk and not upload-new + delete-old:
  Amazon's docs are explicit that deleting an APK "also deletes all of the
  device-targeting information for that APK", while replaceApk "preserves the
  targeting information". replaceApk also keeps the APK's DRM choice, which the
  API has NO endpoint to set (the ApkInjectionChoice/allowDRM field exists in
  the API model but no path consumes it). Uploading a fresh APK instead leaves
  it with no DRM value, so validate fails with error_apk_drm_value_missing.

One-time bootstrap (only matters while the live version came from an AAB):
  If the live version was published from an AAB (as the first Custom RR upload
  was), its APKs are Amazon-generated assets that replaceApk cannot touch
  (error_invalid_asset_id), and a plain upload can't have its DRM set. So the
  FIRST APK update must be done by hand in the Developer Console (upload a
  universal store APK as a new version, set "Apply DRM?" = No). After that the
  live version is APK-based and this script updates every future release on its
  own via replaceApk.

commitEdit submits to review; publishing then takes a few hours, exactly like
Play. Set AMAZON_SUBMIT=false to prepare + validate the Edit WITHOUT committing
(a dry run you can inspect/commit by hand in the Developer Console).

Config comes from the environment (all required unless noted):
  AMAZON_CLIENT_ID       Security Profile client id (amzn1.application-oa2-client...)
  AMAZON_CLIENT_SECRET   Security Profile client secret
  AMAZON_APP_ID          The app's App ID key (Developer Console > app > Upload App File)
  AMAZON_APK_PATH        Path to the universal store APK to upload
  AMAZON_VERSION_CODE    (optional) versionCode of this build, used to find the
                         matching changelog file; if unset, the highest-numbered
                         changelog in each locale is used.
  AMAZON_METADATA_DIR    (optional) fastlane metadata root holding the per-locale
                         changelogs/<code>.txt release notes
                         (default: fastlane/metadata/android)
  AMAZON_SUBMIT          "true" (default) commits/submits; "false" prepares only

Exit codes: 0 ok (committed or prepared); 2 app is in review (try again later);
1 any other error.
"""

from __future__ import annotations

import glob
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

AUTH_URL = "https://api.amazon.com/auth/o2/token"
BASE_URL = "https://developer.amazon.com/api/appstore"
API_VERSION = "v1"
APK_CONTENT_TYPE = "application/vnd.android.package-archive"

# Amazon listing language code (underscore) -> our fastlane metadata locale
# (hyphen). Only the languages Amazon supports for listings; any listing
# language not in this map falls back to the en-US release notes.
AMAZON_LANG_TO_LOCALE = {
    "en_US": "en-US", "en_GB": "en-GB", "en_AU": "en-AU", "en_IN": "en-IN",
    "de_DE": "de-DE", "fr_FR": "fr-FR", "it_IT": "it-IT", "ja_JP": "ja-JP",
    "es_ES": "es-ES", "pt_BR": "pt-BR", "zh_CN": "zh-CN",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def fail(msg: str, code: int = 1) -> "NoReturn":  # type: ignore[name-defined]
    print(f"::error::{msg}", flush=True)
    sys.exit(code)


def _request(method, url, *, token=None, data=None, content_type=None,
             etag=None, want_json=True, allow_errors=False):
    """Perform one HTTP request. Returns (status, headers, parsed_body).

    parsed_body is a dict/list when want_json and the response has a body,
    otherwise the raw bytes (possibly empty).

    When allow_errors is True, an HTTP error status is returned to the caller
    (status, headers, parsed_body) instead of aborting, so a non-fatal step
    (such as updating one listing language) can skip and carry on.
    """
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if content_type:
        headers["Content-Type"] = content_type
    if etag:
        headers["If-Match"] = etag
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read()
            status = resp.status
            resp_headers = dict(resp.headers.items())
    except urllib.error.HTTPError as e:
        body = e.read()
        detail = body.decode("utf-8", "replace")[:600] if body else ""
        # 412 Precondition Failed = the app is currently in review and cannot be
        # updated yet (per Amazon's troubleshooting docs).
        if e.code == 412 and not allow_errors:
            fail(f"{method} {url} -> 412: app is in review, cannot update yet. "
                 f"Wait until it is live, then re-run. {detail}", code=2)
        if allow_errors:
            parsed = body
            if want_json and body:
                try:
                    parsed = json.loads(body.decode("utf-8"))
                except json.JSONDecodeError:
                    parsed = body
            return e.code, dict(e.headers.items()), parsed
        fail(f"{method} {url} -> HTTP {e.code}: {detail}")
    except urllib.error.URLError as e:
        fail(f"{method} {url} -> network error: {e}")

    parsed = body
    if want_json and body:
        try:
            parsed = json.loads(body.decode("utf-8"))
        except json.JSONDecodeError:
            parsed = body
    return status, resp_headers, parsed


def get_token(client_id: str, client_secret: str) -> str:
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": "appstore::apps:readwrite",
    }).encode()
    _status, _headers, body = _request(
        "POST", AUTH_URL, data=data,
        content_type="application/x-www-form-urlencoded")
    if not isinstance(body, dict) or "access_token" not in body:
        fail(f"token response missing access_token: {body!r}")
    log("Obtained LWA access token.")
    return body["access_token"]


def app_url(app_id: str, suffix: str = "") -> str:
    return f"{BASE_URL}/{API_VERSION}/applications/{app_id}/edits{suffix}"


def get_clean_edit(token: str, app_id: str) -> str:
    """Discard any stale open Edit, then create a fresh one.

    An app may have only one open Edit at a time, so a leftover Edit (from a
    failed run, or a half-finished Developer Console session) would make
    createEdit fail. A release publisher should own the Edit lifecycle, so we
    discard whatever is open and start from a clean copy of the live version.
    Amazon explicitly recommends not mixing API and Console edits on one Edit.
    """
    _status, _headers, body = _request("GET", app_url(app_id), token=token)
    if isinstance(body, dict) and body.get("id"):
        stale_id = body["id"]
        _s, headers, _b = _request(
            "GET", app_url(app_id, f"/{stale_id}"), token=token)
        etag = headers.get("ETag")
        _request("DELETE", app_url(app_id, f"/{stale_id}"),
                 token=token, etag=etag, want_json=False)
        log(f"Discarded stale open Edit {stale_id}.")
    _status, _headers, body = _request("POST", app_url(app_id), token=token)
    if not isinstance(body, dict) or "id" not in body:
        fail(f"createEdit response missing id: {body!r}")
    log(f"Created Edit {body['id']} (copy of the live version).")
    return body["id"]


def list_apks(token: str, app_id: str, edit_id: str) -> list:
    _status, _headers, body = _request(
        "GET", app_url(app_id, f"/{edit_id}/apks"), token=token)
    return body if isinstance(body, list) else []


def replace_apk(token: str, app_id: str, edit_id: str, apk_path: str) -> None:
    """Replace the live APK in place with our new binary.

    replaceApk keeps the existing APK's device targeting and DRM / signing
    choice, only swapping the binary, so the new version covers the same devices
    as the live one and validates without a missing-DRM error. If the live
    version somehow has more than one APK resource, the first is replaced and any
    extras are removed (the single universal APK supersedes per-ABI splits). If
    there is no existing APK (a first-ever API submission), a fresh one is
    uploaded instead.
    """
    with open(apk_path, "rb") as fh:
        apk_bytes = fh.read()
    size_mb = len(apk_bytes) / (1024 * 1024)

    apks = list_apks(token, app_id, edit_id)
    if not apks:
        log(f"No existing APK in the Edit; uploading a new one ({size_mb:.1f} MB).")
        _s, _h, body = _request(
            "POST", app_url(app_id, f"/{edit_id}/apks/upload"),
            token=token, data=apk_bytes, content_type=APK_CONTENT_TYPE)
        new_id = body.get("id") if isinstance(body, dict) else None
        log(f"Uploaded APK (id {new_id}).")
        return

    primary_id = apks[0].get("id")
    _s, headers, _b = _request(
        "GET", app_url(app_id, f"/{edit_id}/apks/{primary_id}"), token=token)
    etag = headers.get("ETag")
    log(f"Replacing APK {primary_id} in place ({size_mb:.1f} MB), "
        f"preserving device targeting + DRM...")
    status, _h, body = _request(
        "PUT", app_url(app_id, f"/{edit_id}/apks/{primary_id}/replace"),
        token=token, data=apk_bytes, content_type=APK_CONTENT_TYPE,
        etag=etag, want_json=False, allow_errors=True)
    if status not in (200, 204):
        detail = body.decode("utf-8", "replace")[:400] if isinstance(body, bytes) else str(body)
        if "error_invalid_asset_id" in detail:
            fail(
                "replaceApk was rejected with error_invalid_asset_id. The live "
                "Amazon version was published from an AAB, so its APKs are "
                "Amazon-generated assets that the API cannot replace, and the "
                "API has no way to set the DRM value on a freshly uploaded APK "
                "(so a plain upload fails validation with "
                "error_apk_drm_value_missing). Bootstrap this ONCE by hand: in "
                "the Developer Console upload a universal store APK as a new "
                "version and set 'Apply DRM?' = No. After that the live version "
                "is APK-based and this automation (replaceApk) will update every "
                "future release on its own.")
        fail(f"replaceApk failed -> HTTP {status}: {detail}")
    log(f"Replaced APK {primary_id}.")

    for extra in apks[1:]:
        extra_id = extra.get("id")
        if not extra_id:
            continue
        _s, h2, _b = _request(
            "GET", app_url(app_id, f"/{edit_id}/apks/{extra_id}"), token=token)
        _request("DELETE", app_url(app_id, f"/{edit_id}/apks/{extra_id}"),
                 token=token, etag=h2.get("ETag"), want_json=False)
        log(f"Deleted extra APK {extra_id} (superseded by the universal APK).")


def _read_notes(metadata_dir: str, locale: str, version_code: str):
    """Read the release notes for a locale, or None if not found."""
    if not metadata_dir or not locale:
        return None
    changelog_dir = os.path.join(metadata_dir, locale, "changelogs")
    if not os.path.isdir(changelog_dir):
        return None
    path = None
    if version_code:
        candidate = os.path.join(changelog_dir, f"{version_code}.txt")
        if os.path.isfile(candidate):
            path = candidate
    if path is None:
        # Fall back to the highest-numbered changelog in the locale.
        numbered = []
        for f in glob.glob(os.path.join(changelog_dir, "*.txt")):
            stem = os.path.splitext(os.path.basename(f))[0]
            if re.fullmatch(r"\d+", stem):
                numbered.append((int(stem), f))
        if numbered:
            path = max(numbered)[1]
    if path is None:
        return None
    with open(path, encoding="utf-8") as fh:
        text = fh.read().strip()
    return text or None


def set_recent_changes(token: str, app_id: str, edit_id: str,
                       metadata_dir: str, version_code: str) -> None:
    """Set the "recent changes" (release notes) on every listing language.

    A new Edit copies the live listings, whose recentChanges still describe the
    PREVIOUS version, so Amazon's validate rejects the Edit with
    error_release_notes_incomplete until the new version's notes are set. Each
    language is filled from its matching translated changelog when we have one,
    otherwise from the en-US notes.
    """
    default_notes = _read_notes(metadata_dir, "en-US", version_code)

    _s, _h, raw = _request(
        "GET", app_url(app_id, f"/{edit_id}/listings"), token=token)
    listings = {}
    if isinstance(raw, dict):
        listings = raw.get("listings", raw)
    languages = list(listings.keys()) if isinstance(listings, dict) else []
    if not languages:
        languages = ["en_US"]

    set_count = 0
    for lang in languages:
        locale = AMAZON_LANG_TO_LOCALE.get(lang)
        notes = _read_notes(metadata_dir, locale, version_code) if locale else None
        if not notes:
            notes = default_notes
        if not notes:
            log(f"::warning::No release notes available for {lang}; skipping.")
            continue
        status, headers, body = _request(
            "GET", app_url(app_id, f"/{edit_id}/listings/{lang}"),
            token=token, allow_errors=True)
        if status != 200 or not isinstance(body, dict):
            log(f"::warning::Could not read listing for {lang} (HTTP {status}); skipping.")
            continue
        etag = headers.get("ETag")
        listing = dict(body)
        listing["recentChanges"] = notes
        up_status, _h2, _b2 = _request(
            "PUT", app_url(app_id, f"/{edit_id}/listings/{lang}"),
            token=token, data=json.dumps(listing).encode("utf-8"),
            content_type="application/json", etag=etag,
            want_json=False, allow_errors=True)
        if up_status not in (200, 204):
            log(f"::warning::Could not set recent changes for {lang} (HTTP {up_status}).")
            continue
        set_count += 1
        log(f"Set recent changes for {lang}.")

    if set_count == 0:
        fail("Failed to set recent changes for any listing language; "
             "Amazon would reject the Edit with error_release_notes_incomplete.")


def validate_edit(token: str, app_id: str, edit_id: str) -> None:
    _request("POST", app_url(app_id, f"/{edit_id}/validate"),
             token=token, want_json=False)
    log("Edit validated.")


def commit_edit(token: str, app_id: str, edit_id: str) -> None:
    # commit needs the Edit's current ETag.
    _s, headers, _b = _request(
        "GET", app_url(app_id, f"/{edit_id}"), token=token)
    etag = headers.get("ETag")
    _request("POST", app_url(app_id, f"/{edit_id}/commit"),
             token=token, etag=etag, want_json=False)
    log("Committed Edit. Submitted to Amazon review (publishes in a few hours).")


def main() -> None:
    client_id = os.environ.get("AMAZON_CLIENT_ID", "").strip()
    client_secret = os.environ.get("AMAZON_CLIENT_SECRET", "").strip()
    app_id = os.environ.get("AMAZON_APP_ID", "").strip()
    apk_path = os.environ.get("AMAZON_APK_PATH", "").strip()
    version_code = os.environ.get("AMAZON_VERSION_CODE", "").strip()
    metadata_dir = os.environ.get(
        "AMAZON_METADATA_DIR", "fastlane/metadata/android").strip()
    submit = os.environ.get("AMAZON_SUBMIT", "true").strip().lower() != "false"

    missing = [n for n, v in (
        ("AMAZON_CLIENT_ID", client_id),
        ("AMAZON_CLIENT_SECRET", client_secret),
        ("AMAZON_APP_ID", app_id),
        ("AMAZON_APK_PATH", apk_path),
    ) if not v]
    if missing:
        fail(f"missing required env: {', '.join(missing)}")
    if not os.path.isfile(apk_path):
        fail(f"APK not found at {apk_path}")

    token = get_token(client_id, client_secret)
    edit_id = get_clean_edit(token, app_id)
    # Replace the live APK in place (keeps device targeting + DRM), then set the
    # new version's release notes, before validating.
    replace_apk(token, app_id, edit_id, apk_path)
    set_recent_changes(token, app_id, edit_id, metadata_dir, version_code)
    validate_edit(token, app_id, edit_id)

    if submit:
        commit_edit(token, app_id, edit_id)
    else:
        log("AMAZON_SUBMIT=false: Edit prepared and validated but NOT committed. "
            "Review it in the Developer Console and commit there, or re-run with "
            "AMAZON_SUBMIT=true.")


if __name__ == "__main__":
    main()
