import QtQuick
import QtQuick.Layouts

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    implicitWidth: 58
    implicitHeight: Core.Theme.moduleHeight

    readonly property int level: Services.BrightnessService.level

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
