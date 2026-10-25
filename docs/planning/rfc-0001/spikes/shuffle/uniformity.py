"""Chi-squared check that each tile kind is equally likely at positions 0, 50 and 100."""
import sys
from collections import Counter
from shuffle import draw_order, COUNTS

N = 200_000
expected = {**COUNTS, "?": 3}
for pos in (0, 50, 100):
    seen = Counter(draw_order(g)[pos] for g in range(N))
    chi2 = sum((seen[k] - N * c / 101) ** 2 / (N * c / 101) for k, c in expected.items())
    # 26 degrees of freedom (27 kinds); the 99.9th percentile of chi-squared(26) is 54.05
    print(f"position {pos}: chi-squared = {chi2:.1f} (26 d.f.; < 54.05 passes at p = 0.001)")
