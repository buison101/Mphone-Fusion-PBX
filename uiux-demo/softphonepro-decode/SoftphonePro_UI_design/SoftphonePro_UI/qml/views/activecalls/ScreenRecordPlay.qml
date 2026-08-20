import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    focus: true

    Formatter {
        id: fmt
    }

    MouseArea {
        anchors.fill: parent

        onPressed: {
            initialFocusReceiver.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: "transparent"

        Item {
            id: activeCallsList

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: controls.top

            CallInfoLayer {
                id: callInfo

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                width: 300 * SettingsState.scale
                height: 85 * SettingsState.scale

                account: AppState.callRecord ? AppState.callRecord.call.account : ""
                number: AppState.callRecord ? AppState.callRecord.call.remoteNumber : ""

                name: tmDisplayName.elidedText
                uneditedName: tmDisplayName.text

                city:  AppState.callRecord ? AppState.callRecord.call.city : ""
                country: AppState.callRecord ? AppState.callRecord.call.country : ""

                status: AppState.callRecord ? fmt.formatStatus(AppState.callRecord.call.status) : ""
                duration: AppState.callRecord ? fmt.formatDuration(AppState.callRecord.call.duration) : ""
            }

            TextMetrics {
                id: tmDisplayName

                elide: Text.ElideRight
                elideWidth: text.length > 0 ? callInfo.implicitWidth : 0
                font.family: "Segoe UI"
                text: {
                    if (!AppState.callRecord) {
                        return "";
                    }

                    if (AppState.callRecord.call.contactName.length > 0) {
                        return AppState.callRecord.call.contactName;
                    }

                    return AppState.callRecord.call.remoteDisplayName;
                }
            }

            CrmInfoLayer {
                id: crmInfo

                anchors.top: callInfo.bottom
                anchors.topMargin: 12 * SettingsState.scale
                anchors.horizontalCenter: parent.horizontalCenter

                implicitHeight: 53 * SettingsState.scale

                width: 300 * SettingsState.scale
                height: implicitHeight

                visible: {
                    if (!AppState.callRecord || !AppState.callRecord.call.crmInfo) {
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

                    if (AppState.callRecord.call.crmInfo.name.length == 0) {
                        return AppState.callRecord.call.crmInfo.company;
                    }

                    return AppState.callRecord.call.crmInfo.name;
                }

                company: {
                    if (!visible) {
                        return "";
                    }

                    if (AppState.callRecord.call.crmInfo.name.length == 0) {
                        return "";
                    }

                    return AppState.callRecord.call.crmInfo.company;
                }

                crm: {
                    if (!visible) {
                        return "";
                    }

                    if (AppState.callRecord.call.crmInfo.name.length == 0 ||
                            AppState.callRecord.call.crmInfo.company.length == 0) {
                        return AppState.callRecord.call.crmInfo.crm;
                    }

                    return "(" + AppState.callRecord.call.crmInfo.crm + ")";
                }

                link: visible ? AppState.callRecord.call.crmInfo.link : ""
            }

            Rectangle {
                anchors.top: crmInfo.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                color: "transparent"

                Image {
                    id: callEndImage

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -30

                    width: 66 * SettingsState.scale
                    height: 66 * SettingsState.scale

                    sourceSize.width: width
                    sourceSize.height: height

                    property string imageDefault: ""

                    source: "qrc:/images/record_default.svg"
                }

                Text {
                    id: callEndLabel

                    anchors.horizontalCenter: callEndImage.horizontalCenter
                    anchors.top: callEndImage.bottom
                    anchors.topMargin: -10 * SettingsState.scale

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary

                    text: qsTrId("active_calls_window_play_record") + Translator.translate
                }

                ProgressBar {
                    id: progressBar

                    anchors.top: callEndLabel.bottom
                    anchors.topMargin: 35 * SettingsState.scale
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 300 * SettingsState.scale
                    height: 6 * SettingsState.scale

                    value: {
                        if (AppState.callRecord) {
                            if (AppState.callRecord.position == 0 || AppState.callRecord.duration == 0) {
                                return 0.0;
                            }

                            if (AppState.callRecord.position == AppState.callRecord.duration) {
                                pauseButton.doWorkOnButtonClick();
                                return 1.0;
                            }

                            return (AppState.callRecord.position / AppState.callRecord.duration);
                        }
                        else {
                            return 0.0;
                        }
                    }

                    Behavior on value {
                        id: progressBehaviour

                        property bool enableAnimation: {
                            if (AppState.callRecord && AppState.callRecord.position == 0) {
                                return true;
                            }

                            return false;
                        }

                        onEnableAnimationChanged: {
                            if (enableAnimation) {
                                progressBehaviour.enabled = true;
                            }
                        }

                        PropertyAnimation {
                        }
                    }

                    background: Rectangle {
                        x: progressBar.leftPadding
                        y: progressBar.topPadding + (progressBar.availableHeight - height) / 2

                        implicitWidth: 200 * SettingsState.scale
                        implicitHeight: 6 * SettingsState.scale

                        width: progressBar.availableWidth
                        height: 6 * SettingsState.scale

                        color: ColorStorage.secondaryWindowBackground
                    }


                    contentItem: Rectangle {
                        id: strip

                        x: progressBar.leftPadding
                        y: progressBar.topPadding + (progressBar.availableHeight - height) / 2

                        width: progressBar.availableWidth
                        height: 6 * SettingsState.scale

                        color: "transparent"

                        Rectangle {
                            id: progress

                            width: parent.width * progressBar.visualPosition
                            height: parent.height

                            color: ColorStorage.green
                        }
                    }
                }

                Text {
                    id: recordPosition

                    anchors.top: progressBar.bottom
                    anchors.topMargin: 10 * SettingsState.scale
                    anchors.left: progressBar.left

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary

                    text: {
                        if (AppState.callRecord) {
                            return fmt.formatDuration(AppState.callRecord.position);
                        }
                        else {
                            return "";
                        }
                    }
                }

                Text {
                    id: recordDuration

                    anchors.top: progressBar.bottom
                    anchors.topMargin: 10 * SettingsState.scale
                    anchors.right: progressBar.right

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary

                    text:  {
                        if (AppState.callRecord) {
                            return fmt.formatDuration(AppState.callRecord.duration);
                        }
                        else {
                            return "";
                        }
                    }
                }
            }
        }

        FocusScope {
            id: controls

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            width: parent.width
            height: 100 * SettingsState.scale

            focus: true

            Item {
                id: initialFocusReceiver

                anchors.bottom: controls.top
                anchors.left: controls.left

                width: 0 * SettingsState.scale
                height: 0 * SettingsState.scale

                focus: true

                KeyNavigation.tab: {
                    return controls.prepareControlNavigation();
                }
            }

            Rectangle {
                anchors.fill: parent

                color: ColorStorage.surfaceSecondary

                SoftphonePro.SquareButton {
                    id: continueButton

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: -82 * SettingsState.scale

                    description: "SPACE"

                    KeyNavigation.tab: stopButton

                    width: 140 * SettingsState.scale
                    height: 43 * SettingsState.scale

                    radius: 28 * SettingsState.scale

                    borderWidth: 2 * SettingsState.scale
                    borderWidthOnHover: 3 * SettingsState.scale

                    color: ColorStorage.white
                    colorOnPress: ColorStorage.sSizeButtonOnPress

                    borderColor: ColorStorage.sSizeButtonBorderDefault
                    borderColorOnHover: ColorStorage.sSizeButtonBorderDefault

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: "#0089e0"
                    imageColorOnHover: "#0089e0"
                    imageColorOnPress: "#0089e0"

                    imageDefault: "qrc:/images/play_blue.svg"

                    doWorkOnButtonClick: function() {
                        if (progressBar.value == 1.0) {
                            // disable animation when reset progres value to 0
                            progressBehaviour.enabled = false;
                            ActionProvider.startPlayRecord(AppState.callRecord.name);
                        }
                        else {
                           ActionProvider.continuePlayRecord(AppState.callRecord.name);
                        }

                        controls.state = "pause";

                        if (continueButton.activeFocus) {
                            pauseButton.forceActiveFocus();
                        }
                    }

                    Shortcut {
                        enabled: root.activeFocus && continueButton.enabled

                        sequence: "Space"

                        onActivated: {
                            continueButton.doWorkOnButtonClick();
                        }
                    }
                }

                SoftphonePro.SquareButton {
                    id: pauseButton

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: -82 * SettingsState.scale

                    description: "SPACE"

                    KeyNavigation.tab: stopButton

                    width: 140 * SettingsState.scale
                    height: 43 * SettingsState.scale

                    radius: 28 * SettingsState.scale

                    borderWidth: 2 * SettingsState.scale
                    borderWidthOnHover: 3 * SettingsState.scale

                    color: ColorStorage.white
                    colorOnPress: ColorStorage.sSizeButtonOnPress

                    borderColor: ColorStorage.sSizeButtonBorderDefault
                    borderColorOnHover: ColorStorage.sSizeButtonBorderDefault

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.secondaryWindowBackground
                    imageColorOnHover: ColorStorage.secondaryWindowBackground
                    imageColorOnPress: ColorStorage.secondaryWindowBackground

                    imageDefault: "qrc:/images/pause_blue.svg"

                    doWorkOnButtonClick: function() {
                        ActionProvider.pausePlayRecord(AppState.callRecord.name);
                        controls.state = "continue";

                        if (pauseButton.activeFocus) {
                            continueButton.forceActiveFocus();
                        }
                    }

                    Shortcut {
                        enabled: root.activeFocus && pauseButton.enabled

                        sequence: "Space"

                        onActivated: {
                            pauseButton.doWorkOnButtonClick();
                        }
                    }
                }

                SoftphonePro.SquareButton {
                    id: stopButton

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: 82 * SettingsState.scale

                    description: "ESC"

                    KeyNavigation.tab: {
                        return controls.prepareControlNavigation();
                    }

                    width: 140 * SettingsState.scale
                    height: 43 * SettingsState.scale

                    radius: 28 * SettingsState.scale

                    borderWidth: 2 * SettingsState.scale
                    borderWidthOnHover: 3 * SettingsState.scale

                    color: ColorStorage.white
                    colorOnPress: ColorStorage.sSizeButtonOnPress

                    borderColor: ColorStorage.sSizeButtonBorderDefault
                    borderColorOnHover: ColorStorage.sSizeButtonBorderDefault

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    imageColorDefault: ColorStorage.secondaryWindowBackground
                    imageColorOnHover: ColorStorage.secondaryWindowBackground
                    imageColorOnPress: ColorStorage.secondaryWindowBackground

                    imageDefault: "qrc:/images/stop_blue.svg"

                    doWorkOnButtonClick: function() {
                        ActionProvider.stopPlayRecord(AppState.callRecord.name);
                        controls.state = "pause";
                    }

                    Shortcut {
                        enabled: root.activeFocus && stopButton.enabled

                        sequence: "Escape"

                        onActivated: {
                            stopButton.doWorkOnButtonClick();
                        }
                    }
                }
            }

            function prepareControlNavigation() {
                if (controls.state == "pause") {
                    return pauseButton;
                }

                return continueButton;
            }

            states: [

                State {
                    name: "pause"

                    PropertyChanges {
                        target: continueButton
                        enabled: false
                        visible: false
                    }

                    PropertyChanges {
                        target: pauseButton
                        enabled: true
                        visible: true
                    }
                },

                State {
                    name: "continue"

                    PropertyChanges {
                        target: continueButton
                        enabled: true
                        visible: true
                    }

                    PropertyChanges {
                        target: pauseButton
                        enabled: false
                        visible: false
                    }
                }
            ]
        }

        Component.onCompleted:  {
            controls.state = "pause";
        }
    }
}
