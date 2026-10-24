Feature: The game's word list
  The game uses data/wordlist/game-words.txt: ENABLE minus the blocked words.

  Background:
    Given a test build of the server
    And the word list is the game's word list
    And Ann is signed in

  @WORD-1
  Scenario: A word in ENABLE that is blocked can't be played
    Given game 1 starts from the draw order "SHITAKELNOURDPM"
    When Ann plays "SHIT" across from G8 for turn 1 of game 1
    Then the play is refused because "SHIT" is not an acceptable word

  @WORD-1 @WORD-7
  Scenario: A word that only contains a blocked word can be played
    Given game 1 starts from the draw order "SHITAKELNOURDPM"
    When Ann plays "SHITAKE" across from E8 for turn 1 of game 1
    Then the play is accepted

  @WORD-1
  Scenario: A word that isn't in ENABLE can't be played
    Given game 1 starts from the draw order "QZXJKVWLNOURDPM"
    When Ann plays "QZX" across from G8 for turn 1 of game 1
    Then the play is refused because "QZX" is not an acceptable word
