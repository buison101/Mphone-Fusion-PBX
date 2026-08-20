import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    property alias input: phoneInput

    property var resetFocus: function() {
        focusReceiver.focus = true;
        phoneInput.focus = false;
        callButton.focus = false;
    }

    onEnabledChanged: {
        if (enabled) {
            resetFocus();
        }
    }

    Item {
        id: focusReceiver

        anchors.top: parent.top
        anchors.left: parent.left

        width: 0 * SettingsState.scale
        height: 0 * SettingsState.scale

        focus: true

        KeyNavigation.tab: phoneInput
    }

    ClipboardInput {
        id: phoneInput

        anchors.top: parent.top
        anchors.topMargin: 20 * SettingsState.scale
        anchors.left: parent.left
        anchors.leftMargin: 20 * SettingsState.scale

        edit.text: AppState.clipboardNumber

        KeyNavigation.tab: callButton

        Keys.onReturnPressed: {
            callButton.doWorkOnButtonClick();
        }

        Keys.onEnterPressed: {
            callButton.doWorkOnButtonClick();
        }
    }

    SquareButton {
        id: callButton

        scale: SettingsState.scale

        anchors.left: phoneInput.right
        anchors.leftMargin: 15 * scale
        anchors.verticalCenter: phoneInput.verticalCenter
        anchors.verticalCenterOffset: -4

        width: 36 * SettingsState.scale
        height: 36 * SettingsState.scale

        color: ColorStorage.green
        colorOnPress: ColorStorage.greenOnPress

        imageColorDefault: "#ffffff"
        imageColorOnHover: "#ffffff"
        imageColorOnPress: "#009e16"

        imageDefault: "qrc:/images/call_default.svg"

        KeyNavigation.tab: focusReceiver

        enabled: {
            return AppState.activeCall == null;
        }

        doWorkOnButtonClick: function() {
            ActionProvider.makeCallViaClipboard(phoneInput.edit.text);
        }

        onActiveFocusChanged: {
            var lostFocus = (activeFocus == false);
            if (lostFocus) {
                root.resetFocus();
            }
        }
    }
}
