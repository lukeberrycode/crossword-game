Feature: Making a valid play
  Where tiles may go, which words must be acceptable, and who may play.

  Background:
    Given a test build of the server
    And the test word list: CAT, CATS, AT, TO, TAX
    And game 1 starts from the draw order "CATSOREINLDUPMGHBYFV"
    And Ann and Bob are signed in

  @PLAY-2
  Scenario: A first play in one line, covering the centre, is accepted
    When Ann plays "CAT" across from G8 for turn 1 of game 1
    Then the play is accepted

  @PLAY-2
  Scenario Outline: First plays that break the placement rules are refused
    When Ann places <tiles> for turn 1 of game 1
    Then the play is refused because <reason>

    Examples:
      | tiles                      | reason                                    |
      | C at G8, A at H9, T at I8  | the tiles are not in one row or column    |
      | C at G8, A at H8, T at J8  | the tiles do not form an unbroken line    |
      | C at A1, A at B1, T at C1  | the first play does not cover the centre  |
      | A at H8                    | the first play is shorter than two letters |
      | C at M8, A at N8, T at O8, S at P8 | a tile is off the board          |
      | T at G8, A at H8, X at I8  | a tile is not on the rack                 |
      | C at G8, A at H8, T at I8, T at J8 | a tile is not on the rack         |

  @PLAY-2
  Scenario Outline: Later plays that break the placement rules are refused
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    When Bob places <tiles> for turn 2 of game 1
    Then the play is refused because <reason>

    Examples:
      | tiles            | reason                                   |
      | T at A1, O at B1 | the play does not touch a tile on the board |
      | O at I8          | a cell is already covered                |

  @PLAY-2
  Scenario: A later play may use tiles already on the board
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    When Bob plays "TO" down from I8 for turn 2 of game 1
    Then the play is accepted
    And the only tile placed is O at I9

  @PLAY-3
  Scenario: A play whose main word isn't in the word list is refused, naming the word
    When Ann plays "TCA" across from G8 for turn 1 of game 1
    Then the play is refused because "TCA" is not an acceptable word

  @PLAY-3
  Scenario: A play that makes an unacceptable cross-word is refused, naming it
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    When Bob plays "AT" across from G9 for turn 2 of game 1
    Then the play is refused because "CA" is not an acceptable word
    And the refusal does not name "AT"

  @PLAY-4
  Scenario: A blank must be given a letter
    Given game 2 starts from the draw order "?ATSOREINLDUPMGHBYFV"
    When Ann places a blank with no letter at G8, A at H8, T at I8 for turn 1 of game 2
    Then the play is refused because a blank has no letter

  @PLAY-4
  Scenario: A blank keeps its letter while it stays on the board
    Given game 2 starts from the draw order "?ATSOREINLDUPMGHBYFV"
    And Ann has played "cAT" across from G8 for turn 1 of game 2
    When Bob plays "cATS" across from G8 for turn 2 of game 2
    Then the play is accepted
    And G8 holds a blank standing for C

  @PLAY-5
  Scenario: A play must place at least one tile
    When Ann places no tiles for turn 1 of game 1
    Then the play is refused because no tiles were placed

  @PLAY-5
  Scenario: There is no way to pass, exchange or challenge
    Then the API offers no operation to pass a turn
    And the API offers no operation to exchange tiles
    And the API offers no operation to challenge a play

  @PLAY-1
  Scenario Outline: A play must name its game, turn and version
    When Ann submits "CAT" across from G8 without <field>
    Then the play is refused because the request is incomplete

    Examples:
      | field           |
      | the game number |
      | the turn number |
      | the version     |

  @PLAY-9
  Scenario Outline: A refused play changes nothing
    Given Ann has played "CAT" across from G8 for turn 1 of game 1
    And game 1 is at version 1
    When Bob places <tiles> for turn 2 of game 1
    Then the play is refused because <reason>
    And game 1 is still at version 1, with the same board and rack
    And Ann's and Bob's scores are unchanged

    Examples:
      | tiles            | reason                                     |
      | T at A1, O at B1 | the play does not touch a tile on the board |
      | A at G9, T at H9 | "CA" is not an acceptable word             |

  @PLAY-12 @VIS-2
  Scenario: Visitors can't make plays
    When a visitor plays "CAT" across from G8 for turn 1 of game 1
    Then the play is refused because the visitor is not signed in
    And game 1 has no turns

  @PLAY-12 @AUTH-4
  Scenario: Suspended players can't make plays
    Given the operator has suspended Bob
    When Bob plays "CAT" across from G8 for turn 1 of game 1
    Then the play is refused because Bob is suspended
    And game 1 has no turns
