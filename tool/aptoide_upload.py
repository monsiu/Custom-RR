#!/usr/bin/env python3
"""Submit a new Custom RR version to Aptoide via the Aptoide Connect Uploader API.

Aptoide Connect's submission API is a single multipart/form-data POST with an
Api-Key header (no OAuth, no edit lifecycle) - much simpler than Amazon:

    POST https://uploader.catappult.io/api
    Header: Api-Key: <key>
    Body (multipart): apk=<file>, releaseMode=..., requiresDeveloperApproval=...

A 200 means the version was accepted and is pending Aptoide admin approval; any
non-200 means nothing was queued.

We upload the universal store APK (the same PLAY_BUILD store variant the Amazon
job builds). releaseMode=IMMEDIATE (default) publishes automatically once Aptoide
approves; requiresDeveloperApproval=false sends it straight to review.

Config from the environment:
  APTOIDE_API_KEY    Aptoide Connect API key (Developer-type account). Required.
  APTOIDE_APK_PATH   Path to the universal store APK to upload. Required.
  APTOIDE_RELEASE_MODE          IMMEDIATE (default) | MANUAL | SCHEDULED
  APTOIDE_REQUIRES_DEV_APPROVAL "false" (default) | "true" (hold in console first)

Exit codes: 0 ok (queued for review); 2 a known "expected" conflict that is not a
hard failure for CI (duplicate APK, or version not higher than an existing one);
1 any other error.
"""

from __future__ import annotations

import os
import sys
import uuid

import urllib.error
import urllib.request

ENDPOINT = "https://uploader.catappult.io/api"

# Aptoide error codes that mean "this exact binary/version was already taken",
# i.e. re-running against an already-submitted version. Treated as a soft skip
# (exit 2) so a re-trigger on an unchanged release does not hard-fail the run.
SOFT_CONFLICT_CODES = {
    "APK-ALREADY-EXISTS",
    "APK-VERCODE-LOWER-THAN-MARKET",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def fail(msg: str, code: int = 1) -> "NoReturn":  # type: ignore[name-defined]
    print(f"::error::{msg}", flush=True)
    sys.exit(code)


def build_multipart(fields: dict[str, str], apk_path: str) -> tuple[bytes, str]:
    """Build a multipart/form-data body: simple text fields + the APK file part."""
    boundary = f"----customrr{uuid.uuid4().hex}"
    crlf = b"\r\n"
    parts: list[bytes] = []

    for name, value in fields.items():
        parts.append(b"--" + boundary.encode())
        parts.append(
            f'Content-Disposition: form-data; name="{name}"'.encode())
        parts.append(b"")
        parts.append(str(value).encode())

    with open(apk_path, "rb") as fh:
        apk_bytes = fh.read()
    filename = os.path.basename(apk_path)
    parts.append(b"--" + boundary.encode())
    parts.append(
        f'Content-Disposition: form-data; name="apk"; filename="{filename}"'
        .encode())
    parts.append(b"Content-Type: application/vnd.android.package-archive")
    parts.append(b"")
    parts.append(apk_bytes)

    parts.append(b"--" + boundary.encode() + b"--")
    parts.append(b"")

    body = crlf.join(parts)
    content_type = f"multipart/form-data; boundary={boundary}"
    return body, content_type


def parse_error_code(body: str) -> str:
    """Best-effort pull of Aptoide's error code/message from a JSON-ish body."""
    import json
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        return ""
    if isinstance(data, dict):
        for key in ("code", "error", "errorCode", "status"):
            val = data.get(key)
            if isinstance(val, str):
                return val
        errors = data.get("errors")
        if isinstance(errors, list) and errors:
            first = errors[0]
            if isinstance(first, dict):
                return str(first.get("code") or first.get("errorCode") or "")
    return ""


def main() -> None:
    api_key = os.environ.get("APTOIDE_API_KEY", "").strip()
    apk_path = os.environ.get("APTOIDE_APK_PATH", "").strip()
    release_mode = os.environ.get("APTOIDE_RELEASE_MODE", "IMMEDIATE").strip() or "IMMEDIATE"
    requires_approval = os.environ.get(
        "APTOIDE_REQUIRES_DEV_APPROVAL", "false").strip().lower()

    missing = [n for n, v in (
        ("APTOIDE_API_KEY", api_key),
        ("APTOIDE_APK_PATH", apk_path),
    ) if not v]
    if missing:
        fail(f"missing required env: {', '.join(missing)}")
    if not os.path.isfile(apk_path):
        fail(f"APK not found at {apk_path}")

    fields = {
        "releaseMode": release_mode,
        "requiresDeveloperApproval": "true" if requires_approval == "true" else "false",
    }
    body, content_type = build_multipart(fields, apk_path)
    size_mb = len(body) / (1024 * 1024)
    log(f"Submitting {os.path.basename(apk_path)} to Aptoide "
        f"(releaseMode={release_mode}, ~{size_mb:.1f} MB)...")

    req = urllib.request.Request(
        ENDPOINT, data=body, method="POST",
        headers={"Api-Key": api_key, "Content-Type": content_type})
    try:
        with urllib.request.urlopen(req) as resp:
            status = resp.status
            resp_body = resp.read().decode("utf-8", "replace")
        log(f"HTTP {status}: {resp_body[:500]}")
        log("Submitted to Aptoide. Pending Aptoide admin approval; "
            "publishes per the release mode once approved.")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace") if e.fp else ""
        code = parse_error_code(detail)
        if code in SOFT_CONFLICT_CODES:
            log(f"Aptoide returned {code} (HTTP {e.code}): {detail[:300]}")
            fail(f"Nothing to submit: {code} (this version/APK is already on "
                 f"Aptoide or not higher than the live one). Bump the version "
                 f"and retry.", code=2)
        fail(f"Aptoide submission failed: HTTP {e.code} {code} {detail[:500]}")
    except urllib.error.URLError as e:
        fail(f"Aptoide submission failed: network error: {e}")


if __name__ == "__main__":
    main()
