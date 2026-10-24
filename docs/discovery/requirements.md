# Requirements

Drawn from the rules (root `README.md`) and the interview with Luke on 23 October 2026. Every requirement is tested at the API boundary or the UI, so the same tests run against both the Java and .NET servers.

**Test methods**

| Code | Method |
|---|---|
| AT | Acceptance test: an executable Given/When/Then scenario against the HTTP API, shared by both servers |
| PBT | Property-based test at the API boundary (many generated inputs, one rule that must always hold) |
| X | Cross-server check: the same requests sent to both servers must give identical responses |
| UI | Browser test (e.g. Playwright) against the front end |
| A11Y | Automated accessibility scan plus a manual keyboard and screen-reader check |
| LOAD | Load test against a deployed environment |
| REV | Review against a checklist, by a person |

**Status:** signed off by Luke at the first gate (24 October 2026). None dropped.

## Games and draw orders (G1–G4; risk 2)

| ID | Requirement | Test |
|---|---|---|
| GAME-1 | A game is identified by a number from 0 to 2^64 − 1. Any number in that range is a valid game; opening one for the first time shows it unplayed (G1) | AT |
| GAME-2 | The draw order is computed from the game number by a pseudo-random generator and shuffle algorithm that the API specification defines exactly | AT, X |
| GAME-3 | For a given game number, both servers always produce the same draw order. Published test vectors (game number → draw order) are part of the specification | AT (vectors), X |
| GAME-4 | Players can't create games, or choose or change a draw order | AT |
| GAME-5 | Setup: the rack holds the first 15 tiles of the draw order. The rack size equals the board's width (15) | AT |
| GAME-6 | A game's record holds its number and, for each turn: the tiles played and their positions, the letter each blank stands for, the words made, the score, the player, and the time | AT |
| GAME-7 | The rack at any turn is fully determined by the game number and the turns before it | PBT |
| GAME-8 | A game is complete (G3) when the bag is empty and the rack has been played out. No turn can be added after that | AT |
| GAME-9 | After every change to the latest turn (setup, a play, or a beaten turn), the server checks whether any acceptable play exists for the latest rack, using blanks as any letter. If none does, the game is stalled (G4): no turn can be added after that, though earlier turns can still be beaten (BEAT-4) | AT (racks with and without a play), X |
| GAME-10 | The stall check is exhaustive (it never marks a game stalled that has a play) and both servers agree on it | PBT, X |

## Making a play (P2, P4, P5; risk 1 and 3)

| ID | Requirement | Test |
|---|---|---|
| PLAY-1 | Every play names the game, the turn number it is for, and the version of the game's history it was made against | AT |
| PLAY-2 | Placement rules: one row or column; one unbroken line including existing tiles; the first play covers the centre and is at least two letters long; later plays touch an existing tile; tiles only from the rack; no cell covered twice | AT (one scenario per rule, valid and invalid) |
| PLAY-3 | Every word of two or more letters that the play makes or changes, across or down, must be in the game's word list (WORD-1). The refusal names the unacceptable words | AT |
| PLAY-4 | A blank must be given a letter when played. It keeps that letter while it stays on the board | AT |
| PLAY-5 | Every turn must be a play: there is no passing, exchanging or challenging | AT |
| PLAY-6 | **If the turn is the next unplayed turn**, a valid play is added to the game | AT |
| PLAY-7 | **If the turn has already been played**, the play must also score strictly more than the recorded play for that turn (BEAT-1). This also covers two players playing the same next turn at once: the later one counts as an attempt to beat the earlier | AT, PBT |
| PLAY-8 | **If the history before the named turn has changed** since the version the play was made against (because an earlier turn was beaten), the play is refused, with the current state of the game, so the player can try again | AT |
| PLAY-9 | A refusal says which rule failed (placement, words, score not higher, or game changed), and doesn't change the game or anyone's scores | AT |
| PLAY-10 | After an accepted play, the rack is refilled from the draw order up to 15 tiles, or until the bag is empty | AT |
| PLAY-11 | Plays on the same game are serialised: however many arrive at once, the result is the same as if they had been handled one after another in the order they were accepted | PBT, LOAD |
| PLAY-12 | Only signed-in, unsuspended players can make plays | AT |

## Beating an earlier turn (P3, P4; risk 1)

