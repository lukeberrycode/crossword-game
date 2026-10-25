# RFC-0001: the stack

**Status:** proposed, for Luke's decision at the gate "Is the destination stack approved?" (method, Planning).
**Date:** 25 October 2026. **Author:** Claude Code, from the requirements Luke signed off at the first gate (`docs/discovery/requirements.md`).

## The question

What should the game be built with, and where should it run, to meet the signed-off requirements?

Already decided, and not reopened here:

| Decision | Source |
|---|---|
| One front end and one API contract, so a second server can be added without the front end noticing (NFR-4) | Demo plan; requirements |
| **Java (Spring Boot) first.** A .NET (ASP.NET Core) server comes later, only if the job search calls for it | Luke, 25 October 2026; demo plan (24 October 2026) |
| **The front end is React with TypeScript** | Luke, 25 October 2026 |
| **The Java server is hosted on AWS; the .NET server, when it comes, on Azure** | Luke, 25 October 2026 |
| Infrastructure in Terraform, shipped through CI/CD | Demo plan |
| Acceptance scenarios in Gherkin, run against the HTTP API (`acceptance/`) | First gate |

## What the requirements ask of a stack

| Need | From |
|---|---|
| A draw order that two languages reproduce exactly from a 64-bit game number | GAME-2, GAME-3 |
| A search for any acceptable play after every change, within the play's response time | GAME-9, GAME-10, NFR-7 |
| Plays on one game handled one at a time, with game history and player scores always consistent | PLAY-7, PLAY-8, PLAY-11, PSCORE-4 |
| 500 concurrent players, 50 plays a second, 95% of plays in under 300 ms, on low-cost hosting | NFR-1 |
| GitHub and Google sign-in, no passwords, OWASP session practice | AUTH-1, AUTH-5 |
| Per-player and per-IP rate limits, changeable without a redeploy | OPS-3 |
| Health, errors, load and activity for the operator | OPS-1 |
| A browser UI for desktop and mobile, WCAG 2.2 AA, playable by keyboard | NFR-2, NFR-3 |
| Test builds with explicit draw orders and word lists; none of that in production | TEST-1, TEST-2 |
| The same acceptance scenarios run unchanged against any server | NFR-4 |

## Evidence: three spikes

Code and raw results are in `rfc-0001/spikes/`. All ran on Luke's laptop (Intel Core i7-7600U, 4 logical CPUs) in Docker on 25 October 2026: Java 25.0.4.1 (Eclipse Temurin), .NET SDK 10.0.402, PostgreSQL 18.6, Python 3.12.

### 1. The shuffle (GAME-2, GAME-3)

**Algorithm:** the 101 tiles in a canonical order (A to Z with the approved counts, then 3 blanks); SplitMix64 seeded with the game number as an unsigned 64-bit integer; a Fisher–Yates shuffle from the last position down; each random index drawn without bias by rejecting values in the incomplete last block of 2^64. Written in Python (the reference), Java and C#.

**Result:** for 1,000 game numbers, including 0, 2^63 and 2^64 − 1, all three gave **byte-identical draw orders** (`results/python.txt`, `java.txt`, `dotnet.txt`). Over 200,000 consecutive game numbers, the tile at positions 0, 50 and 100 shows no bias (chi-squared 18.1, 30.6 and 26.3, against 54.05 at p = 0.001; `results/uniformity.txt`).

**Consequence:** the algorithm goes into the API specification, and `results/python.txt` supplies the test vectors that the pending GAME-2/GAME-3 scenario needs. Both target languages handle unsigned 64-bit arithmetic without libraries (Java's `Long.remainderUnsigned` and `compareUnsigned`; C#'s `ulong`).

### 2. The stall check (GAME-9, NFR-7)

**Method:** an Appel–Jacobson move generator (anchors, cross-checks, left parts) over a trie of the 172,692-word game list, stopping at the first acceptable play. It was run after every turn of 100 simulated games (game numbers 2 to 101, after 2 warm-up games), each played by choosing a random acceptable play until the game completed or stalled. For a worst-case bound, a full enumeration of every acceptable play was also timed on every third turn. Each stall was confirmed by a second, independent enumeration.

