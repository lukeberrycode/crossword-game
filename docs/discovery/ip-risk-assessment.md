# Intellectual Property Risk Assessment

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-10-12 |
| **Scope** | Game name, rules, board, tiles, visual design, word list, documentation |
| **Review trigger** | Any change of project purpose (e.g. commercial release), or new branding/asset work |

> This document records a design-time assessment made for a non-commercial portfolio project. It is not legal advice.

## 1. Context

This project is a crossword-style word tile game in which players draw letter tiles and place them on a grid to form words, scoring by letter value and board multipliers. The genre is best known through *Scrabble*, devised by Alfred Butts in the 1930s and trademarked in 1948. The *Scrabble* trademark is held by Hasbro in the US and Canada and by Mattel in all other territories, including the UK.

The project is published in two public forms:

- a public source repository
- a publicly accessible hosted build

Both are intended for evaluation by prospective employers. Neither is monetised.

## 2. How intellectual property applies to games

| Type | What it protects | Relevance to this project |
|---|---|---|
| **Copyright** | Expression: rulebook text, artwork, specific visual presentation, code | Game rules and mechanics are ideas or systems and are not protected. Written rules, artwork and visual presentation are protected. |
| **Patent** | Novel inventions, including mechanics, for about 20 years | Any patents relating to the original game expired decades ago. |
| **Trademark** | Names, logos, branding that identify a source | *Scrabble* is a registered trademark in active use. Its name, logo and confusingly similar names are protected. |
| **Trade dress / get-up** | The distinctive overall look of a product | The recognisable appearance of the original board and tiles may be protected where copying it could cause confusion. |

The core mechanic is therefore free to use. The brand, the written rules and the distinctive presentation are not.

## 3. Precedents

| Case | Outcome | Relevant factor |
|---|---|---|
| **Scrabulous** (Facebook, 2006–2008) | Hasbro brought proceedings in 2008. The app was withdrawn and relaunched as *Lexulous* with altered rules and branding. Settled without a ruling on mechanics. | The name echoed the trademark, and the board, tile values and look closely matched the original. |
| **Words with Friends** (Newtoy, later Zynga, 2009–present) | Has operated commercially for over fifteen years. | Unrelated name, its own premium-square layout, different tile values and distribution, original visual style, and its own asynchronous social play model. |
| **Tetris Holding v. Xio Interactive** (US District Court, New Jersey, 2012) | Infringement found. | The defendant reproduced the mechanics *and* the specific visual expression (playfield dimensions, piece appearance). A close copy of the look was held to go beyond the unprotected idea. |

Taken together, these cases put the boundary at branding and presentation, not at the mechanic.

## 4. Risk register

Likelihood and impact are rated Low / Medium / High for the project's current non-commercial portfolio purpose.

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| IP-1 | Trademark claim over the product name or branding | Low | High | Original name with no phonetic or visual echo of the trademark (see D-1) |
| IP-2 | Trade dress claim over board or tile appearance | Low | Medium | Original board layout and visual design (see D-2, D-4) |
| IP-3 | Copyright claim over rules text | Low | Low | Rules written from scratch (see D-5) |
| IP-4 | Licence breach through the word list | Medium | Medium | Public-domain or permissively licensed list only (see D-6) |
| IP-5 | Brand association in repository or marketing copy | Low | Medium | Genre described generically. No trademark used as a descriptor (see D-1) |
| IP-6 | Copied third-party assets (fonts, icons, sounds) | Low | Medium | Only original or appropriately licensed assets, with sources recorded (see D-7) |

Residual risk with all mitigations in place: **Low**.

## 5. Design constraints

These constraints apply to all subsequent design and implementation work.

- **D-1 Name and copy.** The product name has no association with the *Scrabble* trademark. Repository and product copy describe the game generically (e.g. "a crossword-style word tile game") and do not use the trademark as a descriptor or comparison.
- **D-2 Board.** The premium-square positions are an original design. The dimensions may match the classic 15 × 15 board (amended 24 October 2026, Luke: the rack size equals the board's width, and 15 tiles suits play; see `board-and-tiles.md`).
- **D-3 Tiles.** Letter point values and the tile distribution are an original design.
- **D-4 Visual identity.** The colour palette, tile styling, typography and iconography are original and do not reproduce the appearance of the official board or tiles.
- **D-5 Rules text.** All rules and help text are written independently.
- **D-6 Word list.** The dictionary comes from a source whose licence permits public redistribution, such as ENABLE (public domain). Licensed tournament lists such as Collins Scrabble Words and NWL are not used. The source and licence are recorded in the repository.
- **D-7 Assets.** All third-party assets are listed with their source and licence in a `CREDITS` or `THIRD_PARTY` file.

## 6. Verification checklist

Before each public release:

- [ ] Product name and copy meet D-1
- [ ] Premium-square layout differs from the original (D-2)
- [ ] Tile values and distribution differ from the original (D-3)
- [ ] Visual design has been reviewed against D-4
- [ ] Rules text is original (D-5)
- [ ] Word list source and licence are documented (D-6)
- [ ] Third-party asset register is up to date (D-7)

## 7. Review

This assessment is revisited if the project:

- moves towards commercial use or monetisation
- adopts new branding, assets or a word list
- adds features that reproduce elements of an existing commercial product

A commercial change of purpose would warrant a formal trademark search and professional legal advice.
