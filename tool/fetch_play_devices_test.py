#!/usr/bin/env python3
"""Unit tests for the Play-catalog grouping in fetch_play_devices.build().

Guards the fix for issue #80: the codename `emerald` is reused by the Teracube
2e (brand "Mint") and the Xiaomi POCO M6 Pro 4G. Grouping purely by codename
merged both phones' model numbers, which let the catalog list a Xiaomi model
under the Teracube device. build() must keep them apart.

Usage: python3 -I tool/fetch_play_devices_test.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fetch_play_devices import build, all_models  # noqa: E402

CSV = (
    "Retail Branding,Marketing Name,Device,Model\r\n"
    # One codename, two brands: must not merge.
    "Mint,Emerald,emerald,Emerald_M55CR\r\n"
    "Mint,Emerald,emerald,Emerald_M55CRD\r\n"
    "Xiaomi,POCO M6 Pro 4G,emerald,2312FPCA6G\r\n"
    "Xiaomi,Redmi Note 13 Pro 4G,emerald,23117RA68G\r\n"
    # An ordinary single-brand codename: must keep the old flat shape.
    "Samsung,Galaxy A04e,a04e,SM-A042F\r\n"
    "Samsung,Galaxy A04e,a04e,SM-A042M\r\n"
    # The Model column sometimes repeats the marketing name: must be dropped.
    "Nothing,Phone (2),pong,Phone (2)\r\n"
    "Nothing,Phone (2),pong,A065\r\n"
)

failures = []


def check(name, cond, detail=""):
    if cond:
        print(f"ok    {name}")
    else:
        failures.append(name)
        print(f"FAIL  {name}\n      {detail}")


index = build(CSV)
emerald = index["emerald"]
a04e = index["a04e"]
pong = index["pong"]

check(
    "shared codename keeps the primary brand's models only",
    emerald["brand"] == "Mint" and set(emerald["models"]) == {"Emerald_M55CR", "Emerald_M55CRD"},
    f"got brand={emerald['brand']!r} models={emerald['models']}",
)
check(
    "the other brand lands in variants, not the primary entry",
    emerald.get("variants") == [
        {"brand": "Xiaomi", "name": "POCO M6 Pro 4G", "models": ["2312FPCA6G", "23117RA68G"]}
    ],
    f"got variants={emerald.get('variants')}",
)
check(
    "no cross-brand model leaks into the primary entry",
    "2312FPCA6G" not in emerald["models"],
    f"got models={emerald['models']}",
)
check(
    "all_models() still exposes every number for the recognition index",
    set(all_models(emerald)) == {"Emerald_M55CR", "Emerald_M55CRD", "2312FPCA6G", "23117RA68G"},
    f"got {all_models(emerald)}",
)
check(
    "an ordinary single-brand codename keeps the flat shape",
    "variants" not in a04e and set(a04e["models"]) == {"SM-A042F", "SM-A042M"},
    f"got {a04e}",
)
check(
    "a Model that repeats the marketing name is dropped",
    pong["models"] == ["A065"],
    f"got {pong['models']}",
)

print(f"\n{6 - len(failures)}/6 passed")
sys.exit(1 if failures else 0)
