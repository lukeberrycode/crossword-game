"""Reference draw order: SplitMix64 seeded by the game number, then Fisher-Yates.

Usage: python3 shuffle.py <game number>...   prints one draw order per line.
"""
import sys

# Canonical tile set: letters A to Z with the approved counts, then 3 blanks (?).
COUNTS = dict(A=7, B=2, C=4, D=3, E=11, F=1, G=3, H=2, I=9, J=1, K=1, L=5, M=3,
              N=6, O=6, P=3, Q=1, R=7, S=9, T=6, U=3, V=1, W=1, X=1, Y=1, Z=1)
TILES = [c for c in sorted(COUNTS) for _ in range(COUNTS[c])] + ["?"] * 3
MASK = (1 << 64) - 1


class SplitMix64:
    def __init__(self, seed):
        self.state = seed & MASK

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

    def below(self, n):
        """Unbiased integer in [0, n): reject draws from the incomplete last block."""
        limit = (1 << 64) - ((1 << 64) % n)
        while True:
            x = self.next()
            if x < limit:
                return x % n


def draw_order(game):
    if not 0 <= game <= MASK:
        raise ValueError("game number out of range")
    tiles = TILES[:]
    rng = SplitMix64(game)
    for i in range(len(tiles) - 1, 0, -1):
        j = rng.below(i + 1)
        tiles[i], tiles[j] = tiles[j], tiles[i]
    return "".join(tiles)


if __name__ == "__main__":
    assert len(TILES) == 101
    for arg in sys.argv[1:]:
        print(arg, draw_order(int(arg)))
