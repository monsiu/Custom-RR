#!/usr/bin/env python3
"""Validate Play release-note changelog files for the current versionCode.

Rules enforced:
- Read versionCode from pubspec.yaml version x.y.z+N (or --version-code).
- Every locale folder under fastlane/metadata/android must contain
  changelogs/N.txt.
- Each changelog file must:
  - be UTF-8 decodable
  - be non-empty
  - be <= 500 code points (Play limit)
  - contain bullet lines (every non-empty line starts with "- ")
  - not end with a trailing newline
  - not contain em dashes
  - not contain leaked placeholder tokens
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from typing import List, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate localized Play release-note changelogs."
    )
    parser.add_argument(
        "--pubspec",
        default="pubspec.yaml",
        help="Path to pubspec.yaml (default: pubspec.yaml)",
    )
    parser.add_argument(
        "--metadata-root",
        default="fastlane/metadata/android",
        help="Metadata locale root (default: fastlane/metadata/android)",
    )
    parser.add_argument(
        "--version-code",
        default="",
        help="Override versionCode instead of reading pubspec.yaml",
    )
    return parser.parse_args()


def read_version_code(pubspec_path: str) -> str:
    if not os.path.isfile(pubspec_path):
        raise RuntimeError(f"pubspec not found: {pubspec_path}")

    version_line = ""
    with open(pubspec_path, "r", encoding="utf-8") as handle:
        for raw in handle:
            if raw.startswith("version:"):
                version_line = raw.strip()
                break

    if not version_line:
        raise RuntimeError("version: line not found in pubspec.yaml")

    match = re.match(r"^version:\s*([^\s]+)\s*$", version_line)
    if not match:
        raise RuntimeError(f"could not parse version line: {version_line}")

    version_value = match.group(1)
    if "+" not in version_value:
        raise RuntimeError(
            f"version has no +build number: {version_value}"
        )

    version_code = version_value.split("+", 1)[1].strip()
    if not version_code.isdigit():
        raise RuntimeError(
            f"versionCode is not numeric: {version_code}"
        )
    return version_code


def find_locales(metadata_root: str) -> List[str]:
    if not os.path.isdir(metadata_root):
        raise RuntimeError(f"metadata root not found: {metadata_root}")

    locales = sorted(
        entry
        for entry in os.listdir(metadata_root)
        if os.path.isdir(os.path.join(metadata_root, entry))
    )

    if not locales:
        raise RuntimeError(f"no locale folders found under: {metadata_root}")

    return locales


def validate_changelog(path: str) -> List[str]:
    issues: List[str] = []

    if not os.path.isfile(path):
        issues.append("missing file")
        return issues

    raw = b""
    with open(path, "rb") as handle:
        raw = handle.read()

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        issues.append("not valid UTF-8")
        return issues

    if raw.endswith(b"\n"):
        issues.append("has trailing newline")

    if not text.strip():
        issues.append("is empty")

    code_points = len(text)
    if code_points > 500:
        issues.append(f"exceeds 500 chars ({code_points})")

    non_empty_lines = [line for line in text.split("\n") if line]
    if not non_empty_lines:
        issues.append("has no content lines")
    elif any(not line.startswith("- ") for line in non_empty_lines):
        issues.append("contains non-bullet content")

    if "—" in text:
        issues.append("contains em dash")

    if "ZZTERM" in text or "ЗЗТЕРМ" in text:
        issues.append("contains placeholder token")

    return issues


def main() -> int:
    args = parse_args()

    try:
        version_code = args.version_code or read_version_code(args.pubspec)
        locales = find_locales(args.metadata_root)
    except RuntimeError as exc:
        print(f"ERROR: {exc}")
        return 1

    failures: List[Tuple[str, List[str]]] = []
    for locale in locales:
        changelog_path = os.path.join(
            args.metadata_root,
            locale,
            "changelogs",
            f"{version_code}.txt",
        )
        issues = validate_changelog(changelog_path)
        if issues:
            failures.append((locale, issues))

    if failures:
        print(
            "ERROR: Play release-note validation failed "
            f"for versionCode {version_code}."
        )
        for locale, issues in failures:
            print(f"- {locale}: {', '.join(issues)}")
        print(
            "Fix the listed locale changelogs, then rerun: "
            "python3 tool/check_play_release_notes.py"
        )
        return 1

    print(
        "OK: Play release-note validation passed for "
        f"versionCode {version_code} across {len(locales)} locales."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())