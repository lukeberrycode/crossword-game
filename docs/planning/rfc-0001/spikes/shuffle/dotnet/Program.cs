// C# port of shuffle.py. Usage: dotnet run -- <game number>...
using System.Text;
using System.Text.RegularExpressions;

foreach (var a in args) Console.WriteLine($"{a} {DrawOrder(ulong.Parse(a))}");

static string DrawOrder(ulong game)
{
    var sb = new StringBuilder();
    foreach (Match m in Regex.Matches("A7B2C4D3E11F1G3H2I9J1K1L5M3N6O6P3Q1R7S9T6U3V1W1X1Y1Z1", @"([A-Z])(\d+)"))
        sb.Append(m.Groups[1].Value[0], int.Parse(m.Groups[2].Value));
    sb.Append('?', 3);
    var t = sb.ToString().ToCharArray();
    var rng = new SplitMix64(game);
    for (int i = t.Length - 1; i > 0; i--)
    {
        int j = rng.Below(i + 1);
        (t[i], t[j]) = (t[j], t[i]);
    }
    return new string(t);
}

sealed class SplitMix64(ulong seed)
{
    ulong state = seed;
    public ulong Next()
    {
        unchecked
        {
            state += 0x9E3779B97F4A7C15UL;
            ulong z = state;
            z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL;
            z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL;
            return z ^ (z >> 31);
        }
    }
    public int Below(int n)
    {
        ulong un = (ulong)n;
        ulong rem = unchecked(0UL - un) % un;      // 2^64 mod n
        ulong limit = unchecked(0UL - rem);         // 2^64 - rem
        while (true)
        {
            ulong x = Next();
            if (rem == 0 || x < limit) return (int)(x % un);
        }
    }
}
