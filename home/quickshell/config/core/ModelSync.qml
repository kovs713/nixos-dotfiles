pragma Singleton

import QtQml

// ModelSync
//
// Reconcile a ListModel against a freshly built array of plain objects, keyed by
// one field, so that a delegate survives a poll that changed nothing.
//
// This was open-coded three times, and the three copies had drifted:
//
//   - NetworkService had a diff guard, so it left a row alone when the incoming
//     object was field-for-field identical. BatteryService and BluetoothService
//     called set() unconditionally, on every 30s tick, on every row -- which
//     destroys and rebuilds the delegate and restarts whatever it was animating.
//   - NetworkService had a freeze, because it polls twice a second while its
//     popup is open and reordering the list under a cursor is worse than a stale
//     order. The other two have no such need.
//   - BatteryService did set() before move() where the other two did move() then
//     set().
//
// Same algorithm, three times, each with a different subset of the parts. One
// copy with the two service-specific behaviours as parameters.
//
// Two nested loops per item, so O(n*m) on a device list. That is nothing for the
// handful of rows involved and it keeps the delegates stable, which a
// clear-and-refill would not. A key->index map would be O(n) and would have to
// be rebuilt on every removal anyway, since removals shift every index after
// them.

QtObject {
    id: root

    // `freezeOrder` is for a list that is being polled faster than the user can
    // read: new rows still go in, but nothing moves, so a row under the pointer
    // stays there. Order is corrected on the next unfrozen pass.
    function sync(model, items, key, freezeOrder) {
        const frozen = freezeOrder === true;

        for (let i = model.count - 1; i >= 0; i--) {
            const existing = model.get(i)[key];
            let stillThere = false;

            for (let j = 0; j < items.length; j++) {
                if (items[j][key] === existing) {
                    stillThere = true;
                    break;
                }
            }

            if (!stillThere)
                model.remove(i);
        }

        for (let j = 0; j < items.length; j++) {
            const item = items[j];
            let found = -1;

            for (let i = 0; i < model.count; i++) {
                if (model.get(i)[key] === item[key]) {
                    found = i;
                    break;
                }
            }

            if (found === -1) {
                model.insert(frozen ? model.count : Math.min(j, model.count), item);
                continue;
            }

            if (!frozen && found !== j) {
                model.move(found, j, 1);
                found = j;
            }

            if (root.differs(model.get(found), item))
                model.set(found, item);
        }
    }

    // Whether the row's data actually changed.
    //
    // The guard that two of the three copies were missing. Without it a poll
    // that finds nothing new still writes every row, and a ListView answers a
    // write by destroying the delegate and building a new one -- so a row that
    // had not changed flickered, and any animation on it restarted from zero.
    function differs(current, incoming) {
        for (const k in incoming) {
            if (current[k] !== incoming[k])
                return true;
        }

        return false;
    }
}
