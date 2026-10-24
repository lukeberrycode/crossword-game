# Acceptance scenarios

These scenarios replace the method's characterisation tests: with no old app to act as the test oracle, the requirements themselves are the oracle. They are written in Gherkin (Given/When/Then) at the API boundary, without naming endpoints or technologies, so they can become the shared contract tests that **both** the Java and the .NET server must pass. Which tool runs them is decided in Planning.

Each scenario is tagged with the requirements it tests (e.g. `@PLAY-7`). `@pending` marks a scenario that can't be completed until a Planning decision (for example, the shuffle algorithm's test vectors).

The word-list script requirements (WORD-2, WORD-4, WORD-7) are already executable: `python3 -m unittest discover tests`.

## Conventions

- **Cells** are named by column letter A–O (left to right) and row number 1–15 (top to bottom). The centre is H8.
- **A play** is written as a word, a starting cell and a direction, e.g. `"CAT" across from G8`. Letters already on the board are part of the word but are not placed again.
- **Blanks** are `?` in a draw order. In a play, a blank is written in lowercase, e.g. `"cATS"` means the C is a blank standing for C.
- **Turns** are numbered from 1. A play names the turn it is for.
- **Versions:** each game has a history version, starting at 0 and going up by 1 whenever its history changes (a play is added or a turn is beaten). A play names the version it was made against. When a scenario doesn't state a version, the play is made against the current one.
- **Test builds** (TEST-1) can start a game from any sequence of tiles and use a given word list. Scenarios use short draw orders and tiny word lists so that the tiles and words they need are certain.
- **Letter values and premium cells** are those in `docs/discovery/board-and-tiles.md`. Expected scores were checked against an independent reference calculation.

## Traceability

| Requirement | Scenarios or tests |
|---|---|
| GAME-1 to GAME-6, GAME-8, GAME-9 | `features/games.feature` (GAME-2 and GAME-3 pending the shuffle's test vectors) |
| GAME-2, GAME-7, GAME-10 | Also cross-server and property-based tests (Planning) |
| PLAY-1, PLAY-2, PLAY-3, PLAY-4, PLAY-5, PLAY-9, PLAY-12 | `features/placement.feature` |
| PLAY-6, PLAY-7, PLAY-8, PLAY-10 | `features/turns.feature` |
| PLAY-11 | Property-based and load tests (Planning) |
| BEAT-1 to BEAT-6 | `features/beating.feature` |
| SCORE-1 to SCORE-5 | `features/scoring.feature` |
| SCORE-6 | Cross-server and property-based tests (Planning) |
| SCORE-7 | Review: `docs/discovery/board-and-tiles.md` (approved) |
| PSCORE-1 to PSCORE-3, LB-1 to LB-4 | `features/player-scores.feature` |
| PSCORE-4 | Property-based and load tests (Planning) |
| FIND-1 to FIND-4 | `features/finding.feature` |
| VIS-1 to VIS-3 | `features/visitors.feature` |
| AUTH-1 to AUTH-4, AUTH-6, AUTH-7 | `features/accounts.feature` |
| AUTH-5 | Review against OWASP guidance (Planning) |
| WORD-1 | `features/word-list.feature` |
| WORD-2, WORD-4, WORD-7 | `tests/wordlist/test_build_wordlist.py` (executable now) |
| WORD-3, WORD-6 | Review: `CREDITS.md`, `data/wordlist/blocklist/` (approved) |
| WORD-5 | Cross-server test (Planning) |
| OPS-1 to OPS-4 | `features/operator.feature` |
| TEST-1, TEST-2 | `features/games.feature` |
| NFR-1, NFR-7 | Load tests (Planning) |
| NFR-2, NFR-3 | Browser and accessibility tests (Planning) |
| NFR-4 | Every scenario here, run against both servers; browser tests against each |
| NFR-5, NFR-6 | Review |
