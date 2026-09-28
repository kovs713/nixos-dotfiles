// Run: node model-sync.test.mjs
//
// The check for core/ModelSync, which is the reconcile three services used to
// each write for themselves. What it has to get right is not the arithmetic --
// it is which ListModel calls it makes, because every avoided set() is a
// delegate that is not destroyed and rebuilt for nothing.
import { lift } from './lift.mjs';
import assert from 'node:assert/strict';

// A ListModel stand-in that records what it was asked to do. The real one is a
// C++ type and cannot be instantiated here; what matters is the call sequence.
function makeModel(rows = []) {
    return {
        rows: rows.map((r) => ({ ...r })),
        calls: [],
        get count() { return this.rows.length; },
        get(i) { return this.rows[i]; },
        remove(i) { this.calls.push(['remove', i]); this.rows.splice(i, 1); },
        insert(i, item) { this.calls.push(['insert', i]); this.rows.splice(i, 0, { ...item }); },
        move(from, to, n) {
            this.calls.push(['move', from, to, n]);
            const moved = this.rows.splice(from, n);
            this.rows.splice(to, 0, ...moved);
        },
        set(i, item) { this.calls.push(['set', i]); this.rows[i] = { ...item }; },
    };
}

const sync = lift('core/ModelSync.qml');
const run = (model, items, freeze) => {
    model.calls = [];
    sync.sync(model, items, 'id', freeze);
    return model;
};

// --- an empty model takes everything, in order -----------------------------
{
    const m = makeModel();
    run(m, [{ id: 'a', n: 1 }, { id: 'b', n: 2 }, { id: 'c', n: 3 }]);
    assert.deepStrictEqual(m.calls.map((c) => c[0]), ['insert', 'insert', 'insert']);
    assert.deepStrictEqual(m.rows.map((r) => r.id), ['a', 'b', 'c']);
}

// --- an identical poll writes nothing at all -------------------------------
// This is the whole point of differs(): a 30s tick that finds nothing new must
// not touch the model, or every delegate is destroyed and rebuilt for nothing.
{
    const m = makeModel([{ id: 'a', n: 1 }, { id: 'b', n: 2 }]);
    run(m, [{ id: 'a', n: 1 }, { id: 'b', n: 2 }]);
    assert.deepStrictEqual(m.calls, [], 'an unchanged poll must make no calls');
}

// --- one changed field is enough to justify the write ----------------------
{
    const m = makeModel([{ id: 'a', n: 1 }, { id: 'b', n: 2 }]);
    run(m, [{ id: 'a', n: 1 }, { id: 'b', n: 99 }]);
    assert.deepStrictEqual(m.calls, [['set', 1]]);
    assert.strictEqual(m.rows[1].n, 99);
}

// --- a vanished row is removed, a new one inserted -------------------------
{
    const m = makeModel([{ id: 'a' }, { id: 'b' }, { id: 'c' }]);
    run(m, [{ id: 'b' }, { id: 'd' }]);
    // a and c both went, so two removals, back to front.
    assert.deepStrictEqual(m.calls.map((c) => c[0]), ['remove', 'remove', 'insert']);
    assert.deepStrictEqual(m.rows.map((r) => r.id), ['b', 'd']);
}

// --- a reorder moves rather than remove+insert -----------------------------
// A remove+insert pair would rebuild the delegate and lose its scroll position.
{
    const m = makeModel([{ id: 'a' }, { id: 'b' }]);
    run(m, [{ id: 'b' }, { id: 'a' }]);
    assert.deepStrictEqual(m.calls.filter((c) => c[0] === 'move').length, 1);
    assert.ok(!m.calls.some((c) => c[0] === 'remove' || c[0] === 'insert'));
    assert.deepStrictEqual(m.rows.map((r) => r.id), ['b', 'a']);
}

// --- frozen: new rows go in at the end, nothing moves ----------------------
// What NetworkService wants while its popup polls at 2Hz: a row under the
// pointer must not slide out from under it.
{
    const m = makeModel([{ id: 'a' }, { id: 'b' }]);
    run(m, [{ id: 'b' }, { id: 'a' }, { id: 'c' }], true);
    assert.ok(!m.calls.some((c) => c[0] === 'move'), 'frozen must not move');
    assert.deepStrictEqual(m.calls.filter((c) => c[0] === 'insert'), [['insert', 2]]);
    assert.deepStrictEqual(m.rows.map((r) => r.id), ['a', 'b', 'c']);
}

// --- frozen still removes and still updates --------------------------------
{
    const m = makeModel([{ id: 'a', n: 1 }, { id: 'b', n: 2 }]);
    run(m, [{ id: 'a', n: 5 }], true);
    assert.deepStrictEqual(m.calls, [['remove', 1], ['set', 0]]);
    assert.deepStrictEqual(m.rows, [{ id: 'a', n: 5 }]);
}

// --- every row gone --------------------------------------------------------
{
    const m = makeModel([{ id: 'a' }, { id: 'b' }, { id: 'c' }]);
    run(m, []);
    assert.strictEqual(m.count, 0);
    // Removed back to front, so the earlier removals do not shift later indices.
    assert.deepStrictEqual(m.calls.map((c) => c[1]), [2, 1, 0]);
}

console.log('ok — all assertions passed');
