"""Build the game's word list: ENABLE minus the words blocked in decisions.tsv.

Usage:
  python3 scripts/build_wordlist.py          write data/wordlist/game-words.txt
  python3 scripts/build_wordlist.py --check  fail if game-words.txt is out of date

Fails if any LDNOOBW entry that appears in ENABLE has no decision, so an update
to either list can't slip through without review (requirement WORD-2).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORDLIST = ROOT / "data" / "wordlist"
ENABLE = WORDLIST / "enable1.txt"
LDNOOBW = WORDLIST / "blocklist" / "ldnoobw-en.txt"
DECISIONS = WORDLIST / "blocklist" / "decisions.tsv"
OUTPUT = WORDLIST / "game-words.txt"


def read_words(path):
    with open(path, encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


def read_decisions(path):
    with open(path, encoding="utf-8") as f:
        header = f.readline().rstrip("\n").split("\t")
        rows = [dict(zip(header, line.rstrip("\n").split("\t"))) for line in f if line.strip()]
    return {row["word"]: row["decision"] for row in rows}


def build():
    enable = read_words(ENABLE)
    enable_set = set(enable)
    decisions = read_decisions(DECISIONS)
    errors = []
    for word, decision in decisions.items():
        if decision not in ("block", "allow"):
            errors.append(f"{word}: unknown decision {decision!r}")
        if word not in enable_set:
            errors.append(f"{word}: has a decision but is not in ENABLE")
    for entry in read_words(LDNOOBW):
        if entry in enable_set and entry not in decisions:
            errors.append(f"{entry}: in LDNOOBW and ENABLE but has no decision")
    if errors:
        sys.exit("\n".join(errors))
    blocked = {w for w, d in decisions.items() if d == "block"}
    return [w for w in enable if w not in blocked]


def main():
    words = build()
    text = "\n".join(words) + "\n"
    if "--check" in sys.argv:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != text:
            sys.exit(f"{OUTPUT.relative_to(ROOT)} is out of date: run scripts/build_wordlist.py")
        print(f"{OUTPUT.relative_to(ROOT)} is up to date ({len(words)} words)")
        return
    OUTPUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(words)} words)")


if __name__ == "__main__":
    main()
