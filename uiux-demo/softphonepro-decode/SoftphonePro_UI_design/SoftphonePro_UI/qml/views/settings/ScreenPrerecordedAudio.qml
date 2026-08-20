import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../uicontrols"
import "../dialogs"
import "../utils"

Flickable {
    id: flickable

    ScrollBar.vertical: ScrollBar {}

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int maringsValue: 23
    property int fontSize: 11

    property int idx

    clip: true

    Formatter {
        id: fmt
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: maringsValue
            anchors.leftMargin: maringsValue
            anchors.rightMargin: maringsValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id:  prerecordedFilesSettings

                anchors.top: description.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                height: description.height + description.anchors.topMargin + firstFile.height + firstFile.anchors.topMargin + secondFile.height
                        + secondFile.anchors.topMargin + thirdFile.height + thirdFile.anchors.topMargin + maringsValue / 2

                enabled: !AppState.instanceDisabled

                title: qsTrId("settings_prerecorded_audio") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: maringsValue
                    anchors.left: parent.left
                    anchors.leftMargin: maringsValue
                    anchors.right: parent.right
                    anchors.rightMargin: maringsValue

                    text: qsTrId("settings_prerecorded_audio_description").arg(StringStorage.appTitle) + Translator.translate
                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                }

                SettingsGroupBox {
                    id:  firstFile

                    anchors.top: description.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin:  maringsValue
                    anchors.leftMargin: maringsValue
                    anchors.rightMargin: maringsValue

                    enabled: !AppState.instanceDisabled

                    height: firstFilePlayButton.height + firstFilePathButton.height + audioPathLabel.anchors.topMargin + maringsValue

                    title: qsTrId("settings_prerecorded_audio_label") + Translator.translate + " " + 1


                    Label {
                        id: audioNameLabel

                        anchors.top: parent.top
                        anchors.topMargin: maringsValue
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_name") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        id: audioPathLabel

                        anchors.top: audioNameLabel.bottom
                        anchors.topMargin: maringsValue * 1.5
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_file_path") + Translator.translate
                        font.pixelSize: fontSize
                    }


                    SettingsTextField {
                        id: firstFileNameField

                        anchors {
                            verticalCenter: audioNameLabel.verticalCenter
                            left: audioPathLabel.width > audioNameLabel.width ? audioPathLabel.right :  audioNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[0].name

                        onTextChanged: {
                            ActionProvider.markPrerecordedFileUpdate(PrerecordedAudioFile.Name,
                                                                     {id: 0, name: text});
                        }
                    }

                    SettingsTextField {
                        id: firstFilePathField

                        anchors {
                            verticalCenter: audioPathLabel.verticalCenter
                            left: audioPathLabel.width > audioNameLabel.width ? audioPathLabel.right :  audioNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[0].path

                        readOnly: true

                        onTextChanged: {
                            firstFilePathField.cursorPosition = 0;
                        }
                    }

                    SettingsButton {
                        id: firstFilePlayButton

                        text: qsTrId("settings_prerecorded_audio_play_button") + Translator.translate

                        anchors.top: firstFileNameField.top
                        anchors.left: firstFileNameField.right

                        anchors.leftMargin: maringsValue

                        onClicked: {
                            ActionProvider.startPlayRecord(SettingsState.prerecordedFiles[0].path);
                        }
                    }

                    SettingsButton {
                        id: firstFilePathButton

                        text: qsTrId("settings_prerecorded_audio_browse_button") + Translator.translate

                        anchors.top: firstFilePathField.top
                        anchors.left: firstFilePathField.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 0;
                            prerecordedFilePathDialogLoader.sourceComponent = prerecordedFilePathDialog;

                        }
                    }

                    SettingsButton {
                        id: firstFileRecordButton

                        text: qsTrId("settings_prerecorded_audio_record_button") + Translator.translate

                        anchors.top: firstFilePathField.top
                        anchors.left: firstFilePathButton.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 0;
                            ActionProvider.showRecordingAudioFileDialog("message1.wav")
                        }
                    }
                }

                SettingsGroupBox {
                    id:  secondFile

                    anchors.top: firstFile.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: maringsValue
                    anchors.leftMargin: maringsValue
                    anchors.rightMargin: maringsValue

                    enabled: !AppState.instanceDisabled

                    height: secondFilePlayButton.height + secondFilePathButton.height + secondPathLabel.anchors.topMargin + maringsValue

                    title: qsTrId("settings_prerecorded_audio_label") + Translator.translate + " " + 2


                    Label {
                        id: secondNameLabel

                        anchors.top: parent.top
                        anchors.topMargin: maringsValue
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_name") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        id: secondPathLabel

                        anchors.top: secondNameLabel.bottom
                        anchors.topMargin: maringsValue * 1.5
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_file_path") + Translator.translate
                        font.pixelSize: fontSize
                    }


                    SettingsTextField {
                        id: secondFileNameField

                        anchors {
                            verticalCenter: secondNameLabel.verticalCenter
                            left: secondPathLabel.width > secondNameLabel.width ? secondPathLabel.right :  secondNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[1].name

                        onTextChanged: {
                            ActionProvider.markPrerecordedFileUpdate(PrerecordedAudioFile.Name,
                                                                     {id: 1, name: text});
                        }
                    }

                    SettingsTextField {
                        id: secondFilePathField

                        anchors {
                            verticalCenter: secondPathLabel.verticalCenter
                            left: secondPathLabel.width > secondNameLabel.width ? secondPathLabel.right :  secondNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[1].path

                        readOnly: true

                        onTextChanged: {
                            secondFilePathField.cursorPosition = 0;
                        }
                    }

                    SettingsButton {
                        id: secondFilePlayButton

                        text: qsTrId("settings_prerecorded_audio_play_button") + Translator.translate

                        anchors.top: secondFileNameField.top
                        anchors.left: secondFileNameField.right

                        anchors.leftMargin: maringsValue

                        onClicked: {
                            ActionProvider.startPlayRecord(SettingsState.prerecordedFiles[1].path);
                        }
                    }

                    SettingsButton {
                        id: secondFilePathButton

                        text: qsTrId("settings_prerecorded_audio_browse_button") + Translator.translate

                        anchors.top: secondFilePathField.top
                        anchors.left: secondFilePathField.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 1;
                            prerecordedFilePathDialogLoader.sourceComponent = prerecordedFilePathDialog;

                        }
                    }

                    SettingsButton {
                        id: secondFileRecordButton

                        text: qsTrId("settings_prerecorded_audio_record_button") + Translator.translate

                        anchors.top: secondFilePathField.top
                        anchors.left: secondFilePathButton.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 1;
                            ActionProvider.showRecordingAudioFileDialog("message2.wav")
                        }
                    }
                }

                SettingsGroupBox {
                    id:  thirdFile

                    anchors.top: secondFile.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: maringsValue
                    anchors.leftMargin: maringsValue
                    anchors.rightMargin: maringsValue

                    enabled: !AppState.instanceDisabled

                    height: thirdFilePlayButton.height + thirdFilePathButton.height + thirdPathLabel.anchors.topMargin + maringsValue

                    title: qsTrId("settings_prerecorded_audio_label") + Translator.translate + " " + 3


                    Label {
                        id: thirdNameLabel

                        anchors.top: parent.top
                        anchors.topMargin: maringsValue
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_name") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        id: thirdPathLabel

                        anchors.top: thirdNameLabel.bottom
                        anchors.topMargin: maringsValue * 1.5
                        anchors.left: parent.left
                        anchors.leftMargin: maringsValue

                        text: qsTrId("settings_prerecorded_audio_file_path") + Translator.translate
                        font.pixelSize: fontSize
                    }


                    SettingsTextField {
                        id: thirdFileNameField

                        anchors {
                            verticalCenter: thirdNameLabel.verticalCenter
                            left: thirdPathLabel.width > thirdNameLabel.width ? thirdPathLabel.right :  thirdNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[2].name

                        onTextChanged: {
                            ActionProvider.markPrerecordedFileUpdate(PrerecordedAudioFile.Name,
                                                                     {id: 2, name: text});
                        }
                    }

                    SettingsTextField {
                        id: thirdFilePathField

                        anchors {
                            verticalCenter: thirdPathLabel.verticalCenter
                            left: thirdPathLabel.width > thirdNameLabel.width ? thirdPathLabel.right :  thirdNameLabel.right
                            leftMargin: maringsValue
                        }

                        width: 150

                        text: SettingsState.prerecordedFiles[2].path

                        readOnly: true

                        onTextChanged: {
                            thirdFilePathField.cursorPosition = 0;
                        }
                    }

                    SettingsButton {
                        id: thirdFilePlayButton

                        text: qsTrId("settings_prerecorded_audio_play_button") + Translator.translate

                        anchors.top: thirdFileNameField.top
                        anchors.left: thirdFileNameField.right

                        anchors.leftMargin: maringsValue

                        onClicked: {
                            ActionProvider.startPlayRecord(SettingsState.prerecordedFiles[2].path);
                        }
                    }

                    SettingsButton {
                        id: thirdFilePathButton

                        text: qsTrId("settings_prerecorded_audio_browse_button") + Translator.translate

                        anchors.top: thirdFilePathField.top
                        anchors.left: thirdFilePathField.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 2;
                            prerecordedFilePathDialogLoader.sourceComponent = prerecordedFilePathDialog;

                        }
                    }

                    SettingsButton {
                        id: thirdFileRecordButton

                        text: qsTrId("settings_prerecorded_audio_record_button") + Translator.translate

                        anchors.top: thirdFilePathField.top
                        anchors.left: thirdFilePathButton.right
                        anchors.leftMargin: maringsValue

                        onClicked: {
                            idx = 2;
                            ActionProvider.showRecordingAudioFileDialog("message1.wav")
                        }
                    }
                }
            }
        }
    }

    Component {
        id: prerecordedFilePathDialog

        FileDialog {
            id: fileDialog

            title: qsTrId("settings_general_choose_ringer_sound_path") + Translator.translate

            folder: shortcuts.home
            nameFilters: [ "Wav files (*.wav)"]

            onAccepted: {
                prerecordedFilePathDialogLoader.sourceComponent = null;
                ActionProvider.markPrerecordedFileUpdate(PrerecordedAudioFile.Path,
                                                         {id: idx, path: fileDialog.fileUrl});
            }

            onRejected: {
                prerecordedFilePathDialogLoader.sourceComponent = null;
            }

            Component.onCompleted: visible = true
        }
    }

    Loader {
        id: prerecordedFilePathDialogLoader
    }

    RecordingAudioFileDialog {
        id: fileRecordingDialog
        width: 250
        height: 115

        message: AppState.recordAudioFileStatus == RecordAudioFileStatus.RecordingEnabled ?
                     qsTrId("settings_prerecorded_audio_record_enable") + Translator.translate + ":" + " " +
                     fmt.formatDuration(AppState.timeNow - AppState.startRecordTime) :
                     qsTrId("settings_prerecorded_audio_record_error") + Translator.translate

        buttonText: AppState.recordAudioFileStatus == RecordAudioFileStatus.RecordingEnabled ?
                        qsTrId("settings_prerecorded_audio_button_stop") + Translator.translate :
                        qsTrId("dialog_button_ok") + Translator.translate

        visible: SettingsState.showFileRecordingDialog

        onVisibleChanged: ActionProvider.setStartRecordTime()

        onOKAction: function() {
            ActionProvider.stopRecordingAudioFile();
            if (AppState.recordAudioFileStatus != RecordAudioFileStatus.RecordingError) {
                var number = idx + 1;
                ActionProvider.markPrerecordedFileUpdate(PrerecordedAudioFile.Path,
                                                         {id: idx, path: SettingsState.appDefaultPrerecordPath + "message" + number + ".wav"});
            }
        }
    }
}

