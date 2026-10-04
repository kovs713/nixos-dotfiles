// Run: node fuzzy.test.mjs
//
// The check for core/Fuzzy: the three primitives both search services used to
// write for themselves. AppsService and ShellService have different tier
// numbers on purpose -- they are different corpora -- so the ladder is not
// tested here. What is tested is how a match is found and how results are
// ordered, because a bug in either is invisible until the launcher feels wrong.
import { lift } from './lift.mjs';
import assert from 'node:assert/strict';

const F = lift('core/Fuzzy.qml');

// --- subsequence ----------------------------------------------------------
assert.ok(F.subsequence('firefox', 'ffx'), 'characters in order match');
assert.ok(F.subsequence('firefox', 'fox'), 'a contiguous run matches');
assert.ok(F.subsequence('firefox', 'firefox'), 'the whole string matches');
assert.ok(F.subsequence('anything', ''), 'an empty needle matches anything');
assert.ok(!F.subsequence('firefox', 'xfx'), 'out of order does not match');
assert.ok(!F.subsequence('firefox', 'firefoxx'), 'more than the haystack does not match');
assert.ok(!F.subsequence('firefox', 'chromium'), 'unrelated does not match');
// The cursor must advance past each hit, or "aa" would match a single "a".
assert.ok(!F.subsequence('a', 'aa'), 'one character cannot satisfy two');
assert.ok(F.subsequence('aa', 'aa'), 'two characters can');
// A repeated character must consume a position rather than reuse the first.
assert.ok(!F.subsequence('ab', 'aab'), 'the cursor has to move past a hit');

// --- words ----------------------------------------------------------------
// The contract is that the caller lowercases first, so these are lowercased.
assert.deepStrictEqual(F.words('btop copy'), ['btop', 'copy']);
assert.deepStrictEqual(F.words('nixos-rebuild switch'), ['nixos', 'rebuild', 'switch']);
assert.deepStrictEqual(F.words('org.gnome.nautilus'), ['org', 'gnome', 'nautilus']);
assert.deepStrictEqual(F.words('a  b'), ['a', 'b'], 'a run of separators is one gap');
assert.deepStrictEqual(F.words(''), [], 'no words in an empty name');
// The dash has to trail the separator class. Leading it, the class reads as a
// range from "." to "_" and swallows every capital letter in between, N
// included -- and `nixos-rebuild` above is the case that would break first.

// --- wordPrefix -----------------------------------------------------------
// The case that was broken in one of the two copies: whitespace was not in the
// separator class, so the second word of a two-word name could never match.
assert.ok(F.wordPrefix('btop copy', 'copy'), 'a second word must be matchable');
assert.ok(F.wordPrefix('btop copy', 'btop'), 'the first word matches');
assert.ok(F.wordPrefix('nixos-rebuild switch', 'rebuild'), 'a hyphenated word matches');
assert.ok(!F.wordPrefix('btop copy', 'op c'), 'mid-word is not a prefix');
assert.ok(!F.wordPrefix('btop copy', 'py'), 'a suffix is not a prefix');
assert.ok(!F.wordPrefix('firefox', 'fox'), 'the start of the name is handled by the caller');

// --- byScore --------------------------------------------------------------
// Highest first.
assert.deepStrictEqual(
    F.byScore([{ score: 60, index: 0 }, { score: 400, index: 1 }, { score: 200, index: 2 }])
        .map((r) => r.score),
    [400, 200, 60],
);
// A tie keeps the order it came in with, so the selection does not jump between
// keystrokes as unrelated scores shift.
assert.deepStrictEqual(
    F.byScore([{ score: 100, index: 0 }, { score: 100, index: 1 }, { score: 100, index: 2 }])
        .map((r) => r.index),
    [0, 1, 2],
);
assert.deepStrictEqual(
    F.byScore([{ score: 100, index: 1 }, { score: 100, index: 0 }]).map((r) => r.index),
    [0, 1],
);
// It does not mutate its argument: the callers build the list and then read it.
{
    const input = [{ score: 1, index: 0 }, { score: 9, index: 1 }];
    F.byScore(input);
    assert.deepStrictEqual(input.map((r) => r.score), [1, 9], 'input must not be reordered');
}
assert.deepStrictEqual(F.byScore([]), []);

console.log('ok — all assertions passed');
