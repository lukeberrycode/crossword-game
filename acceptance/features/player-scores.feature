Feature: Player scores and leaderboards
  Build-up: the total score of a player's turns still in a game's history.
  Burn-down: the total score of every turn a player has removed by beating a turn.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, ACT, TO
    And game 1 starts from the draw order "CATSOREINLDUPMGHBYFVKW"
    And Ann, Bob and Cara are signed in
    And Ann has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    And Bob has played "TO" down from I8 for turn 2 of game 1, scoring 4

  @PSCORE-1
  Scenario: Build-up scores count surviving turns
    Then the players' scores are:
      | player | build-up | burn-down |
      | Ann    | 14       | 0         |
      | Bob    | 4        | 0         |
      | Cara   | 0        | 0         |

  @PSCORE-1 @PSCORE-2
  Scenario: Beating a turn moves points from build-up to the beater's burn-down
    When Cara plays "CATS" across from E8 for turn 1 of game 1
    Then the players' scores are:
      | player | build-up | burn-down |
      | Ann    | 0        | 0         |
      | Bob    | 0        | 0         |
      | Cara   | 28       | 18        |

  @PSCORE-3
  Scenario: Beating your own turn
    When Ann plays "CATS" across from E8 for turn 1 of game 1
    Then the players' scores are:
      | player | build-up | burn-down |
      | Ann    | 28       | 18        |
      | Bob    | 0        | 0         |

  @LB-1 @LB-2
  Scenario: Global leaderboards rank players by each score
    Given Cara has played "CATS" across from E8 for turn 1 of game 1
    And Bob has played "TO" down from G8 for turn 2 of game 1, scoring 4
    Then the top of the build-up leaderboard is:
      | rank | player | build-up |
      | 1    | Cara   | 28       |
      | 2    | Bob    | 4        |
    And the top of the burn-down leaderboard is:
      | rank | player | burn-down |
      | 1    | Cara   | 18        |

  @LB-3
  Scenario: A per-game leaderboard ranks players by their surviving points in that game
    Given game 2 starts from the draw order "CATSOREINLDUPMGHBYFVKW"
    And Cara has played "CATS" across from E8 for turn 1 of game 2, scoring 28
    Then the leaderboard for game 1 is:
      | rank | player | points |
      | 1    | Ann    | 14     |
      | 2    | Bob    | 4      |

  @LB-4
  Scenario: Each player has a public profile
    When a visitor opens Ann's profile
    Then it shows Ann's display name, a build-up score of 14 and a burn-down score of 0
    And it lists game 1 among the games Ann has played in
    And it lists Ann's surviving play "CAT" in game 1, scoring 14
