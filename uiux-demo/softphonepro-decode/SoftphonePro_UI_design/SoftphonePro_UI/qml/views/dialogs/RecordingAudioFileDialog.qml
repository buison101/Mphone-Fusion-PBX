import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property alias message: msg.text
    property alias buttonText: controlButton.text
    property var onOKAction: function func() {}

    title: qsTrId("recording_audio_file_dialog_title") + Translator.translate

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

            Label {
                id: msg

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: controlButton.top
                anchors.bottomMargin: 30
                visible: true

                wrapMode: Text.WordWrap
            }

            SettingsButton {
                id: controlButton

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter

                visible: true

                focus: true

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