| | Turns | p50 | p95 | p99 | Max |
|---|---|---|---|---|---|
| **Stall check** (any play?) | 3,131 | 0.03 ms | 1.3 ms | 3.8 ms | 8.9 ms |
| Full enumeration, no blanks on the rack | 941 | 3.9 ms | 18 ms | 31 ms | 47 ms |
| Full enumeration, 1 blank | 97 | 54 ms | 210 ms | 274 ms | 274 ms |
| Full enumeration, 2 blanks | 6 | 174 ms | 607 ms | – | 607 ms |

The trie has 387,679 nodes and builds in about 0.2 seconds.

**Consequences:**

- **The stall check can run synchronously inside every play.** Its worst case (8.9 ms) is about 30 times inside NFR-7's 300 ms. No queue, cache or background job is needed.
- **Full enumeration** (needed only for something like a "best play" hint, which isn't a requirement) is much slower with blanks, and would need its own design.
- **A design finding, outside this RFC's scope but for the gate: 97 of the 100 games ended stalled, not complete.** Every stall came with an empty bag and 1 to 3 tiles left: Q in 74 of the 97, often with Z or J. Simulated players choose plays at random rather than planning, so real games may differ, but "stalled with a Q left" will be the usual ending. See decision G-1.

### 3. Concurrency (PLAY-7, PLAY-8, PLAY-11, PSCORE-4)

**Method:** Java with JDBC against PostgreSQL 18. The game rules were reduced to what matters for consistency: plays for the next turn or to beat an earlier one, the strictly-higher rule, the stale-history rule, removing later turns, and build-up and burn-down scores, with 2 ms of CPU per play standing in for validation and the stall check. 32 client threads ran for 15 seconds, against **one hot game** or **spread over 1,000 games**, with two strategies:

- **Row lock:** `SELECT … FOR UPDATE` on the game row, so plays on one game queue.
- **Version check and retry:** no lock; the final `UPDATE … WHERE version = ?` fails if another play got in first, and the play is retried.

| Strategy | Games | Plays handled a second | p50 | p95 | p99 | Retries | Abandoned after 5 s of retrying |
|---|---|---|---|---|---|---|---|
| Row lock | 1 | 410 | 74 ms | 126 ms | 157 ms | 0 | 0 |
| Row lock | 1,000 | 931 | 27 ms | 62 ms | 93 ms | 0 | 0 |
| Version check | 1 | 215 | 6 ms | 220 ms | 3,390 ms | 7,669 | 20 |
| Version check | 1,000 | 1,029 | 24 ms | 56 ms | 89 ms | 287 | 0 |

After every run, four checks passed: each player's build-up equals their surviving turns, each burn-down equals the turns they removed, every game's turns are numbered 1 to n without gaps, and no turn is newer than its game.

**Consequences:**

- **Use a row lock on the game.** Spread across games, the two strategies are alike, and both are about 20 times NFR-1's 50 plays a second. On a busy game, the version check starves: some plays retry for seconds. It also needs care that the lock doesn't: in the first version-check run, a turn being beaten was deleted by another play between two reads, and the spike crashed until that case was treated as a retry.
- **The game's version number stays, as a domain concept**, not as the locking mechanism: it is how PLAY-8 decides that a player's view is out of date. This refines the demo plan's note, which suggested JPA's `@Version` (optimistic locking).
- Player rows are updated in id order inside the play's transaction, so concurrent plays in different games don't deadlock on shared players.

## Options and recommendations

### Server (Java)

| Choice | Recommended | Considered | Why |
|---|---|---|---|
| Language | **Java 25** (LTS, supported to 2031) | Java 27 (current, non-LTS) | LTS is the professional default; 25 has virtual threads and modern language features |
| Framework | **Spring Boot 4.1** (Spring MVC on virtual threads) | Spring WebFlux; Quarkus; Micronaut | Spring Boot is what Java job adverts ask for. Blocking MVC with virtual threads is simpler than reactive code, and the row-lock design is blocking anyway |
| Data access | **Spring Data JPA (Hibernate)** with `PESSIMISTIC_WRITE` on the game; plain SQL (`JdbcClient`) where it is clearer | jOOQ; JDBC only | JPA is the expected skill; the lock maps directly. jOOQ is a fine alternative but less common in adverts |
| Migrations | **Flyway** | Liquibase | Plain SQL files, simplest to review |
| Build | **Maven** | Gradle | The enterprise default; easiest for reviewers to read |
| Sign-in | **Spring Security OAuth2 Login** (GitHub, Google OpenID Connect); server-side sessions in Postgres (Spring Session JDBC); `SameSite=Lax` cookies plus CSRF tokens | Tokens (JWT) in the browser | Server-side sessions keep tokens out of JavaScript and make sign-out and suspension immediate (AUTH-4, AUTH-5) |
| Rate limits | **Bucket4j**, with buckets in Postgres and limits read from a table | A gateway-level limiter (e.g. AWS WAF) | Per-player limits need the signed-in identity, which only the app knows; limits in a table change without a redeploy (OPS-3) |
| Word list and stall check | **In memory:** `game-words.txt` packaged with the server and loaded into a trie at start-up (about 0.2 s); the Appel–Jacobson search from spike 2 | A database table of words; a DAWG | The spike shows the trie is fast and small enough. A DAWG would save memory if it's ever needed |
| Tests | **JUnit, jqwik** (property-based), **Testcontainers** (real Postgres), Spring Security test support | H2 in-memory database | Testcontainers tests against the real database and its locking; H2 doesn't behave the same |
| Observability | **Spring Boot Actuator** (health) and **Micrometer** metrics to **CloudWatch**, with a CloudWatch dashboard in Terraform | Prometheus and Grafana; OpenTelemetry | CloudWatch needs nothing extra to run on AWS. OpenTelemetry is the upgrade path if the .NET server shares dashboards later |

### API contract

**OpenAPI 3.1, written first, in `api/openapi.yaml`.** The Spring server implements interfaces generated from it (openapi-generator, `interfaceOnly`); the front end and the acceptance tests use TypeScript types generated from it (openapi-typescript with openapi-fetch). CI lints the contract. The shuffle algorithm and its test vectors are part of the specification.

Considered: code-first (annotations generate the contract). Rejected, because the contract must belong to neither server.

### Front end

| Choice | Recommended | Why |
|---|---|---|
| Framework | **React 19 + TypeScript**, built with **Vite** as a single-page app | Luke's choice; the servers provide everything else, so no server-side rendering is needed |
| Server state | **TanStack Query**: plays as mutations; a light poll for other players' moves ("anything since version n?") | Matches the demo plan's request/response design; the poll can become server-sent events later without changing the play API |
| Routing | **React Router** | The common choice |
| Board interaction | **dnd-kit**, with its keyboard support, plus a typed entry mode (choose a cell and type the word) | NFR-3 needs plays by keyboard alone; typing a word is also the fastest way on a desktop |
| Styling | Plain CSS with design tokens, an original visual design | IP constraint D-4 |
| Tests | **Vitest** and Testing Library; **Playwright** for browser tests on desktop and mobile viewports; **axe-core** in Playwright for accessibility | NFR-2, NFR-3 |

### Acceptance scenarios and other cross-server tests

| Choice | Recommended | Considered | Why |
|---|---|---|---|
| Gherkin runner | **Cucumber-JS** in TypeScript, calling the API through the generated client | Cucumber-JVM | A runner outside both servers is the only one that can test both unchanged (NFR-4), and it exercises the contract exactly as the front end does |
| Sign-in in tests | **mock-oauth2-server** (an open-source mock OpenID Connect provider, run in Docker) | Real test accounts | Repeatable, offline, and works for both stacks |
| Property-based tests at the API | **fast-check** (TypeScript) | – | Same reasoning as Cucumber-JS: shared by both servers |
| Load tests | **k6** | Gatling; JMeter | Scripts in JavaScript, easy to run in CI and against a deployed environment (NFR-1, NFR-7) |

### Database

**PostgreSQL 18** (Amazon RDS supports 18.x). It supports the row lock, `DELETE … RETURNING`, and server-side sessions and rate-limit buckets without extra services. Considered: MySQL (no `RETURNING`, weaker fit) and DynamoDB (no multi-row transactions of the kind PSCORE-4 needs without much more work).

### Hosting (Java server, AWS)

| Part | Recommended | Considered |
|---|---|---|
| Server | **ECS on Fargate** behind an Application Load Balancer, one task to start, image in ECR | **App Runner:** closed to new customers since 30 April 2026. **ECS Express Mode:** AWS's suggested replacement; it creates the load balancer and service for you, but hides the parts that make good Terraform evidence, and its Terraform support needs checking. **Lambda:** the in-memory trie and server-side sessions suit a long-running process better |
| Database | **RDS for PostgreSQL 18**, smallest Graviton instance, single zone | Aurora Serverless (costs more at this size) |
| Front end | **S3 and CloudFront**, with CloudFront sending `/api/*` to the load balancer | A separate API domain (needs CORS and cross-site cookies) |
| Secrets | **Secrets Manager** (database password, OAuth client secrets) | – |
| Infrastructure | **Terraform 1.16** with the AWS provider, state in S3 with S3's native locking | AWS CDK (Luke has used it; Terraform is the gap to close) |
| CI/CD | **GitHub Actions**: build, unit and integration tests, acceptance scenarios against the server in Docker Compose, word-list check, contract lint; then image to ECR, `terraform apply`, and deploy. AWS access through GitHub's OpenID Connect, so there are no long-lived keys | – |

Same origin for the app and the API (through CloudFront) keeps cookies, CSRF and sign-in simple.

**Rough cost** (eu-west-2, on-demand, before free-tier allowances; to be confirmed with the AWS pricing calculator): Fargate 0.5 vCPU and 1 GB, about $21 a month; load balancer, about $18 plus a little for traffic; RDS `db.t4g.micro` with 20 GB, about $16; public IPv4 addresses, about $4 each; CloudFront, S3 and CloudWatch at demo traffic, a few dollars. **About $60–70 a month** if left running. The design avoids a NAT gateway (about $35 a month more): the Fargate task runs in a public subnet, reachable only from the load balancer by its security group. See decision G-3.

### Later: the .NET server on Azure

Not designed here; it gets its own RFC if the job search calls for it. The outline: ASP.NET Core on .NET 10 (LTS) with EF Core and the same row-lock design; Azure Container Apps; Azure Database for PostgreSQL Flexible Server; the same React build on Azure Static Web Apps. The shuffle spike already runs on .NET 10.

Two consequences to note now:

- **Two deployments, two databases.** The AWS and Azure sites would hold separate games and players. That suits a demo that compares the two servers; a shared database across clouds would add latency and complexity for no requirement.
- **The acceptance scenarios and load tests run unchanged against both**, which gives the like-for-like comparison the demo plan wants.

## Repository layout

```
api/            openapi.yaml: the contract
server-java/    Spring Boot (Maven)
web/            React front end (Vite)
acceptance/     Gherkin features (already written) and Cucumber-JS step definitions
infra/aws/      Terraform
data/           word list and blocklist (already there)
scripts/        word-list and tile scripts (already there)
tests/          word-list tests (already there)
docs/           discovery, planning, ADRs
```

`server-dotnet/` and `infra/azure/` would be added later.

## Decisions for the gate

| # | Decision | Claude's recommendation |
|---|---|---|
| S-1 | Approve the stack above for the Java server and the front end | Approve |
| S-2 | Row lock on the game, not optimistic locking; the version number stays as a domain concept for PLAY-8 | Approve (spike 3) |
| S-3 | The stall check runs synchronously inside each play | Approve (spike 2) |
| S-4 | The shuffle algorithm above goes into the API specification, with test vectors from spike 1 | Approve |
| G-1 | **Most games will end stalled with a Q or similar left.** Accept that as the normal ending, or change the rules or tiles (for example, a "Qu" tile, or ending the game when the bag is empty and no play remains)? | A game design decision for Luke. It doesn't change the stack either way |
| G-2 | Update the demo plan's crossword notes: optimistic locking (`@Version`) replaced by a row lock | Yes, after the gate |
| G-3 | Hosting cost of about $60–70 a month while running. Keep it running, or switch the environment off between demos (Terraform makes that one command)? | Run it during the job search; switch off otherwise |

## Sources

- Version and support data: [endoflife.date](https://endoflife.date) (Java, Spring Boot, .NET), Maven Central and the npm registry, checked 25 October 2026.
- [AWS App Runner availability change](https://docs.aws.amazon.com/apprunner/latest/dg/apprunner-availability-change.html); [Amazon ECS Express Mode](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-overview.html).
- [Amazon RDS for PostgreSQL supports 18.4](https://aws.amazon.com/about-aws/whats-new/2026/05/amazon-rds-postgresql/).
- Move generation: Appel and Jacobson, "The World's Fastest Scrabble Program", *Communications of the ACM* 31(5), 1988; Gordon, "A Faster Scrabble Move Generation Algorithm", *Software: Practice and Experience* 24(2), 1994 (the GADDAG, a faster alternative if ever needed).
- SplitMix64: Steele, Lea and Flood, "Fast Splittable Pseudorandom Number Generators", OOPSLA 2014.
