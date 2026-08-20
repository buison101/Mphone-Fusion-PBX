import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: shadowBody

    property int scale: 1
    property string bodyColor: "transparent"
    property string shadowColor: "black"

    radius: 8 * scale
    color: bodyColor
    layer.enabled: true

    layer.effect: DropShadow {
        id: menuShadow
        visible: parent.visible
        anchors.fill: shadowBody
        radius: 14
        samples: 28
        transparentBorder: true
        color: shadowColor
        smooth: true
        source: shadowBody
    }
}
