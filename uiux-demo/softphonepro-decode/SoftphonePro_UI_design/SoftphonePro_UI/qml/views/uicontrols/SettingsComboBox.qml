import QtQuick 2.15
import QtQuick.Controls 2.15


ComboBox {
    id: control

    width: 170
    height: 30

    property int listViewMaxWidth: 500
    property int listViewMaxHeight: 300
    property int listViewMinHeight: 0

    font.pixelSize: 11

    contentItem: Text {
        leftPadding: 10
        rightPadding: control.indicator.width + control.spacing

        text: control.displayText
        font: control.font

        color: "#26282a"
        opacity: enabled ? 1 : 0.3

        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 10
        height: 6
        contextType: "2d"

        onPaint: {
            context.reset();
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.lineTo(width / 2, height);
            context.closePath();
            context.fillStyle = "gray"
            context.fill();
        }
    }

    background: Rectangle {
        implicitWidth: control.width
        implicitHeight: control.height
        opacity: enabled ? 1 : 0.3

        color: {
            if(!enabled){
                return "#e0e0e0"
            }
            if (down || parent.activeFocus) {
                return "#bdbdbd"
            }
            return "#e0e0e0"
        }

    }
    enabled: popup.contentItem.model.count > 1

    popup: Popup {
        y: control.height
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            id: lv
            clip: true
            implicitHeight: {
                if(listViewMinHeight != 0) {
                    return listViewMinHeight
                }

                if(contentHeight > listViewMaxHeight) {
                    scrollBar.policy = ScrollBar.AlwaysOn
                }

                return Math.min(contentHeight, listViewMaxHeight)
            }
            model: control.delegateModel
            currentIndex: control.highlightedIndex

            implicitWidth: {
                var max = 0
                for(var child in contentItem.children) {
                    max = Math.max(max, contentItem.children[child].implicitWidth)

                }
                return Math.max(Math.min(listViewMaxWidth, max), control.width)
            }

            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
                policy: ScrollBar.AlwaysOff
            }
        }

        background: Rectangle {
            border.color: "black"
            radius: 1
        }
    }
}
