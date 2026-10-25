// Java port of shuffle.py. Usage: java Shuffle.java <game number>...
public class Shuffle {
    static final String COUNTS = "A7B2C4D3E11F1G3H2I9J1K1L5M3N6O6P3Q1R7S9T6U3V1W1X1Y1Z1";

    static char[] tiles() {
        StringBuilder sb = new StringBuilder();
        var m = java.util.regex.Pattern.compile("([A-Z])(\\d+)").matcher(COUNTS);
        while (m.find()) sb.append(m.group(1).repeat(Integer.parseInt(m.group(2))));
        sb.append("???");
        return sb.toString().toCharArray();
    }

    static final class SplitMix64 {
        long state;
        SplitMix64(long seed) { state = seed; }
        long next() {
            state += 0x9E3779B97F4A7C15L;
            long z = state;
            z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9L;
            z = (z ^ (z >>> 27)) * 0x94D049BB133111EBL;
            return z ^ (z >>> 31);
        }
        int below(int n) {
            // limit = 2^64 - (2^64 mod n); 2^64 mod n == (2^64 - n) mod n, computed unsigned.
            long rem = Long.remainderUnsigned(-n, n);
            long limit = -rem; // 2^64 - rem, as unsigned; rem == 0 means no rejection needed
            while (true) {
                long x = next();
                if (rem == 0 || Long.compareUnsigned(x, limit) < 0) return (int) Long.remainderUnsigned(x, n);
            }
        }
    }

    static String drawOrder(long game) {
        char[] t = tiles();
        SplitMix64 rng = new SplitMix64(game);
        for (int i = t.length - 1; i > 0; i--) {
            int j = rng.below(i + 1);
            char c = t[i]; t[i] = t[j]; t[j] = c;
        }
        return new String(t);
    }

    public static void main(String[] args) {
        for (String a : args) System.out.println(a + " " + drawOrder(Long.parseUnsignedLong(a)));
    }
}
