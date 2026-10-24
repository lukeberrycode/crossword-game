Feature: Scoring
  Letter values and premium cells are those in docs/discovery/board-and-tiles.md.
  Values used here: A 2, C 3, E 1, I 2, O 2, R 2, S 1, T 2, blank 0.
  Premiums used here: H8 double word (centre); E4 and K4 double word;
  E8 and K8 triple letter; H5 triple letter; G4 and I4 double letter.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, OAT, OATS, ITS, ASTER, ROTATES, SCATTER, SCATTERS
    And Ann and Bob are signed in

  @SCORE-1 @SCORE-5
  Scenario: A word scores the sum of its letters, doubled on the centre
    Given game 1 starts from the draw order "CATSLNIUDPMGHBY"
    When Ann plays "CAT" across from G8 for turn 1 of game 1
    Then the play is accepted with a score of 14
    # (C 3 + A 2 + T 2) x 2 for H8

  @SCORE-2
  Scenario: Letter premiums are applied before word premiums
    Given game 1 starts from the draw order "CATSLNIUDPMGHBY"
    When Ann plays "CATS" across from E8 for turn 1 of game 1
    Then the play is accepted with a score of 28
    # (C 3 x 3 for E8 + A 2 + T 2 + S 1) x 2 for H8

  @SCORE-2
  Scenario: A premium counts only on the turn its tile is placed
    Given game 1 starts from the draw order "CATSLNIUDPMGHBY"
    And Ann has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    When Bob plays "CATS" across from G8 for turn 2 of game 1
    Then the play is accepted with a score of 8
    # C 3 + A 2 + T 2 + S 1: H8's double word was used on turn 1

  @SCORE-2
  Scenario: Two word premiums under one word multiply
    Given game 1 starts from the draw order "ASTERROTTESLNIUBCDFG"
    And Ann has played "ASTER" down from H4 for turn 1 of game 1, scoring 20
    # (A 2 + S 1 x 3 for H5 + T 2 + E 1 + R 2) x 2 for H8
    When Bob plays "ROTATES" across from E4 for turn 2 of game 1
    Then the play is accepted with a score of 64
    # (R 2 + O 2 + T 2 x 2 for G4 + A 2 + T 2 x 2 for I4 + E 1 + S 1) x 2 for E4 x 2 for K4

  @SCORE-1 @SCORE-2
  Scenario: A play scores every word it makes, and a premium counts in each word
    Given game 1 starts from the draw order "OATITSLNEURDPMG"
    And Ann has played "OAT" across from H8 for turn 1 of game 1, scoring 12
    When Bob plays "ITS" down from K6 for turn 2 of game 1
    Then the play is accepted with a score of 16
    And the play's words are:
      | word | score |
      | ITS  | 7     |
      | OATS | 9     |
    # ITS: I 2 + T 2 + S 1 x 3 for K8. OATS: O 2 + A 2 + T 2 + S 1 x 3 for K8

  @SCORE-3
  Scenario: A blank on a letter premium scores nothing
    Given game 1 starts from the draw order "?ATSLNIUDPMGHBY"
    When Ann plays "cATS" across from E8 for turn 1 of game 1
    Then the play is accepted with a score of 10
    # (blank 0 + A 2 + T 2 + S 1) x 2 for H8

  @SCORE-3
  Scenario: A blank on a word premium still multiplies the word
    Given game 1 starts from the draw order "C?TSLNIUDPMGHBY"
    When Ann plays "CaT" across from G8 for turn 1 of game 1
    Then the play is accepted with a score of 10
    # (C 3 + blank 0 + T 2) x 2 for H8

  @SCORE-4
  Scenario Outline: Playing 8 or more tiles earns a 50-point bonus
    Given game 1 starts from the draw order "SCATTERSLNIUDPM"
    When Ann plays "<word>" across from E8 for turn 1 of game 1
    Then the play is accepted with a score of <score>

    Examples:
      | word     | tiles | score | why                         |
      | SCATTER  | 7     | 38    | 19 x 2, no bonus            |
      | SCATTERS | 8     | 90    | 20 x 2, plus the 50 bonus   |
