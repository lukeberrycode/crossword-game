// Concurrency spike (PLAY-7, PLAY-8, PLAY-11, PSCORE-4): many parallel plays, with the game
// rules reduced to what matters for consistency. Compares a row lock on the game (pessimistic)
// with a version check and retry (optimistic).
// Usage: java -cp postgresql.jar Concurrency.java <jdbc url> <mode: lock|version> <games> <threads> <seconds>
import java.sql.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

public class Concurrency {
    static String url; static boolean lock; static int games, threads, seconds;
    static final int PLAYERS = 200;
    static final AtomicLong accepted = new AtomicLong(), refusedScore = new AtomicLong(), refusedStale = new AtomicLong(), retries = new AtomicLong(), vanished = new AtomicLong(), gaveUp = new AtomicLong();
    static final ConcurrentLinkedQueue<Long> latencies = new ConcurrentLinkedQueue<>();

    public static void main(String[] a) throws Exception {
        url = a[0]; lock = a[1].equals("lock"); games = Integer.parseInt(a[2]); threads = Integer.parseInt(a[3]); seconds = Integer.parseInt(a[4]);
        try (Connection c = DriverManager.getConnection(url)) { setUp(c); }
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        long end = System.nanoTime() + seconds * 1_000_000_000L;
        List<Future<?>> fs = new ArrayList<>();
        for (int t = 0; t < threads; t++) {
            int id = t;
            fs.add(pool.submit(() -> { client(id, end); return null; }));
        }
        try { for (Future<?> f : fs) f.get(); } finally { pool.shutdownNow(); }
        long[] l = latencies.stream().mapToLong(Long::longValue).sorted().toArray();
        double secs = seconds;
        System.out.printf("mode=%s games=%d threads=%d seconds=%d%n", lock ? "row lock" : "version check + retry", games, threads, seconds);
        System.out.printf("plays handled %.0f/s (accepted %d, refused: score not higher %d, history changed %d), retries %d (beaten turn vanished %d), gave up after 5 s %d%n",
            l.length / secs, accepted.get(), refusedScore.get(), refusedStale.get(), retries.get(), vanished.get(), gaveUp.get());
        System.out.printf("latency p50 %.1f ms, p95 %.1f ms, p99 %.1f ms, max %.1f ms%n",
            l[l.length / 2] / 1e6, l[(int) (l.length * .95)] / 1e6, l[(int) (l.length * .99)] / 1e6, l[l.length - 1] / 1e6);
        try (Connection c = DriverManager.getConnection(url)) { check(c); }
    }

    static void setUp(Connection c) throws SQLException {
        try (Statement s = c.createStatement()) {
            s.execute("DROP TABLE IF EXISTS turns, games, players, removed");
            s.execute("CREATE TABLE players (id int PRIMARY KEY, build_up bigint NOT NULL DEFAULT 0, burn_down bigint NOT NULL DEFAULT 0)");
            s.execute("CREATE TABLE games (id bigint PRIMARY KEY, version bigint NOT NULL DEFAULT 0, turns int NOT NULL DEFAULT 0)");
            // written_version: the game version at which this turn was written (for PLAY-8's staleness rule)
            s.execute("CREATE TABLE turns (game_id bigint, turn int, player int NOT NULL, score int NOT NULL, written_version bigint NOT NULL, PRIMARY KEY (game_id, turn))");
            // a log of removed turns, only so the spike can check burn-down totals afterwards
            s.execute("CREATE TABLE removed (game_id bigint, turn int, player int, score int, by_player int)");
            s.execute("INSERT INTO players (id) SELECT generate_series(0, " + (PLAYERS - 1) + ")");
            s.execute("INSERT INTO games (id) SELECT generate_series(0, " + (games - 1) + ")");
        }
    }

    record View(long version, int turns, int[] scores) {}

    static View load(Connection c, long game) throws SQLException {
        try (PreparedStatement p = c.prepareStatement("SELECT version, turns FROM games WHERE id = ?")) {
            p.setLong(1, game);
            try (ResultSet r = p.executeQuery()) {
                r.next();
                long v = r.getLong(1); int n = r.getInt(2);
                int[] sc = new int[n + 1];
                try (PreparedStatement q = c.prepareStatement("SELECT turn, score FROM turns WHERE game_id = ?")) {
                    q.setLong(1, game);
                    try (ResultSet rs = q.executeQuery()) { while (rs.next()) if (rs.getInt(1) <= n) sc[rs.getInt(1)] = rs.getInt(2); }
                }
                return new View(v, n, sc);
            }
        }
    }

    /** A player loads a game, thinks, and submits a play: usually the next turn, sometimes an attempt to beat an earlier one. */
    static void client(int id, long end) throws Exception {
        Random rnd = new Random(id);
        try (Connection c = DriverManager.getConnection(url)) {
            c.setAutoCommit(false);
            while (System.nanoTime() < end) {
                long game = rnd.nextInt(games);
                View v = load(c, game); c.commit();
                int turn = (v.turns == 0 || rnd.nextInt(5) > 0) ? v.turns + 1 : 1 + rnd.nextInt(v.turns);
                int score = 5 + rnd.nextInt(60);
                int player = rnd.nextInt(PLAYERS);
                long s = System.nanoTime();
                submit(c, game, turn, v.version, player, score);
                latencies.add(System.nanoTime() - s);
            }
        }
    }

    static void spin(long nanos) { long t = System.nanoTime() + nanos; while (System.nanoTime() < t) Thread.onSpinWait(); }

