#!/usr/bin/env python3
"""Собирает словари интерфейса PWA.

Исходник переводов — tools/i18n/*.tsv: первая колонка русский текст из кода (ключ),
дальше колонки языков из заголовка. Скрипт сверяет таблицы со строками в public/js
и пишет public/i18n/<язык>.json. С флагом --check только проверяет и падает при пропусках.
"""
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JS = ROOT / "public" / "js"
TABLES = ROOT / "tools" / "i18n"
OUT = ROOT / "public" / "i18n"
SKIP = {"ui/settings/changelog-screen.js", "i18n/i18n.js"}
CYRILLIC = re.compile("[А-Яа-яЁё]")
TOKEN = re.compile(r'`(?:[^`\\]|\\.)*`|"((?:[^"\\\n]|\\.)*)"|//.*$', re.M)


def code_strings():
    found = set()
    for path in sorted(JS.rglob("*.js")):
        if str(path.relative_to(JS)) in SKIP:
            continue
        for match in TOKEN.finditer(path.read_text(encoding="utf-8")):
            text = match.group(1)
            if text is not None and CYRILLIC.search(text):
                found.add(json.loads(f'"{text}"'))
    return found


def read_tables():
    languages, rows = None, {}
    for table in sorted(TABLES.glob("*.tsv")):
        with table.open(encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)
            header = next(reader)
            if languages is None:
                languages = header[1:]
            elif header[1:] != languages:
                sys.exit(f"{table.name}: другой набор языков в заголовке")
            for line, row in enumerate(reader, start=2):
                if not row or not row[0].strip():
                    continue
                if len(row) != len(header):
                    sys.exit(f"{table.name}:{line}: ожидалось {len(header)} колонок, получено {len(row)}")
                rows[row[0]] = dict(zip(languages, row[1:]))
    return languages or [], rows


def placeholders(text):
    return sorted(re.findall(r"\{\w+\}", text))


def main():
    check_only = "--check" in sys.argv
    languages, rows = read_tables()
    source = code_strings()
    problems = [f"нет перевода: {s}" for s in sorted(source - rows.keys())]
    problems += [f"лишняя строка (нет в коде): {s}" for s in sorted(rows.keys() - source)]
    for key, translations in rows.items():
        for language, text in translations.items():
            if not text.strip():
                problems.append(f"{language}: пусто для «{key}»")
            elif placeholders(text) != placeholders(key):
                problems.append(f"{language}: подстановки не совпадают в «{key}»")
    for problem in problems:
        print(problem)
    if problems:
        sys.exit(1)
    if not check_only:
        OUT.mkdir(exist_ok=True)
        for language in languages:
            data = {key: rows[key][language] for key in sorted(rows)}
            (OUT / f"{language}.json").write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"строк: {len(rows)}, языков: {len(languages)}")


if __name__ == "__main__":
    main()
