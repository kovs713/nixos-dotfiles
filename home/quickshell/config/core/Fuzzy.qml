pragma Singleton

import QtQml

QtObject {
    id: root

    readonly property string wordSeparator: "-_. /"

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

    function words(name) {
        return name.split(new RegExp("[" + root.wordSeparator + "]+")).filter(function (word) {
            return word.length > 0;
        });
    }

    function wordPrefix(name, query) {
        const parts = root.words(name);

        for (let i = 0; i < parts.length; i++) {
            if (parts[i].indexOf(query) === 0)
                return true;
        }

        return false;
    }

    function byScore(scored) {
        return scored.slice().sort(function (a, b) {
            if (a.score !== b.score)
                return b.score - a.score;

            return a.index - b.index;
        });
    }
}
