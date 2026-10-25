// Stall-check spike (GAME-9, NFR-7): is there any acceptable play for a rack?
// Appel-Jacobson move generation (anchors, cross-checks, left parts) over a trie.
// Usage: java StallCheck.java <word list> <games> <seed offset>
import java.nio.file.*;
import java.util.*;

public class StallCheck {
    static final int N = 15, BLANK = 26, RACK = 15, ALL = (1 << 26) - 1;

    // ---- trie ----
    static int[] child = new int[26 * 500_000];
    static boolean[] term = new boolean[500_000];
    static int nodes = 1;

    static void insert(String w) {
        int n = 0;
        for (int i = 0; i < w.length(); i++) {
            int l = w.charAt(i) - 'a', k = n * 26 + l;
            if (child[k] == 0) {
                if (nodes == term.length) {
                    child = Arrays.copyOf(child, child.length * 2);
                    term = Arrays.copyOf(term, term.length * 2);
                }
                child[k] = nodes++;
            }
            n = child[k];
        }
        term[n] = true;
    }

    // ---- search state ----
    // board cells: -1 empty, else letter 0..25 (blanks on the board count as their letter)
    static int[][] g;
    static int[] rack;
    static int[] cross = new int[N];
    static boolean[] anchor = new boolean[N];
    static int row, anchorCol;
    static boolean countAll, found;
    static long count;

    static boolean empty(int[][] b) {
        for (int[] r : b) for (int x : r) if (x >= 0) return false;
        return true;
    }

    static int[][] transpose(int[][] b) {
        int[][] t = new int[N][N];
        for (int r = 0; r < N; r++) for (int c = 0; c < N; c++) t[c][r] = b[r][c];
        return t;
    }

    /** Returns the number of plays (countAll) or 1/0 for "any play exists". */
    static long search(int[][] board, int[] rk, boolean all) {
        rack = rk; countAll = all; found = false; count = 0;
        boolean firstMove = empty(board);
        for (int pass = 0; pass < 2 && !found; pass++) {
            g = pass == 0 ? board : transpose(board);
            for (row = 0; row < N && !found; row++) {
                computeRow(firstMove);
                for (int c = 0; c < N && !found; c++) {
                    if (!anchor[c]) continue;
                    anchorCol = c;
                    if (c > 0 && g[row][c - 1] >= 0) {
                        int s = c - 1;
                        while (s > 0 && g[row][s - 1] >= 0) s--;
                        int n = 0;
                        for (int k = s; k < c && n >= 0; k++) n = n == -1 ? -1 : next(n, g[row][k]);
                        if (n > 0 || s == c) extendRight(n, c);
                    } else {
                        int limit = 0;
                        for (int k = c - 1; k >= 0 && g[row][k] < 0 && !anchor[k]; k--) limit++;
                        leftPart(0, limit);
                    }
                }
            }
        }
        return countAll ? count : (found ? 1 : 0);
    }

    static int next(int n, int l) {
        int k = child[n * 26 + l];
        return k == 0 ? -1 : k;
    }

    static void computeRow(boolean firstMove) {
        for (int c = 0; c < N; c++) {
            anchor[c] = false;
            if (g[row][c] >= 0) continue;
            boolean up = row > 0 && g[row - 1][c] >= 0, down = row < N - 1 && g[row + 1][c] >= 0;
            boolean side = (c > 0 && g[row][c - 1] >= 0) || (c < N - 1 && g[row][c + 1] >= 0);
            anchor[c] = firstMove ? (row == 7 && c == 7) : (up || down || side);
            if (!up && !down) { cross[c] = ALL; continue; }
            int top = row;
            while (top > 0 && g[top - 1][c] >= 0) top--;
            int n = 0;
            for (int r = top; r < row && n >= 0; r++) n = next(n, g[r][c]);
            int mask = 0;
            if (n >= 0) {
                for (int l = 0; l < 26; l++) {
                    int m = next(n, l);
                    for (int r = row + 1; r < N && g[r][c] >= 0 && m >= 0; r++) m = next(m, g[r][c]);
                    if (m >= 0 && term[m]) mask |= 1 << l;
                }
            }
            cross[c] = mask;
        }
    }

    static void leftPart(int n, int limit) {
        extendRight(n, anchorCol);
        if (limit == 0 || found) return;
        for (int l = 0; l < 26 && !found; l++) {
            int m = child[n * 26 + l];
            if (m == 0) continue;
            tryTile(l, () -> leftPart(m, limit - 1));
        }
    }

    static void extendRight(int n, int c) {
        if (found) return;
        if (c == N || g[row][c] < 0) {
            if (c > anchorCol && term[n]) {
                if (countAll) count++; else { found = true; return; }
            }
            if (c == N) return;
            for (int l = 0; l < 26 && !found; l++) {
                int m = child[n * 26 + l];
                if (m == 0 || (cross[c] >> l & 1) == 0) continue;
                final int cc = c;
                g[row][c] = l;
                tryTile(l, () -> extendRight(m, cc + 1));
                g[row][c] = -1;
            }
        } else {
            int m = child[n * 26 + g[row][c]];
            if (m != 0) extendRight(m, c + 1);
        }
    }

