import QtQuick
import QtQuick.Layouts

import "../core" as Core
import "../services" as Services

// Brightness (bar module)

Core.BarButton {
    id: root

    implicitWidth: 58
    implicitHeight: Core.Theme.moduleHeight

    readonly property int level: Services.BrightnessService.level

    // No popup: the wheel and the click are the whole control, and there is
    // nothing to configure behind it.
    onPrimary: function () {
        Services.BrightnessService.step(true);
    }
    onScrolled: function (delta) {
        if (delta !== 0)
            Services.BrightnessService.step(delta > 0);
    }

    RowLayout {
        anchors.centerIn: parent

        spacing: 5

        Text {
            // Ramps with the level instead of showing the same sun at 5% and at 100%.
            text: Core.Icons.forBrightness(Services.BrightnessService.fraction)

            font.family: Core.Theme.iconFont

            font.pixelSize: Core.Theme.iconSize

            color: Core.Theme.accent
        }

        Text {
            text: root.level + "%"

            font.family: Core.Theme.fontFamily

            font.pixelSize: Core.Theme.fontSize

            font.weight: Font.Medium

            color: Core.Theme.foreground

            renderType: Text.QtRendering
        }
    }

}
