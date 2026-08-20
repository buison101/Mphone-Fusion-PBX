import QtQuick 2.15
import QtQuick.Layouts 1.3
import Flux 1.0

FocusScope {
    id: root

    readonly property int multicalls: 0
    readonly property int multicallsEnd: 1
    readonly property int calls: 2
    readonly property int callEnd: 3
    readonly property int recordPlay: 4

    property int currentScreen: 0

    focus: true

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.secondaryWindowBackground

        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            color: ColorStorage.secondaryWindowTitleBackgroundColor
            width: parent.width
            height: 39 * SettingsState.scale

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.secondaryWindowTitleAndIcons //white: "#000000" //black: #FFFFFF

                text: qsTrId("active_calls_window_title") + Translator.translate
            }
        }

        FocusScope {
            anchors.top: titleLayer.bottom
            anchors.topMargin: 8 * SettingsState.scale
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            focus: true

            StackLayout {
                id: layout

                anchors.fill: parent

                focus: true
                currentIndex: root.currentScreen

                ScreenMulticalls {
                    id: multiCalls
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                ScreenMulticallEnd {
                    id: multiCallsEnd
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                /*ScreenRecordPlay {
                    id: recordPlay
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }*/

                onCurrentIndexChanged: {
                    layout.forceActiveFocusOnCurrentItem();
                }

                onActiveFocusChanged: {
                    if (layout.activeFocus) {
                        layout.forceActiveFocusOnCurrentItem();
                    }
                }

                function forceActiveFocusOnCurrentItem() {
                    var item = layout.children[layout.currentIndex];
                    item.forceActiveFocus();
                }
            }
        }
    }
}
