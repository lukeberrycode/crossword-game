# Board and tiles

**Approved by Luke, 24 October 2026** (requirement SCORE-7), with a bonus for 8 or more tiles and the 15 × 15 size kept. Proposed by Claude from Luke's brief (24 October 2026):

- Change the board only minimally from the classic board.
- Players hold around 14 tiles, not 7, to help avoid stalled games.
- UI consideration: the rack size could equal the length of the board's bottom edge, in squares.

## Board

**15 × 15**, so the rack holds **15 tiles** and lines up under the board as one row of the same width. The grid needs an odd size for its single centre cell, so 15 is the nearest size to "around 14" that works, and it keeps the classic dimensions.

### Layout

`W` triple word · `w` double word · `L` triple letter · `l` double letter · `.` plain. Rows top to bottom, columns left to right; the centre cell (row 8, column 8) is a double word.

```
. . . W . . l . l . . W . . .
. . w . l . . . . . l . w . .
. w . . . L . . . L . . . w .
W . . . w . l . l . w . . . W
. l . w . . . L . . . w . l .
. . L . . . . . . . . . L . .
l . . l . . . . . . . l . . l
. . . . L . . w . . L . . . .
l . . l . . . . . . . l . . l
. . L . . . . . . . . . L . .
. l . w . . . L . . . w . l .
W . . . w . l . l . w . . . W
. w . . . L . . . L . . . w .
. . w . l . . . . . l . w . .
. . . W . . l . l . . W . . .
```

### What stays the same as the classic board

- Size: 15 × 15.
- The number of each premium: 8 triple word, 17 double word (including the centre), 12 triple letter, 24 double letter.
- Symmetry: the layout looks the same after any rotation or reflection.
- The broad pattern: triple words on the edges, double words in bands running in from the corners, letter premiums spread between them.
- Spacing on the edges: the two triple words on an edge are 8 cells apart, so a 9-letter word along an edge can cover both (×9).

### What changes

Every premium square has moved. The only cell that has the same premium as on the classic board is the centre (needed by SCORE-5). Only 9 of the 61 premium cells sit on any classic premium cell at all, and those 9 have a different premium type there.

- The corners are plain. The triple words sit three cells in from each corner, on the edges.
- Double words form two bands, near each corner and in a ring further in, rather than one diagonal line.
- The centre 5 × 5 area has no letter premiums. The nearest triple letters are three cells from the centre in each direction, so a long first play can reach one.

## Tiles

**101 tiles: 98 lettered and 3 blanks.**

Counts and values are worked out from the game's own word list rather than chosen by hand, using `scripts/derive_tiles.py`:

- **Counts:** the 98 lettered tiles are shared out in proportion to how often each letter appears in ENABLE words of 2 to 15 letters, with at least one of each letter.
- **Values:** 1 for the commonest letter, rising to 10 for the rarest, on a logarithmic scale of rarity. So every halving of a letter's frequency adds roughly the same number of points.
- **Blanks:** 3 rather than the classic 2, which makes it less likely a rack has no playable word (GAME-9).

| Letter | Frequency in ENABLE | Count | Value |
|---|---|---|---|
| E | 11.54% | 11 | 1 |
| S | 9.48% | 9 | 1 |
| I | 8.90% | 9 | 2 |
| A | 7.60% | 7 | 2 |
| R | 7.10% | 7 | 2 |
| N | 6.79% | 6 | 2 |
| T | 6.61% | 6 | 2 |
| O | 6.52% | 6 | 2 |
| L | 5.32% | 5 | 3 |
| C | 4.06% | 4 | 3 |
| D | 3.46% | 3 | 4 |
| U | 3.29% | 3 | 4 |
| P | 2.92% | 3 | 4 |
| M | 2.83% | 3 | 4 |
| G | 2.75% | 3 | 4 |
| H | 2.31% | 2 | 4 |
| B | 1.87% | 2 | 5 |
| Y | 1.63% | 1 | 5 |
| F | 1.26% | 1 | 6 |
| V | 0.98% | 1 | 6 |
| K | 0.89% | 1 | 6 |
| W | 0.78% | 1 | 7 |
| Z | 0.47% | 1 | 8 |
| X | 0.30% | 1 | 9 |
| Q | 0.17% | 1 | 10 |
| J | 0.16% | 1 | 10 |
| Blank | – | 3 | 0 |

Compared with the classic set, 15 of the 26 letter counts and 21 of the 26 letter values differ. Vowels are 36 of the 98 lettered tiles (37%). The lettered tiles have a combined face value of 274 points.

### Points to check

- **S is common** (9 tiles, value 1) because ENABLE lists plurals and verb forms, which add many S's. S is also the easiest letter to add to an existing word. If that makes play too easy, the derivation could count each word's root only, or cap S by hand.
- **Values run higher** than the classic set, because the scale goes up to 10 more steeply. Scores will run higher in general. Since the game has no winner and player scores are only compared with each other, this does no harm.

## Rule changes that follow from a 15-tile rack

- **Setup and refills:** the rack holds 15 tiles, not 7. With 101 tiles that leaves 86 in the bag at the start.
- **Full-rack bonus:** using all 15 tiles in one play is almost impossible: on a 15-wide board, the play would have to fill a whole row or column. **Decided (Luke):** a 50-point bonus for playing **8 or more tiles** in one turn.

## IP check

The IP assessment's constraint D-2 originally required both the board's dimensions and its premium-square positions to be original. Luke chose to keep the classic 15 × 15 size (24 October 2026), and D-2 was amended to require original premium-square positions only. This layout meets it: only the centre cell matches the classic board.

D-3 (original values and distribution) is met: the set is derived from ENABLE by a published formula, and most counts and values differ from the classic set.