    /** Use a real tile for letter l, or a blank. To find any play, a real tile is enough when there is one. */
    static void tryTile(int l, Runnable k) {
        boolean usedReal = false;
        if (rack[l] > 0) { rack[l]--; k.run(); rack[l]++; usedReal = true; }
        if ((countAll || !usedReal) && rack[BLANK] > 0 && !found) { rack[BLANK]--; k.run(); rack[BLANK]++; }
    }

    // ---- random play, for building realistic boards: first play found from a random anchor order ----
    static final Random RNG = new Random(1);

    /** Plays a random valid play by trying random single-row placements; returns tiles used or 0. */
    static int playRandom(int[][] board, int[] rk) {
        // Collect plays by enumerating with a cap, choosing one by reservoir sampling.
        Chooser ch = new Chooser();
        ch.run(board, rk);
        if (ch.best == null) return 0;
        for (int[] t : ch.best) { board[t[0]][t[1]] = t[2]; rk[t[3] == 1 ? BLANK : t[2]]--; }
        return ch.best.size();
    }

    static final class Chooser {
        List<int[]> best; long seen; Deque<int[]> placed = new ArrayDeque<>();
        boolean transposed; int[][] bd; int[] rk; int r, anc; int[] cr = new int[N]; boolean[] an = new boolean[N];
        static final long CAP = 20_000;

        void run(int[][] board, int[] rack) {
            rk = rack;
            boolean first = empty(board);
            for (int pass = 0; pass < 2 && seen < CAP; pass++) {
                transposed = pass == 1;
                bd = transposed ? transpose(board) : board;
                for (r = 0; r < N && seen < CAP; r++) {
                    g = bd; row = r; computeRow(first);
                    System.arraycopy(cross, 0, cr, 0, N); System.arraycopy(anchor, 0, an, 0, N);
                    for (int c = 0; c < N && seen < CAP; c++) {
                        if (!an[c]) continue;
                        anc = c;
                        if (c > 0 && bd[r][c - 1] >= 0) {
                            int s = c - 1;
                            while (s > 0 && bd[r][s - 1] >= 0) s--;
                            int n = 0;
                            for (int k = s; k < c && n >= 0; k++) n = next(n, bd[r][k]);
                            if (n >= 0) ext(n, c);
                        } else {
                            int limit = 0;
                            for (int k = c - 1; k >= 0 && bd[r][k] < 0 && !an[k]; k--) limit++;
                            left(0, limit, c - 1);
                        }
                    }
                }
            }
        }

        // Left parts are built right-to-left in squares anc-1, anc-2... so track them as a prefix string.
        void left(int n, int limit, int unused) { leftRec(n, limit, new ArrayList<>()); }

        void leftRec(int n, int limit, List<int[]> prefix) {
            int len = prefix.size();
            for (int i = 0; i < len; i++) { int[] p = prefix.get(i); placed.push(new int[]{r, anc - len + i, p[0], p[1]}); }
            ext(n, anc);
            for (int i = 0; i < len; i++) placed.pop();
            if (limit == 0 || seen >= CAP) return;
            for (int l = 0; l < 26; l++) {
                int m = child[n * 26 + l];
                if (m == 0) continue;
                for (int blank = 0; blank < 2; blank++) {
                    int key = blank == 1 ? BLANK : l;
                    if (rk[key] == 0) continue;
                    rk[key]--; prefix.add(new int[]{l, blank}); leftRec(m, limit - 1, prefix); prefix.remove(prefix.size() - 1); rk[key]++;
                }
            }
        }

        void ext(int n, int c) {
            if (seen >= CAP) return;
            if (c == N || bd[r][c] < 0) {
                if (c > anc && term[n]) {
                    seen++;
                    if (RNG.nextLong(seen) == 0) {
                        best = new ArrayList<>();
                        for (int[] p : placed) best.add(transposed ? new int[]{p[1], p[0], p[2], p[3]} : p.clone());
                    }
                }
                if (c == N) return;
                for (int l = 0; l < 26; l++) {
                    int m = child[n * 26 + l];
                    if (m == 0 || (cr[c] >> l & 1) == 0) continue;
                    for (int blank = 0; blank < 2; blank++) {
                        int key = blank == 1 ? BLANK : l;
                        if (rk[key] == 0) continue;
                        rk[key]--; bd[r][c] = l; placed.push(new int[]{r, c, l, blank});
                        ext(m, c + 1);
                        placed.pop(); bd[r][c] = -1; rk[key]++;
                    }
                }
            } else {
                int m = child[n * 26 + bd[r][c]];
                if (m != 0) ext(m, c + 1);
            }
        }
    }

