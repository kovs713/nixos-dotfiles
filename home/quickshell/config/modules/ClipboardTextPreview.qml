import QtQuick

import "../core" as Core

Flickable {
    id: root

    property string text: ""

    clip: true
    contentWidth: width
    contentHeight: Math.max(height, body.implicitHeight)
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    onTextChanged: contentY = 0

    Text {
        id: body

        width: root.width
        text: root.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap

        color: Core.Theme.foreground
        font.family: Core.Theme.fontMono
        font.pixelSize: Core.Theme.fontSizeSmall
    }
}
