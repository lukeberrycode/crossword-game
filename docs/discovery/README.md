# Discovery

The first phase of Luke's method (`daytrader-to-python/docs/method.md`), applied to a migration from "no app" to "app". The game's rules are in the root `README.md`; the IP constraints are in `ip-risk-assessment.md`.

## How the method is adapted (Luke, 23 October 2026)

With no old slice, the steps that depend on one are changed as follows.

| Method step | Here |
|---|---|
| Can we run the old slice locally? | Skipped |
| What does the product do? | `one-pager.md`, drawn from the rules and the interview |
| How does it do it? (projects, technologies, architecture) | Skipped. Technology and architecture are decided in Planning's RFC |
| What data does the slice own? | Skipped. Left to Planning |
| Users, states, risks, journeys, requirements, test methods | As in the method: `users-states-journeys.md` and `requirements.md`, drawn from an interview with Luke |
| Does the old slice behave as the requirements say? (characterisation tests) | Replaced by **acceptance tests**: executable scenarios written from the requirements, at the API boundary. They fail until the servers are built, then serve as the shared contract tests that both the Java and .NET servers must pass |
| Keep or fix the odd behaviour? | Dropped. Ambiguities are settled directly in the requirements during the interview |
| Time each phase against a no-AI estimate | Not done for this project |
| Planning: data migration, cut-over, rollback; decommissioning the old slice | Dropped: there is nothing to migrate or replace |

Everything else (gates, the RFC, vertical slices, traceability, continuous evaluation, future-proofing) applies as written.

## Why the game is being built

A portfolio project, to close gaps in the Grove Talent advert (`jobs-sept-26/unsent/Sara-Quinn-Grove-Talent/demo-plan.md`): **writing Java and .NET**. One front end talks to two interchangeable servers, one in Java (Spring Boot) and one in .NET (ASP.NET Core), built in parallel from a single API contract and tested by the same contract tests.

## Status

| Question | Answer |
|---|---|
| What does it do? | `one-pager.md` (draft) |
| Who are its users; their states, risks and journeys? | `users-states-journeys.md` (draft) |
| What are the requirements, and how is each tested? | `requirements.md` (draft; no open questions) |

## First gate

**Not yet passed.**

- [x] Requirements drawn from the interview, each with a test method (`requirements.md`)
- [x] Board and tile design proposed by Claude (`board-and-tiles.md`)
- [x] Luke: board and tiles approved, 8-tile bonus, 15 × 15 kept with IP constraint D-2 amended (24 October 2026)
- [ ] Offensive-word blocklist additions drafted by Claude and approved by Luke
- [ ] Acceptance tests written for the requirements, each traced to its requirement
- [ ] Luke: sign off the requirements, recording any dropped with the reason
