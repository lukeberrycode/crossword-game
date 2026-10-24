# One-pager

## What it is

A massively multiplayer crossword-building word game, played in the browser. The rules are in the root `README.md`.

## How it differs from the board games that inspired it

- **A game is a draw order.** Every game is identified by a number, which fixes the order in which its 101 tiles come out of the bag. Players can't create games; any number is a game, and it comes into being when someone first opens it. The number of games is finite (one per seed).
- **One notional player per game.** The person in control at any moment makes that player's play. Anyone can make the next play in any game.
- **Turns can be beaten.** Anyone can go back to an earlier turn, with the same letters on the rack, and try to score more than the recorded play. A higher score replaces that turn and wipes out every turn after it. The tiles go back into the bag and come out again in the same order.
- **No winners, only player scores.** Each player has a **build-up** score (the points from their surviving turns) and a **burn-down** score (the points they've wiped out by beating turns).

## Who uses it

- **Signed-in players** (GitHub or Google sign-in) make plays, beat turns, and follow their games and scores.
- **Anonymous visitors** browse games and leaderboards, and can try plays to see what they'd score, without saving them.
- **The operator** monitors the service, suspends abusive players and sets rate limits.
- **Portfolio reviewers** read the public repository and try the hosted game.

## Why it's being built

To show Java and .NET skills in a public demo (`demo-plan.md` in the job-search repository). One front end talks to two interchangeable servers, one in Java (Spring Boot) and one in .NET (ASP.NET Core), built from one API contract and tested by the same acceptance tests.

## What's hard about it

- **Concurrency.** Many players can play or beat turns in the same game at once. The server must decide which play stands without losing or corrupting history.
- **Determinism across two stacks.** Both servers must produce the same draw order from a game number, and the same score for the same play.
- **Rules correctness.** Placement, cross-words, premium cells, blanks and the full-rack bonus all have to be right, and both servers must agree.
