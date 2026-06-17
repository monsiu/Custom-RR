#!/usr/bin/env python3
"""Upload a new Custom RR version to the Amazon Appstore via the App Submission API.

Amazon's App Submission API is APK-only (it does NOT accept AAB), so CI builds a
universal store APK (the same PLAY_BUILD store variant, just APK output) and this
script pushes it as a new version of the already-live app.

Flow (per https://developer.amazon.com/docs/app-submission-api/flows.html):
  1. Exchange the Security Profile client id/secret for an LWA access token.
  2. Get the open Edit, or create one (an Edit is a copy of the live version).
  3. Replace the binary: delete the Edit's existing APK(s), upload our APK.
  4. validateEdit, then commitEdit (= submit to Amazon review).

commitEdit submits to review; publishing then takes a few hours, exactly like
Play. Set AMAZON_SUBMIT=false to prepare + validate the Edit WITHOUT committing
(a dry run you can inspect/commit by hand in the Developer Console).

This intentionally only swaps the APK and commits. Listing copy, screenshots,
pricing, DRM and content rating are left at the live version's values (the API
cannot change DRM/rating/pricing anyway); change those in the Console when needed.

Config comes from the environment (all required unless noted):
  AMAZON_CLIENT_ID       Security Profile client id (amzn1.application-oa2-client...)
  AMAZON_CLIENT_SECRET   Security Profile client secret
  AMAZON_APP_ID          The app's App ID key (Developer Console > app > Upload App File)
  AMAZON_APK_PATH        Path to the universal store APK to upload
  AMAZON_SUBMIT          "true" (default) commits/submits; "false" prepares only

Exit codes: 0 ok (committed or prepared); 2 app is in review (try again later);
1 any other error.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

AUTH_URL = "https://api.amazon.com/auth/o2/token"
BASE_URL = "https://developer.amazon.com/api/appstore"
API_VERSION = "v1"
APK_CONTENT_TYPE = "application/vnd.android.package-archive"


def log(msg: str) -> None:
    print(msg, flush=True)


def fail(msg: str, code: int = 1) -> "NoReturn":  # type: ignore[name-defined]
    print(f"::error::{msg}", flush=True)
    sys.exit(code)


def _request(method, url, *, token=None, data=None, content_type=None,
             etag=None, want_json=True):
    """Perform one HTTP request. Returns (status, headers, parsed_body).

    parsed_body is a dict/list when want_json and the response has a body,
    otherwise the raw bytes (possibly empty).
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
        if e.code == 412:
            fail(f"{method} {url} -> 412: app is in review, cannot update yet. "
                 f"Wait until it is live, then re-run. {detail}", code=2)
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


def get_or_create_edit(token: str, app_id: str) -> str:
    # getActiveEdit: an open Edit may already exist (e.g. a prior partial run).
    status, _headers, body = _request("GET", app_url(app_id), token=token)
    if isinstance(body, dict) and body.get("id"):
        edit_id = body["id"]
        log(f"Reusing open Edit {edit_id}.")
        return edit_id
    # None open: create a fresh Edit (copies the live version's listing + APKs).
    _status, _headers, body = _request("POST", app_url(app_id), token=token)
    if not isinstance(body, dict) or "id" not in body:
        fail(f"createEdit response missing id: {body!r}")
    log(f"Created Edit {body['id']}.")
    return body["id"]


def clear_existing_apks(token: str, app_id: str, edit_id: str) -> None:
    status, _headers, body = _request(
        "GET", app_url(app_id, f"/{edit_id}/apks"), token=token)
    apks = body if isinstance(body, list) else []
    if not apks:
        log("No existing APKs in the Edit.")
        return
    for apk in apks:
        apk_id = apk.get("id")
        if apk_id is None:
            continue
        # Need the per-APK ETag for the conditional DELETE.
        _s, headers, _b = _request(
            "GET", app_url(app_id, f"/{edit_id}/apks/{apk_id}"), token=token)
        etag = headers.get("ETag")
        _request("DELETE", app_url(app_id, f"/{edit_id}/apks/{apk_id}"),
                 token=token, etag=etag, want_json=False)
        log(f"Deleted existing APK {apk_id}.")


def upload_apk(token: str, app_id: str, edit_id: str, apk_path: str) -> None:
    with open(apk_path, "rb") as fh:
        apk_bytes = fh.read()
    size_mb = len(apk_bytes) / (1024 * 1024)
    log(f"Uploading APK {apk_path} ({size_mb:.1f} MB)...")
    _status, _headers, body = _request(
        "POST", app_url(app_id, f"/{edit_id}/apks/upload"),
        token=token, data=apk_bytes, content_type=APK_CONTENT_TYPE)
    new_id = body.get("id") if isinstance(body, dict) else None
    log(f"Uploaded APK (id {new_id}).")


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
    edit_id = get_or_create_edit(token, app_id)
    clear_existing_apks(token, app_id, edit_id)
    upload_apk(token, app_id, edit_id, apk_path)
    validate_edit(token, app_id, edit_id)

    if submit:
        commit_edit(token, app_id, edit_id)
    else:
        log("AMAZON_SUBMIT=false: Edit prepared and validated but NOT committed. "
            "Review it in the Developer Console and commit there, or re-run with "
            "AMAZON_SUBMIT=true.")


if __name__ == "__main__":
    main()
