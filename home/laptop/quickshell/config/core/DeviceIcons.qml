pragma Singleton

import QtQuick

// DeviceIcons
//
// One resolver for "what glyph does this peripheral get", over the freedesktop
// icon name that UPower, BlueZ and NetworkManager all expose.
//
// This used to be three functions with three different answers. BatteryService
// preferred a live UPowerDeviceType enum probe and fell back to the name;
// BluetoothService matched only the name; AudioService kept its own private
// glyphs. They overlapped on ten cases and had already diverged — a bluetooth
// headset rendered as a headphone glyph in the power popup and a speaker glyph
// in the bluetooth popup, from the same icon name.
//
// Name matching only, no enum. The enum probe was best-effort ("prefer it when
// the build exposes it") and every value it could return was already covered by
// a name the freedesktop spec requires. With no test harness to exercise a live
// DBus enum, an internal seam nothing can cross is just indirection.
//
// Order matters. Freedesktop names compound, so `audio-headset` and
// `audio-headphones` are real and must reach the headset glyph — hence
// headset/headphone is matched before speaker/audio. A bare `audio` prefix
// names an audio *port*, not a headset, and lands on the speaker.

QtObject {
    // Any peripheral the table does not recognise. `computer` rather than
    // `bluetooth`, because the bluetooth popup's own glyph would be a strange
    // answer for an unknown battery device.
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
