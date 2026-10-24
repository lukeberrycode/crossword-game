"""Tests for scripts/build_wordlist.py and the word lists it reads.

Run with: python3 -m unittest discover tests
"""
import importlib.util
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("build_wordlist", ROOT / "scripts" / "build_wordlist.py")
build_wordlist = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(build_wordlist)

HEADER = "word\tdecision\tcategory\tsource\tnote\tfor_review\n"


def game_words():
    return set(build_wordlist.read_words(build_wordlist.OUTPUT))


class GameWordListIsUpToDate(unittest.TestCase):
    """WORD-2: the committed list is what the script builds."""

    def test_committed_list_matches_a_fresh_build(self):
        expected = build_wordlist.build()
        self.assertEqual(build_wordlist.read_words(build_wordlist.OUTPUT), expected)

    def test_original_lists_are_unchanged(self):
        self.assertEqual(len(build_wordlist.read_words(build_wordlist.ENABLE)), 172823)
        self.assertEqual(len(build_wordlist.read_words(build_wordlist.LDNOOBW)), 403)


class BuildFailsWithoutReview(unittest.TestCase):
    """WORD-2: an update to either list can't slip through without a decision."""

    def build_with(self, enable, ldnoobw, decisions):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "enable.txt").write_text("\n".join(enable) + "\n")
            (tmp / "ldnoobw.txt").write_text("\n".join(ldnoobw) + "\n")
            (tmp / "decisions.tsv").write_text(HEADER + "".join(f"{w}\t{d}\t\t\t\t\n" for w, d in decisions))
            with mock.patch.multiple(
                build_wordlist,
                ENABLE=tmp / "enable.txt",
                LDNOOBW=tmp / "ldnoobw.txt",
                DECISIONS=tmp / "decisions.tsv",
            ):
                return build_wordlist.build()

    def test_blocked_words_are_removed(self):
        words = self.build_with(["cat", "dog", "rat"], ["dog"], [("dog", "block")])
        self.assertEqual(words, ["cat", "rat"])

    def test_allowed_words_are_kept(self):
        words = self.build_with(["cat", "dog"], ["dog"], [("dog", "allow")])
        self.assertEqual(words, ["cat", "dog"])

    def test_an_ldnoobw_word_in_enable_without_a_decision_fails(self):
        with self.assertRaises(SystemExit) as raised:
            self.build_with(["cat", "dog"], ["dog"], [])
        self.assertIn("dog: in LDNOOBW and ENABLE but has no decision", str(raised.exception))

    def test_an_ldnoobw_entry_not_in_enable_needs_no_decision(self):
        words = self.build_with(["cat"], ["two words", "dog"], [])
        self.assertEqual(words, ["cat"])

    def test_a_decision_for_a_word_not_in_enable_fails(self):
        with self.assertRaises(SystemExit) as raised:
            self.build_with(["cat"], [], [("dgo", "block")])
        self.assertIn("dgo: has a decision but is not in ENABLE", str(raised.exception))

    def test_an_unknown_decision_fails(self):
        with self.assertRaises(SystemExit) as raised:
            self.build_with(["cat"], [], [("cat", "maybe")])
        self.assertIn("cat: unknown decision 'maybe'", str(raised.exception))


class ExclusionsInTheRules(unittest.TestCase):
    """WORD-4: no capitals (proper nouns, acronyms), hyphens, apostrophes or other characters."""

    def test_every_word_is_lowercase_letters_only(self):
        bad = [w for w in game_words() if not re.fullmatch(r"[a-z]+", w)]
        self.assertEqual(bad, [])

    def test_every_word_has_at_least_two_letters(self):
        self.assertEqual([w for w in game_words() if len(w) < 2], [])


class ExactWordsOnly(unittest.TestCase):
    """WORD-7: blocking is by exact word, never by substring."""

    def test_blocked_words_are_absent(self):
        words = game_words()
        for word in ["shit", "fuck", "cunt"]:
            self.assertNotIn(word, words)

    def test_innocent_words_containing_blocked_strings_are_kept(self):
        words = game_words()
        for word in ["shitake", "shittim", "sniggers", "niggard", "pedagogue", "spoof", "sauerkraut", "aspic"]:
            self.assertIn(word, words)

    def test_each_inflection_is_decided_separately(self):
        words = game_words()
        self.assertIn("faggoting", words)
        self.assertIn("dyke", words)
        self.assertNotIn("dykey", words)


if __name__ == "__main__":
    unittest.main()
