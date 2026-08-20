import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0


FocusScope {
    id: scope

    implicitWidth: dropdown.width
    implicitHeight: dropdown.height

    focus: true

    function open() {
        dropdown.open();
    }

    function close() {
        dropdown.close();
    }

    Popup {
        id: dropdown

        width: message.width
        height: message.height;

        closePolicy: Popup.NoAutoClose

        contentItem: Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: message

                width: 200 * SettingsState.scale
                height: text.implicitHeight + (10 * SettingsState.scale)

                border.color: "black"
                border.width: 1

                visible: true
                enabled: visible

                focus: true

                color: ColorStorage.iconsAndTextPrimary

                Text {
                    id: text

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8

                    font.pixelSize: 12 * SettingsState.scale
                    font.family: "Segoe UI"
                    color: ColorStorage.mainWindowBackground

                    wrapMode: Text.WordWrap

                    property int callMakeError: AppState.callMakeAccountError

                    text: {
                        switch(callMakeError) {

                        case CallMakeAccountError.UnregisteredAccount:
                            return qsTrId("call_make_unregistered_account_message") + Translator.translate;
                        }

                        return "";
                    }
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        dropdown.visible = false;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: message.enabled

                hoverEnabled: enabled

                onEntered: {
                    message.forceActiveFocus();
                }

                onReleased: {
                    dropdown.visible = false;
                }
            }
        }

        background: Rectangle {
            border.color: ColorStorage.sSizeButtonBorderDefault
            border.width: 1 * SettingsState.scale

            color: ColorStorage.surfaceSecondary
        }
    }
}
