#!/usr/bin/env python3
"""Downloads the Quran (Uthmani text + Saheeh International) for the web preview.

Writes a compact JSON file the demo app loads at runtime:
  {"source": ..., "surahs": [{id, name_ar, name_en, transliteration, revelation_place, ayah_count}],
   "ayahs": [[surah, number, text_uthmani, translation, page, juz], ...]}   # index + 1 = global ayah id

Usage: python3 tools/fetch_demo_quran.py app/web/demo-data/quran.json
Source: api.alquran.cloud (Tanzil Uthmani text, Saheeh International translation).
"""
import json
import os
import re
import sys
import urllib.request

API = "https://api.alquran.cloud/v1/quran/"


def get(edition):
    req = urllib.request.Request(API + edition, headers={"User-Agent": "muslim-ai-web-preview-build"})
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.load(r)
    if data.get("code") != 200:
        raise SystemExit(f"{edition}: unexpected response code {data.get('code')}")
    return data["data"]["surahs"]


DIACRITICS = re.compile("[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")


def plain(s):
    """Arabic letters only: no harakat, Quranic marks or tatweel; alef wasla -> alef."""
    return DIACRITICS.sub("", s).replace("\u0671", "\u0627")


def strip_basmala(text):
    """The Tanzil text prefixes ayah 1 of each surah (except 1 and 9) with the basmala;
    the app's database stores it separately, so drop it here too. Compared without
    diacritics because some surahs spell it with a shadda (e.g. 95, 97)."""
    words = text.split()
    if len(words) > 4 and plain(words[0]) == "بسم" and plain(words[3]) == "الرحيم":
        return " ".join(words[4:])
    return text


def main(out):
    ar = get("quran-uthmani")
    en = get("en.sahih")
    surahs, ayahs = [], []
    for s, t in zip(ar, en):
        assert s["number"] == t["number"] and len(s["ayahs"]) == len(t["ayahs"])
        # "سُورَةُ ٱلْفَاتِحَةِ" -> "الفاتحة" (the API name carries the genitive case ending)
        name = plain(s["name"]).replace("سورة ", "").strip()
        surahs.append({
            "id": s["number"],
            "name_ar": name,
            "name_en": s["englishNameTranslation"],
            "transliteration": s["englishName"],
            "revelation_place": "madinah" if s["revelationType"] == "Medinan" else "makkah",
            "ayah_count": len(s["ayahs"]),
        })
        for a, b in zip(s["ayahs"], t["ayahs"]):
            text = a["text"].lstrip("\ufeff")
            if a["numberInSurah"] == 1 and s["number"] not in (1, 9):
                text = strip_basmala(text)
            ayahs.append([s["number"], a["numberInSurah"], text, b["text"], a["page"], a["juz"]])
    leftover = [a[0] for a in ayahs if a[1] == 1 and a[0] > 1 and plain(a[2]).startswith("بسم الله الرحمن")]
    if leftover:
        raise SystemExit(f"basmala not stripped in surahs {leftover}")
    if len(surahs) != 114 or len(ayahs) != 6236:
        raise SystemExit(f"unexpected counts: {len(surahs)} surahs, {len(ayahs)} ayahs")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"source": "api.alquran.cloud quran-uthmani + en.sahih", "surahs": surahs, "ayahs": ayahs},
                  f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {out}: {len(surahs)} surahs, {len(ayahs)} ayahs, {os.path.getsize(out) // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "app/web/demo-data/quran.json")
