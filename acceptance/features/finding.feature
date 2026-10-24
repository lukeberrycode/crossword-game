Feature: Finding games and viewing their history

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, TO
    And the clock is controlled by the test
    And Ann and Bob are signed in

  @FIND-1
  Scenario: The random-game button opens a random game number
    When a visitor asks for a random game 20 times
    Then every game number is between 0 and 18446744073709551615
    And at least two of the game numbers are different

  @FIND-2
  Scenario: The active-games list shows games with recent plays, most recent first
    Given games 3, 7 and 9 start from the draw order "CATOREINLDUPMGS"
    And at 10:00 Ann plays "CAT" across from G8 for turn 1 of game 7
    And at 10:05 Ann plays "CAT" across from G8 for turn 1 of game 3
    When a visitor opens the active-games list
    Then it lists game 3 and then game 7
    And it does not list game 9

  @FIND-3
  Scenario: "My games" lists the games a player has played in
    Given games 3 and 7 start from the draw order "CATOREINLDUPMGS"
    And Ann has played "CAT" across from G8 for turn 1 of game 7
    When Ann opens "My games"
    Then it lists game 7
    And it does not list game 3

  @FIND-3
  Scenario: Alerts for removed turns are counted until the player looks
    Given game 7 starts from the draw order "CATSOREINLDUPMGH"
    And Ann has played "CAT" across from G8 for turn 1 of game 7
    And Bob has played "CATS" across from E8 for turn 1 of game 7
    When Ann opens "My games"
    Then game 7 is flagged as having a removed turn
    And Ann's unread alert count is 1
    When Ann opens game 7
    Then Ann's unread alert count is 0
    And game 7 is no longer flagged in Ann's "My games"

  @FIND-4
  Scenario: Anyone can view a game at any turn of its history
    Given game 1 starts from the draw order "CATOREINLDUPMGS"
    And Ann has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    And Bob has played "TO" down from I8 for turn 2 of game 1, scoring 4
    When a visitor views game 1 at turn 1
    Then the board holds only C at G8, A at H8, T at I8
    And the rack is the rack as it was before turn 2
    And the history of game 1 is:
      | turn | player | word | tiles                     | score |
      | 1    | Ann    | CAT  | C at G8, A at H8, T at I8 | 14    |
      | 2    | Bob    | TO   | O at I9                   | 4     |
