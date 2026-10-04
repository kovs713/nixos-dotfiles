pragma Singleton

import QtQml

QtObject {
    id: root

    readonly property int cellCount: 42

    readonly property int columns: 7

    function monthStart(from, offset) {
        const base = new Date(from.getFullYear(), from.getMonth(), 1);

        base.setMonth(base.getMonth() + (offset || 0));

        return base;
    }

    function leadingBlanks(viewDate) {
        const first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);

        return (first.getDay() + 6) % 7;
    }

    function daysInMonth(viewDate) {
        return new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate();
    }

    function dayFor(viewDate, index) {
        const day = index - root.leadingBlanks(viewDate) + 1;

        if (day < 1 || day > root.daysInMonth(viewDate))
            return 0;

        return day;
    }

    function isWeekend(index) {
        const col = index % root.columns;

        return col === 5 || col === 6;
    }

    function isToday(viewDate, now, day) {
        if (day <= 0)
            return false;

        return viewDate.getFullYear() === now.getFullYear()
            && viewDate.getMonth() === now.getMonth()
            && day === now.getDate();
    }
}
