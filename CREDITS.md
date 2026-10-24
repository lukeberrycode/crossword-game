# Credits

Third-party material used in this project, with its source and licence (see constraint D-7 in `docs/discovery/ip-risk-assessment.md`).

## Word list

| | |
|---|---|
| **Name** | ENABLE (Enhanced North American Benchmark LExicon), in the widely distributed `enable1.txt` form |
| **Originators** | Alan Beale (researcher and compiler) and M. Cooper |
| **File** | `data/wordlist/enable1.txt` (172,823 words, one lowercase word per line) |
| **SHA-256** | `3f16130220645692ed49c7134e24a18504c2ca55b3c012f7290e3e77c63b1a89` |
| **Downloaded from** | <https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt> on 2026-10-23 |
| **Licence** | Public domain |
| **Licence evidence** | `data/wordlist/ENABLE-README.txt`, the original ENABLE README, from <https://sources.debian.org/src/scowl/6-2/r/enable/README> |

The ENABLE README formally releases the list into the public domain and states that "Game designers may feel free to incorporate the WORD.LST into their games. Please mention the source and credit us as originators of the list." This project credits Alan Beale and M. Cooper accordingly. As the README requires, the project places no restriction on redistributing the word list.

## Offensive-word blocklist

| | |
|---|---|
| **Name** | List of Dirty, Naughty, Obscene, and Otherwise Bad Words (LDNOOBW), English list |
| **Copyright** | © 2012–2020 Shutterstock, Inc. |
| **File** | `data/wordlist/blocklist/ldnoobw-en.txt` (unchanged copy) |
| **SHA-256** | `af851ecef1d5f212caba17339b12ac39cc2fef7d78c74876f67237644fcee8bd` |
| **Downloaded from** | <https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words>, commit `5faf2ba42d7b1c0977169ec3611df25a3c08eb13`, on 2026-10-24 |
| **Licence** | Creative Commons Attribution 4.0 International (CC BY 4.0), <https://creativecommons.org/licenses/by/4.0/>; full text in `data/wordlist/blocklist/LDNOOBW-LICENSE.txt` |

**Changes made:** the list is used as a checklist, not applied whole. `data/wordlist/blocklist/decisions.tsv` records a block or allow decision for every LDNOOBW entry that appears in ENABLE, under this project's policy (slurs and strong profanity blocked; clinical, mild and dual-meaning words allowed), and adds words that LDNOOBW does not include.
