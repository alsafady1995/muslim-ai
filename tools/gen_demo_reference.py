#!/usr/bin/env python3
"""Generates app/assets/demo/reference.json from the reference-data migration.

The web preview (DEMO_MODE) has no database, so it reads the same achievements,
reciters, adhkar categories, adhkar, XP rules and plan limits from this file.
Run after editing supabase/migrations/*_reference_data.sql:

    python3 tools/gen_demo_reference.py
"""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL = sorted(glob.glob(os.path.join(ROOT, "supabase/migrations/*_reference_data.sql")))[0]
OUT = os.path.join(ROOT, "app/assets/demo/reference.json")

TABLES = ["xp_rules", "plan_limits", "achievements", "reciters", "adhkar_categories", "adhkar"]


def tokenize_values(body: str):
    """Yields rows (lists of python values) from a SQL VALUES list."""
    i, n = 0, len(body)
    row, rows, depth = None, [], 0
    while i < n:
        c = body[i]
        if c == "-" and body.startswith("--", i):
            i = body.index("\n", i) if "\n" in body[i:] else n
            continue
        if c == "(":
            depth += 1
            row = []
            i += 1
            continue
        if c == ")":
            depth -= 1
            rows.append(row)
            row = None
            i += 1
            continue
        if c == "'":
            j, buf = i + 1, []
            while True:
                if body[j] == "'" and j + 1 < n and body[j + 1] == "'":
                    buf.append("'")
                    j += 2
                elif body[j] == "'":
                    break
                else:
                    buf.append(body[j])
                    j += 1
            row.append("".join(buf))
            i = j + 1
            continue
        if row is not None and (c.isalnum() or c in "-."):
            m = re.match(r"[A-Za-z0-9_.\-]+", body[i:])
            tok = m.group(0)
            if tok in ("true", "false"):
                row.append(tok == "true")
            elif tok == "null":
                row.append(None)
            elif re.fullmatch(r"-?\d+", tok):
                row.append(int(tok))
            elif re.fullmatch(r"-?\d+\.\d+", tok):
                row.append(float(tok))
            else:
                row.append(tok)
            i += len(tok)
            continue
        i += 1
    return rows


def main():
    sql = open(SQL, encoding="utf-8").read()
    out = {}
    for table in TABLES:
        m = re.search(
            r"insert into public\.%s \(([^)]*)\) values(.*?)\non conflict" % table, sql, re.S
        )
        if not m:
            raise SystemExit(f"table {table} not found in {SQL}")
        cols = [c.strip() for c in m.group(1).split(",")]
        rows = tokenize_values(m.group(2))
        for r in rows:
            if len(r) != len(cols):
                raise SystemExit(f"{table}: row has {len(r)} values, expected {len(cols)}: {r[:2]}")
        out[table] = [dict(zip(cols, r)) for r in rows]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print({k: len(v) for k, v in out.items()})


if __name__ == "__main__":
    main()