    static void submit(Connection c, long game, int turn, long seenVersion, int player, int score) throws SQLException {
        long deadline = System.nanoTime() + 5_000_000_000L;
        while (true) {
            if (System.nanoTime() > deadline) { c.rollback(); gaveUp.incrementAndGet(); return; }
            try {
                // 1. read the game (locked, or as of now)
                long version; int turns;
                try (PreparedStatement p = c.prepareStatement("SELECT version, turns FROM games WHERE id = ?" + (lock ? " FOR UPDATE" : ""))) {
                    p.setLong(1, game);
                    try (ResultSet r = p.executeQuery()) { r.next(); version = r.getLong(1); turns = r.getInt(2); }
                }
                // 2. PLAY-8: refuse if any turn before this one was written after the version the player saw
                try (PreparedStatement p = c.prepareStatement("SELECT coalesce(max(written_version), 0) FROM turns WHERE game_id = ? AND turn < ?")) {
                    p.setLong(1, game); p.setInt(2, turn);
                    try (ResultSet r = p.executeQuery()) { r.next(); if (r.getLong(1) > seenVersion || turn > turns + 1) { c.rollback(); refusedStale.incrementAndGet(); return; } }
                }
                // 3. validate the play and run the stall check: about 2 ms of CPU (the stall check's p95 is 1.3 ms)
                spin(2_000_000);
                // 4. PLAY-7: a played turn must be beaten by a strictly higher score
                Map<Integer, Long> lose = new TreeMap<>(); long burned = 0;
                if (turn <= turns) {
                    int recorded;
                    try (PreparedStatement p = c.prepareStatement("SELECT score FROM turns WHERE game_id = ? AND turn = ?")) {
                        p.setLong(1, game); p.setInt(2, turn);
                        try (ResultSet r = p.executeQuery()) {
                            // Without a lock, another play may have removed this turn since step 1: a conflict, so retry.
                            if (!r.next()) { c.rollback(); retries.incrementAndGet(); vanished.incrementAndGet(); continue; }
                            recorded = r.getInt(1);
                        }
                    }
                    if (score <= recorded) { c.rollback(); refusedScore.incrementAndGet(); return; }
                    try (PreparedStatement p = c.prepareStatement("DELETE FROM turns WHERE game_id = ? AND turn >= ? RETURNING turn, player, score")) {
                        p.setLong(1, game); p.setInt(2, turn);
                        try (ResultSet r = p.executeQuery(); PreparedStatement log = c.prepareStatement("INSERT INTO removed VALUES (?, ?, ?, ?, ?)")) {
                            while (r.next()) {
                                lose.merge(r.getInt(2), (long) r.getInt(3), Long::sum); burned += r.getInt(3);
                                log.setLong(1, game); log.setInt(2, r.getInt(1)); log.setInt(3, r.getInt(2)); log.setInt(4, r.getInt(3)); log.setInt(5, player); log.addBatch();
                            }
                            log.executeBatch();
                        }
                    }
                }
                // 5. bump the version (optimistic mode: only if no one else has)
                try (PreparedStatement p = c.prepareStatement("UPDATE games SET version = version + 1, turns = ? WHERE id = ? AND version = ?")) {
                    p.setInt(1, turn); p.setLong(2, game); p.setLong(3, version);
                    if (p.executeUpdate() == 0) { c.rollback(); retries.incrementAndGet(); continue; }
                }
                try (PreparedStatement p = c.prepareStatement("INSERT INTO turns VALUES (?, ?, ?, ?, ?)")) {
                    p.setLong(1, game); p.setInt(2, turn); p.setInt(3, player); p.setInt(4, score); p.setLong(5, version + 1); p.executeUpdate();
                }
                // 6. PSCORE-4: scores in the same transaction, players updated in id order to avoid deadlocks
                lose.merge(player, (long) -score, Long::sum);
                try (PreparedStatement p = c.prepareStatement("UPDATE players SET build_up = build_up - ?, burn_down = burn_down + ? WHERE id = ?")) {
                    for (var e : lose.entrySet()) {
                        p.setLong(1, e.getValue()); p.setLong(2, e.getKey() == player ? burned : 0); p.setInt(3, e.getKey()); p.addBatch();
                    }
                    p.executeBatch();
                }
                c.commit(); accepted.incrementAndGet(); return;
            } catch (SQLException e) {
                c.rollback();
                if (!"40P01".equals(e.getSQLState()) && !"40001".equals(e.getSQLState())) throw e;
                retries.incrementAndGet();
            }
        }
    }

    static void check(Connection c) throws SQLException {
        String[][] checks = {
            {"build-up = surviving turns, per player",
             "SELECT count(*) FROM players p WHERE build_up <> (SELECT coalesce(sum(score), 0) FROM turns t WHERE t.player = p.id)"},
            {"burn-down = turns removed, per player",
             "SELECT count(*) FROM players p WHERE burn_down <> (SELECT coalesce(sum(score), 0) FROM removed r WHERE r.by_player = p.id)"},
            {"each game's turns are numbered 1..n with no gaps",
             "SELECT count(*) FROM games g WHERE turns <> (SELECT count(*) FROM turns t WHERE t.game_id = g.id) OR turns <> coalesce((SELECT max(turn) FROM turns t WHERE t.game_id = g.id), 0)"},
            {"no turn was written after its game's current version",
             "SELECT count(*) FROM turns t JOIN games g ON g.id = t.game_id WHERE t.written_version > g.version"},
        };
        for (String[] ch : checks) {
            try (Statement s = c.createStatement(); ResultSet r = s.executeQuery(ch[1])) {
                r.next();
                System.out.printf("check: %-50s %s%n", ch[0], r.getLong(1) == 0 ? "OK" : "FAILED (" + r.getLong(1) + " rows)");
            }
        }
    }
}
