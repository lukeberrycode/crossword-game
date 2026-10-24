Feature: Which turn a play is for
  Every play names a turn and the version of the game it was made against.
  The next unplayed turn is added; a played turn must be beaten; a play made
  on a history that has since changed is refused.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, ACT, TO
    And game 1 starts from the draw order "CATSOREINLDUPMGHBYFV"
    And Ann, Bob and Cara are signed in

  @PLAY-6
  Scenario: A valid play for the next unplayed turn is added
    When Ann plays "CAT" across from G8 for turn 1 of game 1 against version 0
    Then the play is accepted with a score of 14
    And game 1 has 1 turn
    And game 1 is at version 1

  @PLAY-10
  Scenario: The rack is refilled from the draw order after a play
    When Ann plays "CAT" across from G8 for turn 1 of game 1
    Then the rack holds "SOREINLDUPMG" and then "HBY" from the bag
    And the bag holds "FV" in that order

  @PLAY-10
  Scenario: The rack is refilled only as far as the bag allows
    Given game 2 starts from the draw order "CATSOREINLDUPMGH"
    When Ann plays "CAT" across from G8 for turn 1 of game 2
    Then the rack holds "SOREINLDUPMG" and then "H" from the bag
    And the rack holds 13 tiles
    And the bag is empty

  @PLAY-7
  Scenario: Two plays for the same next turn: a higher-scoring second play beats the first
    Given Ann and Bob have both loaded game 1 at version 0
    When Ann plays "CAT" across from G8 for turn 1 of game 1 against version 0
    And Bob plays "CATS" across from E8 for turn 1 of game 1 against version 0
    Then Ann's play is accepted with a score of 14
    And Bob's play is accepted with a score of 28
    And turn 1 of game 1 is Bob's play

  @PLAY-7 @BEAT-2
  Scenario: Two plays for the same next turn: a second play that doesn't score more is refused
    Given Ann and Bob have both loaded game 1 at version 0
    When Ann plays "CAT" across from G8 for turn 1 of game 1 against version 0
    And Bob plays "ACT" down from H8 for turn 1 of game 1 against version 0
    Then Ann's play is accepted with a score of 14
    And Bob's play is refused because it does not score more than 14
    And turn 1 of game 1 is Ann's play

  @PLAY-7
  Scenario: A play for a turn beyond the next unplayed turn is refused
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    When Bob plays "TO" down from I8 for turn 3 of game 1
    Then the play is refused because turn 3 is neither played nor the next turn

  @PLAY-8
  Scenario: A play made on a history that has since changed is refused
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    And Bob has played "TO" down from I8 for turn 2 of game 1
    And Ann has loaded game 1 at version 2
    And Cara has played "CATS" across from E8 for turn 1 of game 1
    When Ann plays any valid tiles for turn 3 of game 1 against version 2
    Then the play is refused because the game has changed
    And the refusal includes game 1 at version 3, with 1 turn

  @PLAY-8
  Scenario: A change after the named turn doesn't make a play stale
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    And Bob has loaded game 1 at version 1
    And Cara has played "TO" down from I8 for turn 2 of game 1
    When Bob plays "CATS" across from G8 for turn 2 of game 1 against version 1
    Then Bob's play counts as an attempt to beat turn 2
    And the play is accepted with a score of 8
