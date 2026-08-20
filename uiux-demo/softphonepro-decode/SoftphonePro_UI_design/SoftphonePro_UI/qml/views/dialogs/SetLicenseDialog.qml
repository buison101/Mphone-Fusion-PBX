import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property alias key: keyField.text
    property var onOKAction: function func() {}
    property var onCancelAction: function func() {}

    title: qsTrId("dialog_license_title") + Translator.translate

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
            id: keyLabel

            anchors.top: parent.top
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.leftMargin: 20

            text: qsTrId("settings_license_key") + Translator.translate
        }

        SettingsTextField {
            id: keyField

            anchors.verticalCenter: keyLabel.verticalCenter
            anchors.left: keyLabel.right
            anchors.leftMargin: 20

            implicitWidth: 190

            Keys.onReturnPressed: {
                root.onOKAction();
            }

            Keys.onEnterPressed: {
                root.onOKAction();
            }
        }

        SettingsButton {
            id: ok

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.left: keyField.left

            text: qsTrId("dialog_button_ok") + Translator.translate

            onClicked: {
                root.onOKAction();
            }
        }

        SettingsButton {
            id: cancel

            anchors.verticalCenter: ok.verticalCenter
            anchors.left: ok.right
            anchors.leftMargin: 10

            text: qsTrId("dialog_button_cancel") + Translator.translate

            onClicked: {
                root.onCancelAction();
            }
        }
    }
}
