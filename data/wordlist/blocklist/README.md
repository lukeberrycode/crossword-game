# Offensive-word blocklist

The game's word list (`../game-words.txt`) is ENABLE minus the words marked `block` in `decisions.tsv`. Build it with `python3 scripts/build_wordlist.py`; `--check` fails if it is out of date.

## Policy (Luke, 24 October 2026)

- **Blocked:** slurs (racial, ethnic, religious, homophobic, transphobic, ableist, misogynist) and strong vulgar profanity.
- **Allowed:** clinical and anatomical words, mild words, sexual words that aren't vulgar, and any word whose main meaning is innocent even if it has an offensive sense (for example, "chink" meaning a narrow gap).

## Files

| File | What it is |
|---|---|
| `ldnoobw-en.txt` | The LDNOOBW English list, unchanged, pinned to one commit (see `CREDITS.md`) |
| `LDNOOBW-LICENSE.txt` | Its licence, CC BY 4.0 |
| `decisions.tsv` | One row per reviewed word: `word`, `decision` (block or allow), `category`, `source` (ldnoobw or added), `note`, `for_review` |

## Rules for `decisions.tsv`

- Exact words only, never substrings: ENABLE has innocent words containing offensive strings (shitake, shittim, sniggers, pedagogue).
- Each inflection is its own row, decided on its own merits (e.g. "sluts" is blocked, but "faggoting", an embroidery stitch, is allowed).
- Every LDNOOBW entry that appears in ENABLE must have a row; the build fails otherwise. So when either list is updated, the build shows what needs a decision.
- Rows marked `for_review` are judgement calls waiting for Luke's decision. All current rows were approved by Luke on 24 October 2026.