| ID | Requirement | Test |
|---|---|---|
| BEAT-1 | Any signed-in player can try to beat any played turn of any game, including their own turns, using the rack as it was at that turn | AT |
| BEAT-2 | To beat a turn, a play must score strictly more than the recorded play. An equal score doesn't | AT |
| BEAT-3 | Beating turn N invalidates turn N and every turn after it. Their tiles return to the bag in their original positions in the draw order, so they are drawn again in the same order | AT, PBT |
| BEAT-4 | The new play becomes turn N, and the game continues from there. A complete or stalled game becomes open again | AT |
| BEAT-5 | Invalidated turns are removed from the game's history | AT |
| BEAT-6 | Players whose turns were invalidated get an alert in "My games" (FIND-3) | AT, UI |

## Scoring (risk 3)

| ID | Requirement | Test |
|---|---|---|
| SCORE-1 | A play scores every word it makes or extends; a word scores the sum of its letter values | AT |
| SCORE-2 | Premium cells: double and triple letter; double and triple word. Letter premiums are applied first, then word premiums. Several word premiums under one word multiply. A premium under a new tile applies to every word containing that tile. Premiums count only on the turn a tile is placed | AT (one scenario each) |
| SCORE-3 | A blank scores 0, including on a letter premium. A blank on a word premium still multiplies the word | AT |
| SCORE-4 | Playing 8 or more tiles in one play adds 50 points | AT |
| SCORE-5 | The centre cell is a double-word cell | AT |
| SCORE-6 | Both servers give the same score for the same play | X, PBT |
| SCORE-7 | Board layout, letter values and tile counts are an original design (IP constraints D-2, D-3). Defined in `board-and-tiles.md` (approved by Luke, 24 October 2026): a 15 × 15 board and 101 tiles derived from ENABLE by `scripts/derive_tiles.py` | REV |

## Player scores and leaderboards (V5; risk 1)

| ID | Requirement | Test |
|---|---|---|
| PSCORE-1 | A player's build-up score is the total score of their turns that are still in a game's history | AT, PBT |
| PSCORE-2 | A player's burn-down score is the total score of every turn they have invalidated by beating a turn (the beaten turn and all the turns after it), whoever made those turns | AT, PBT |
| PSCORE-3 | Beating your own turn takes its points out of your build-up score and adds them to your burn-down score | AT |
| PSCORE-4 | Scores are updated in the same operation as the play that changes them; there's never a moment when a game and the scores disagree | PBT, LOAD |
| LB-1 | A global leaderboard ranks players by build-up score | AT, UI |
| LB-2 | A global leaderboard ranks players by burn-down score | AT, UI |
| LB-3 | A per-game leaderboard ranks the players with surviving turns in that game by their points in it | AT, UI |
| LB-4 | Each player has a public profile: display name, both scores, the games they've played in, and their surviving plays | AT, UI |

## Finding games (V1, P1)

| ID | Requirement | Test |
|---|---|---|
| FIND-1 | A random-game button opens a random game number | AT, UI |
| FIND-2 | An active-games list shows games with recent plays, most recent first | AT, UI |
| FIND-3 | A signed-in player's "My games" lists games they have made plays in, flagging those where one of their turns has been invalidated since they last looked, with an unread count. Alerts are in the app only: no email | AT, UI |
| FIND-4 | Any game can be viewed at any turn of its history, by anyone, including the recorded plays, positions, scores and players | AT, UI |

## Visitors (V1–V5)

| ID | Requirement | Test |
|---|---|---|
| VIS-1 | Visitors can do everything in FIND-1, FIND-2, FIND-4 and LB-1 to LB-4 without signing in | AT |
| VIS-2 | Visitors can try a play at any turn and see whether it's valid and what it would score. Nothing is saved, and no score is credited | AT |
| VIS-3 | Signed-in players can try plays in the same way before submitting them | AT |

## Sign-in and accounts (V6, P6, P7; risk 4)

| ID | Requirement | Test |
|---|---|---|
| AUTH-1 | Players sign in with GitHub or Google (OAuth 2.0 / OpenID Connect). The game stores no passwords | AT (mock provider), REV |
| AUTH-2 | On first sign-in the player chooses a display name, which must be unique. Their name from GitHub or Google is never shown publicly | AT |
| AUTH-6 | Players can change their display name, subject to the same uniqueness rule | AT |
| AUTH-3 | Players can sign out | AT, UI |
| AUTH-4 | A suspended player can browse and try plays but not make plays | AT |
| AUTH-5 | Sessions and tokens follow current OWASP guidance (secure cookies, CSRF protection or token-based API, expiry) | REV |
| AUTH-7 | A player can delete their account. Their turns stay in game histories, credited to "deleted player", so no game changes. Their account, display name and sign-in link are removed, and they leave the leaderboards | AT |

