# RFC-0001 spikes

Throwaway code that produced the evidence in `../../rfc-0001-stack.md`. Not part of the product. Everything runs in Docker; no local Java or .NET is needed. Run from the repository root unless stated.

| Spike | Question | Run |
|---|---|---|
| `shuffle/` | Can Java and C# reproduce a draw order exactly from a game number? | See below |
| `stall-check/` | Is the "any acceptable play?" search fast enough to run inside every play? | See below |
| `concurrency/` | Row lock or version check: which keeps games and scores consistent under parallel plays? | See below |

## Shuffle

```sh
cd docs/planning/rfc-0001/spikes/shuffle
python3 shuffle.py $(cat results/seeds.txt) > results/python.txt
docker run --rm -v "$PWD":/w -w /w eclipse-temurin:25-jdk sh -c 'java Shuffle.java $(cat results/seeds.txt)' > results/java.txt
docker run --rm -v "$PWD":/w -w /w/dotnet mcr.microsoft.com/dotnet/sdk:10.0 sh -c 'dotnet run -c Release -- $(cat ../results/seeds.txt) 2>/dev/null' > results/dotnet.txt
cmp results/python.txt results/java.txt && cmp results/python.txt results/dotnet.txt
python3 uniformity.py
```

## Stall check

```sh
docker run --rm -v "$PWD":/w -w /w eclipse-temurin:25-jdk \
  java -Xss64m docs/planning/rfc-0001/spikes/stall-check/StallCheck.java data/wordlist/game-words.txt 102 0
```

Arguments: word list, number of games (the first 2 warm up the JIT and aren't measured), first game number.

## Concurrency

```sh
cd docs/planning/rfc-0001/spikes/concurrency
curl -sSfL -o postgresql.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.14/postgresql-42.7.14.jar
docker network create spike-net
docker run -d --name spike-pg --network spike-net -e POSTGRES_PASSWORD=spike -e POSTGRES_DB=spike postgres:18
for mode in lock version; do for games in 1 1000; do
  docker run --rm --network spike-net -v "$PWD":/w -w /w eclipse-temurin:25-jdk \
    java -cp postgresql.jar Concurrency.java "jdbc:postgresql://spike-pg/spike?user=postgres&password=spike" $mode $games 32 15
done; done
docker rm -f spike-pg && docker network rm spike-net
```

Arguments: JDBC URL, `lock` or `version`, number of games, client threads, seconds.
