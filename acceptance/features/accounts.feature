Feature: Sign-in and accounts
  Players sign in with GitHub or Google. Tests use a mock OpenID Connect
  provider in place of both.

  Background:
    Given a test build of the server
    And the mock sign-in provider knows these people:
      | provider | id  | name on the provider |
      | GitHub   | 101 | Ann Smith            |
      | Google   | 202 | Bob Jones            |
      | GitHub   | 303 | Cara Lee             |

  @AUTH-1
  Scenario Outline: Players sign in with GitHub or Google
    When person <id> signs in with <provider>
    Then they are signed in

    Examples:
      | provider | id  |
      | GitHub   | 101 |
      | Google   | 202 |

  @AUTH-1
  Scenario: There is no password sign-in
    Then the API offers no way to sign in with a password
    And the API offers no way to register with a password

  @AUTH-2
  Scenario: The first sign-in asks for a display name
    When person 101 signs in with GitHub for the first time
    Then they are asked to choose a display name
    And they cannot make plays until they have chosen one
    When they choose the display name "ann_s"
    Then their profile shows "ann_s"
    And nothing anywhere shows "Ann Smith"

  @AUTH-2
  Scenario: Display names must be unique
    Given person 101 has the display name "ann_s"
    When person 202 signs in with Google for the first time
    And they choose the display name "ann_s"
    Then the choice is refused because the name is taken

  @AUTH-6
  Scenario: Players can change their display name, to one that isn't taken
    Given person 101 has the display name "ann_s"
    And person 202 has the display name "bob_j"
    When person 101 changes their display name to "annie"
    Then their profile shows "annie"
    When person 101 changes their display name to "bob_j"
    Then the change is refused because the name is taken

  @AUTH-3
  Scenario: Players can sign out
    Given person 101 is signed in as "ann_s"
    When they sign out
    Then they are a visitor
    And a play they submit is refused because they are not signed in

  @AUTH-4
  Scenario: A suspended player can browse and try plays, but not play
    Given the test word list: CAT
    And game 1 starts from the draw order "CATSOREINLDUPMG"
    And person 101 is signed in as "ann_s"
    And the operator has suspended "ann_s"
    When they view game 1
    Then the request succeeds
    When they try "CAT" across from G8 for turn 1 of game 1
    Then the trial says the play is valid and would score 14
    When they play "CAT" across from G8 for turn 1 of game 1
    Then the play is refused because they are suspended

  @AUTH-7
  Scenario: Deleting an account keeps its turns, credited to "deleted player"
    Given the test word list: CAT, TO
    And game 1 starts from the draw order "CATOREINLDUPMGS"
    And person 101 is signed in as "ann_s"
    And person 202 is signed in as "bob_j"
    And "ann_s" has played "CAT" across from G8 for turn 1 of game 1, scoring 14
    And "bob_j" has played "TO" down from I8 for turn 2 of game 1, scoring 4
    When "ann_s" deletes their account
    Then game 1 still has 2 turns, with the same board
    And turn 1 of game 1 is credited to "deleted player"
    And "ann_s" appears on no leaderboard and has no profile
    And person 101 signing in with GitHub again starts a new account
