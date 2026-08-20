import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property alias message: msg.text
    property var onYesAction: function func() {}
    property var onNoAction: function func() {}
    property var onCancelAction: function func() {}
    property int buttonsOffset: 10

    title: StringStorage.appTitle

    flags: {
        return AppFeatures.osType == OSType.Unix ?
                    (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowStaysOnTopHint)
                  : (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint)
    }

    modality: Qt.WindowModal

    minimumWidth: width
    minimumHeight: height

    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

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

    Shortcut {
        enabled: visible
        sequence: "Esc"

        onActivated: {
            root.onCancelAction();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor
        clip: true

        Label {
            id: msg

            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: yes.left
            anchors.right: cancel.right
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        SettingsButton {
            id: cancel

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: (root.width - yes.width - no.width - cancel.width - 2 * buttonsOffset) / 2

            text: qsTrId("dialog_button_cancel") + Translator.translate

            onClicked: {
                root.onCancelAction();
            }
        }

        SettingsButton {
            id: no

            anchors.verticalCenter: cancel.verticalCenter
            anchors.right: cancel.left
            anchors.rightMargin: buttonsOffset

            text: qsTrId("dialog_button_no") + Translator.translate

            onClicked: {
                root.onNoAction();
            }
        }

        SettingsButton {
            id: yes

            anchors.verticalCenter: no.verticalCenter
            anchors.right: no.left
            anchors.rightMargin: buttonsOffset

            text: qsTrId("dialog_button_yes") + Translator.translate

            onClicked: {
                root.onYesAction();
            }
        }
    }
}
