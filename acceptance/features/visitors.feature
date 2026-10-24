Feature: Visitors and trying plays
  Visitors can look at everything without signing in, and anyone can try a
  play to see whether it's valid and what it would score, without saving it.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, TO
    And game 1 starts from the draw order "CATSOREINLDUPMGHBY"

  @VIS-1
  Scenario Outline: Visitors can browse without signing in
    When a visitor <action>
    Then the request succeeds without signing in

    Examples:
      | action                             |
      | asks for a random game             |
      | opens the active-games list        |
      | views game 1 at any turn           |
      | opens the build-up leaderboard     |
      | opens the burn-down leaderboard    |
      | opens the leaderboard for game 1   |
      | opens a player's profile           |

  @VIS-2
  Scenario: A visitor tries a valid play
    When a visitor tries "CATS" across from E8 for turn 1 of game 1
    Then the trial says the play is valid and would score 28
    And game 1 has no turns
    And no player's score has changed

  @VIS-2
  Scenario: A visitor tries an invalid play
    When a visitor tries "CTA" across from G8 for turn 1 of game 1
    Then the trial says the play is invalid because "CTA" is not an acceptable word

  @VIS-2
  Scenario: A visitor tries a play for an earlier turn
    Given Ann is signed in
    And Ann has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    And Ann has played "TO" down from I8 for turn 2 of game 1, scoring 4
    When a visitor tries "CATS" across from E8 for turn 1 of game 1
    Then the trial says the play is valid, would score 28, and would beat turn 1
    And game 1 still has 2 turns

  @VIS-3
  Scenario: A signed-in player tries a play before submitting it
    Given Ann is signed in
    When Ann tries "CAT" across from G8 for turn 1 of game 1
    Then the trial says the play is valid and would score 14
    And game 1 has no turns
    And Ann's build-up score is 0