    // ---- shuffle (same as spikes/shuffle) ----
    static String drawOrder(long game) {
        String counts = "A7B2C4D3E11F1G3H2I9J1K1L5M3N6O6P3Q1R7S9T6U3V1W1X1Y1Z1";
        StringBuilder sb = new StringBuilder();
        var mt = java.util.regex.Pattern.compile("([A-Z])(\\d+)").matcher(counts);
        while (mt.find()) sb.append(mt.group(1).repeat(Integer.parseInt(mt.group(2))));
        char[] t = (sb + "???").toCharArray();
        long[] st = {game};
        for (int i = t.length - 1; i > 0; i--) {
            int n = i + 1;
            long rem = Long.remainderUnsigned(-n, n), limit = -rem, x;
            do {
                st[0] += 0x9E3779B97F4A7C15L; long z = st[0];
                z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9L; z = (z ^ (z >>> 27)) * 0x94D049BB133111EBL; x = z ^ (z >>> 31);
            } while (rem != 0 && Long.compareUnsigned(x, limit) >= 0);
            int j = (int) Long.remainderUnsigned(x, n);
            char c = t[i]; t[i] = t[j]; t[j] = c;
        }
        return new String(t);
    }

    static int tileIndex(char ch) { return ch == '?' ? BLANK : ch - 'A'; }

    static long pct(long[] a, double p) { return a[Math.min(a.length - 1, (int) Math.ceil(p * a.length) - 1)]; }

    static String stats(String label, List<Long> ns) {
        long[] a = ns.stream().mapToLong(Long::longValue).sorted().toArray();
        return String.format("%-44s n=%5d  p50=%8.3f ms  p95=%8.3f ms  p99=%8.3f ms  max=%9.3f ms",
            label, a.length, pct(a, .50) / 1e6, pct(a, .95) / 1e6, pct(a, .99) / 1e6, a[a.length - 1] / 1e6);
    }

    public static void main(String[] args) throws Exception {
        long t0 = System.nanoTime();
        List<String> words = Files.readAllLines(Path.of(args[0]));
        for (String w : words) insert(w);
        System.out.printf("trie: %d words, %d nodes, built in %d ms%n", words.size(), nodes, (System.nanoTime() - t0) / 1_000_000);
        int games = Integer.parseInt(args[1]);
        long offset = Long.parseLong(args[2]);

        List<Long> exist = new ArrayList<>(), full = new ArrayList<>();
        Map<Integer, List<Long>> fullByBlanks = new TreeMap<>(), existNone = new TreeMap<>();
        List<Long> noPlay = new ArrayList<>();
        List<String> stalls = new ArrayList<>();
        int stalled = 0, completed = 0, turns = 0;
        long maxPlays = 0;
        for (int gi = 0; gi < games; gi++) {
            String order = drawOrder(offset + gi);
            int[][] board = new int[N][N];
            for (int[] r : board) Arrays.fill(r, -1);
            int[] rk = new int[27];
            int drawn = 0;
            for (; drawn < RACK; drawn++) rk[tileIndex(order.charAt(drawn))]++;
            boolean measure = gi >= 2; // first games warm the JIT
            int gameTurns = 0;
            while (true) {
                long s = System.nanoTime();
                boolean any = search(board, rk, false) == 1;
                long e = System.nanoTime() - s;
                if (measure) { exist.add(e); if (!any) noPlay.add(e); }
                if (measure && turns % 3 == 0) {
                    s = System.nanoTime();
                    long plays = search(board, rk, true);
                    long f = System.nanoTime() - s;
                    full.add(f);
                    fullByBlanks.computeIfAbsent(rk[BLANK], k -> new ArrayList<>()).add(f);
                    maxPlays = Math.max(maxPlays, plays);
                }
                if (measure) turns++;
                if (!any) {
                    Chooser check = new Chooser();
                    check.run(board, rk);
                    if (check.best != null) throw new IllegalStateException("stall check missed a play in game " + (offset + gi));
                    if (measure) {
                        stalled++;
                        StringBuilder rs = new StringBuilder();
                        for (int l = 0; l < 27; l++) rs.append(String.valueOf(l == BLANK ? '?' : (char) ('A' + l)).repeat(rk[l]));
                        stalls.add(String.format("game %d: stalled after %d turns, %d tiles left in the bag, rack %s",
                            offset + gi, gameTurns, order.length() - drawn, rs));
                    }
                    break;
                }
                int used = playRandom(board, rk);
                if (used == 0) throw new IllegalStateException("search found a play but the chooser did not");
                gameTurns++;
                for (int k = 0; k < used && drawn < order.length(); k++) rk[tileIndex(order.charAt(drawn++))]++;
                int left = 0; for (int x : rk) left += x;
                if (left == 0) { if (measure) completed++; break; }
            }
        }
        System.out.printf("games measured: %d (completed %d, stalled %d), turns measured: %d, most plays in one state: %d%n",
            games - 2, completed, stalled, turns, maxPlays);
        System.out.println(stats("any play? (the stall check)", exist));
        if (!noPlay.isEmpty()) System.out.println(stats("any play? when there was none (stalled)", noPlay));
        System.out.println(stats("every play (full enumeration, worst-case bound)", full));
        for (var en : fullByBlanks.entrySet()) System.out.println(stats("  every play, rack with " + en.getKey() + " blank(s)", en.getValue()));
        System.out.println("stalls (each confirmed by an independent enumeration):");
        stalls.forEach(x -> System.out.println("  " + x));
    }
}
