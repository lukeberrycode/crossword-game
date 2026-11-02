# Follow-ups

Points found on 2026-11-02 during a review of this repository (at `64eb8cb8`, plus the open PR #1 "RFC-0001: the stack") for the `lukeberrycode-help` notes. Each one says what was found, why it matters, and what to do. Delete an entry once it's dealt with, and this file once it's empty.

## 1. Run the word-list tests in CI

**Found:** the repository has no `.github/workflows/` folder, on `main` or on the `planning/rfc-0001-stack` branch. The 13 tests in `tests/wordlist/test_build_wordlist.py` (requirements WORD-2, WORD-4 and WORD-7) only run when someone runs `python3 -m unittest discover tests` by hand.

**Why it matters:** WORD-2 says an update to either source list can't slip through without a review decision, and the tests are what enforce it (for example, `GameWordListIsUpToDate.test_committed_list_matches_a_fresh_build` and the `BuildFailsWithoutReview` cases). Without CI, a change to `data/wordlist/` or `scripts/build_wordlist.py` can be merged with the tests failing, and nobody notices until they're next run.

**What to do:** add `.github/workflows/test.yml`, following the pattern in slice-migration and daytrader-to-python (a pinned runner, a checkout pinned to a commit SHA, and read-only permissions):

```yaml
name: Test

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  wordlist:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - name: Word-list tests
        run: python3 -m unittest discover -v tests
```

Check the checkout SHA is still the latest v7 release before using it. Keep `tests/__init__.py` and `tests/wordlist/__init__.py`: since Python 3.11, unittest discovery only finds tests in subfolders that are regular packages (https://docs.python.org/3.12/library/unittest.html#test-discovery). When the servers and acceptance tests arrive, add their jobs to the same workflow.

## 2. When the Gherkin runner is set up: exclude `@pending`

This and the next two points apply once a runner is chosen. PR #1 proposes Cucumber-JS in TypeScript; they're written for that, but the same issues arise with any runner.

**Found:** in `acceptance/features/games.feature`, the Scenario Outline "A game number always gives the same draw order" is tagged `@GAME-2 @GAME-3 @pending`. Its Examples hold `(vector)` placeholders until the shuffle algorithm's test vectors are published in Planning.

**Why it matters:** a tag has no built-in meaning in Cucumber; `@pending` skips nothing unless the run excludes it (https://cucumber.io/docs/cucumber/api/#ignoring-a-subset-of-scenarios). The scenario will fail or report undefined steps, and Cucumber-JS's `strict` option, on by default, fails the run on pending steps (https://github.com/cucumber/cucumber-js/blob/main/docs/configuration.md#options).

**What to do:** add `tags: "not @pending"` to the default profile in the Cucumber-JS config file (`cucumber.json`, `cucumber.mjs` or similar), and remove the tag once the test vectors are in.

## 3. When the Gherkin runner is set up: tell it where the features are

**Found:** the feature files are in `acceptance/features/`. The RFC on PR #1 puts the Cucumber-JS step definitions in `acceptance/` too.

**Why it matters:** by default Cucumber-JS looks for `features/**/*.{feature,feature.md}` relative to where it's run, and loads support code from the `features` folder. Once you set `import`, the defaults stop applying (https://github.com/cucumber/cucumber-js/blob/main/docs/configuration.md#finding-your-features). Run from the repository root with no config, it finds nothing.

**What to do:** either run Cucumber-JS from `acceptance/` (so `features/` is found), or set `paths: ["acceptance/features/**/*.feature"]` and `import` for the step-definition files explicitly in the config. For TypeScript step definitions, register tsx as the Cucumber-JS transpiling guide describes (https://github.com/cucumber/cucumber-js/blob/main/docs/transpiling.md). Then check a run reports 83 scenarios.

## 4. When the Gherkin runner is set up: make scenarios safe to run in parallel

**Found:** many scenarios share names and game numbers: "game 1", "Ann" and "Bob" appear throughout, and the scoring feature's Background signs in "Ann and Bob".

**Why it matters:** Cucumber's rule is that scenarios must be independent (https://cucumber.io/docs/cucumber/state/#sharing-state-between-scenarios). Run one after another against a fresh test build, shared names may work. With `--parallel`, several workers run scenarios at the same time against the same server, so two scenarios playing turn 1 of game 1 would collide (https://github.com/cucumber/cucumber-js/blob/main/docs/parallel.md).

**What to do:** decide this when the step definitions are written. Options:

- Run the acceptance tests serially (`parallel: 0`, the default) and reset the server's state in a `Before` hook.
- Have the step definitions map scenario names to unique ones per scenario (e.g. "game 1" becomes a fresh game number, "Ann" a fresh account), so the feature files stay readable and runs can be parallel.
- Give each worker its own range using the `CUCUMBER_WORKER_ID` environment variable.

Also pass the server's address as a World parameter (e.g. `worldParameters: { apiUrl: ... }`) so the same steps can run against the Java server and later the .NET one (https://github.com/cucumber/cucumber-js/blob/main/docs/support_files/world.md#world-parameters).

**Background:** the `lukeberrycode-help` notes `gherkin/what-is-gherkin.md`, `cucumber/what-is-cucumber-js.md` and `unittest/what-is-unittest.md` each have an "In the crossword game" section.
