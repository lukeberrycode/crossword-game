Feature: Beating an earlier turn
  Any signed-in player can replay any played turn with the rack as it was
  then. A strictly higher score replaces that turn and wipes out every turn
  after it; their tiles go back into the bag in their original order.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, ACT, TO
    And game 1 starts from the draw order "CATSOREINLDUPMGHBYFVKW"
    And Ann, Bob and Cara are signed in
    And Ann has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    And Bob has played "TO" down from I8 for turn 2 of game 1, scoring 4

  @BEAT-1
  Scenario: The rack for an earlier turn is the rack as it was at that turn
    When Cara opens turn 1 of game 1 to beat it
    Then the board is empty
    And the rack holds "CATSOREINLDUPMG"
    And the score to beat is 14

  @BEAT-1 @BEAT-2 @BEAT-4
  Scenario: A higher score beats a turn and becomes that turn
    When Cara plays "CATS" across from E8 for turn 1 of game 1
    Then the play is accepted with a score of 28
    And turn 1 of game 1 is Cara's play
    And the next turn of game 1 is turn 2

  @BEAT-1
  Scenario: Players can beat their own turns
    When Ann plays "CATS" across from E8 for turn 1 of game 1
    Then the play is accepted with a score of 28
    And turn 1 of game 1 is Ann's play

  @BEAT-2
  Scenario Outline: A play that doesn't score strictly more doesn't beat the turn
    When Cara plays <play> for turn 1 of game 1
    Then the play is refused because it does not score more than 14
    And game 1 still has Ann's turn 1 and Bob's turn 2

    Examples:
      | play                 | score | why                 |
      | "ACT" down from H8   | 14    | equal is not enough |
      | "TO" across from H8  | 8     | lower               |

  @BEAT-3 @BEAT-5
  Scenario: Beating a turn removes it and every later turn
    When Cara plays "CATS" across from E8 for turn 1 of game 1
    Then game 1 has 1 turn
    And the history of game 1 holds only Cara's play
    And the board holds only C at E8, A at F8, T at G8, S at H8

  @BEAT-3
  Scenario: Tiles from removed turns are drawn again in the same order
    Ann's play drew "HBY" and Bob's drew "F". Cara's play uses four tiles,
    so the rack draws the next four tiles of the draw order: the same
    "HBY" and "F" as before.

    When Cara plays "CATS" across from E8 for turn 1 of game 1
    Then the rack holds "OREINLDUPMG" and then "HBYF" from the bag
    And the bag holds "VKW" in that order

  @BEAT-4
  Scenario: Beating a turn of a complete game reopens it
    Given game 2 starts from the draw order "CATOS"
    And Ann has played "CAT" across from G8 for turn 1 of game 2, scoring 14
    And Bob has played "TO" down from I8 for turn 2 of game 2, scoring 4
    And Ann has played "CATS" across from G8 for turn 3 of game 2, scoring 8
    And game 2 is complete
    When Cara plays "CATS" across from G8 for turn 2 of game 2
    Then the play is accepted with a score of 8
    And game 2 is open
    And game 2 has 2 turns
    And the rack holds "O"

  @BEAT-6 @FIND-3
  Scenario: Players whose turns are removed are alerted in the app
    When Cara plays "CATS" across from E8 for turn 1 of game 1
    Then Ann's "My games" flags game 1 as having a removed turn
    And Bob's "My games" flags game 1 as having a removed turn
    And Cara's "My games" does not flag game 1
    And no email is sent
