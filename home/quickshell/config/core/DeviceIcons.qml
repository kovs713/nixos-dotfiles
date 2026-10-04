pragma Singleton

import QtQuick

QtObject {
    readonly property string generic: Icons.computer

    function forName(name) {
        const n = String(name || "").toLowerCase();

        if (n.length === 0)
            return generic;

        if (n.indexOf("headset") >= 0 || n.indexOf("headphone") >= 0)
            return Icons.headset;

        if (n.indexOf("speaker") >= 0 || n.indexOf("audio") >= 0)
            return Icons.speaker;

        if (n.indexOf("mouse") >= 0)
            return Icons.mouse;

        if (n.indexOf("keyboard") >= 0)
            return Icons.keyboard;

        if (n.indexOf("phone") >= 0)
            return Icons.phone;

        if (n.indexOf("gaming") >= 0 || n.indexOf("joypad") >= 0)
            return Icons.gamepad;

        if (n.indexOf("watch") >= 0 || n.indexOf("tablet") >= 0)
            return Icons.watch;

        if (n.indexOf("printer") >= 0)
            return Icons.printer;

        if (n.indexOf("camera") >= 0)
            return Icons.camera;

        if (n.indexOf("computer") >= 0 || n.indexOf("display") >= 0)
            return Icons.computer;

        return generic;
    }
}
