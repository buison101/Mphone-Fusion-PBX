import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property alias message: msg.text
    property alias messageLabel: msg
    property string buttonText: qsTrId("dialog_button_ok") + Translator.translate
    property var onOKAction: function func() {}

    title: StringStorage.appTitle

    flags: {
        return AppFeatures.osType == OSType.Unix ?
                    (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowStaysOnTopHint)
                  : (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint)
    }

    minimumWidth: width
    minimumHeight: height

    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

    modality: Qt.WindowModal

    onVisibleChanged: {
        if (root.visible) {
            root.requestActivate();
        }
    }

    property bool instanceWillDestroy: AppState.instanceWillDestroy

    onInstanceWillDestroyChanged: {
        if (instanceWillDestroy) {
            root.destroy();
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Rectangle {
            anchors.fill: parent

            color: ColorStorage.settingsWindowBaseColor
            clip: true

            TextEdit {
                id: msg

                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 30
                anchors.right: parent.right
                anchors.rightMargin: 30

                font.pixelSize: 11

                wrapMode: Text.WordWrap
                readOnly: true
            }

            SettingsButton {
                id: ok

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter

                focus: true

                text: buttonText

                onClicked: {
                    root.onOKAction();
                }

                Keys.onReturnPressed: {
                    root.onOKAction();
                }

                Keys.onEnterPressed: {
                    root.onOKAction();
                }
            }
        }
    }
}
