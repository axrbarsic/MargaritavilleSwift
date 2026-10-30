"""Собирает журнал сборок iOS-приложения (App/BuildChangelogEntries*.swift) в JSON для PWA."""
import json, re, sys, pathlib

root = pathlib.Path(__file__).resolve().parents[3] / "MargaritavilleSwift" / "App"
order = ["Recent", "Mid", "Archive", "Legacy"]
entries = []
pattern = re.compile(r'BuildChangelogEntry\(\s*version:\s*"([^"]*)",\s*date:\s*"([^"]*)",\s*changes:\s*\[(.*?)\]\s*\)', re.S)
for name in order:
    text = (root / f"BuildChangelogEntries{name}.swift").read_text()
    for version, date, body in pattern.findall(text):
        changes = [json.loads('"' + c + '"') for c in re.findall(r'"((?:[^"\\]|\\.)*)"', body)]
        entries.append({"version": version, "date": date, "changes": changes})
out = pathlib.Path(__file__).resolve().parents[1] / "public" / "data" / "ios-changelog.json"
out.write_text(json.dumps(entries, ensure_ascii=False, indent=0))
print(len(entries), "записей →", out)
