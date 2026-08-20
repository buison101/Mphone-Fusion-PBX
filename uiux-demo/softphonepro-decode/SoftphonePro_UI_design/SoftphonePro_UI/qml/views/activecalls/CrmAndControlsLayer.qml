import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"
import "../utils"

Item {
    id: root
    focus: true

    implicitHeight: {
        if (!crmBorderVisible) {
            return controlsBorder.height;
        }

        else if (crmBorderVisible) {
            return controlsBorder.height + crmBorder.height + 10;
        }

        return 150 * SettingsState.scale;
    }

    property string name: ""
    property string company: ""
    property string crm: ""
    property string link: ""
    property string number: ""
    property bool focusToLastItem: false
    property var forceFocusOnFirstItem: function() {
        if (activeFocus){
            if (AppState.activeCall) {
                if (AppState.activeCall.status != SipCall.Conference) {
                    if (focusToLastItem) {
                        if (sendMessageButton.enabled) {
                            sendMessageButton.forceActiveFocus();
                        }
                    } else {
                        if (callTransferButton.enabled) {
                            callTransferButton.forceActiveFocus();
                        }
                    }
                }
            } else {
                if (focusToLastItem) {
                    if (sendMessageButton.enabled) {
                        sendMessageButton.forceActiveFocus();
                    }
                } else {
                    if (playButton.enabled) {
                        playButton.forceActiveFocus();
                    } else if (sendMessageButton.enabled) {
                        sendMessageButton.forceActiveFocus();
                    }
                }
            }
        }
    }


    readonly property string colorDefault: ColorStorage.surfaceSecondary //black: #242424
    readonly property string colorOnHover: ColorStorage.secondaryWindowBackground // black: #171717
    readonly property string colorOnPress: ColorStorage.grayNeutral //white: "#D9D9D9"//black: #3B3B3B

    property alias status: status.text
    property alias duration: duration.text

    property alias statusElement: status
    property alias durationElement: duration

    property bool crmBorderVisible
    property bool volumeSliderVisible: currentCallStatus == SipCall.Answered ? true : false

    property int currentCallId
    property int currentCallStatus
    property int currentCallAccountId

    property int toolTipDelay: 1000

    Rectangle {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.implicitHeight


        color: ColorStorage.mainWindowBackground //black: #000000 //currentCallStatus == SipCall.Answered || currentCallStatus == SipCall.Finished ? "#0070c7" : root.colorDefault

        radius: 8 * SettingsState.scale

        Rectangle {
            id: crmBorder

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            visible: crmBorderVisible
            height: 58 * SettingsState.scale
            color: ColorStorage.surfaceSecondary //black: #242424

            radius: 8 * SettingsState.scale

            Rectangle {
                id: imageBorder

                anchors.top: parent.top
                anchors.left: parent.left

                width: 58 * SettingsState.scale
                height: 58 * SettingsState.scale

                visible: crmBorder.visible

                color: "transparent"

                Image {
                    id: image

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    width: 32 * SettingsState.scale
                    height: 32 * SettingsState.scale
                    visible: false

                    sourceSize.width: width
                    sourceSize.height: height

                    source: "qrc:/images/account_circle.svg"
                }

                IconShader {
                    imageSrcComponent: image

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    imgColor: ColorStorage.iconsAndTextSecondary //white: "#707070" //black" #ACACAC
                    imageWidth: image.width
                    imageHeight: image.height
                }
            }

            Rectangle {
                id: infoBorder

                width: parent.width - imageBorder.width
                height: 53 * SettingsState.scale

                anchors.top: parent.top
                anchors.left: imageBorder.right

                visible: crmBorder.visible

                color: "transparent"

                property int crmNameLeftMargin: 5 * SettingsState.scale
                property int crmNameRightMargin: 5 * SettingsState.scale

                Text {
                    id: firstName

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 11 * SettingsState.scale
                    anchors.right: parent.right
                    anchors.rightMargin: 20 * SettingsState.scale

                    elide: Text.ElideRight

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF

                    text: root.name
                }

                Text {
                    id: companyName

                    property int maxWidth: parent.width - crmName.implicitWidth - parent.crmNameLeftMargin - parent.crmNameRightMargin - 6 * SettingsState.scale;
                    anchors.top: firstName.bottom
                    anchors.topMargin: 1 * SettingsState.scale
                    anchors.left: parent.left

                    elide: Text.ElideRight

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: "#ACACAC"
                    text: root.company

                    width: implicitWidth > maxWidth ? maxWidth : implicitWidth
                }

                Text {
                    id: crmName

                    anchors.verticalCenter: companyName.verticalCenter
                    anchors.left: companyName.right
                    anchors.leftMargin: companyName.width == 0 ? 0 * SettingsState.scale : parent.crmNameLeftMargin
                    anchors.right: parent.right
                    anchors.rightMargin: parent.crmNameRightMargin

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: "#ACACAC"
                    text: root.crm
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    crmBorder.color = root.colorOnHover;
                }

                onExited: {
                    crmBorder.color = root.colorDefault;
                }

                onPressed: {
                    crmBorder.color = root.colorOnPress;
                }

                onReleased: {
                    if (containsMouse && link.length != 0) {
                        Qt.openUrlExternally(root.link);
                        crmBorder.color = root.colorOnHover;
                        return;
                    }

                    crmBorder.color = root.colorDefault;
                }
            }
        }

        Rectangle {
            id: controlsBorder

            height: slider.visible ? 80 * SettingsState.scale : 50 * SettingsState.scale

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            radius: 8 * SettingsState.scale

            color: "transparent"

            VolumeSlider {
                id: slider

                anchors.verticalCenter: micOnButton.verticalCenter
                anchors.right: micOnButton.left
                anchors.left: parent.left
                anchors.leftMargin: 14 * SettingsState.scale

                sliderWidth: 253

                visible: volumeSliderVisible

                tooltipText: qsTrId("volume_button_tooltip") + Translator.translate

                imageMicOff: "qrc:/images/volume_off_white.svg"
                imageMicLow:"qrc:/images/volume_low_white.svg"
                imageMicMedium: "qrc:/images/volume_medium_white.svg"
                imageMicHigh: "qrc:/images/volume_high_white.svg"

                colorBeforeHandle:  ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                colorAfterHandle: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageColor: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC

                sliderSize: 10 * SettingsState.scale

                imgWidth: 26 * SettingsState.scale
                imgHeight: 26 * SettingsState.scale
            }

            SquareButton {
                id: micOnButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsMicOnButton"

                scale: SettingsState.scale

                anchors.bottom: playButton.top
                anchors.bottomMargin: 11 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: 14 * SettingsState.scale

                enabled: {
                    return SettingsState.muteMicrophoneDevice == true;
                }

                visible: enabled && volumeSliderVisible

                Shortcut {
                    enabled: micOnButton.enabled
                    sequence: "Ctrl+M"

                    onActivated: {
                        micOnButton.doWorkOnButtonClick();
                    }
                }

                width: 21 * SettingsState.scale
                height: width

                radius: width / 2

                colorDefault: body.color

                imageWidth: 26 * SettingsState.scale
                imageHeight: 26 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                imageColorOnHover: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                imageColorOnPress: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC

                imageDefault: "qrc:/images/microphone_off_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.muteMicrophone(false);

                    if (micOnButton.activeFocus) {
                        micOffButton.forceActiveFocus();
                    }
                }

                tooltipText: qsTrId("mic_on_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: micOffButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsMicOffButton"

                scale: SettingsState.scale

                anchors.verticalCenter: micOnButton.verticalCenter
                anchors.horizontalCenter: micOnButton.horizontalCenter

                enabled: !micOnButton.enabled
                visible: enabled && volumeSliderVisible

                Shortcut {
                    enabled: micOffButton.enabled
                    sequence: "Ctrl+M"

                    onActivated: {
                        micOffButton.doWorkOnButtonClick();
                    }
                }

                width: 21 * SettingsState.scale
                height: width

                radius: width / 2

                colorDefault: body.color

                imageWidth: 26 * SettingsState.scale
                imageHeight: 26 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                imageColorOnHover: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                imageColorOnPress: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC

                imageDefault: "qrc:/images/microphone_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.muteMicrophone(true);

                    if (micOffButton.activeFocus) {
                        micOnButton.forceActiveFocus();
                    }
                }

                tooltipText: qsTrId("mic_off_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            Text {
                id: status

                anchors.top: playButton.top
                anchors.topMargin: -1 * SettingsState.scale
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                height: 12 * SettingsState.scale

                color: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
            }

            Text {
                id: duration

                anchors.top: status.bottom
                anchors.topMargin: 3 * SettingsState.scale
                anchors.left: status.left

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            }

            SquareButton {
                id: sendMessageButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsSendMessageButton"

                scale: SettingsState.scale

                KeyNavigation.backtab: {
                    if (startRecordCallButton.enabled) {
                        return startRecordCallButton;
                    } else if (stopRecordCallButton.enabled)
                        return stopRecordCallButton;
                    else if (playButton.enabled){
                        return playButton;
                    } else {
                        return null;
                    }
                }

                anchors.top: playButton.top
                anchors.right: {
                    if (startRecordCallButton.visible || stopRecordCallButton.visible) {
                        return startRecordCallButton.left;
                    }

                    if (addToConferenceButton.visible) {
                        return addToConferenceButton.left;
                    }

                    return playButton.left;
                }
                anchors.rightMargin: 8 * SettingsState.scale

                enabled: !AppFeatures.hideMessagingWindow && SettingsState.messagingEnable && (root.number != "")
                visible: enabled

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageWidth: 18 * SettingsState.scale
                imageHeight: 18 * SettingsState.scale

                imageDefault: "qrc:/images/message_button_default.svg"

                tooltipText: qsTrId("message_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay

                doWorkOnButtonClick: function() {
                    if (SettingsState.compactWindowMode) {
                        ActionProvider.showCompactWindowMode(false);
                    }
                    ActionProvider.showMessagingWindow(true);
                    ActionProvider.changeMessagingWindowFocusToInput();
                    ActionProvider.sendMessageNumberFromUi(root.number);
                }
            }

            SquareButton {
                id: startRecordCallButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsStartRecordCallButton"

                scale: SettingsState.scale

                KeyNavigation.backtab: playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton

                anchors.top: playButton.top
                anchors.right: playPrerecordedFileButton.enabled || stopPrerecordedFileButton.enabled ? playPrerecordedFileButton.left : addToConferenceButton.left
                anchors.rightMargin: 8 * SettingsState.scale

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: AppState.activeCall && !AppState.disableCallRecordingControl && !stopRecordCallButton.enabled
                visible: currentCallStatus != SipCall.OnHold && enabled

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 14 * SettingsState.scale
                imageHeight: 14 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/record_rec.svg"

                onVisibleChanged: {
                    if (visible) {
                        startRecordCallButton.forceActiveFocus();
                    }
                }

                doWorkOnButtonClick: function() {
                    ActionProvider.continueRecordCall(currentCallId);
                    stopRecordCallButton.forceActiveFocus();
                }

                tooltipText: qsTrId("start_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: stopRecordCallButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsStopRecordCallButton"

                scale: SettingsState.scale

                KeyNavigation.backtab: playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton

                anchors.top: playButton.top
                anchors.right: playPrerecordedFileButton.enabled || stopPrerecordedFileButton.enabled ? playPrerecordedFileButton.left : addToConferenceButton.left
                anchors.rightMargin: 8 * SettingsState.scale

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: AppState.activeCall && !AppState.disableCallRecordingControl &&
                            (AppState.activeCall.recordingStatus == RecordStatus.GlobalStarted ||
                            AppState.activeCall.recordingStatus == RecordStatus.ManualStarted)
                visible: currentCallStatus != SipCall.OnHold && enabled

                colorDefault: ColorStorage.selectedControlDefault
                colorOnHover: ColorStorage.selectedControlOnHover
                colorOnPress: ColorStorage.sSizeButtonOnPress
                colorOnDisabled: ColorStorage.sSizeButtonDisabled

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 14 * SettingsState.scale
                imageHeight: 14 * SettingsState.scale

                imageColorDefault: ColorStorage.red //white: "#F01D00" //black: #F01D00
                imageColorOnHover: ColorStorage.red //white: "#F01D00" //black: #F01D00
                imageColorOnPress: ColorStorage.red //white: "#F01D00" //black: #F01D00
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/record_rec.svg"

                onVisibleChanged: {
                    if (visible) {
                        stopRecordCallButton.forceActiveFocus();
                    }
                }

                doWorkOnButtonClick: function() {
                    ActionProvider.pauseRecordCall(currentCallId);
                    startRecordCallButton.forceActiveFocus();
                }

                tooltipText: qsTrId("stop_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }


            SquareButton {
                id: playPrerecordedFileButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsPlayPrerecordedFileButton"

                scale: SettingsState.scale

                KeyNavigation.tab: stopRecordCallButton.enabled ? stopRecordCallButton : startRecordCallButton
                KeyNavigation.backtab: addToConferenceButton

                anchors.top: playButton.top
                anchors.right: addToConferenceButton.left
                anchors.rightMargin: 8 * SettingsState.scale

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: !stopPrerecordedFileButton.enabled && AppState.activeCall && AppState.activeCall.status == SipCall.Answered && !AppFeatures.hidePrerecordedAudio
                visible: enabled && currentCallStatus != SipCall.OnHold

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 17 * SettingsState.scale
                imageHeight: 17 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/play_default.svg"

                PlayPrerecordedFilePopup {
                    id: playPrerecordedFilePopup
                    alwaysOnTop: true
                }

                doWorkOnButtonClick: function() {
                    var point = playPrerecordedFileButton.mapToGlobal(width / 2, height / 2);

                    playPrerecordedFilePopup.x = point.x;
                    playPrerecordedFilePopup.y = point.y;

                    playPrerecordedFilePopup.open();
                    playPrerecordedFilePopup.forceActiveFocus();
                }

                tooltipText: qsTrId("play_prerecorded_file_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: stopPrerecordedFileButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsStopPrerecordedFileButton"

                scale: SettingsState.scale

                KeyNavigation.tab: stopRecordCallButton.enabled ? stopRecordCallButton : startRecordCallButton
                KeyNavigation.backtab: addToConferenceButton

                anchors.top: playButton.top
                anchors.right: addToConferenceButton.left
                anchors.rightMargin: 8 * SettingsState.scale

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: AppState.prerecordedFilePlayStatus && AppState.activeCall && AppState.activeCall.status == SipCall.Answered && !AppFeatures.hidePrerecordedAudio
                visible: enabled && currentCallStatus != SipCall.OnHold

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 17 * SettingsState.scale
                imageHeight: 17 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/stop_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.stopPrerecordedFile();
                }

                tooltipText: qsTrId("stop_prerecorded_file_button_tooltip") + Translator.translate
            }

            SquareButton {
                id: addToConferenceButton

                Accessible.role: Accessible.Button
                Accessible.name: "AddToConferenceButton"

                KeyNavigation.tab: playPrerecordedFileButton.enabled ? playPrerecordedFileButton : stopPrerecordedFileButton
                KeyNavigation.backtab: callTransferButton

                scale: SettingsState.scale

                anchors.top: playButton.top
                anchors.right: callTransferButton.left
                anchors.rightMargin: 8 * SettingsState.scale

                enabled: AppState.activeCall && (currentCallStatus === SipCall.Answered || currentCallStatus === SipCall.OnHold)
                visible: AppState.activeCall

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 17 * SettingsState.scale
                imageHeight: 17 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/conference_add_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.addCallToConference(currentCallId);
                }

                tooltipText: qsTrId("add_to_conference_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: callTransferButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsCallTransferButton"
                KeyNavigation.tab: addToConferenceButton
                KeyNavigation.backtab: null
                scale: SettingsState.scale

                anchors.right: playButton.right
                anchors.top: playButton.top

                enabled: AppState.activeCall
                visible: enabled

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 16 * SettingsState.scale
                imageHeight: 16 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/phone_forward_default.svg"

                MulticallTransferPopup {
                    id: callTransferPopup
                    alwaysOnTop: true

                    currentActiveCallId: currentCallId
                    currentAccountId: currentCallAccountId
                }

                doWorkOnButtonClick: function() {
                    var point = callTransferButton.mapToGlobal(width / 2, height / 2);

                    callTransferPopup.x = point.x;
                    callTransferPopup.y = point.y;

                    callTransferPopup.open();
                    callTransferPopup.forceActiveFocus();
                }

                tooltipText: qsTrId("transfer_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: playButton

                Accessible.role: Accessible.Button
                Accessible.name: "CrmAndControlsPlayButton"

                scale: SettingsState.scale

                anchors.right: parent.right
                anchors.rightMargin: 16 * SettingsState.scale
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16 * SettingsState.scale

                KeyNavigation.tab: {
                    if (AppState.activeCall) {
                        return startRecordCallButton.enabled ? startRecordCallButton : stopRecordCallButton;
                    } else {
                        return sendMessageButton;
                    }
                }

                enabled: !AppState.activeCall && AppState.callRecord && SettingsState.showPlayRecordButton
                visible: !AppState.activeCall

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale
                KeyNavigation.backtab: null

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 17 * SettingsState.scale
                imageHeight: 17 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/play_default.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.startPlayRecord(AppState.callRecord.name);
                }

                tooltipText: qsTrId("play_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }
        }
    }
}
