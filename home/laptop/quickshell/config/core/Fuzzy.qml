pragma Singleton

import QtQml

// Fuzzy
//
// The three things both search services wrote for themselves, and which have no
// business differing between them:
//
//   - subsequence(): does the query's characters appear in order? Two
//     implementations of the same loop, one nested and one using indexOf with a
//     cursor.
//   - wordPrefix(): does any *word* of the name start with the query? Two
//     copies, and the word-splitting regexes disagreed: one included
//     whitespace in the separator class and the other did not, so a two-word
//     name like "btop copy" only ever matched on its first word in one of them.
//   - byScore(): order by score descending, ties by original position. Written
//     out twice, character for character.
//
// The tier *numbers* are not here. AppsService scores a .desktop entry against
// its name, generic name, comment and keywords; ShellService scores a Fish
// command against its name and its category. Those are different corpora tuned
// separately, and merging the ladders would mean one of them getting the other's
// weights. What they share is how a match is found and how results are ordered,
// and that is what this is.

QtObject {
    id: root

    // The characters that end a word in a name, used as a character class.
    // Whitespace is in there on purpose: "btop copy" is two words, and treating
    // it as one made the second word unmatchable from its start.
    readonly property string wordSeparator: "-_. /"

    // Every needle character, in order, somewhere in the haystack. "ffx" matches
    // "Firefox". This is the weakest tier, so it is only reached once every
    // substring test has already failed.
    function subsequence(haystack, needle) {
        if (needle.length === 0)
            return true;

        if (needle.length > haystack.length)
            return false;

        let offset = 0;

        for (let i = 0; i < needle.length; i++) {
            offset = haystack.indexOf(needle.charAt(i), offset);

            if (offset < 0)
                return false;

            offset++;
        }

        return true;
    }

    // The words of a name, lowercased. Callers pass a lowercased name already.
    function words(name) {
        return name.split(new RegExp("[" + root.wordSeparator + "]+")).filter(function (word) {
            return word.length > 0;
        });
    }

    // Whether any word starts with the query. Stronger than a plain substring
    // hit, weaker than a hit at the very start of the name: that is why it sits
    // between them in both ladders.
    function wordPrefix(name, query) {
        const parts = root.words(name);

        for (let i = 0; i < parts.length; i++) {
            if (parts[i].indexOf(query) === 0)
                return true;
        }

        return false;
    }

    // Highest first, and a tie keeps the order it came in with. The stable part
    // matters: two commands that score the same should not swap places between
    // keystrokes, or the selection moves under the cursor.
    //
    // Takes [{ score, index }] and returns a new array, sorted. The index is
    // what breaks the tie -- Array.prototype.sort is stable in modern engines,
    // but leaning on that would make the ordering depend on the JS engine.
    function byScore(scored) {
        return scored.slice().sort(function (a, b) {
            if (a.score !== b.score)
                return b.score - a.score;

            return a.index - b.index;
        });
    }
}
