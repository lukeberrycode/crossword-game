Feature: Games and draw orders
  A game is a number. The number fixes the order in which the tiles are drawn.

  @GAME-1 @GAME-5
  Scenario: Any game number opens an unplayed game
    Given a production build of the server
    And no one has played game 12345
    When a visitor opens game 12345
    Then the game is unplayed
    And the game has no turns
    And the rack holds 15 tiles
    And the bag holds 86 tiles

  @GAME-1
  Scenario Outline: Game numbers run from 0 to 2^64 - 1
    Given a production build of the server
    When a visitor opens game <number>
    Then the response is <result>

    Examples:
      | number               | result            |
      | 0                    | an unplayed game  |
      | 18446744073709551615 | an unplayed game  |
      | 18446744073709551616 | "no such game"    |
      | -1                   | "no such game"    |
      | abc                  | "no such game"    |

  @GAME-2 @GAME-3 @pending
  Scenario Outline: A game number always gives the same draw order
    The test vectors are published with the shuffle algorithm in Planning (GAME-2).

    Given a production build of the server
    When a visitor opens game <number>
    Then the rack holds the first 15 tiles of "<draw order>"

    Examples:
      | number | draw order |
      | 0      | (vector)   |
      | 1      | (vector)   |
      | 2^63   | (vector)   |

  @GAME-5
  Scenario: The rack holds the first 15 tiles of the draw order
    Given a test build of the server
    When game 1 starts from the draw order "CATSOREINLDUPMGHBYFV"
    Then the rack holds "CATSOREINLDUPMG"
    And the bag holds "HBYFV" in that order

  @GAME-6
  Scenario: A game records every turn
    Given a test build of the server
    And the test word list: CAT
    And game 1 starts from the draw order "CATSOREINLDUPMGHBYFV"
    And Ann is signed in
    When Ann plays "CAT" across from G8 for turn 1 of game 1
    Then turn 1 of game 1 records:
      | tiles  | C at G8, A at H8, T at I8 |
      | words  | CAT                       |
      | score  | 14                        |
      | player | Ann                       |
    And turn 1 records the time it was played

  @GAME-8
  Scenario: A game is complete when the bag and the rack are empty
    Given a test build of the server
    And the test word list: CATS
    And game 1 starts from the draw order "CATS"
    And Ann and Bob are signed in
    When Ann plays "CATS" across from G8 for turn 1 of game 1
    Then game 1 is complete
    When Bob plays any tiles for turn 2 of game 1
    Then the play is refused because the game is complete

  @GAME-9
  Scenario: A game that can't move at the start is stalled
    Given a test build of the server
    And the test word list: CAT
    When game 1 starts from the draw order "QQQQQQQQQQQQQQQ"
    Then game 1 is stalled

  @GAME-9
  Scenario Outline: The server checks for a possible play after every play
    Given a test build of the server
    And the test word list: CAT, CATS
    And game 1 starts from the draw order "CATQQQQQQQQQQQQXZ<last>"
    And Ann is signed in
    When Ann plays "CAT" across from G8 for turn 1 of game 1
    Then game 1 is <state>

    Examples:
      | last | state   | because                                 |
      | J    | stalled | no tile on the rack can make a word     |
      | S    | open    | S can be added to make CATS             |
      | ?    | open    | the blank can stand for S to make CATS  |

  @GAME-9 @BEAT-4
  Scenario: A stalled game can still have earlier turns beaten
    Given a test build of the server
    And the test word list: TA, CAT, CATS
    And game 1 starts from the draw order "CATQQQQQQQQQQQQQSQ"
    And Ann and Bob are signed in
    And Ann has played "TA" across from H8 for turn 1 of game 1, scoring 8
    And game 1 is stalled
    When Bob plays "CAT" across from G8 for turn 1 of game 1
    Then the play is accepted with a score of 14
    And game 1 is open

  @TEST-1
  Scenario: Test builds start games from any sequence of tiles and any word list
    Given a test build of the server
    And the test word list: ZZZ
    When game 1 starts from the draw order "ZZZ"
    Then the rack holds "ZZZ"
    And the bag is empty

  @TEST-2 @GAME-4
  Scenario: Production builds have no way to create games or set draw orders
    Given a production build of the server
    When anyone tries to start a game from a chosen draw order
    Then the operation does not exist
    When anyone tries to set the word list
    Then the operation does not exist
