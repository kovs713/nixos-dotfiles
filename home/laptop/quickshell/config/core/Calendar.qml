pragma Singleton

import QtQml

// Calendar
//
// The date arithmetic behind the calendar popup: which month is shown, how many
// blanks precede the first, how many days the month has, and which cell holds
// which day.
//
// It was 50 lines inside CalendarPopup.qml, a PanelWindow that cannot be
// exercised headless, and it is the kind of code that is wrong quietly: an
// off-by-one in leadingBlanks shows up as a grid that is one column out, on
// every month except the one you happened to check. calendar.test.mjs asserts
// the boundaries -- a leap February, a 30-day month, a month that starts on
// Sunday, and December rolling into January -- which is the only way to tell
// this is right without paging through a year by eye.
//
// Everything is Monday-first, because that is what the grid's first column is.
// getDay() is Sunday-first, so the shift is done once, here, rather than at every
// comparison.
QtObject {
    id: root

    // Always 6 rows, so the card does not change height as you page between a
    // 28-day February and a 31-day March. Five would be enough for most months
    // and would be wrong twice a year.
    readonly property int cellCount: 42

    readonly property int columns: 7

    // The first day of the month `offset` months from `from`, at midnight.
    //
    // Built from the year and month rather than by adding months to a Date: setMonth
    // on the 31st of January lands on the 3rd of March, and the 1st is what makes
    // that impossible.
    function monthStart(from, offset) {
        const base = new Date(from.getFullYear(), from.getMonth(), 1);

        base.setMonth(base.getMonth() + (offset || 0));

        return base;
    }

    // Weekday index of the 1st, Monday = 0.
    function leadingBlanks(viewDate) {
        const first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);

        // getDay(): 0 = Sunday. Shift so Monday = 0.
        return (first.getDay() + 6) % 7;
    }

    // Day 0 of the next month is the last day of this one.
    function daysInMonth(viewDate) {
        return new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate();
    }

    // Day number in a cell, or 0 for a padding cell. 0 is what the grid renders
    // as blank, so it has to be a value no real day can take.
    function dayFor(viewDate, index) {
        const day = index - root.leadingBlanks(viewDate) + 1;

        if (day < 1 || day > root.daysInMonth(viewDate))
            return 0;

        return day;
    }

    // A column is Saturday or Sunday.
    function isWeekend(index) {
        const col = index % root.columns;

        return col === 5 || col === 6;
    }

    // Whether a day cell is today. False for a padding cell, which is why the
    // day number is checked first rather than compared.
    function isToday(viewDate, now, day) {
        if (day <= 0)
            return false;

        return viewDate.getFullYear() === now.getFullYear()
            && viewDate.getMonth() === now.getMonth()
            && day === now.getDate();
    }
}
