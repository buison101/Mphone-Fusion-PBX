import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0

import "../activecalls"
import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root
    enum Buttons {
        Root,
        HangupButton,
        HoldButton,
        UnholdButton,
        CallVolumeButton,
        MicOnButton,
        MicOffButton,
        CallTransferButton,
        AdditionalButton,
        SendMessageButton,
        ExternalEventButton,
        DialButton,
        StartRecordCallButton,
        StopRecordCallButton,
        PlayPrerecordedFileButton
    }

    KeyNavigation.tab: callHangupButton
    KeyNavigation.backtab: additionalButton

    property int selectedFocus : FloatingWindow.Buttons.Root

    function forceFocusOnLastItem(){
        switch(selectedFocus) {
            case FloatingWindow.Buttons.Root:
                root.focus = true
                break
            case FloatingWindow.Buttons.HangupButton:
                callHangupButton.focus = true;
                break;
            case FloatingWindow.Buttons.HoldButton:
                holdButton.focus = true;
                break;
            case FloatingWindow.Buttons.UnholdButton:
                unholdButton.focus = true;
                break;
            case FloatingWindow.Buttons.CallVolumeButton:
                callVolumeButtonLoader.forceActiveFocus();
                break;
            case FloatingWindow.Buttons.MicOnButton:
                micOnButton.focus = true;
                break;
            case FloatingWindow.Buttons.MicOffButton:
                micOffButton.focus = true;
                break;
            case FloatingWindow.Buttons.CallTransferButton:
                callTransferButton.focus = true;
                break;
            case FloatingWindow.Buttons.AdditionalButton:
                additionalButton.focus = true;
                break;
            case FloatingWindow.Buttons.SendMessageButton:
                sendMessageButton.focus = true;
                break;
            case FloatingWindow.Buttons.ExternalEventButton:
                externalEventButton.focus = true;
                break;
            case FloatingWindow.Buttons.DialButton:
                dialButton.focus = true;
                break;
            case FloatingWindow.Buttons.StartRecordCallButton:
                startRecordCallButton.focus = true;
                break;
            case FloatingWindow.Buttons.StopRecordCallButton:
                stopRecordCallButton.focus = true;
                break;
            case FloatingWindow.Buttons.PlayPrerecordedFileButton:
                playPrerecordedFileButton.focus = true;
                break;
        }
    }

    focus: true

    property int expandedHeight: 119 * SettingsState.scale
    property int normalHeight: 79 * SettingsState.scale

    width: 455 * SettingsState.scale
    height: normalHeight

    property int toolTipDelay: 1000

    Formatter {
        id: fmt
    }

    Rectangle {
        width: parent.width
        height: parent.height

        color: ColorStorage.secondaryWindowBackground

        CallInfoLayer {
            id: callInfo

            anchors.top: parent.top
            anchors.left: parent.left

            width: 0 * SettingsState.scale
            height: 0 * SettingsState.scale
        }

        SoftphonePro.SquareButton {
            id: callDirectionButton

            scale: SettingsState.scale
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            radius: 0
            width: 23 * scale
            height: parent.height

            enabled: true

            colorDefault: ColorStorage.mainWindowBackground
            colorOnPress: ColorStorage.buttonSecondaryOnPress
            colorOnHover: ColorStorage.buttonSecondaryOnHover

            imageColorDefault: ColorStorage.additionalText
            imageColorOnHover: ColorStorage.additionalText
            imageColorOnPress: ColorStorage.additionalText

            imageWidth: 24 * scale
            imageHeight: 24 * scale

            imageDefault: "qrc:/images/chevron_call_direction_down.svg"

            doWorkOnButtonClick: function() {
                ActionProvider.showMainWindowManually(true);
            }
        }

        Rectangle {
            anchors.left: callDirectionButton.right
            height: parent.height
            width: 1 * SettingsState.scale
            color: ColorStorage.mainWindowBorder
            opacity: ColorStorage.floatingWindowSeparatorOpacity
        }

        Column {
            id: remoteInfo

            anchors.bottom: callButtons.verticalCenter
            anchors.bottomMargin: displayName.contentWidth != 0 ? (displayName.height / 2) * -1 : 0
            anchors.left: callDirectionButton.right
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: callButtons.left

            TextEdit {
                id: number
                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true
                width: text.length > 0 ? parent.width : 0 * SettingsState.scale
                height: 16 * SettingsState.scale
                text: {
                    if(!AppState.activeCall) {
                        return ""
                    }
                    if((AppState.activeCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                        return SettingsState.hiddenCallerIDTemplate
                    }
                    return AppState.activeCall.remoteNumber
                }
                clip: true

                onActiveFocusChanged: {
                    forceFocusOnLastItem();
                }

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.ExtraBold
                color: ColorStorage.iconsAndTextPrimary
                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                function copyText() {
                    if (hasTextSelected()) {
                        copy();
                    } else {
                        selectAll();
                        copy();
                        deselect();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: {
                        // destroy old Menu element if it exists
                        numberLoader.sourceComponent = null;
                    }

                    onReleased: {
                        // need to save selected text because it would
                        // lost after mouse click
                        number.lastSelectionBegin = number.selectionStart
                        number.lastSelectionEnd = number.selectionEnd

                        numberLoader.sourceComponent = numberMenuComponent;

                        // restore selection
                        number.select(number.lastSelectionBegin, number.lastSelectionEnd);

                    }
                }
            }

            TextMetrics {
                id: tmDisplayName

                elide: Text.ElideRight
                elideWidth: text.length > 0 ? font.pointSize * 12 : 0
                font.family: "Segoe UI"
                text: {
                    if (!AppState.activeCall) {
                        return "";
                    }

                    if((AppState.activeCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                        return ""
                    }

                    if (AppState.activeCall.contactName.length > 0) {
                        return AppState.activeCall.contactName;
                    }

                    return AppState.activeCall.remoteDisplayName;
                }
            }

            TextEdit {
                id: displayName

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true

                width: text.length > 0 ? parent.width : 0
                height: 16 * SettingsState.scale
                text: tmDisplayName.elidedText

                font.pixelSize: 12 * SettingsState.scale

                color: ColorStorage.iconsAndTextPrimary

                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                function copyText() {
                    if (hasTextSelected()) {
                        copy();
                    } else {
                        selectAll();
                        copy();
                        deselect();
                    }
                }

                function elided(){return text !== tmDisplayName.text}

                MouseArea {
                    id: displayNameMouseArea

                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    hoverEnabled: true

                    ToolTip {
                        visible: displayNameMouseArea.containsMouse && content.text && displayName.elided()

                        delay: 1000
                        timeout: 5000
                        contentItem: Text {
                            id: content
                            text: tmDisplayName.text
                            color: ColorStorage.mainWindowBackground
                            wrapMode: Text.WordWrap
                        }

                        background: Rectangle {
                            color: ColorStorage.iconsAndTextPrimary
                        }
                    }

                    onPressed: {
                        // destroy old Menu element if it exists
                        nameLoader.sourceComponent = null;
                    }

                    onReleased: {
                        // need to save selected text because it would
                        // lost after mouse click
                        displayName.lastSelectionBegin = displayName.selectionStart
                        displayName.lastSelectionEnd = displayName.selectionEnd

                        nameLoader.sourceComponent = nameMenuComponent;

                        // restore selection
                        displayName.select(displayName.lastSelectionBegin, displayName.lastSelectionEnd);
                    }
                }
            }

            Component {
                id: numberMenuComponent

                // Menu element should be placed into Component
                // to crete every time new Menu element
                Menu {
                    id: numberMenu

                    background: Rectangle {
                        implicitWidth: 215 * SettingsState.scale
                        implicitHeight: 30 * SettingsState.scale
                        radius: 8 * SettingsState.scale
                        color: "transparent"

                        MenuShadow {
                            scale: SettingsState.scale
                            anchors.fill: parent
                            bodyColor: ColorStorage.mainWindowBackground
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        enabled: true
                        actionLabel: qsTrId("clipboard_copy") + Translator.translate
                        shortcutLabel: "Ctrl+C"

                        colorDefault: ColorStorage.mainWindowBackground
                        colorOnHover: ColorStorage.surfaceSecondary

                        topMargin: 1
                        bottomMargin: 1

                        roundCorners: true
                        onTriggered: {
                            number.copyText();
                        }
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            numberMenu.close();
                        }
                    }

                    Component.onCompleted: {
                        numberMenu.open();
                    }
                }
            }

            Loader {
                id: numberLoader
            }

            Component {
                id: nameMenuComponent

                // Menu element should be placed into Component
                // to crete every time new Menu element
                Menu {
                    id: nameMenu

                    background: Rectangle {
                        implicitWidth: 215 * SettingsState.scale
                        implicitHeight: 30 * SettingsState.scale
                        radius: 8 * SettingsState.scale
                        color: "transparent"

                        MenuShadow {
                            scale: SettingsState.scale
                            anchors.fill: parent
                            bodyColor: ColorStorage.surfaceSecondary
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        enabled: true
                        actionLabel: qsTrId("clipboard_copy") + Translator.translate
                        shortcutLabel: "Ctrl+C"

                        colorDefault: ColorStorage.mainWindowBackground
                        colorOnHover: ColorStorage.surfaceSecondary

                        topMargin: 1
                        bottomMargin: 1

                        roundCorners: true

                        onTriggered: {
                            displayName.copyText();
                        }
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            nameMenu.close();
                        }
                    }

                    Component.onCompleted: {
                        nameMenu.open();
                    }
                }
            }

            Loader {
                id: nameLoader
            }
        }

        Item {
            anchors.left: remoteInfo.left
            anchors.top: remoteInfo.bottom
            implicitWidth: remoteInfo.width
            implicitHeight: 16 * SettingsState.scale

            Text {
                id: callState
                color: ColorStorage.iconsAndTextSecondary

                font.family: "Segoe UI"
                font.pixelSize: 11 * SettingsState.scale
                height: 12 * SettingsState.scale
                text: {
                    if (!AppState.activeCall) {
                        return "";
                    }

                    return fmt.formatStatus(AppState.activeCall.status);
                }
            }

            Text {
                id: callDuration

                anchors.left: callState.right
                anchors.top: callState.top
                anchors.leftMargin: 5 * SettingsState.scale

                color: ColorStorage.iconsAndTextPrimary
                height: parent.height
                font.family: "Segoe UI"
                font.pixelSize: 12 * SettingsState.scale

                text: {
                    if (!AppState.activeCall) {
                        return "";
                    }

                    return fmt.formatDuration(AppState.timeNow - AppState.activeCall.startTime);
                }
            }
        }

        Row {
            id: callButtons

            anchors.top: parent.top
            anchors.topMargin: 31 * SettingsState.scale
            anchors.bottomMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            spacing: 8 * SettingsState.scale

            SoftphonePro.SquareButton {
                id: callHangupButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingWindowCallHangupButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                enabled: AppState.activeCall

                colorDefault: ColorStorage.red
                colorOnPress: ColorStorage.redOnHover
                colorOnHover: ColorStorage.redOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.white
                imageColorOnHover: ColorStorage.white
                imageColorOnPress: ColorStorage.white
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageDefault: "qrc:/images/phone_hangup_default.svg"

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                doWorkOnButtonClick: function() {
                    AppLogger.debug("Floating window: User clicked Hangup button");
                    if (AppState.activeCall.direction == SipCall.Conference) {
                        ActionProvider.hangupConference();
                    }
                    ActionProvider.hangupCall(AppState.activeCall.id);
                }

                KeyNavigation.tab: holdButton.enabled ? holdButton: unholdButton
                KeyNavigation.backtab: !AppState.showFloatingWindowExpanded ? additionalButton : sendMessageButton

                onActiveFocusChanged: {
                    if (callHangupButton.focus){
                        selectedFocus = FloatingWindow.Buttons.HangupButton;
                    }
                }

                tooltipText: qsTrId("hangup_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: holdButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingWindowHoldButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                enabled: AppState.activeCall && (AppState.activeCall.status == SipCall.Answered || AppState.activeCall.status == SipCall.Calling)
                visible: enabled

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageDefault: "qrc:/images/phone_hold_default.svg"

                doWorkOnButtonClick: function() {
                    if (AppState.activeCall.direction == SipCall.Conference) {
                        ActionProvider.holdConference(true);
                        return;
                    }

                    ActionProvider.holdCall(AppState.activeCall.id);

                    if (holdButton.activeFocus) {
                        unholdButton.forceActiveFocus();
                    }
                }

                KeyNavigation.tab: callVolumeButtonLoader.item
                KeyNavigation.backtab: callHangupButton

                onActiveFocusChanged: {
                    if (holdButton.focus){
                        selectedFocus = FloatingWindow.Buttons.HoldButton;
                    }
                }

                tooltipText: qsTrId("hold_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: unholdButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingWindowUnholdButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                enabled: AppState.activeCall && !holdButton.enabled
                visible: enabled

                colorDefault: ColorStorage.selectedControlDefault
                colorOnHover: ColorStorage.selectedControlOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                imageColorDefault: ColorStorage.selectedControlImageDefault
                imageColorOnHover: ColorStorage.selectedControlImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageDefault: "qrc:/images/phone_unhold_default.svg"

                doWorkOnButtonClick: function() {
                    if(AppState.activeCall.direction == SipCall.Conference){
                        ActionProvider.holdConference(false);
                        return;
                    }

                    ActionProvider.holdCall(AppState.activeCall.id);

                    if (unholdButton.activeFocus) {
                        holdButton.forceActiveFocus();
                    }
                }

                KeyNavigation.tab: callVolumeButtonLoader.item
                KeyNavigation.backtab: callHangupButton

                onActiveFocusChanged: {
                    if (unholdButton.focus){
                        selectedFocus = FloatingWindow.Buttons.UnholdButton;
                    }
                }
                tooltipText: qsTrId("unhold_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            Component {
                id: callVolumeButtonComponent

                SoftphonePro.SquareButton {
                    id: callVolumeButton

                    scale: SettingsState.scale

                    width: 32 * scale
                    height: 32 * scale
                    radius: 8 * scale

                    colorDefault: ColorStorage.sSizeButtonDefault
                    colorOnHover: ColorStorage.sSizeButtonOnHover
                    colorOnPress: ColorStorage.sSizeButtonOnPress
                    colorOnDisabled: ColorStorage.sSizeButtonDisabled

                    borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                    borderWidthDefault: 1 * scale

                    tooltipText: qsTrId("volume_button_tooltip") + Translator.translate
                    toolTipDelay: root.toolTipDelay

                    property real volumeLevelSpeakerDevice: SettingsState.volumeLevelSpeakerDevice

                    onVolumeLevelSpeakerDeviceChanged: {
                        if (volumeLevelSpeakerDevice == 0.0) {
                            callVolumeButton.state = "speakerOff";
                            return;
                        }

                        if (volumeLevelSpeakerDevice > 0.0 && volumeLevelSpeakerDevice <= 0.33) {
                            callVolumeButton.state = "speakerLow";
                            return;
                        }

                        if (volumeLevelSpeakerDevice > 0.33 && volumeLevelSpeakerDevice <= 0.66) {
                            callVolumeButton.state = "speakerMedium";
                            return;
                        }

                        if (volumeLevelSpeakerDevice > 0.66) {
                            callVolumeButton.state = "speakerHigh";
                            return;
                        }
                    }

                    imageColorDefault: ColorStorage.sSizeButtonImageDefault
                    imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                    imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                    imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                    imageWidth: 16 * scale
                    imageHeight: 16 * scale

                    imageDefault: "qrc:/images/volume_high_blue.svg"

                    states: [
                        State {
                            name: "speakerOff"

                            PropertyChanges {
                                target: callVolumeButton
                                imageDefault: "qrc:/images/volume_off_white.svg"
                                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                            }
                        },

                        State {
                            name: "speakerLow"

                            PropertyChanges {
                                target: callVolumeButton
                                imageDefault: "qrc:/images/volume_low_white.svg"
                                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                            }
                        },

                        State {
                            name: "speakerMedium"

                            PropertyChanges {
                                target: callVolumeButton
                                imageDefault: "qrc:/images/volume_medium_white.svg"
                                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                            }
                        },

                        State {
                            name: "speakerHigh"

                            PropertyChanges {
                                target: callVolumeButton
                                imageDefault: "qrc:/images/volume_high_white.svg"
                                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                            }
                        }
                    ]

                    SoftphonePro.SpeakersVolumePopup {
                        id: speakersVolumePopup
                        sliderBackgroudColor: ColorStorage.secondaryWindowBackground
                        alwaysOnTop: true
                    }

                    doWorkOnButtonClick: function() {
                        var point = callVolumeButton.mapToItem(root, width / 2, height / 2);

                        speakersVolumePopup.x = floatingWindow.x + point.x;
                        speakersVolumePopup.y = floatingWindow.y + point.y;

                        speakersVolumePopup.open();
                        speakersVolumePopup.forceActiveFocus();
                    }

                    KeyNavigation.tab: micOnButton.enabled ? micOnButton : micOffButton
                    KeyNavigation.backtab: holdButton.enabled ? holdButton: unholdButton
                }
            }

            Loader {
                id: callVolumeButtonLoader
                sourceComponent: callVolumeButtonComponent
                onActiveFocusChanged: {
                    if (callVolumeButtonLoader.focus){
                        selectedFocus = FloatingWindow.Buttons.CallVolumeButton;
                    }
                }
            }

            SoftphonePro.SquareButton {
                id: micOnButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingMicOnButton"

                scale: SettingsState.scale
                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: { return SettingsState.muteMicrophoneDevice == true; }
                visible: enabled

                Shortcut {
                    enabled: micOnButton.enabled
                    sequence: "Ctrl+M"

                    onActivated: {
                        micOnButton.doWorkOnButtonClick();
                    }
                }

                colorDefault: ColorStorage.selectedControlDefault
                colorOnHover: ColorStorage.selectedControlOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageColorDefault: ColorStorage.selectedControlImageDefault
                imageColorOnHover: ColorStorage.selectedControlImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageDefault: "qrc:/images/microphone_off_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.muteMicrophone(false);

                    if (micOnButton.activeFocus) {
                        micOffButton.forceActiveFocus();
                    }
                }

                tooltipText: qsTrId("mic_on_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                KeyNavigation.tab: callTransferButton
                KeyNavigation.backtab: callVolumeButtonLoader.item

                onActiveFocusChanged: {
                    if (micOnButton.focus) {
                        selectedFocus = FloatingWindow.Buttons.MicOnButton;
                    }
                }
            }

            SoftphonePro.SquareButton {
                id: micOffButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingMicOffButton"

                scale: SettingsState.scale
                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: !micOnButton.enabled
                visible: enabled

                Shortcut {
                    enabled: micOffButton.enabled
                    sequence: "Ctrl+M"

                    onActivated: {
                        micOffButton.doWorkOnButtonClick();
                    }
                }

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageDefault: "qrc:/images/microphone_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.muteMicrophone(true);

                    if (micOffButton.activeFocus) {
                        micOnButton.forceActiveFocus();
                    }
                }

                tooltipText: qsTrId("mic_off_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                KeyNavigation.tab: callTransferButton
                KeyNavigation.backtab: callVolumeButtonLoader.item

                onActiveFocusChanged: {
                    if (micOffButton.focus){
                        selectedFocus = FloatingWindow.Buttons.MicOffButton;
                    }
                }
            }

            SoftphonePro.SquareButton {
                id: callTransferButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingCallTransferButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageDefault: "qrc:/images/phone_forward_default.svg"

                visible: AppState.activeCall && AppState.activeCall.direction != SipCall.Conference

                SoftphonePro.MulticallTransferPopup {
                    id: multicallTransferPopup
                    alwaysOnTop: true

                    currentAccountId: AppState.activeCall.accountId
                }

                doWorkOnButtonClick: function() {
                    var point = callTransferButton.mapToItem(root, width / 2, height / 2);

                    multicallTransferPopup.x = floatingWindow.x + point.x;
                    multicallTransferPopup.y = floatingWindow.y + point.y;

                    multicallTransferPopup.open();
                    multicallTransferPopup.forceActiveFocus();
                }

                tooltipText: qsTrId("transfer_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                KeyNavigation.tab: additionalButton
                KeyNavigation.backtab: micOnButton.enabled ? micOnButton : micOffButton

                onActiveFocusChanged: {
                    if (callTransferButton.focus){
                        selectedFocus = FloatingWindow.Buttons.CallTransferButton;
                    }
                }
            }

            SoftphonePro.SquareButton {
                id: additionalButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingAdditionalButton"

                scale: SettingsState.scale

                property bool showFloatingWindowExpanded: AppState.showFloatingWindowExpanded
                onShowFloatingWindowExpandedChanged: {
                    if (!showFloatingWindowExpanded) {
                        root.height = root.normalHeight;
                        return;
                    }

                    root.height = root.expandedHeight;

                }

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageDefault: "qrc:/images/dots_horizontal_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.expandFloatingWindow(!AppState.showFloatingWindowExpanded);
                }

                tooltipText: qsTrId("additional_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                KeyNavigation.tab: {
                    if (!AppState.showFloatingWindowExpanded) {
                        return callHangupButton;
                    } else if (AppState.activeCall.status != SipCall.Calling) {
                        return playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton;
                    } else if (startRecordCallButton.enabled){
                        return startRecordCallButton;
                    } else {
                        return stopRecordCallButton;
                    }
                }
                KeyNavigation.backtab: callTransferButton

                onActiveFocusChanged: {
                    if (additionalButton.focus){
                        selectedFocus = FloatingWindow.Buttons.AdditionalButton;
                    }
                }
            }
        }

        Row {
            id: additionalCallButtons

            Accessible.role: Accessible.Button
            Accessible.name: "FloatingAdditionalCallButton"

            anchors.top: callButtons.bottom
            anchors.topMargin: 8 * SettingsState.scale
            anchors.bottom: root.bottom
            anchors.bottomMargin: 31 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 15 * SettingsState.scale

            spacing: 8 * SettingsState.scale

            visible: AppState.showFloatingWindowExpanded

            SoftphonePro.SquareButton {
                id: sendMessageButton

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                enabled: !AppFeatures.hideMessagingWindow && !AppState.activeCall.isConference && SettingsState.messagingEnable
                visible: enabled

                imageWidth: 18 * scale
                imageHeight: 18 * scale

                imageDefault: "qrc:/images/message_button_default.svg"

                tooltipText: qsTrId("message_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                doWorkOnButtonClick: function() {
                    if (SettingsState.compactWindowMode) {
                        ActionProvider.showCompactWindowMode(false);
                    }
                    ActionProvider.showMessagingWindow(true);
                    ActionProvider.changeMessagingWindowFocusToInput();
                    ActionProvider.sendMessageNumberFromUi(AppState.activeCall.remoteNumber);
                }

                KeyNavigation.tab: callHangupButton
                KeyNavigation.backtab: externalEventButton
                onActiveFocusChanged: {
                    if (sendMessageButton.focus){
                        selectedFocus = FloatingWindow.Buttons.SendMessageButton;
                    }
                }
            }

            SoftphonePro.SquareButton {
                id: externalEventButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingExternalEventButton"

                scale: SettingsState.scale

                property int buttonClickCount : AppState.externalEventButtonClickCount
                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: visible && buttonClickCount > 0
                visible: AppState.activeCall && !AppFeatures.hideExternalAppIntegration

                onVisibleChanged: {
                    if (visible)
                    ActionProvider.notifyExternalAppButtonClickCountChanged()
                }

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                imageDefault: "qrc:/images/phone_external_event_on_default.svg"

                SoftphonePro.ExternalEventPopup {
                    id: extEventPopup
                    alwaysOnTop: true
                }

                doWorkOnButtonClick: function() {
                    if (buttonClickCount < 2) {
                        ActionProvider.sendExternalAppButtonClick(AppState.activeCall.id, -1)
                    } else {
                    var point = externalEventButton.mapToItem(root, width / 2, height / 2);

                    extEventPopup.x = floatingWindow.x + point.x;
                    extEventPopup.y = floatingWindow.y + point.y;

                    extEventPopup.open();
                    extEventPopup.forceActiveFocus();
                    }
                }

                onButtonClickCountChanged: {
                    if (buttonClickCount < 1)
                        enabled = false;
                    else
                        enabled = true;
                }

                KeyNavigation.tab: sendMessageButton
                KeyNavigation.backtab: {
                    if (AppState.activeCall.status != SipCall.Calling) {
                        return dialButton;
                    } else if (startRecordCallButton.enabled) {
                        return startRecordCallButton;
                    } else {
                        return stopRecordCallButton;
                    }
                }
                onActiveFocusChanged: {
                    if (externalEventButton.focus){
                        selectedFocus = FloatingWindow.Buttons.ExternalEventButton;
                    }
                }

                tooltipText: buttonClickCount == 1 ? AppState.externalEventButtonClickTooltip : qsTrId("external_event_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: dialButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingDialButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 16 * scale
                imageHeight: 16 * scale

                visible: AppState.activeCall && AppState.activeCall.status != SipCall.Calling

                SoftphonePro.DialPadPopup {
                    id: dialPadPopup
                    alwaysOnTop: true
                    activeLoader: AppState.activeCall
                }

                doWorkOnButtonClick: function() {
                    var point = dialButton.mapToItem(root, width / 2, height / 2);

                    dialPadPopup.x = floatingWindow.x + point.x;
                    dialPadPopup.y = floatingWindow.y + point.y;

                    dialPadPopup.open();
                    dialPadPopup.forceActiveFocus();
                }

                imageDefault: "qrc:/images/dial_default.svg"

                KeyNavigation.tab: externalEventButton
                KeyNavigation.backtab: stopRecordCallButton.enabled ? stopRecordCallButton : startRecordCallButton

                onActiveFocusChanged: {
                    if (dialButton.focus){
                        selectedFocus = FloatingWindow.Buttons.DialButton;
                    }
                }

                tooltipText: qsTrId("dialpad_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: startRecordCallButton
                Accessible.role: Accessible.Button
                Accessible.name: "FloatingStartRecordingButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: !stopRecordCallButton.enabled && !AppState.disableCallRecordingControl
                visible: enabled && AppState.activeCall && AppState.activeCall.status != SipCall.OnHold

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 14 * scale
                imageHeight: 14 * scale

                imageDefault: "qrc:/images/record_rec.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.continueRecordCall(AppState.activeCall.id);
                }

                onVisibleChanged: {
                    if (visible && selectedFocus == FloatingWindow.Buttons.StopRecordCallButton) {
                        startRecordCallButton.forceActiveFocus();
                    }
                }

                KeyNavigation.tab: AppState.activeCall.status != SipCall.Calling ? dialButton : externalEventButton
                KeyNavigation.backtab: AppState.activeCall.status != SipCall.Calling ? (playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton) : additionalButton

                onActiveFocusChanged: {
                    if (startRecordCallButton.focus){
                        selectedFocus = FloatingWindow.Buttons.StartRecordCallButton;
                    } else {
                        forceFocusOnLastItem();
                    }
                }

                tooltipText: qsTrId("start_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: stopRecordCallButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingStopRecordingButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: AppState.activeCall && !AppState.disableCallRecordingControl &&
                                (AppState.activeCall.recordingStatus == RecordStatus.GlobalStarted ||
                                 AppState.activeCall.recordingStatus == RecordStatus.ManualStarted)

                visible: enabled && AppState.activeCall && AppState.activeCall.status != SipCall.OnHold

                colorDefault: ColorStorage.selectedControlDefault
                colorOnHover: ColorStorage.selectedControlOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.red
                imageColorOnHover: ColorStorage.redOnHover
                imageColorOnPress: ColorStorage.redOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                imageWidth: 14 * scale
                imageHeight: 14 * scale

                imageDefault: "qrc:/images/record_rec.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.pauseRecordCall(AppState.activeCall.id);
                }

                onVisibleChanged: {
                    if (visible && selectedFocus == FloatingWindow.Buttons.StartRecordCallButton) {
                        stopRecordCallButton.forceActiveFocus();
                    }
                }

                KeyNavigation.tab: AppState.activeCall.status != SipCall.Calling ? dialButton : externalEventButton
                KeyNavigation.backtab: AppState.activeCall.status != SipCall.Calling ? (playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton) : additionalButton

                onActiveFocusChanged: {
                    if (stopRecordCallButton.focus){
                        selectedFocus = FloatingWindow.Buttons.StopRecordCallButton;
                    }
                }

                tooltipText: qsTrId("stop_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: playPrerecordedFileButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingPlayPrerecordedFileButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: !stopPrerecordedFileButton.enabled && AppState.activeCall && AppState.activeCall.status == SipCall.Answered && !AppFeatures.hidePrerecordedAudio
                visible: enabled

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                imageWidth: 17 * scale
                imageHeight: 17 * scale

                imageDefault: "qrc:/images/play_default.svg"

                SoftphonePro.PlayPrerecordedFilePopup {
                    id: playPrerecordedFilePopup
                    alwaysOnTop: true
                }

                doWorkOnButtonClick: function() {
                    var point = playPrerecordedFileButton.mapToItem(root, width / 2, height / 2);

                    playPrerecordedFilePopup.x = floatingWindow.x + point.x;
                    playPrerecordedFilePopup.y = floatingWindow.y + point.y;

                    playPrerecordedFilePopup.open();
                    playPrerecordedFilePopup.forceActiveFocus();
                }

                KeyNavigation.tab: stopRecordCallButton.enabled ? stopRecordCallButton : startRecordCallButton
                KeyNavigation.backtab: additionalButton

                onActiveFocusChanged: {
                    if (playPrerecordedFileButton.focus){
                        selectedFocus = FloatingWindow.Buttons.PlayPrerecordedFileButton;
                    }
                }

                tooltipText: qsTrId("play_prerecorded_file_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SoftphonePro.SquareButton {
                id: stopPrerecordedFileButton

                Accessible.role: Accessible.Button
                Accessible.name: "FloatingStopPrerecordedFileButton"

                scale: SettingsState.scale

                width: 32 * scale
                height: 32 * scale
                radius: 8 * scale

                borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                borderWidthDefault: 1 * scale

                enabled: AppState.prerecordedFilePlayStatus && AppState.activeCall && AppState.activeCall.status == SipCall.Answered && !AppFeatures.hidePrerecordedAudio
                visible: enabled

                colorDefault: ColorStorage.sSizeButtonDefault
                colorOnHover: ColorStorage.sSizeButtonOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                imageColorDefault: ColorStorage.sSizeButtonImageDefault
                imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled
                imageWidth: 17 * scale
                imageHeight: 17 * scale

                imageDefault: "qrc:/images/stop_default.svg"

                KeyNavigation.tab: stopRecordCallButton.enabled ? stopRecordCallButton : startRecordCallButton
                KeyNavigation.backtab: additionalButton

                doWorkOnButtonClick: function() {
                    ActionProvider.stopPrerecordedFile();
                }

                tooltipText: qsTrId("stop_prerecorded_file_button_tooltip") + Translator.translate
            }
        }
    }
}
