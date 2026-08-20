import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0
import QtQuick.Layouts 1.3

import "../activecalls"
import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    readonly property int buttonsCount: {
        var count = 1;
        count = SettingsState.displayDeclineButtonOnRingingPopup ? count + 1 : count;
        count = SettingsState.displayIgnoreButtonOnRingingPopup ? count + 1 : count;
        count = SettingsState.displayPlayPrerecordedAudioButtonOnRingingPopup ? count + 1 : count;
        count = SettingsState.displayForwardButtonOnRingingPopup ? count + 1 : count;
        return count;
    }

    implicitWidth: 364 * SettingsState.scale
    implicitHeight: {
        if (root.buttonsCount < 4) {
            return AppState.activeCall.crmInfo ? 486 * SettingsState.scale : 400 * SettingsState.scale;
        } else {
            return AppState.activeCall.crmInfo ? 542 * SettingsState.scale : 456 * SettingsState.scale;
        }
    }

    focus: true

    Formatter {
        id: fmt
    }

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

                color: ColorStorage.secondaryWindowTitleAndIcons

                text: qsTrId("incoming_call_window_title") + Translator.translate
            }
        }

        CallInfoLayer {
            id: callInfo

            anchors.top: titleLayer.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            width: 332 * SettingsState.scale
            height: 124 * SettingsState.scale

            account: AppState.activeCall ? AppState.activeCall.account + " " + AppState.activeCall.didName : ""

            number: {
                if(SettingsState.hideCallerIDForInboundCalls) {
                    return SettingsState.hiddenCallerIDTemplate
                }
                if(AppState.activeCall) {
                    return AppState.activeCall.remoteNumber
                }
                return ""
            }
            name: tmDisplayName.elidedText
            uneditedName: tmDisplayName.text
            city: AppState.activeCall ? AppState.activeCall.city : ""
            country: AppState.activeCall ? AppState.activeCall.country : ""

            status: AppState.activeCall ? fmt.formatStatus(AppState.activeCall.status) : ""
            duration: AppState.activeCall ? fmt.formatDuration(AppState.timeNow - AppState.activeCall.startTime) : ""
        }

        TextMetrics {
            id: tmDisplayName

            elide: Text.ElideRight
            elideWidth: text.length > 0 ? callInfo.implicitWidth : 0
            font.family: "Segoe UI"
            text: {
                if(!AppState.activeCall) {
                    return ""
                }

                if((AppState.activeCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                    return ""
                }

                if(AppState.activeCall.contactName) {
                    return AppState.activeCall.contactName
                }
                return AppState.activeCall.remoteDisplayName
            }
        }

        CrmInfoLayer {
            id: crmInfo

            anchors.top: callInfo.bottom
            anchors.topMargin: 30 * SettingsState.scale
            anchors.horizontalCenter: parent.horizontalCenter
            imageColorDefault: ColorStorage.additionalText
            implicitHeight: 58 * SettingsState.scale

            width: 332 * SettingsState.scale
            height: implicitHeight

            visible: {
                if (!AppState.activeCall || !AppState.activeCall.crmInfo) {
                    crmInfo.height = 0;
                    return false;
                }

                crmInfo.height = crmInfo.implicitHeight
                return true;
            }

            name: {
                if (!visible) {
                    return "";
                }

                if (!AppState.activeCall.crmInfo.name.length) {
                    return AppState.activeCall.crmInfo.company;
                }

                return AppState.activeCall.crmInfo.name;
            }

            company: {
                if (!visible) {
                    return "";
                }

                if (!AppState.activeCall.crmInfo.name) {
                    return "";
                }

                return AppState.activeCall.crmInfo.company;
            }

            crm: {
                if (!visible) {
                    return "";
                }

                if (!AppState.activeCall.crmInfo.name || !AppState.activeCall.crmInfo.company) {
                    return AppState.activeCall.crmInfo.crm;
                }

                return "(" + AppState.activeCall.crmInfo.crm + ")";
            }

            link: visible ? AppState.activeCall.crmInfo.link : ""
        }

        Item {
            id: loadingIndicator
            anchors.top: crmInfo.bottom
            anchors.topMargin: 10 * SettingsState.scale
            anchors.left: parent.left
            anchors.right: parent.right
            height: 108 * SettingsState.scale
            property int animationDuration: 400
            Column{
                anchors.centerIn: parent
                spacing: 5 * SettingsState.scale
                Repeater{
                    model: 4
                    Rectangle{
                        required property int index

                        width: 4 * SettingsState.scale
                        height: 4 * SettingsState.scale
                        radius: 20 * SettingsState.scale
                        color: ColorStorage.loadingIndicatorCircles
                        opacity: {
                            if (index == 0) {
                                return 1.0;
                            } else if (index == 1) {
                                return 0.6;
                            } else if (index == 2) {
                                return 0.4;
                            } else if (index == 3) {
                                return 0.2;
                            }
                        }

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation{
                                to: {
                                    if (index == 0) {
                                        return 0.2;
                                    } else if (index == 1) {
                                        return 1;
                                    } else if (index == 2) {
                                        return 0.6;
                                    } else if (index == 3) {
                                        return 0.4;
                                    }
                                }
                                duration: loadingIndicator.animationDuration
                            }

                            NumberAnimation{
                                to: {
                                    if (index == 0) {
                                        return 0.4;
                                    } else if (index == 1) {
                                        return 0.2;
                                    } else if (index == 2) {
                                        return 1.0;
                                    } else if (index == 3) {
                                        return 0.6;
                                    }
                                }
                                duration: loadingIndicator.animationDuration
                            }

                            NumberAnimation{
                                to: {
                                    if (index == 0) {
                                        return 0.6;
                                    } else if (index == 1) {
                                        return 0.4;
                                    } else if (index == 2) {
                                        return 0.2;
                                    } else if (index == 3) {
                                        return 1.0;
                                    }
                                }
                                duration: loadingIndicator.animationDuration
                            }

                            NumberAnimation{
                                to: {
                                    if (index == 0) {
                                        return 1.0;
                                    } else if (index == 1) {
                                        return 0.6;
                                    } else if (index == 2) {
                                        return 0.4;
                                    } else if (index == 3) {
                                        return 0.2;
                                    }
                                }
                                duration: loadingIndicator.animationDuration
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: controls

            anchors.left: crmInfo.left
            anchors.right: crmInfo.right
            anchors.top: loadingIndicator.bottom
            anchors.topMargin: 8 * SettingsState.scale
            height: root.buttonsCount < 4 ? 48 * SettingsState.scale : 104 * SettingsState.scale
            implicitWidth: crmInfo.width

            GridLayout {
                id: buttonsRow
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                rows: root.buttonsCount > 3 ? 2 : 1
                columns: 6

                columnSpacing: 8 * SettingsState.scale
                rowSpacing: 8 * SettingsState.scale

                property real buttonWidth: {
                    if (root.buttonsCount < 4) {
                        return (buttonsRow.width - buttonsRow.columnSpacing * (root.buttonsCount - 1) ) / root.buttonsCount;
                    } else {
                        if (SettingsState.displayDeclineButtonOnRingingPopup) {
                            return (buttonsRow.width - buttonsRow.columnSpacing ) / 2;
                        } else {
                            return buttonsRow.width;
                        }
                    }
                }

                property real buttonWidthSecondary: {
                    if (root.buttonsCount == 5 || root.buttonsCount == 4 && !SettingsState.displayDeclineButtonOnRingingPopup) {
                        return (buttonsRow.width - 2 * buttonsRow.columnSpacing ) / 3 ;
                    } else {
                        return buttonsRow.buttonWidth;
                    }
                }

                property int columnSpanFirstRow: {
                    if (root.buttonsCount == 1 || root.buttonsCount == 4 && !SettingsState.displayDeclineButtonOnRingingPopup) {
                        return 6;
                    } else if (root.buttonsCount == 3) {
                        return 2;
                    } else {
                        return 3;
                    }
                }

                property int columnSpanSecondRow: {
                    if (root.buttonsCount == 5 || root.buttonsCount == 4 && !SettingsState.displayDeclineButtonOnRingingPopup) {
                        return 2;
                    } else {
                        return buttonsRow.columnSpanFirstRow;
                    }
                }

                SoftphonePro.SquareButton {
                    id: answerButton

                    Accessible.role: Accessible.Button
                    Accessible.name: "IncomingAnswerButton"
                    KeyNavigation.tab: hangupButton
                    KeyNavigation.backtab: playPrerecordedFileButton
                    Layout.preferredWidth: buttonsRow.buttonWidth
                    Layout.columnSpan: buttonsRow.columnSpanFirstRow
                    Layout.preferredHeight: 48 * SettingsState.scale
                    radius: 8 * SettingsState.scale

                    colorDefault: ColorStorage.green
                    colorOnHover: ColorStorage.greenOnHover
                    colorOnPress: ColorStorage.greenOnPress
                    colorOnDisabled: ColorStorage.disabledButtonsGrey

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.white
                    imageColorOnHover: ColorStorage.white
                    imageColorOnPress: ColorStorage.white
                    imageColorOnDisabled: ColorStorage.white

                    imageDefault: "qrc:/images/call_default.svg"

                    doWorkOnButtonClick: function() {
                        if (!AppState.activeCall) {
                            return;
                        }

                        ActionProvider.answerCall(AppState.activeCall.id);
                        AppLogger.debug("Incoming window: User clicked Answer button");
                    }

                    tooltipText: qsTrId("answer_button_tooltip") + Translator.translate
                }

                SoftphonePro.SquareButton {
                    id: hangupButton

                    Accessible.role: Accessible.Button
                    Accessible.name: "IncomingHangupButton"

                    KeyNavigation.tab: callIgnore
                    KeyNavigation.backtab: answerButton
                    enabled: SettingsState.displayDeclineButtonOnRingingPopup
                    visible: SettingsState.displayDeclineButtonOnRingingPopup

                    Layout.preferredWidth: buttonsRow.buttonWidth
                    Layout.columnSpan: buttonsRow.columnSpanFirstRow
                    Layout.preferredHeight: 48 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    colorDefault: ColorStorage.red
                    colorOnHover: ColorStorage.redOnHover
                    colorOnPress: ColorStorage.redOnPress
                    colorOnDisabled: ColorStorage.textAndDisabledIconsGrey

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.white
                    imageColorOnHover: ColorStorage.white
                    imageColorOnPress: ColorStorage.white
                    imageColorOnDisabled: ColorStorage.iconsAndTextPrimary

                    imageDefault: "qrc:/images/phone_hangup_default.svg"

                    doWorkOnButtonClick: function() {
                        if (!AppState.activeCall) {
                            return;
                        }

                        ActionProvider.hangupCall(AppState.activeCall.id);
                        AppLogger.debug("Incoming window: User clicked Hangup button");
                    }

                    tooltipText: qsTrId("decline_button_tooltip") + Translator.translate
                }

                SoftphonePro.SquareButton {
                    id: callIgnore

                    Accessible.role: Accessible.Button
                    Accessible.name: "IncomingIgnoreButton"

                    KeyNavigation.tab: callTransferButton
                    KeyNavigation.backtab: hangupButton
                    enabled: SettingsState.displayIgnoreButtonOnRingingPopup
                    visible: SettingsState.displayIgnoreButtonOnRingingPopup

                    Layout.preferredWidth: buttonsRow.buttonWidthSecondary
                    Layout.columnSpan: buttonsRow.columnSpanSecondRow
                    Layout.preferredHeight: 48 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    colorDefault: ColorStorage.lSizeButtonDefault
                    colorOnHover: ColorStorage.lSizeButtonOnHover
                    colorOnPress: ColorStorage.lSizeButtonOnPress
                    colorOnDisabled: ColorStorage.disabledButtonsGrey

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.iconsAndTextPrimary
                    imageColorOnHover: ColorStorage.iconsAndTextPrimary
                    imageColorOnPress: ColorStorage.white
                    imageColorOnDisabled: ColorStorage.iconsAndTextPrimary

                    imageDefault: "qrc:/images/phone_ignore_default.svg"

                    doWorkOnButtonClick: function() {
                        if (!AppState.activeCall) {
                            return;
                        }

                        ActionProvider.ignoreCall(AppState.activeCall.id);
                        AppLogger.debug("Incoming window: User clicked Ignore button");
                    }

                    tooltipText: qsTrId("ignore_button_tooltip") + Translator.translate
                }

                SoftphonePro.SquareButton {
                    id: callTransferButton

                    Accessible.role: Accessible.Button
                    Accessible.name: "IncomingCallTransferButton"

                    KeyNavigation.tab: playPrerecordedFileButton
                    KeyNavigation.backtab: callIgnore
                    enabled: SettingsState.displayForwardButtonOnRingingPopup
                    visible: SettingsState.displayForwardButtonOnRingingPopup

                    Layout.preferredWidth: buttonsRow.buttonWidthSecondary
                    Layout.columnSpan: buttonsRow.columnSpanSecondRow
                    Layout.preferredHeight: 48 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    colorDefault: ColorStorage.lSizeButtonDefault
                    colorOnHover: ColorStorage.lSizeButtonOnHover
                    colorOnPress: ColorStorage.lSizeButtonOnPress
                    colorOnDisabled: ColorStorage.disabledButtonsGrey

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.iconsAndTextPrimary
                    imageColorOnHover: ColorStorage.iconsAndTextPrimary
                    imageColorOnPress: ColorStorage.white
                    imageColorOnDisabled: ColorStorage.iconsAndTextPrimary

                    imageDefault: "qrc:/images/phone_forward_default.svg"

                    SoftphonePro.MulticallTransferPopup {
                        id: multicallTransferPopup
                        alwaysOnTop: true
                        showTransferMethodBlock: false
                        currentAccountId: AppState.activeCall.accountId
                    }

                    doWorkOnButtonClick: function() {
                        var point = callTransferButton.mapToItem(root, width / 2, height / 2);

                        multicallTransferPopup.x = incomingWindow.x + point.x;
                        multicallTransferPopup.y = incomingWindow.y + point.y;

                        multicallTransferPopup.open();
                        multicallTransferPopup.forceActiveFocus();
                    }

                    tooltipText: qsTrId("transfer_button_tooltip") + Translator.translate
                }

                SoftphonePro.SquareButton {
                    id: playPrerecordedFileButton

                    Accessible.role: Accessible.Button
                    Accessible.name: "IncomingPlayPrerecordedFileButton"
                    KeyNavigation.tab: answerButton
                    KeyNavigation.backtab: callTransferButton

                    scale: SettingsState.scale

                    Layout.preferredWidth: buttonsRow.buttonWidthSecondary
                    Layout.columnSpan: buttonsRow.columnSpanSecondRow
                    Layout.preferredHeight: 48 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    enabled: SettingsState.displayPlayPrerecordedAudioButtonOnRingingPopup
                    visible: SettingsState.displayPlayPrerecordedAudioButtonOnRingingPopup

                    colorDefault: ColorStorage.lSizeButtonDefault
                    colorOnHover: ColorStorage.lSizeButtonOnHover
                    colorOnPress: ColorStorage.lSizeButtonOnPress
                    colorOnDisabled: ColorStorage.disabledButtonsGrey

                    imageColorDefault: ColorStorage.iconsAndTextPrimary
                    imageColorOnHover: ColorStorage.iconsAndTextPrimary
                    imageColorOnPress: ColorStorage.white
                    imageColorOnDisabled: ColorStorage.iconsAndTextPrimary
                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageDefault: "qrc:/images/phone_play.svg"

                    SoftphonePro.PlayPrerecordedFilePopup {
                        id: playPrerecordedFilePopup
                        fromIncomingWindow: true
                        alwaysOnTop: true
                    }

                    doWorkOnButtonClick: function() {
                        var point = playPrerecordedFileButton.mapToItem(root, width / 2, height / 2);

                        playPrerecordedFilePopup.x = incomingWindow.x + point.x;
                        playPrerecordedFilePopup.y = incomingWindow.y + point.y;

                        playPrerecordedFilePopup.open();
                        playPrerecordedFilePopup.forceActiveFocus();
                    }

                    tooltipText: qsTrId("play_prerecorded_file_button_tooltip_incoming") + Translator.translate
                }
            }

            Text {
                id: autoanswerLabel

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 15 * SettingsState.scale
                anchors.horizontalCenterOffset: -20

                visible: autoanswerSeconds.visible

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary

                text: qsTrId("incoming_call_autoanswer") + Translator.translate
            }

            Text {
                id: autoanswerSeconds

                anchors.left: autoanswerLabel.right
                anchors.leftMargin: 5 * SettingsState.scale
                anchors.verticalCenter: autoanswerLabel.verticalCenter

                property int milliseconds: AppState.activeCall ? AppState.activeCall.autoAnsweredTime - AppState.timeNow : 0

                visible: AppState.activeCall && AppState.activeCall.autoAnswered && milliseconds > 0

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary

                text: fmt.formatDuration(milliseconds)
            }
        }
    }
}
