"""Derive tile counts and letter values from letter frequencies in a word list.

Usage: python3 scripts/derive_tiles.py data/wordlist/enable1.txt

Counts: the 98 lettered tiles are shared out in proportion to each letter's
frequency in playable words (2 to 15 letters), by largest remainder, with at
least one tile per letter. Values: 1 for the commonest letter up to 10 for the
rarest, on a logarithmic scale of rarity.
"""
import math
import sys
from collections import Counter

TILES = 101
BLANKS = 3
LETTERS = "abcdefghijklmnopqrstuvwxyz"


def letter_frequencies(path):
    counts = Counter()
    with open(path) as f:
        for line in f:
            word = line.strip()
            if 2 <= len(word) <= 15:
                counts.update(word)
    total = sum(counts.values())
    return {c: counts[c] / total for c in LETTERS}


def tile_counts(freq, lettered):
    raw = {c: freq[c] * lettered for c in LETTERS}
    counts = {c: max(1, math.floor(raw[c])) for c in LETTERS}
    while sum(counts.values()) < lettered:
        c = max(LETTERS, key=lambda c: raw[c] - counts[c])
        counts[c] += 1
    while sum(counts.values()) > lettered:
        c = min((c for c in LETTERS if counts[c] > 1), key=lambda c: raw[c] - counts[c])
        counts[c] -= 1
    return counts


def letter_values(freq):
    most, least = max(freq.values()), min(freq.values())
    return {c: 1 + round(9 * math.log(most / freq[c]) / math.log(most / least)) for c in LETTERS}


def main(path):
    freq = letter_frequencies(path)
    counts = tile_counts(freq, TILES - BLANKS)
    values = letter_values(freq)
    print("letter,frequency_percent,count,value")
    for c in sorted(LETTERS, key=lambda c: -freq[c]):
        print(f"{c.upper()},{100 * freq[c]:.2f},{counts[c]},{values[c]}")
    print(f"blank,,{BLANKS},0")


if __name__ == "__main__":
    main(sys.argv[1])
