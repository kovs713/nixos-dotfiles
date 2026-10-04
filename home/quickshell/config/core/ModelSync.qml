pragma Singleton

import QtQml

QtObject {
    id: root

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

    function differs(current, incoming) {
        for (const k in incoming) {
            if (current[k] !== incoming[k])
                return true;
        }

        return false;
    }
}
