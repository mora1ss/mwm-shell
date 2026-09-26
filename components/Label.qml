pragma ComponentBehavior: Bound

import QtQuick
import "../styles"

Text {
    property bool mono: false
    property bool small: false

    textFormat: Text.PlainText
    renderType: Text.NativeRendering
    color: Theme.text
    font.family: mono ? Theme.fontMono : Theme.fontUi
    font.pixelSize: small ? Theme.fontSizeSmall : (mono ? Theme.fontSizeMono : Theme.fontSizeUi)
    font.hintingPreference: Font.PreferVerticalHinting
    font.kerning: true
    height: Math.max(implicitHeight, font.pixelSize + 4)
}
