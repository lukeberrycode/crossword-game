This is a massively multiplayer crossword building game.

Many games are in progress at any time, and players may join any game they like at any time. They may not create games however. As will become clear, only a finite number of games are possible.

Each game has a single notional player, and the people using the app log on, choose a game to load up, and control this notional player. They can make new moves on behalf of the player, or they can rewind a game to previous turns and redo the players past moves, attempting to score higher than the player originally did at that point in the game. The rules below are written from the point of view of whoever is in control for the current turn. See [Taking a turn](#taking-a-turn) for how this works.

The components of the game:
- a set of 101 letter tiles, each showing a letter in a large and central position and its score as a subscript.
- a board with a grid. The grid is square and has an odd number of cells on each side, so that it has exactly one centre cell. Some cells are premium cells, which boost the score of tiles placed on them (see [Premium cells](#premium-cells)).
- a rack, which holds the notional player's current tiles.
- a bag, which holds the tiles not yet drawn. Each game has its own fixed draw order, so the tiles always come out of the bag in the same sequence for that game.

> The board dimensions, the positions of the premium cells, and the letter values and counts of the tiles are not settled yet. Each must be an original design (see constraints D-2 and D-3 in `docs/discovery/ip-risk-assessment.md`).

# Rules

## Aim

Players take turns adding words to a shared grid, crossword fashion. Each word earns points. In a given turn, a player should aim to get the highest score for their available letters.

## Tiles

Each lettered tile shows its point value. Common letters are worth little and rare letters are worth more.

A small number of the 101 tiles are **blanks**. A blank has no letter and scores nothing. When a player puts a blank on the board, they say which letter it stands for. It keeps that letter for as long as it stays on the board.

## What a game is

A game is defined entirely by its data:

- the deterministic order in which the tiles are drawn from the bag in that game
- for every consecutive turn: the tiles played, the words they made, where they were placed on the board, what the turn scored, and the id of the player who made it.

All of this is kept in the app database. Because the draw order is fixed and every turn must be a play, the letters on the rack at any turn depend only on the draw order and the turns before it.

## Setting up

1. All 101 tiles go into the bag in the game's fixed draw order.
2. The first 15 tiles in that order are drawn onto the rack. The rack holds as many tiles as the board is wide.
3. The game is then open for its first turn.

## Taking a turn

A player takes a turn by taking control of the notional player. They may do either of these:

1. **Play the latest turn.** Go to the latest turn of the game and make a new play with the letters now on the rack.
2. **Beat an earlier turn.** Go to any previous turn of the game. This rewinds their view of the game to the state it was in at that time, with the same letters on the rack that were available then. They then try to make a play that scores *more* than the turn already recorded for that point. A play that only equals the recorded score does not count.

In both cases the player scores the points for their play.

Every turn must be a play. Passing and exchanging tiles are not allowed.

### Playing tiles

When you play tiles, every one of these must hold:

1. All the tiles you place go in a single row or a single column.
2. Together with any tiles already on the board between them, your tiles form one unbroken line with no gaps.
3. **First play:** the first word of the game must be at least two letters long and must cover the centre cell.
4. **Later plays:** at least one of your new tiles must touch a tile already on the board, either beside it or above or below it. Your play can add to an existing word, cross one, or lie next to one.
5. Every unbroken line of two or more tiles that your play creates or changes, across or down, must be an acceptable word (see [Acceptable words](#acceptable-words)).
6. Words read left to right or top to bottom only.

Once tiles are on the board they cannot be moved or swapped back. They are removed only if their turn is invalidated (see [Invalidating turns](#invalidating-turns)).

After scoring, the rack is refilled with the next tiles in the draw order until it holds 15 tiles again, or until the bag is empty.

### Invalidating turns

When a player beats an earlier turn, the turn they beat and every turn after it are invalidated. Time winds back to that point in the game:

- All tiles those turns placed on the board are removed. They return to the bag in their original positions in the draw order, so they will be drawn onto the rack again in the same order as before.
- The invalidated turns are dropped from the database, and the scores they earned are taken away from the players who made them.
- The new, higher-scoring play takes the beaten turn's place, and the game continues from there.

## Scoring

### Basic scoring

A word scores the sum of the point values of its letters, with adjustments for premium cells.

A play scores **every** word it makes or extends: the main word along the line of your tiles, plus each cross-word that a new tile forms in the other direction. A tile that belongs to two new words counts in both.

### Premium cells

There are four kinds of premium cell:

| Cell | Effect |
|---|---|
| Double letter | The tile placed on it scores twice its value. |
| Triple letter | The tile placed on it scores three times its value. |
| Double word | The whole word that covers it scores double. |
| Triple word | The whole word that covers it scores triple. |

- Letter premiums are worked out first, then word premiums.
- If one word covers two word-premium cells, both apply: two double-word cells make ×4, and two triple-word cells make ×9.
- If a new tile on a premium cell is part of two words, the premium applies to both.
- A premium counts only on the turn a tile is first placed on it. After that the cell scores like a plain cell.
- A blank on a letter-premium cell still scores nothing. A blank on a word-premium cell still multiplies the word.
- The centre cell is a double-word cell, so the first word of the game always scores double.

### Full-rack bonus

If you play 8 or more tiles in a single play, you score a **50-point bonus** on top of the score for the words.

## Acceptable words

Words are checked against a single named source: the **ENABLE** word list (Enhanced North American Benchmark Lexicon), compiled by Alan Beale and M. Cooper. ENABLE has been formally released into the public domain, and its authors invite game designers to use it, asking only that the list is credited. The list is stored at `data/wordlist/enable1.txt`, and its source and licence are recorded in `CREDITS.md`. A word is acceptable if ENABLE lists it. Even if the source lists them, these are **not** acceptable:

- words that always start with a capital letter, such as proper nouns
- abbreviations and acronyms
- words that need a hyphen or an apostrophe
- prefixes and suffixes on their own

Inflected forms such as plurals and verb tenses are acceptable when the source includes them.

The app checks every play before accepting it. A play that would make any unacceptable word is refused, and the player in control can try a different play. There are no challenges.

## Ending the game

A game is **complete** when the bag is empty and every tile on the rack has been played.

A game **stalls** if no acceptable play can be made with the letters on the rack at the latest turn. Because passing and exchanging are not allowed, a stalled game can never get past that turn.

No new turns can be added to a complete or stalled game. Players can still beat any earlier turn, which invalidates the turns after it and reopens the game from that point.

## Player scores

A game has no winner. Instead, each player has two scores across all games, which express how good they are at the game:

- **Build-up score:** the total score of every turn they have ever played, in all games, minus the scores of their turns that have since been invalidated.
- **Burn-down score:** the total score of all the turns they have invalidated, in all games.

This scoring formula may be revised later.
