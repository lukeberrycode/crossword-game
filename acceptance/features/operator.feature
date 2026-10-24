Feature: Operator

  Background:
    Given a test build of the server
    And the clock is controlled by the test
    And Olive is signed in with an operator account
    And Ann is signed in with a player account

  @OPS-1
  Scenario: The service reports its health
    When anyone asks for the service's health
    Then the response says the service is healthy

  @OPS-1
  Scenario: The operator can see activity
    When Olive opens the operator's activity view
    Then it shows the error rate, the request load, plays per minute and the number of active games

  @OPS-2
  Scenario: The operator can suspend and reinstate a player
    Given the test word list: CAT
    And game 1 starts from the draw order "CATSOREINLDUPMG"
    When Olive suspends Ann
    Then a play by Ann is refused because Ann is suspended
    When Olive reinstates Ann
    Then Ann's play "CAT" across from G8 for turn 1 of game 1 is accepted

  @OPS-3
  Scenario: Rate limits apply to visitors by IP address
    Given Olive has set the limit for tried plays by visitors to 3 a minute
    When a visitor tries 4 plays within a minute from one IP address
    Then the first 3 trials are answered
    And the 4th is refused because the rate limit was reached
    When a minute passes
    Then the visitor's next trial is answered

  @OPS-3
  Scenario: Rate limits apply to players by account
    Given Olive has set the limit for plays by a player to 2 a minute
    When Ann submits 3 plays within a minute
    Then the 3rd is refused because the rate limit was reached

  @OPS-3
  Scenario: The operator changes a rate limit without a redeploy
    Given Olive has set the limit for tried plays by visitors to 3 a minute
    When Olive sets the limit for tried plays by visitors to 5 a minute
    And a visitor tries 5 plays within a minute from one IP address
    Then all 5 trials are answered
    And the server was not restarted

  @OPS-4
  Scenario Outline: Operator functions need an operator account
    When <who> tries to <action>
    Then the request is refused because an operator account is needed

    Examples:
      | who       | action                     |
      | Ann       | suspend a player           |
      | Ann       | change a rate limit        |
      | Ann       | open the activity view     |
      | a visitor | suspend a player           |