## Word list (risk 3)

| ID | Requirement | Test |
|---|---|---|
| WORD-1 | The game's word list is `data/wordlist/game-words.txt`: ENABLE (`data/wordlist/enable1.txt`) minus the words blocked in `data/wordlist/blocklist/decisions.tsv` | AT |
| WORD-2 | The filtered list is produced by a repeatable script (`scripts/build_wordlist.py`), re-run whenever ENABLE or the blocklist is updated; CI runs it with `--check`. The original ENABLE and LDNOOBW files are kept unchanged. The script fails if any LDNOOBW entry in ENABLE has no decision | AT (script test), REV |
| WORD-3 | The blocklist is the English list from LDNOOBW ("List of Dirty, Naughty, Obscene, and Otherwise Bad Words", CC BY 4.0), plus the project's own additions. Its source, licence and attribution are recorded in `CREDITS.md` | REV |
| WORD-6 | Policy (Luke, 24 October 2026): block slurs and strong profanity; allow clinical, mild and non-vulgar sexual words, and words whose main meaning is innocent. LDNOOBW is a checklist, not applied whole. Claude drafted the decisions, including additions LDNOOBW misses; Luke approved them on 24 October 2026 | REV |
| WORD-7 | Blocking is by exact word, never by substring, and each inflection is decided separately | AT (script test) |
| WORD-4 | The exclusions in the rules (proper nouns, abbreviations, hyphenated words, lone prefixes and suffixes) are already met by ENABLE; this is checked once by script | AT (script test) |
| WORD-5 | Both servers use the identical filtered list | X |

## Operator (O1–O4)

| ID | Requirement | Test |
|---|---|---|
| OPS-1 | The operator can see health, error rates, request load and activity (plays per minute, active games) | REV, AT (health endpoint) |
| OPS-2 | The operator can suspend and reinstate a player | AT |
| OPS-3 | Rate limits apply per player and per visitor (by IP) to plays, tried plays and other requests. The operator can change them without a redeploy | AT (controlled clock) |
| OPS-4 | Operator functions require an operator account | AT |

## Non-functional

| ID | Requirement | Test |
|---|---|---|
| NFR-1 | Scale target: 500 concurrent players and 50 plays a second, with 95% of plays answered in under 300 ms, on low-cost hosting. Proposed figures for the gate | LOAD |
| NFR-2 | The front end works on desktop and mobile browsers | UI (desktop and mobile viewports) |
| NFR-3 | The front end meets WCAG 2.2 AA, including making plays by keyboard alone | A11Y |
| NFR-4 | One API contract (e.g. OpenAPI), shared by both servers. The front end works unchanged against either | X, UI (run against each server) |
| NFR-5 | The repository is public, and meets the IP assessment's checklist before each release | REV |
| NFR-6 | Each requirement is traced to its tests and to the code that meets it | REV |
| NFR-7 | The stall check (GAME-9) fits within NFR-1's response time for plays | LOAD |

## Testability

| ID | Requirement | Test |
|---|---|---|
| TEST-1 | Test builds of both servers can start a game from any sequence of tiles (not necessarily the full 101-tile set) and use a given word list | AT |
| TEST-2 | These hooks don't exist in production builds | AT (against a production build) |

## Mocking and test tools

| Need | Tool (chosen in Planning) | Used by |
|---|---|---|
| OAuth providers | A mock OpenID Connect server that both stacks can sign in against | AUTH-1, AUTH-2 and every test of a signed-in player |
| Known racks and boards | Test builds only: start a game from an explicit draw order (TEST-1) | PLAY, BEAT, SCORE |
| Small word list | Test builds only: a tiny test word list, so scenarios don't depend on ENABLE's contents (TEST-1) | PLAY-3, SCORE |
| Time | A controllable clock | OPS-3, FIND-2, FIND-3 |
| Concurrency | A test harness that sends many plays to one game at once | PLAY-7, PLAY-11, PSCORE-4 |

## Still to do before the gate

- **Acceptance tests:** written (`acceptance/`, 83 scenarios, traced by tag), apart from the shuffle's test vectors, which wait for Planning. The word-list script tests are executable now (`tests/wordlist/`).
- **Luke's sign-off:** given, 24 October 2026.
