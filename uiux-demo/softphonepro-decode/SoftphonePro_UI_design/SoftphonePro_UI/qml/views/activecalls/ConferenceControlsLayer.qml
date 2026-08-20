import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import Flux 1.0

import "../uicontrols"

Item {
    id: root

    implicitHeight: {
            if (!volumeSliderVisible) {
                return 50 * SettingsState.scale + conferenceBorder.implicitHeight
            }

            return 90 * SettingsState.scale + conferenceBorder.implicitHeight
        }

    property var forceFocusOnFirstItem: function() {
        if (stopRecordCallButton.enabled) {
            stopRecordCallButton.forceActiveFocus();
        } else startRecordCallButton.forceActiveFocus();
    }

    readonly property string colorDefault: ColorStorage.surfaceSecondary
    readonly property string colorOnHover: ColorStorage.grayNeutralOnHover
    readonly property string colorOnPress: ColorStorage.grayNeutralOnHover

    property alias status: status.text
    property alias duration: duration.text

    property alias statusElement: status
    property alias durationElement: duration

    property bool volumeSliderVisible: currentCallStatus == SipCall.Answered ? true : false

    property int currentCallId
    property int currentCallStatus
    property int currentCallAccountId
    property bool expandConference: AppState.expandConference
    property int toolTipDelay: 1000

    Rectangle {
        id: body

        anchors.fill: parent

        color: "transparent"

        radius: 8 * SettingsState.scale

        Rectangle {
            id: conferenceBorder

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.rightMargin: 16 * SettingsState.scale

            implicitHeight: 30 * SettingsState.scale
            color: ColorStorage.surfaceSecondary //black: #242424

            radius: 8 * SettingsState.scale

            Item {
                id: activeCallsList

                anchors.fill: parent

                Component {
                    id: rowDelegate

                    Rectangle {
                        width: parent.width
                        height: 30 * SettingsState.scale

                        color: "transparent"
                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true

                            property bool contactAreaContainsMouse: false

                            onEntered: {
                                hangupButton.visible = true;
                                removeFromConferenceButton.visible = true;
                            }

                            onExited: {
                                hangupButton.visible = false;
                                removeFromConferenceButton.visible = false;
                            }

                            Text {
                                id: contactName

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 15 * SettingsState.scale
                                anchors.right: parent.right
                                anchors.rightMargin: 54 * SettingsState.scale

                                font.pixelSize: 13 * SettingsState.scale
                                font.family: "Segoe UI"
                                font.bold: true

                                color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF

                                text: {
                                    if (!AppState.activeCall) {
                                        return "";
                                    }

                                    if((callDirection == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                                        return SettingsState.hiddenCallerIDTemplate
                                    }

                                    if (callContactName.length > 0) {
                                        return callContactName;
                                    }

                                    return callRemoteNumber;
                                }
                                elide: Text.ElideRight

                                MouseArea {
                                    id: contactNameMouseArea

                                    anchors.fill: parent

                                    acceptedButtons: Qt.NoButton

                                    onPressed: mouseArea.pressed()
                                    hoverEnabled: true

                                    ToolTip {
                                        visible: contactNameMouseArea.containsMouse && content.text && contactName.implicitWidth > contactName.width

                                        contentItem: Text {
                                            id: content
                                            text: contactName.text ? contactName.text : ""
                                            color: ColorStorage.mainWindowBackground
                                            wrapMode: Text.WordWrap
                                        }

                                        background: Rectangle {
                                            color: ColorStorage.iconsAndTextPrimary
                                        }

                                        delay: 1000
                                        timeout: 5000
                                    }
                                    onContainsMouseChanged: mouseArea.contactAreaContainsMouse = containsMouse
                                }
                            }

                            SquareButton {
                                id: hangupButton

                                Accessible.role: Accessible.Button
                                Accessible.name: "ConferenceCallHangupButton"

                                anchors.right: parent.right
                                anchors.rightMargin: 10 * SettingsState.scale
                                anchors.verticalCenter: contactName.verticalCenter

                                enabled: AppState.activeCall
                                visible: false

                                width: 22 * SettingsState.scale
                                height: 22 * SettingsState.scale

                                radius: 8 * SettingsState.scale

                                colorDefault: ColorStorage.red //white: "#F01D00" //black: #F01D00
                                colorOnHover: ColorStorage.redOnHover //white: "#C71700" //black: #C71700
                                colorOnPress: ColorStorage.redOnPress //white: "#781002" //black: #781002
                                colorOnDisabled: ColorStorage.sSizeButtonDisabled //white: "#D9D9D9" //black: #707070

                                imageWidth: 14 * SettingsState.scale
                                imageHeight: 14 * SettingsState.scale

                                imageColorDefault: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                                imageColorOnHover: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                                imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled //white: "#ACACAC" //black: #545454

                                imageDefault: "qrc:/images/phone_hangup.svg"

                                doWorkOnButtonClick: function() {
                                    ActionProvider.hangupCall(callId);
                                    AppLogger.debug("Active calls; Conference controls layer: User clicked Hangup button");
                                }

                                tooltipText: qsTrId("decline_button_tooltip") + Translator.translate
                                toolTipDelay: root.toolTipDelay
                            }

                            SquareButton {
                                id: removeFromConferenceButton

                                Accessible.role: Accessible.Button
                                Accessible.name: "RemoveFromConferenceButton"

                                anchors.verticalCenter: hangupButton.verticalCenter
                                anchors.right: hangupButton.left
                                anchors.rightMargin: 5 * SettingsState.scale

                                width: 22 * SettingsState.scale
                                height: 22 * SettingsState.scale

                                radius: 8 * SettingsState.scale

                                enabled: AppState.activeCall
                                visible: false                                

                                colorDefault: ColorStorage.mainWindowBackground //black: #000000
                                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                                borderWidthDefault: 1 * SettingsState.scale
                                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                                imageWidth: 20 * SettingsState.scale
                                imageHeight: 20 * SettingsState.scale

                                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                                imageDefault: "qrc:/images/minus_grey.svg"

                                doWorkOnButtonClick: function() {
                                    ActionProvider.removeCallFromConference(callId);
                                }

                                tooltipText: qsTrId("remove_from_conference_button_tooltip") + Translator.translate
                                toolTipDelay: root.toolTipDelay
                            }
                        }
                    }
                }

                ListView {
                    id: listview

                    anchors.fill: parent

                    focus: true
                    clip: true

                    boundsBehavior: Flickable.StopAtBounds

                    model: AppState.activeCallsInConferenceModel

                    delegate: rowDelegate

                    interactive: false

                    onCountChanged: {
                        if (expandConference || count < 3) {
                            conferenceBorder.implicitHeight = count * 30 * SettingsState.scale;
                            return;
                        }

                        conferenceBorder.implicitHeight = 60 * SettingsState.scale;
                    }
                }
            }

            SquareButton {
                id: expandConferenceButton

                Accessible.role: Accessible.Button
                Accessible.name: "ExpandConferenceButton"

                anchors.verticalCenter: parent.bottom
                anchors.horizontalCenter:  parent.horizontalCenter

                width: 40 * SettingsState.scale
                height: 15 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: !expandConference
                visible: enabled && listview.count > 2

                colorDefault: ColorStorage.mainWindowBackground //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 24 * SettingsState.scale
                imageHeight: 24 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/dots_horizontal_grey.svg"

                doWorkOnButtonClick: function() {
                    if (listview.count > 2) {
                        ActionProvider.expandConference(true);
                        conferenceBorder.implicitHeight = 30 * listview.count * SettingsState.scale;
                    }
                }
            }

            SquareButton {
                id: rollUpConferenceButton

                Accessible.role: Accessible.Button
                Accessible.name: "RollUpConferenceButton"

                anchors.verticalCenter: parent.bottom
                anchors.horizontalCenter:  parent.horizontalCenter

                width: 40 * SettingsState.scale
                height: 15 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: !expandConferenceButton.enabled
                visible: enabled && listview.count > 2

                colorDefault: ColorStorage.mainWindowBackground //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 24 * SettingsState.scale
                imageHeight: 24 * SettingsState.scale

                imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
                imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                imageDefault: "qrc:/images/menu_up_grey.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.expandConference(false);
                    conferenceBorder.implicitHeight = 60 * SettingsState.scale;
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

                sliderWidth: 253 * SettingsState.scale;

                visible: volumeSliderVisible
                tooltipText: qsTrId("volume_button_tooltip") + Translator.translate

                imageMicOff: "qrc:/images/volume_off_white.svg"
                imageMicLow:"qrc:/images/volume_low_white.svg"
                imageMicMedium: "qrc:/images/volume_medium_white.svg"
                imageMicHigh: "qrc:/images/volume_high_white.svg"

                colorBeforeHandle: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
                colorAfterHandle: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageColor: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC

                sliderSize: 10 * SettingsState.scale

                imgWidth: 26 * SettingsState.scale
                imgHeight: 26 * SettingsState.scale
            }

            SquareButton {
                id: micOnButton

                Accessible.role: Accessible.Button
                Accessible.name: "ConferenceMicOnButton"

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

                colorDefault: "transparent"

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
                Accessible.name: "ConferenceMicOffButton"

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

                borderWidth: 0 * SettingsState.scale
                borderWidthOnHover: 1 * SettingsState.scale

                colorDefault: "transparent"

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
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextSecondary //white: "#707070" //black: #ACACAC
            }

            Text {
                id: duration

                anchors.bottom: playButton.bottom
                anchors.left: status.left

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            }

            SquareButton {
                id: startRecordCallButton
                Accessible.role: Accessible.Button
                Accessible.name: "ConferenceStartRecordCallButton"
                KeyNavigation.tab: null
                anchors.top: playButton.top
                anchors.right: playButton.right

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                enabled: AppState.activeCall && !stopRecordCallButton.enabled && !AppState.disableCallRecordingControl
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
                Accessible.name: "ConferenceStopRecordCallButton"
                KeyNavigation.tab: null
                anchors.top: playButton.top
                anchors.right: playButton.right

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

                doWorkOnButtonClick: function() {
                    ActionProvider.pauseRecordCall(currentCallId);
                    startRecordCallButton.forceActiveFocus();
                }

                tooltipText: qsTrId("stop_record_button_tooltip") + Translator.translate
                toolTipDelay: root.toolTipDelay
            }

            SquareButton {
                id: playButton

                Accessible.role: Accessible.Button
                Accessible.name: "ConferencePlayButton"

                anchors.right: parent.right
                anchors.rightMargin: 16 * SettingsState.scale
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16 * SettingsState.scale

                enabled: !AppState.activeCall && AppState.callRecord && SettingsState.showPlayRecordButton
                visible: !AppState.activeCall

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                radius: 8 * SettingsState.scale

                colorDefault: "transparent" //"#FFFFFF" //black: #000000
                colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
                colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
                colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                borderWidthDefault: 1 * SettingsState.scale
                borderColorDefault: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070

                imageWidth: 24 * SettingsState.scale
                imageHeight: 24 * SettingsState.scale

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
