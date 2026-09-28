// Run: node calendar.test.mjs
//
// The check for core/Calendar, the date arithmetic that used to be 50 lines
// inside a PanelWindow nobody can run headless. Wrong, it is wrong quietly: an
// off-by-one in leadingBlanks is a grid one column out on every month except the
// one you happened to look at.
//
// So this asserts boundaries rather than a typical month: a leap February, a
// 30-day month, a month that begins on Sunday, and December rolling into January.
import { lift } from './lift.mjs';
import assert from 'node:assert/strict';

const C = lift('core/Calendar.qml');

const jan1 = new Date(2026, 0, 1);   // a Thursday
const jan = new Date(2026, 0, 1);
const feb2026 = new Date(2026, 1, 1);   // 28 days, starts on a Sunday
const feb2024 = new Date(2024, 1, 1);   // 29 days, leap
const apr = new Date(2026, 3, 1);       // 30 days
const dec = new Date(2026, 11, 1);

// --- leadingBlanks ---------------------------------------------------------
// 2026-01-01 is a Thursday, so Mon, Tue and Wed come first.
assert.strictEqual(C.leadingBlanks(jan), 3);
// February 2026 starts on a Sunday, which is the last column of a Monday-first
// grid, so it has the most blanks any month can have.
assert.strictEqual(C.leadingBlanks(feb2026), 6);
// A month starting on a Monday has none. 2026-06-01 is one.
assert.strictEqual(C.leadingBlanks(new Date(2026, 5, 1)), 0);
// 2026-08-01 is a Saturday: five columns of blanks, then the 1st.
assert.strictEqual(C.leadingBlanks(new Date(2026, 7, 1)), 5);
// 2026-03-01 is a Sunday, the other extreme from February.
assert.strictEqual(C.leadingBlanks(new Date(2026, 2, 1)), 6);

// --- monthStart is built from year+month, not by adding months -------------
// setMonth on a late date skips: Jan 31 + 1 month is Mar 3, not Feb 28.
assert.strictEqual(C.monthStart(jan, 0).getDate(), 1, 'the 1st stays the 1st');
assert.strictEqual(C.monthStart(jan, 1).getMonth(), 1, 'one month on is February');
assert.strictEqual(C.monthStart(jan, -1).getMonth(), 11, 'one month back is December');
assert.strictEqual(C.monthStart(jan, 12).getFullYear(), 2027, 'twelve on is next January');
assert.strictEqual(C.monthStart(jan, -1).getFullYear(), 2025, 'twelve back is last December');
assert.strictEqual(C.monthStart(jan, 12).getDate(), 1, 'and still the 1st');
// A 31st cannot skip a month when the target is built this way.
assert.strictEqual(C.monthStart(new Date(2026, 0, 31), 1).getDate(), 1);

// --- monthStart is not the same as setMonth -------------------------------
// The failure this avoids, stated as a fact rather than a comment: setMonth on
// the 31st of January lands on the 3rd of March, because February has no 31st
// and Date rolls over rather than clamping.
const rollover = new Date(2026, 0, 31);
rollover.setMonth(rollover.getMonth() + 1);
assert.notStrictEqual(rollover.getDate(), 1, 'setMonth really does skip');

// --- daysInMonth -----------------------------------------------------------
assert.strictEqual(C.daysInMonth(jan), 31);
assert.strictEqual(C.daysInMonth(feb2026), 28, '2026 is not a leap year');
assert.strictEqual(C.daysInMonth(feb2024), 29, '2024 is');
assert.strictEqual(C.daysInMonth(apr), 30);
assert.strictEqual(C.daysInMonth(dec), 31);
assert.strictEqual(C.daysInMonth(new Date(2000, 1, 1)), 29, '2000 was a leap year');
assert.strictEqual(C.daysInMonth(new Date(1900, 1, 1)), 28, '1900 was not');

// --- dayFor ----------------------------------------------------------------
assert.strictEqual(C.dayFor(jan, 0), 0, 'before the first');
assert.strictEqual(C.dayFor(jan, 3), 1, 'the first sits after three blanks');
assert.strictEqual(C.dayFor(jan, 33), 31, 'the last');
assert.strictEqual(C.dayFor(jan, 34), 0, 'after the last');
assert.strictEqual(C.dayFor(feb2026, 6), 1, 'a month starting on Sunday has six blanks');
assert.strictEqual(C.dayFor(feb2026, 6 + 28 - 1), 28);
assert.strictEqual(C.dayFor(feb2026, 6 + 28), 0);
// Feb 2024 also starts on a Thursday, so three blanks, and the 29th is real.
assert.strictEqual(C.leadingBlanks(feb2024), 3);
assert.strictEqual(C.dayFor(feb2024, 3 + 29 - 1), 29, 'the leap day is a real day');
assert.strictEqual(C.dayFor(feb2024, 3 + 29), 0, 'and 30 March does not exist');
// Every month lays its days out contiguously, with no gap and no repeat.
for (let m = 0; m < 12; m++) {
    const start = new Date(2026, m, 1);
    const blanks = C.leadingBlanks(start);
    const days = C.daysInMonth(start);
    const seen = [];
    for (let i = 0; i < C.cellCount; i++) {
        const d = C.dayFor(start, i);
        if (d !== 0) seen.push(d);
    }
    assert.deepStrictEqual(seen, Array.from({ length: days }, (_, k) => k + 1),
        new Date(2026, m, 1).toDateString() + ' lays out its days once each');
    assert.ok(blanks + days <= C.cellCount, 'a month always fits in six rows');
}

// --- isWeekend -------------------------------------------------------------
// Monday-first, so column 5 is Saturday and column 6 is Sunday.
assert.strictEqual(C.isWeekend(0), false);
assert.strictEqual(C.isWeekend(4), false, 'Friday');
assert.strictEqual(C.isWeekend(5), true, 'Saturday');
assert.strictEqual(C.isWeekend(6), true, 'Sunday');
assert.strictEqual(C.isWeekend(7), false, 'the next Monday');
assert.strictEqual(C.isWeekend(13), true, 'and it repeats every seven');

// --- isToday ---------------------------------------------------------------
assert.ok(C.isToday(jan, jan1, 1), 'the first of the month shown, viewed on the first');
assert.ok(!C.isToday(jan, jan1, 2));
assert.ok(!C.isToday(jan, jan1, 0), 'a padding cell is never today');
assert.ok(!C.isToday(feb2026, jan1, 1), 'a day number from another month is not today');
assert.ok(C.isToday(feb2026, new Date(2026, 1, 14), 14), 'mid-month, same month');
assert.ok(!C.isToday(feb2026, new Date(2026, 1, 14), 15));

// --- the grid is always six rows, and always full enough -------------------
assert.strictEqual(C.cellCount, 42, 'six rows of seven');
assert.strictEqual(C.columns, 7);

console.log('ok — all assertions passed');
