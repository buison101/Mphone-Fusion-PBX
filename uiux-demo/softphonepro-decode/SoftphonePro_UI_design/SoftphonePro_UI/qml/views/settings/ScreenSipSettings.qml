import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        contentHeight: silenceDetectionSettings.height + marginValue
                       + echoCancellationSettings.height + marginValue
                       + denyIncomingSettings.height + marginValue
                       + enableCallWaitingCheckbox.height + marginValue
                       + playCallWaitingToneSettings.height + marginValue
                       + autoAnswerSettings.height + marginValue
                       + callRecordingGroupBox.height + marginValue
                       + setSipBusyHereForStatusesRow.height + marginValue
                       + codecsControls.height + marginValue
                       + stunServersTextField.height + marginValue + 2 * marginValue

        boundsBehavior: Flickable.StopAtBounds

        clip: true

        enabled: !AppState.instanceDisabled

        Rectangle {
            id: sip

            anchors.fill: parent

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: marginValue
                anchors.leftMargin: marginValue
                anchors.rightMargin: marginValue

                color: ColorStorage.settingsWindowBaseColor

                Row {
                    id: silenceDetectionSettings

                    anchors.top: parent.top
                    anchors.left: parent.left

                    enabled: AppState.activeCall == null

                    spacing: marginValue

                    SettingsCheckBox {
                        id: silenceDetectionCheckbox

                        property bool sipSilenceDetection: SettingsState.sipSilenceDetection

                        checked: sipSilenceDetection

                        onCheckedChanged: {
                            if (checked != sipSilenceDetection) {
                                ActionProvider.markAppConfigUpdate(AppConfig.VoiceActivityDetection, checked);
                            }
                        }

                        onSipSilenceDetectionChanged: {
                            checked = sipSilenceDetection;
                        }
                    }

                    Label {
                        anchors.verticalCenter: silenceDetectionCheckbox.verticalCenter
                        text: qsTrId("settings_sip_silence_detection") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                Row {
                    id: echoCancellationSettings

                    anchors.top: silenceDetectionSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left

                    enabled: AppState.activeCall == null

                    spacing: marginValue

                    SettingsCheckBox {
                        id: echoCancellationCheckbox

                        property bool sipEchoCancellation: SettingsState.sipEchoCancellation

                        checked: sipEchoCancellation

                        onCheckedChanged: {
                            if (checked != sipEchoCancellation) {
                                ActionProvider.markAppConfigUpdate(AppConfig.EchoCancellation, checked);
                            }
                        }

                        onSipEchoCancellationChanged: {
                            checked = sipEchoCancellation;
                        }
                    }

                    Label {
                        anchors.verticalCenter: echoCancellationCheckbox.verticalCenter
                        text: qsTrId("settings_sip_echo_cancellation") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                Row {
                    id: denyIncomingSettings

                    anchors.top: echoCancellationSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: denyIncomingCheckbox

                        property bool denyIncoming: SettingsState.sipDenyIncoming

                        checked: denyIncoming

                        onCheckedChanged: {
                            if (checked != denyIncoming) {
                                ActionProvider.markAppConfigUpdate(AppConfig.DenyIncoming, checked);
                            }
                        }

                        onDenyIncomingChanged: {
                            checked = denyIncoming;
                        }
                    }

                    Label {
                        anchors.verticalCenter: denyIncomingCheckbox.verticalCenter
                        text: qsTrId("settings_sip_deny_incoming") + Translator.translate
                        font.pixelSize: fontSize

                        enabled: denyIncomingCheckbox.enabled
                    }
                }

                SettingsCheckBox {
                    id: enableCallWaitingCheckbox

                    anchors.top: denyIncomingSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left


                    property bool enableCallWaiting: SettingsState.sipEnableCallWaiting

                    checked: enableCallWaiting

                    onCheckedChanged: {
                        if (checked != enableCallWaiting) {
                            ActionProvider.markAppConfigUpdate(AppConfig.EnableCallWaiting, checked);
                        }
                    }

                    onEnableCallWaitingChanged: {
                        checked = enableCallWaiting;
                    }
                }

                Label {
                    id: enableCallWaitingLabel

                    anchors.top: enableCallWaitingCheckbox.top
                    anchors.left: enableCallWaitingCheckbox.right
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_sip_enable_call_waiting").arg(StringStorage.appTitle) + Translator.translate
                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap

                    enabled: enableCallWaitingCheckbox.enabled
                }

                Row {
                    id: playCallWaitingToneSettings

                    anchors.top: enableCallWaitingLabel.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: playCallWaitingToneCheckbox

                        property bool playCallWaitingTone: SettingsState.sipPlayCallWaitingTone

                        checked: playCallWaitingTone

                        onCheckedChanged: {
                            if (checked != playCallWaitingTone) {
                                ActionProvider.markAppConfigUpdate(AppConfig.PlayCallWaitingTone, checked);
                            }
                        }

                        onPlayCallWaitingToneChanged: {
                            checked = playCallWaitingTone;
                        }
                    }

                    Label {
                        anchors.verticalCenter: playCallWaitingToneCheckbox.verticalCenter
                        text: qsTrId("settings_sip_play_call_waiting_tone") + Translator.translate
                        font.pixelSize: fontSize

                        enabled: playCallWaitingToneCheckbox.enabled
                    }
                }

                Row {
                    id: autoAnswerSettings

                    anchors.top: playCallWaitingToneSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: playCallWaitingToneSettings.left
                    visible: !AppFeatures.hideAutoAnswers

                    height: visible ? 15 : 0

                    spacing:  marginValue

                    Label {
                        anchors.verticalCenter: autoAnswerComboBox.verticalCenter
                        text: qsTrId("settings_sip_auto_answer") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsComboBox {
                        id: autoAnswerComboBox

                        width: 150

                        model: SettingsState.sipAutoAnswerModel
                        textRole: "name"

                        property int sipAutoAnswerModelSelectedIdx: SettingsState.sipAutoAnswerModelSelectedIdx

                        currentIndex: sipAutoAnswerModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != onCurrentIndexChanged) {
                                ActionProvider.markAppConfigUpdate(AppConfig.AutoAnswer, currentIndex);
                            }
                        }

                        onSipAutoAnswerModelSelectedIdxChanged: {
                            currentIndex = sipAutoAnswerModelSelectedIdx;
                        }
                    }
                }

                SettingsGroupBox {
                    id: callRecordingGroupBox

                    anchors.top: autoAnswerSettings.bottom
                    anchors.topMargin: marginValue * 2
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: recordCallAutomaticallySettings.height + marginValue
                            + labelsColumn.height + marginValue + 1.5 * marginValue

                    title: qsTrId("settings_sip_call_recording") + Translator.translate

                    Row {
                        id: recordCallAutomaticallySettings

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue

                        spacing: marginValue

                        SettingsCheckBox {
                            id: recordCallAutomaticallyCheckbox

                            enabled: !AppState.disableCallRecordingControl

                            property bool recordCallAutomatically: SettingsState.sipRecordCallAutomatically

                            checked: recordCallAutomatically

                            onCheckedChanged: {
                                if (checked != recordCallAutomatically) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.SaveRecords, checked);
                                }
                            }

                            onRecordCallAutomaticallyChanged: {
                                checked = recordCallAutomatically;
                            }
                        }

                        Label {
                            anchors.verticalCenter: recordCallAutomaticallyCheckbox.verticalCenter
                            text: qsTrId("settings_sip_record_call_automatically") + Translator.translate
                            font.pixelSize: fontSize

                            enabled: recordCallAutomaticallyCheckbox.enabled
                        }
                    }

                    Column{
                        id:labelsColumn

                        anchors.top: recordCallAutomaticallySettings.bottom
                        anchors.topMargin: marginValue / 2 + recordTypeComboBox.height / 2
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        spacing: 1.5 * marginValue

                        Label {
                            text: qsTrId("settings_sip_choose_record_type") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        Label {
                            text: qsTrId("settings_sip_choose_record_extension") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }


                    Row {
                        id: recordTypeDropdown
                        anchors.top: recordCallAutomaticallySettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: labelsColumn.right
                        anchors.leftMargin: marginValue

                        height: visible ? marginValue : 0

                        spacing:  marginValue

                        SettingsComboBox {
                            id: recordTypeComboBox

                            width: 150

                            model: SettingsState.sipRecordTypeModel
                            textRole: "name"

                            enabled: !AppState.activeCall && !AppFeatures.provisioningOn

                            property int sipRecordTypeModelSelectedIdx: SettingsState.sipRecordTypeModelSelectedIdx

                            currentIndex: sipRecordTypeModelSelectedIdx

                            onCurrentIndexChanged:  {
                                if (currentIndex != onCurrentIndexChanged) {
                                    if (AppFeatures.provisioningOn) {
                                        //0 is stereo record
                                        ActionProvider.markAppConfigUpdate(AppConfig.RecordType, 0);
                                        //here 1 is mp3 record extension
                                        recordExtensionComboBox.currentIndex = 1;
                                    } else {
                                        ActionProvider.markAppConfigUpdate(AppConfig.RecordType, currentIndex);
                                        //here 1 is mono record
                                        if (currentIndex == 1 || AppFeatures.provisioningOn) {
                                            //here 1 is mp3 record extension
                                            if (AppFeatures.osType == OSType.MacOS) {
                                                recordExtensionComboBox.currentIndex = 0;
                                            } else {
                                                recordExtensionComboBox.currentIndex = 1;
                                            }
                                        }
                                    }
                                }
                            }
                            onSipRecordTypeModelSelectedIdxChanged: {
                                if (AppFeatures.provisioningOn) {
                                     //0 is stereo record
                                    currentIndex = 0;
                                } else {
                                    currentIndex = sipRecordTypeModelSelectedIdx;
                                }
                            }
                        }
                    }

                    Row {
                        id: recordExtensionDropdown
                        anchors.top: recordTypeDropdown.bottom
                        anchors.topMargin: marginValue
                        anchors.left: labelsColumn.right
                        anchors.leftMargin: marginValue

                        height: visible ? marginValue : 0

                        spacing:  marginValue

                        SettingsComboBox {
                            id: recordExtensionComboBox

                            width: 150

                            anchors.topMargin: marginValue

                            model: SettingsState.sipRecordExtensionModel
                            textRole: "name"

                            //0 is stereo record index
                            enabled: !AppState.activeCall && (recordTypeComboBox.currentIndex == 0) && !AppFeatures.provisioningOn && AppFeatures.osType != OSType.MacOS

                            property int sipRecordExtensionModelSelectedIdx: SettingsState.sipRecordExtensionModelSelectedIdx

                            currentIndex: sipRecordExtensionModelSelectedIdx

                            onCurrentIndexChanged:  {
                                if (currentIndex != onCurrentIndexChanged) {
                                    if (AppFeatures.osType == OSType.MacOS)
                                        ActionProvider.markAppConfigUpdate(AppConfig.RecordExtension, 0);
                                    else if (AppFeatures.provisioningOn)
                                        ActionProvider.markAppConfigUpdate(AppConfig.RecordExtension, 1);
                                    else
                                        ActionProvider.markAppConfigUpdate(AppConfig.RecordExtension, currentIndex);
                                }
                            }

                            onSipRecordExtensionModelSelectedIdxChanged: {
                                if (AppFeatures.osType == OSType.MacOS)
                                    currentIndex = 0;
                                else if (AppFeatures.provisioningOn)
                                    currentIndex = 1;
                                else
                                    currentIndex = sipRecordExtensionModelSelectedIdx;

                            }
                        }
                    }
                }

                Row {
                    id: setSipBusyHereForStatusesRow

                    anchors.top: callRecordingGroupBox.bottom
                    anchors.topMargin: visible ? marginValue : 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: visible ? setSipBusyHereForNACheckbox.height : 0
                    spacing: marginValue

                    visible: !AppFeatures.hideStatusSettings

                    Label {
                        id: setSipBusyHereForStatusesLabel

                        text: qsTrId("set_busy_here_for_statuses_label") + ":" + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsCheckBox {
                        id: setSipBusyHereForNACheckbox

                        anchors.verticalCenter: setSipBusyHereForStatusesLabel.verticalCenter

                        property bool setBusyHereForNAStatus: SettingsState.setSipBusyHereForNA

                        checked: setBusyHereForNAStatus

                        enabled: setSipBusyHereForStatusesRow.visible

                        onCheckedChanged: {
                            if (checked != setBusyHereForNAStatus) {
                                ActionProvider.markAppConfigUpdate(AppConfig.SetSipBusyHereForNA, checked)
                            }
                        }

                        onSetBusyHereForNAStatusChanged: {
                            checked = setBusyHereForNAStatus
                        }
                    }

                    Label {
                        anchors.verticalCenter: setSipBusyHereForNACheckbox.verticalCenter
                        text: qsTrId("phone_status_na") + Translator.translate + ";"
                        font.pixelSize: fontSize
                    }

                    SettingsCheckBox {
                        id: setSipBusyHereForAwayCheckbox

                        anchors.verticalCenter: setSipBusyHereForNACheckbox.verticalCenter

                        property bool setBusyHereForAwayStatus: SettingsState.setSipBusyHereForAway

                        checked: setBusyHereForAwayStatus

                        enabled: setSipBusyHereForStatusesRow.visible

                        onCheckedChanged: {
                            if (checked != setBusyHereForAwayStatus) {
                                ActionProvider.markAppConfigUpdate(AppConfig.SetSipBusyHereForAway, checked)
                            }
                        }

                        onSetBusyHereForAwayStatusChanged: {
                            checked = setBusyHereForAwayStatus
                        }
                    }

                    Label {
                        anchors.verticalCenter: setSipBusyHereForAwayCheckbox
                        text: qsTrId("phone_status_away") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                SettingsGroupBox {
                    id: codecsControls
                    anchors.top: setSipBusyHereForStatusesRow.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: availableCodecs.height + marginValue + marginValue

                    title: qsTrId("settings_sip_audio_codecs") + Translator.translate

                    GroupBox {
                        id: availableCodecs

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        width: 150
                        height: 200

                        title: qsTrId("settings_sip_audio_codecs_available") + Translator.translate

                        ScrollView {
                            anchors.fill: parent

                            Rectangle {
                                anchors.fill: parent
                            }

                            contentItem: ListView {
                                id: availableCodecsListView

                                ScrollBar.vertical: ScrollBar {
                                    active: true
                                    policy: ScrollBar.AlwaysOn
                                }

                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                model: SettingsState.availableAudioCodecsModel

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 20

                                    color: "transparent"

                                    MouseArea {
                                        anchors.fill: parent

                                        onClicked: {
                                            availableCodecsListView.currentIndex = index;
                                        }
                                    }

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: marginValue / 4

                                        text: name
                                        font.pixelSize: fontSize
                                    }
                                }

                                highlight: Rectangle {
                                    color: "lightsteelblue";
                                }

                                highlightFollowsCurrentItem: true
                            }
                        }
                    }

                    Row {
                        id: codecActivationButtons

                        anchors.verticalCenter: availableCodecs.verticalCenter
                        anchors.topMargin: marginValue
                        anchors.left: availableCodecs.right
                        anchors.leftMargin: marginValue

                        spacing: marginValue

                        Button {
                            id: deactivateCodecButton

                            width: 30
                            height: 30

                            enabled: activeCodecsListView.currentIndex != -1

                            Image {
                                anchors.centerIn: deactivateCodecButton

                                source: {
                                    if (deactivateCodecButton.enabled) {
                                        return "qrc:/images/arrow_left.svg";
                                    }

                                    return "qrc:/images/arrow_left_grey.svg";
                                }
                            }

                            onClicked: {
                                ActionProvider.deactivateAudioCodec(activeCodecsListView.currentIndex);
                            }
                        }

                        Button {
                            id: activateCodecButton

                            width: 30
                            height: 30

                            enabled: availableCodecsListView.currentIndex != -1

                            Image {
                                anchors.centerIn: activateCodecButton

                                source: {
                                    if (activateCodecButton.enabled) {
                                        return "qrc:/images/arrow_right.svg";
                                    }

                                    return "qrc:/images/arrow_right_grey.svg";
                                }
                            }

                            onClicked: {
                                ActionProvider.activateAudioCodec(availableCodecsListView.currentIndex);
                            }
                        }
                    }

                    GroupBox {
                        id: activeCodecs

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: codecActivationButtons.right
                        anchors.leftMargin: marginValue

                        width: 150
                        height: 200

                        title: qsTrId("settings_sip_audio_codecs_active") + Translator.translate

                        ScrollView {
                            anchors.fill: parent

                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Rectangle {
                                anchors.fill: parent
                            }

                            contentItem: ListView {
                                id: activeCodecsListView

                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                model: SettingsState.activeAudioCodecsModel

                                delegate: Rectangle {
                                    width: activeCodecsListView.width
                                    height: 20

                                    color: "transparent"

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 5

                                        text: name
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        onClicked: {
                                            activeCodecsListView.currentIndex = index;
                                        }
                                    }
                                }

                                highlight: Rectangle {
                                    color: "lightsteelblue"
                                }

                                highlightFollowsCurrentItem: true
                            }
                        }
                    }

                    Column {
                        id: codecPriorityButtons

                        anchors.verticalCenter: activeCodecs.verticalCenter
                        anchors.left: activeCodecs.right
                        anchors.leftMargin: marginValue

                        spacing: marginValue

                        Button {
                            id: increasePriorityButton

                            width: 30
                            height: 30

                            enabled: {
                                return activeCodecsListView.currentIndex != -1
                                        && activeCodecsListView.currentIndex != 0;
                            }

                            Image {
                                anchors.centerIn: increasePriorityButton

                                source: {
                                    if (increasePriorityButton.enabled) {
                                        return "qrc:/images/arrow_up.svg";
                                    }

                                    return "qrc:/images/arrow_up_grey.svg";
                                }
                            }

                            onClicked: {
                                ActionProvider.increaseAudioCodecPriority(activeCodecsListView.currentIndex);
                                activeCodecsListView.currentIndex -= 1;
                            }
                        }

                        Button {
                            id: decreasePriorityButton

                            width: 30
                            height: 30

                            enabled: {
                                return activeCodecsListView.currentIndex != -1 &&
                                        activeCodecsListView.currentIndex != activeCodecsListView.count - 1;
                            }

                            Image {
                                anchors.centerIn: decreasePriorityButton
                                source: {
                                    if (decreasePriorityButton.enabled) {
                                        return "qrc:/images/arrow_down.svg";
                                    }

                                    return "qrc:/images/arrow_down_grey.svg";
                                }
                            }

                            onClicked: {
                                ActionProvider.decreaseAudioCodecPriority(activeCodecsListView.currentIndex);
                                activeCodecsListView.currentIndex += 1;
                            }
                        }
                    }
                }

                Label {
                    id: stunServersLabel

                    anchors.top: codecsControls.bottom
                    anchors.topMargin: marginValue
                    anchors.left: codecsControls.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_sip_stun_servers") + Translator.translate
                }

                SettingsTextField {
                    id: stunServersTextField

                    anchors.verticalCenter: stunServersLabel.verticalCenter
                    anchors.left: stunServersLabel.right
                    anchors.leftMargin: marginValue

                    width: 150

                    property int idx
                    property string address

                    text: SettingsState.stunServers
                    font.pixelSize: 11

                    onTextChanged: {
                        ActionProvider.markAppConfigUpdate(AppConfig.StunServers, text);
                    }
                }
            }
        }
    }
}
