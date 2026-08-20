import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../uicontrols"
import "../dialogs"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        contentHeight: general.height
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        Rectangle {
            id: general

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: languageSettings.height + languageSettings.anchors.topMargin
                    + startupSettings.height + startupSettings.anchors.topMargin
                    + soundSettings.height + soundSettings.anchors.topMargin
                    + ringtone.height + ringtone.anchors.topMargin
                    + loggingSettings.height + loggingSettings.anchors.topMargin
                    + groupBox.height + groupBox.anchors.topMargin
                    + 2 * marginValue

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: marginValue
                anchors.leftMargin: marginValue
                anchors.rightMargin: marginValue

                color: ColorStorage.settingsWindowBaseColor

                Row {
                    id: languageSettings

                    anchors.top: parent.top
                    anchors.left: parent.left

                    spacing: marginValue

                    Label {
                        anchors.verticalCenter: combobox.verticalCenter
                        text: qsTrId("settings_general_language") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsComboBox {
                        id: combobox

                        width: 110

                        model: SettingsState.languageModel
                        textRole: "name"

                        font.pixelSize: fontSize

                        property int languageModelSelectedIdx: SettingsState.languageModelSelectedIdx

                        currentIndex: languageModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != languageModelSelectedIdx) {
                                Translator.selectLanguage(currentIndex);
                                ActionProvider.markAppConfigUpdate(AppConfig.Language, currentIndex);
                            }
                        }

                        onLanguageModelSelectedIdxChanged: {
                            currentIndex = languageModelSelectedIdx;
                        }
                    }
                }

                Row {
                    id: startupSettings

                    anchors.top: languageSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: startupCheckbox

                        property bool generalRunOnStartup: SettingsState.generalRunOnStartup

                        checked: generalRunOnStartup

                        onCheckedChanged: {
                            if (checked != generalRunOnStartup) {
                                ActionProvider.markAppConfigUpdate(AppConfig.RunOnStartup, checked);
                            }
                        }

                        onGeneralRunOnStartupChanged: {
                            checked = generalRunOnStartup;
                        }
                    }

                    Label {
                        anchors.verticalCenter: startupCheckbox.verticalCenter
                        text: qsTrId("settings_general_run_on_startup") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                SettingsGroupBox {
                    id:  soundSettings

                    anchors.top: startupSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    enabled: !AppState.instanceDisabled

                    height: speakerCombobox.height + speakerCombobox.anchors.topMargin + speakerVolumeLabel.height
                            + speakerVolumeLabel.anchors.topMargin + microphoneCombobox.height + microphoneCombobox.anchors.topMargin
                            + microphoneVolumeLabel.height + microphoneVolumeLabel.anchors.topMargin
                            + ringerCombobox.height + ringerCombobox.anchors.topMargin + ringerVolumeSettings.height
                            + ringerVolumeSettings.anchors.topMargin + reduceExternalSoundsSettings.height + reduceExternalSoundsSettings.anchors.topMargin
                            + enableKeyPressSoundsSettings.height + enableKeyPressSoundsSettings.anchors.topMargin
                            + enablePlaySoundAfterHangupSettings.height + enablePlaySoundAfterHangupSettings.anchors.topMargin
                            + hidIntegrationSettings.height + hidIntegrationSettings.anchors.topMargin
                            + marginValue

                    title: qsTrId("settings_general_sound") + Translator.translate

                    Column{
                        anchors.top: parent.top
                        anchors.topMargin: marginValue / 2 + speakerCombobox.height / 2
                        anchors.leftMargin: marginValue
                        anchors.left: parent.left
                        id:labelsColumn
                        spacing: 3.5 * marginValue

                        Label {
                            id: speakerLabel

                            anchors.left: parent.left

                            text: qsTrId("settings_general_speakers") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        Label {
                            id: microphoneLabel

                            anchors.left: parent.left
                            text: qsTrId("settings_general_microphone") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        Label {
                            id: ringerLabel

                            anchors.left: parent.left

                            text: qsTrId("settings_general_ring_device") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    SettingsComboBox {
                        id: speakerCombobox

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: labelsColumn.right
                        anchors.leftMargin: marginValue

                        model: SettingsState.speakerDeviceModel
                        textRole: "name"

                        font.pixelSize: fontSize

                        property int speakerDeviceModelSelectedIdx: SettingsState.speakerDeviceModelSelectedIdx

                        currentIndex: speakerDeviceModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != speakerDeviceModelSelectedIdx) {
                                ActionProvider.markAppConfigUpdate(AppConfig.Speaker, currentIndex);
                            }
                        }

                        onSpeakerDeviceModelSelectedIdxChanged: {
                            currentIndex = speakerDeviceModelSelectedIdx;
                        }
                    }

                    Label {
                        id: speakerVolumeLabel

                        anchors.top: speakerCombobox.bottom
                        anchors.topMargin: marginValue
                        anchors.left: speakerCombobox.left

                        text: qsTrId("settings_general_speakers_sound_level") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsSlider {
                        id: speakerVolume

                        anchors.left: speakerVolumeLabel.right
                        anchors.leftMargin: marginValue
                        anchors.verticalCenter: speakerVolumeLabel.verticalCenter

                        width: 150

                        property real volumeLevelSpeakerDevice: SettingsState.volumeLevelSpeakerDevice

                        value: volumeLevelSpeakerDevice

                        onValueChanged: {
                            speakerVolumeTimer.restart();
                        }

                        onVolumeLevelSpeakerDeviceChanged: {
                            value = volumeLevelSpeakerDevice;
                        }

                        Timer {
                            id: speakerVolumeTimer

                            interval: 500
                            running: false
                            repeat: false

                            onTriggered: {
                                if (speakerVolume.value != speakerVolume.volumeLevelSpeakerDevice) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.VolumeLevelSpeaker, speakerVolume.value);
                                }
                            }
                        }
                    }

                    SettingsComboBox {
                        id: microphoneCombobox

                        anchors.top: speakerVolumeLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: labelsColumn.right
                        anchors.leftMargin: marginValue

                        model: SettingsState.microphoneDeviceModel
                        textRole: "name"

                        font.pixelSize: fontSize

                        property int microphoneDeviceModelSelectedIdx: SettingsState.microphoneDeviceModelSelectedIdx

                        currentIndex: microphoneDeviceModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != microphoneDeviceModelSelectedIdx) {
                                ActionProvider.markAppConfigUpdate(AppConfig.Microphone, currentIndex);
                            }
                        }

                        onMicrophoneDeviceModelSelectedIdxChanged: {
                            currentIndex = microphoneDeviceModelSelectedIdx;
                        }
                    }

                    Label {
                        id: microphoneVolumeLabel

                        anchors.top: microphoneCombobox.bottom
                        anchors.topMargin: marginValue
                        anchors.left: microphoneCombobox.left

                        text: qsTrId("settings_general_microphone_volume_level") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsSlider {
                        id: microphoneVolume

                        anchors.left: speakerVolume.left
                        anchors.verticalCenter: microphoneVolumeLabel.verticalCenter

                        implicitWidth: 150

                        property real volumeLevelMicrophoneDevice: SettingsState.volumeLevelMicrophoneDevice

                        value: volumeLevelMicrophoneDevice

                        onValueChanged: {
                            microphoneVolumeTimer.restart();
                        }

                        onVolumeLevelMicrophoneDeviceChanged: {
                            value = volumeLevelMicrophoneDevice;
                        }

                        Timer {
                            id: microphoneVolumeTimer

                            interval: 500
                            running: false
                            repeat: false

                            onTriggered: {
                                if (microphoneVolume.value != microphoneVolume.volumeLevelMicrophoneDevice) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.VolumeLevelMicrophone, microphoneVolume.value);
                                }
                            }
                        }
                    }

                    SettingsComboBox {
                        id: ringerCombobox

                        anchors.top: microphoneVolumeLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: labelsColumn.right
                        anchors.leftMargin: marginValue

                        model: SettingsState.ringDeviceModel
                        textRole: "name"

                        font.pixelSize: fontSize

                        property int ringDeviceModelSelectedIdx: SettingsState.ringDeviceModelSelectedIdx

                        currentIndex: ringDeviceModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != ringDeviceModelSelectedIdx) {
                                ActionProvider.markAppConfigUpdate(AppConfig.RingDevice, currentIndex);
                            }
                        }

                        onRingDeviceModelSelectedIdxChanged: {
                            currentIndex = ringDeviceModelSelectedIdx;
                        }
                    }

                    Row {
                        id: ringerVolumeSettings

                        anchors.top: ringerCombobox.bottom
                        anchors.topMargin: marginValue
                        anchors.left: ringerCombobox.left

                        spacing: marginValue

                        Label {
                            anchors.verticalCenter: ringerVolume.verticalCenter
                            text: qsTrId("settings_general_ring_device_volume_level") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsSlider {
                            id: ringerVolume
                            width: 150

                            property real volumeLevelRingDevice: SettingsState.volumeLevelRingDevice

                            value: volumeLevelRingDevice

                            onValueChanged: {
                                ringerVolumeTimer.restart();
                            }

                            onVolumeLevelRingDeviceChanged: {
                                value = volumeLevelRingDevice;
                            }

                            Timer {
                                id: ringerVolumeTimer

                                interval: 500
                                running: false
                                repeat: false

                                onTriggered: {
                                    if (ringerVolume.value != ringerVolume.volumeLevelRingDevice) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.VolumeLevelRingDevice, ringerVolume.value);
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: reduceExternalSoundsSettings

                        anchors.top: ringerVolumeSettings.bottom
                        anchors.topMargin: marginValue / 2
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        spacing: marginValue

                        SettingsCheckBox {
                            id: reduceExternalSoundsCheckbox

                            property bool reduceExternalSounds: SettingsState.reduceExternalSounds

                            checked: reduceExternalSounds

                            onCheckedChanged: {
                                if (checked != reduceExternalSounds) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.ReduceExternalSounds, checked);
                                }
                            }

                            onReduceExternalSoundsChanged: {
                                checked = reduceExternalSounds;
                            }
                        }

                        Label {
                            anchors.verticalCenter: reduceExternalSoundsCheckbox.verticalCenter
                            text: qsTrId("settings_general_reduce_windows_sounds") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: enableKeyPressSoundsSettings

                        anchors.top: reduceExternalSoundsSettings.bottom
                        anchors.topMargin: marginValue / 2
                        anchors.left: reduceExternalSoundsSettings.left

                        spacing: marginValue

                        SettingsCheckBox {
                            id: enableKeyPressSoundsCheckbox

                            property bool enableKeyPressSounds: SettingsState.enableKeyPressSounds

                            checked: enableKeyPressSounds

                            onCheckedChanged: {
                                if (checked != enableKeyPressSounds) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.EnableKeyPressSounds, checked);
                                }
                            }

                            onEnableKeyPressSoundsChanged: {
                                checked = enableKeyPressSounds;
                            }
                        }

                        Label {
                            anchors.verticalCenter: enableKeyPressSoundsCheckbox.verticalCenter
                            text: qsTrId("settings_general_enable_key_press_sounds") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: enablePlaySoundAfterHangupSettings

                        anchors.top: enableKeyPressSoundsSettings.bottom
                        anchors.topMargin: marginValue / 2
                        anchors.left: reduceExternalSoundsSettings.left

                        spacing: marginValue

                        SettingsCheckBox {
                            id: enablePlaySoundAfterHangupCheckbox

                            property bool enablePlaySoundAfterHangup: SettingsState.playSoundAfterHangup

                            checked: enablePlaySoundAfterHangup

                            onCheckedChanged: {
                                if (checked != enablePlaySoundAfterHangup) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.PlaySoundAfterHangup, checked);
                                }
                            }

                            onEnablePlaySoundAfterHangupChanged: {
                                checked = enablePlaySoundAfterHangup;
                            }
                        }

                        Label {
                            anchors.verticalCenter: enablePlaySoundAfterHangupCheckbox.verticalCenter
                            text: qsTrId("settings_general_play_sound_after_hangup") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: hidIntegrationSettings

                        anchors.top: enablePlaySoundAfterHangupSettings.bottom
                        topPadding: marginValue / 2
                        anchors.left: parent.left
                        leftPadding: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue * 2
                        height: hidIntegrationSettingsCombobox.height

                        spacing: marginValue

                        Label {
                            id: hidIntegrationSettingsLabel
                            anchors.verticalCenter: hidIntegrationSettingsCombobox.verticalCenter

                            text: qsTrId("settings_general_hid_integration") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsComboBox {
                            id: hidIntegrationSettingsCombobox

                            model: SettingsState.hidIntegrationDeviceModel
                            textRole: "name"

                            font.pixelSize: fontSize

                            property int hidIntegrationDeviceModelSelectedIdx: SettingsState.hidIntegrationDeviceModelSelectedIdx

                            currentIndex: hidIntegrationDeviceModelSelectedIdx

                            onCurrentIndexChanged:  {
                                if (currentIndex != onCurrentIndexChanged) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.HidIntegrationDevice, currentIndex);
                                }
                            }

                            onHidIntegrationDeviceModelSelectedIdxChanged: {
                                currentIndex = hidIntegrationDeviceModelSelectedIdx;
                            }
                        }

                        Label {
                            id: hidIntegrationSettingDescription

                            anchors.verticalCenter: hidIntegrationSettingsCombobox.verticalCenter

                            horizontalAlignment: Text.AlignLeft

                            width: hidIntegrationSettings.width - hidIntegrationSettingsCombobox.width - hidIntegrationSettingsLabel.width - 2 * marginValue

                            text: !AppFeatures.whiteLabel ? qsTrId("settings_general_hid_integration_description").arg(StringStorage.hidIntegrationListURL) + Translator.translate : ""

                            wrapMode: Text.WordWrap
                            font.pixelSize: fontSize

                            onLinkActivated: Qt.openUrlExternally(link)

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }

                SettingsGroupBox {
                    id: ringtone

                    anchors.top: soundSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: description.height + marginValue / 2
                            + predefinedRingtoneComboBox.height + marginValue
                            + ringerSoundButton.height + marginValue
                            + playButton.height + marginValue
                            + marginValue

                    title: qsTrId("settings_general_ringtone") + Translator.translate

                    Label {
                        id: description

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        text: qsTrId("settings_general_ringtone_description") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsRadioButton {
                        id: customSelectionRadioButton

                        anchors.left: parent.left
                        anchors.leftMargin: marginValue / 2
                        anchors.verticalCenter: ringingSoundField.verticalCenter

                        text: qsTrId("settings_general_custom") + Translator.translate
                        font.pixelSize: fontSize

                        property string type: SettingsState.ringtoneType

                        onTypeChanged: {
                            checked = SettingsState.isCustomRingtoneType
                        }

                        onCheckedChanged: {
                            if (checked) {
                                ActionProvider.updateRingtoneCustomType(true);
                            }
                        }
                    }

                    SettingsTextField {
                        id: ringingSoundField

                        anchors.verticalCenter: ringerSoundButton.verticalCenter
                        anchors.right: ringerSoundButton.left
                        anchors.rightMargin: marginValue

                        text: SettingsState.ringingSound

                        readOnly: true

                        onTextChanged: {
                            ringingSoundField.cursorPosition = 0;
                        }

                        enabled: customSelectionRadioButton.checked

                        width: 180
                    }

                    SettingsButton {
                        id: ringerSoundButton

                        text: qsTrId("settings_general_ringer_sound_button") + Translator.translate

                        anchors.top: description.bottom
                        anchors.topMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        enabled: customSelectionRadioButton.checked

                        onClicked: {
                            ringerSoundDialogLoader.sourceComponent = ringerSoundDialogComponent;
                        }
                    }

                    SettingsRadioButton {
                        id: predefinedSelectionRadioButton

                        anchors.left: parent.left
                        anchors.leftMargin: marginValue / 2
                        anchors.verticalCenter: predefinedRingtoneComboBox.verticalCenter

                        text: qsTrId("settings_general_predefined") + Translator.translate
                        font.pixelSize: fontSize

                        property string type: SettingsState.ringtoneType

                        onTypeChanged: {
                            checked = SettingsState.isPredefinedRingtoneType;
                        }

                        onCheckedChanged: {
                            if (checked) {
                                ActionProvider.updateRingtonePredefinedType(true);
                            }
                        }
                    }

                    SettingsComboBox {
                        id: predefinedRingtoneComboBox

                        anchors.top: ringingSoundField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: ringingSoundField.left
                        width: 120

                        model: SettingsState.predefinedRingtoneModel
                        textRole: "name"

                        enabled:predefinedSelectionRadioButton.checked

                        font.pixelSize: fontSize

                        property int predefinedRingtoneModelSelectedIdx: SettingsState.predefinedRingtoneModelSelectedIdx

                        currentIndex: predefinedRingtoneModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != onCurrentIndexChanged) {
                                ActionProvider.markAppConfigUpdate(AppConfig.RingtoneId, currentIndex);
                            }
                        }

                        onPredefinedRingtoneModelSelectedIdxChanged: {
                            currentIndex = predefinedRingtoneModelSelectedIdx;
                        }
                    }

                    SettingsButton {
                        id: playButton

                        text: AppState.isRingtoneCurrentlyPlaying ? qsTrId("dialog_button_cancel") + Translator.translate
                                                                  : qsTrId("settings_prerecorded_audio_play_button") + Translator.translate

                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.top: predefinedSelectionRadioButton.bottom
                        anchors.topMargin: marginValue / 2

                        onClicked: {
                            if (!AppState.activeCall) {
                                if (!AppState.isRingtoneCurrentlyPlaying) {
                                    ActionProvider.getRingtoneInfoThenPlay();
                                } else {
                                    ActionProvider.stopPlayRingtone();
                                }
                            }
                        }
                    }
                }

                SettingsGroupBox {
                    id: loggingSettings

                    anchors.top: ringtone.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: turnOnJournal.height + turnOnJournal.anchors.topMargin
                            + (statisticsSettings.visible ? statisticsSettings.height + statisticsSettings.anchors.topMargin : 0)
                            + logLevelCombobox.height + logLevelCombobox.anchors.topMargin
                            + logPathField.height + logPathField.anchors.topMargin + marginValue

                    title: qsTrId("settings_general_logging") + Translator.translate

                    Row {
                        id: turnOnJournal

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        spacing: marginValue

                        SettingsCheckBox {
                            id: journalCheckbox

                            property bool logEnabled: SettingsState.logEnabled

                            checked: logEnabled

                            onCheckedChanged: {
                                if (checked != logEnabled) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.LogEnabled, checked);
                                }
                            }

                            onLogEnabledChanged: {
                                checked = logEnabled;
                            }
                        }

                        Label {
                            anchors.verticalCenter: journalCheckbox.verticalCenter
                            text: qsTrId("settings_general_use_log") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: statisticsSettings

                        anchors.top: turnOnJournal.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        visible: AppFeatures.sendTelemetryStatistics
                        spacing: marginValue

                        SettingsCheckBox {
                            id: statisticsCheckbox

                            property bool generalSendStatistics: SettingsState.generalSendStatistics

                            checked: generalSendStatistics

                            onCheckedChanged: {
                                if (checked != generalSendStatistics) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.SendStatistics, checked);
                                }
                            }

                            onGeneralSendStatisticsChanged: {
                                checked = generalSendStatistics;
                            }
                        }

                        Label {
                            anchors.verticalCenter: statisticsCheckbox.verticalCenter
                            text: qsTrId("settings_general_send_statistics") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Label {
                        id: logLevelLabel

                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.verticalCenter: logLevelCombobox.verticalCenter

                        text: qsTrId("settings_general_log_level") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsComboBox {
                        id: logLevelCombobox

                        anchors.top: statisticsSettings.visible ? statisticsSettings.bottom : turnOnJournal.bottom
                        anchors.topMargin: marginValue
                        anchors.left: logPathLabel.right
                        anchors.leftMargin: marginValue

                        model: SettingsState.logLevelModel
                        textRole: "name"

                        font.pixelSize: fontSize

                        property int logLevelModelSelectedIdx: SettingsState.logLevelModelSelectedIdx

                        currentIndex: logLevelModelSelectedIdx

                        onCurrentIndexChanged:  {
                            if (currentIndex != onCurrentIndexChanged) {
                                ActionProvider.markAppConfigUpdate(AppConfig.LogLevel, currentIndex);
                            }
                        }

                        onLogLevelModelSelectedIdxChanged: {
                            currentIndex = logLevelModelSelectedIdx;
                        }
                    }

                    SettingsButton {
                        id: errorReportButton

                        text: qsTrId("settings_general_error_report_button") + Translator.translate

                        anchors.verticalCenter: logLevelCombobox.verticalCenter
                        anchors.horizontalCenter: logButton.horizontalCenter

                        width: 170

                        enabled: !SettingsState.showArchivingLogsDialog
                        visible: !AppFeatures.disableErrorReports

                        onClicked: {
                            ActionProvider.createSupportInfo();
                        }
                    }

                    Label {
                        id: logPathLabel

                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.verticalCenter: logPathField.verticalCenter

                        text: qsTrId("settings_general_log_path") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: logPathField

                        anchors.top: logLevelCombobox.bottom
                        anchors.topMargin: marginValue
                        anchors.left: logLevelCombobox.left

                        width: 150

                        text: SettingsState.logPath
                        readOnly: true

                        onTextChanged: {
                            logPathField.cursorPosition = 0;
                        }
                    }

                    SettingsButton {
                        id: openLogButton

                        anchors.verticalCenter: logPathField.verticalCenter
                        anchors.left: logPathField.right
                        anchors.leftMargin: marginValue

                        width: 20

                        Image {
                            anchors.centerIn: parent

                            width: 14
                            height: 14

                            sourceSize.width: width
                            sourceSize.height: height

                            source: "qrc:/images/book_open.svg"
                        }

                        onClicked: {
                            ActionProvider.openLogFile();
                        }
                    }

                    SettingsButton {
                        id: logButton

                        text: qsTrId("settings_general_log_button") + Translator.translate

                        anchors.verticalCenter: openLogButton.verticalCenter
                        anchors.left: openLogButton.right
                        anchors.leftMargin: marginValue / 2

                        width: 170

                        onClicked: {
                            fileDialogLoader.sourceComponent = fileDialogComponent;
                        }
                    }
                }

                SettingsGroupBox {
                    id: groupBox

                    anchors.top: loggingSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: {
                        if(!visible) {
                            return 0
                        }
                        return pathToProgramLabel.height + pathToProgramLabel.anchors.topMargin + marginValue
                    }

                    title: qsTrId("settings_program_info") + Translator.translate

                    Label {
                        id: pathToProgramLabel

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        text: qsTrId("settings_path_to_program_dir") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: pathToProgramField
                        anchors.left: pathToProgramLabel.right
                        anchors.leftMargin: marginValue
                        anchors.verticalCenter: pathToProgramLabel.verticalCenter
                        implicitWidth: 230
                        readOnly: true
                        text: SettingsState.pathToProgramDir
                    }

                    SettingsButton {
                        id: showProgramDirButton

                        anchors.verticalCenter: pathToProgramField.verticalCenter
                        anchors.left: pathToProgramField.right
                        anchors.leftMargin: marginValue

                        text: qsTrId("settings_show_program_dir_button") + Translator.translate

                        onClicked: {
                            ActionProvider.showProgramPath(pathToProgramField.text);
                        }
                    }
                }
            }
        }

        Component {
            id: fileDialogComponent

            FileDialog {
                id: fileDialog

                title: qsTrId("settings_general_choose_log_path") + Translator.translate

                folder: shortcuts.home
                selectFolder: true

                onAccepted: {
                    fileDialogLoader.sourceComponent = null;
                    ActionProvider.markAppConfigUpdate(AppConfig.LogPath, fileDialog.folder);
                }

                onRejected: {
                    fileDialogLoader.sourceComponent = null;
                }

                Component.onCompleted: visible = true
            }
        }

        Loader {
            id: fileDialogLoader
        }

        Component {
            id: ringerSoundDialogComponent

            FileDialog {
                id: fileDialog

                title: qsTrId("settings_general_choose_ringer_sound_path") + Translator.translate

                folder: shortcuts.home
                nameFilters: [ "Wav files (*.wav)"]

                onAccepted: {
                    ringerSoundDialogLoader.sourceComponent = null;
                    ActionProvider.markAppConfigUpdate(AppConfig.RingingSound, fileDialog.fileUrl);
                }

                onRejected: {
                    ringerSoundDialogLoader.sourceComponent = null;
                }

                Component.onCompleted: visible = true
            }
        }

        Loader {
            id: ringerSoundDialogLoader
        }

        ArchivingLogsDialog {
            id: archivingDialog

            visible: SettingsState.showArchivingLogsDialog
        }
    }
}
