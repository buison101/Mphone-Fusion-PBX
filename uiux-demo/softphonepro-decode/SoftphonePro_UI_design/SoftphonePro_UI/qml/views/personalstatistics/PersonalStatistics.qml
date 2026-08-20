import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Window 2.15
import QtCharts 2.0
import Flux 1.0

import "../uicontrols" as SoftphonePro

FocusScope {
    id: root

    focus: true

    Rectangle {
        id: statisticsWindow

        property bool team: true

        function allCalls () {
            return AppState.personalStatistics.outgoingCallsCount + AppState.personalStatistics.incomingCallsCount
        }

        // calculation coordinates of circular sectors
        function allWorkTime () {
            return AppState.personalStatistics.oncallDuration + AppState.personalStatistics.naDuration +
                    AppState.personalStatistics.awayDuration + AppState.personalStatistics.downtime
        }

        function onCallPieBegin() {
            return Math.PI * 1.5
        }

        function onCallPieEnd() {
            if (AppState.personalStatistics.planningEnabled) {
                return Math.PI * 1.5 + 2 * Math.PI * AppState.personalStatistics.oncallDuration / 480
            } else {
                return Math.PI * 1.5 + 2 * Math.PI * AppState.personalStatistics.oncallDuration / statisticsWindow.allWorkTime()
            }
        }

        function naPieEnd() {
            if (AppState.personalStatistics.planningEnabled) {
                return statisticsWindow.onCallPieEnd() + 2 * Math.PI * AppState.personalStatistics.naDuration / 480
            } else {
                return statisticsWindow.onCallPieEnd() + 2 * Math.PI * AppState.personalStatistics.naDuration / statisticsWindow.allWorkTime()
            }
        }

        function downtimePieEnd() {
            if (AppState.personalStatistics.planningEnabled) {
                return statisticsWindow.naPieEnd() + 2 * Math.PI * AppState.personalStatistics.downtime / 480
            } else {
                return statisticsWindow.naPieEnd() + 2 * Math.PI * AppState.personalStatistics.downtime / statisticsWindow.allWorkTime()
            }
        }

        function awayPieEnd() {
            if (AppState.personalStatistics.planningEnabled) {
                return statisticsWindow.downtimePieEnd() + 2 * Math.PI * AppState.personalStatistics.awayDuration / 480
            } else {
                return statisticsWindow.downtimePieEnd() + 2 * Math.PI * AppState.personalStatistics.awayDuration / statisticsWindow.allWorkTime()
            }
        }

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
                anchors.leftMargin: 16 * SettingsState.scale
                anchors.left: parent.left

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.secondaryWindowTitleAndIcons

                text: qsTrId("statistics_window_label") + Translator.translate
            }
        }

        ColumnLayout {
            id: columnMail

            anchors.top: titleLayer.bottom
            anchors.topMargin: AppState.teamEnabled ? 8 * SettingsState.scale : 12 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            spacing: 15 * SettingsState.scale

            SoftphonePro.SeparatorWithAccount {
                id: separatorWithAccount

                Layout.fillWidth: true

                visible: AppState.teamEnabled

                account: AppState.personalStatistics.currentUserLogin
                currentCallDirection: SipCall.Unknown
            }

            Rectangle {
                id: connectRect

                height: 68 * SettingsState.scale
                Layout.fillWidth: true

                radius: 8 * SettingsState.scale

                visible: !AppState.teamEnabled

                color: ColorStorage.mainWindowBackground

                Text {
                    id: labelConnect

                    anchors.left: parent.left
                    anchors.leftMargin: 15 * SettingsState.scale
                    anchors.verticalCenter: connectRect.verticalCenter

                    width: connectRect.width * 0.6

                    font.pixelSize: 12 * SettingsState.scale
                    font.family: "Segoe UI"
                    text: qsTrId("statistics_connection_description").arg(StringStorage.appTitle) + Translator.translate
                    textFormat: Text.StyledText

                    wrapMode: "WordWrap"

                    color: ColorStorage.iconsAndTextSecondary
                }

                SoftphonePro.SquareButton {
                    id: connectButton

                    anchors.top: connectRect.top
                    anchors.topMargin: 18 * SettingsState.scale
                    anchors.left: labelConnect.right
                    anchors.leftMargin: 10 * SettingsState.scale
                    anchors.right: connectRect.right
                    anchors.rightMargin: 10 * SettingsState.scale
                    anchors.bottom: connectRect.bottom
                    anchors.bottomMargin: 18 * SettingsState.scale
                    anchors.verticalCenter: parent.verticalCenter

                    scale: SettingsState.scale

                    borderWidthDefault: 1 * SettingsState.scale
                    borderWidthOnHover: 1 * SettingsState.scale
                    borderWidthOnPress: 1 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    borderColorOnHover: ColorStorage.invertedBorder
                    borderColorDefault: ColorStorage.invertedBorder
                    borderColorOnPress: ColorStorage.invertedBorder

                    enabled: true

                    colorDefault: ColorStorage.mainWindowBackground
                    colorOnPress: ColorStorage.grayNeutralOnPress
                    colorOnHover: ColorStorage.grayNeutralOnHover

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 12 * SettingsState.scale
                        font.family: "Segoe UI"

                        text: qsTrId("settings_connect_button") + Translator.translate
                        color: ColorStorage.iconsAndTextPrimary
                    }

                    doWorkOnButtonClick: function() {
                        Qt.openUrlExternally(AppState.personalStatistics.connectionButtonUrl);
                    }
                }
            }
        }

        Rectangle{
            id: delimiter0

            anchors.top: columnMail.bottom
            anchors.topMargin: 10 * SettingsState.scale
            anchors.left : parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            height: 1 * SettingsState.scale

            visible: !AppState.teamEnabled

            color: ColorStorage.textAndDisabledIconsGrey
        }

        ColumnLayout {
            id: columnStartTime

            anchors.top: columnMail.bottom
            anchors.topMargin: AppState.teamEnabled ? 10 * SettingsState.scale : 20 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            RowLayout {
                id: startTime
                spacing: 30  * SettingsState.scale

                ColumnLayout {
                    id: factualColumn

                    spacing: 3 * SettingsState.scale
                    Text {
                        id: factualTime

                        font.pixelSize: 14 * SettingsState.scale
                        font.family: "Segoe UI"

                        color: ColorStorage.iconsAndTextSecondary
                        text: qsTrId("statistics_actual_shift_start") + Translator.translate
                    }

                    Text {
                        id: factualStartTime

                        font.pixelSize: 16 * SettingsState.scale
                        font.family: "Segoe UI"
                        font.bold: true

                        color: ColorStorage.iconsAndTextPrimary
                        text: AppState.personalStatistics.actualShiftStart
                    }

                }

                ColumnLayout {
                    id: actualColumn

                    visible: AppState.personalStatistics.planningEnabled

                    spacing: 3 * SettingsState.scale

                    Text {
                        id: actualTime

                        font.pixelSize: 14 * SettingsState.scale
                        font.family: "Segoe UI"

                        color: ColorStorage.iconsAndTextSecondary
                        text: qsTrId("statistics_work_shift") + Translator.translate
                    }

                    Text {
                        id: actualStartTime

                        font.pixelSize: 13 * SettingsState.scale
                        font.family: "Segoe UI"

                        color: ColorStorage.iconsAndTextPrimary
                        text: AppState.personalStatistics.planningEnabled ?
                                  "%1 - %2".arg(AppState.personalStatistics.planningStart).
                                  arg(AppState.personalStatistics.planningEnd) : "—"
                    }
                }
            }
        }

        Rectangle{
            id: delimiter1

            anchors.top: columnStartTime.bottom
            anchors.topMargin: 15 * SettingsState.scale
            anchors.left : parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            height: 1 * SettingsState.scale

            color: ColorStorage.textAndDisabledIconsGrey
        }

        ColumnLayout {
            id: columnCalls

            anchors.top: delimiter1.bottom
            anchors.topMargin: 15 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            height: 130 * SettingsState.scale

            RowLayout {
                id:calls

                Layout.fillWidth: true
                Layout.topMargin:0

                Text {
                    id: callLabel

                    Layout.fillWidth: true

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: qsTrId("statistics_calls") + Translator.translate
                }

                Text {
                    id: callNumAllLabel

                    Layout.rightMargin: 0

                    font.pixelSize: 16 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: "%1 /".arg(AppState.personalStatistics.outgoingCallsCount + AppState.personalStatistics.incomingCallsCount)
                }


                Text {
                    id: callNumAcceptedLabel

                    font.pixelSize: 16 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.additionalText
                    text: statisticsWindow.allCalls() > 0 ? "%1 (%2%)".arg(AppState.personalStatistics.answeredOutgoingCallsCount
                                                                           + AppState.personalStatistics.answeredIncomingCallsCount)
                                                            .arg(((AppState.personalStatistics.answeredOutgoingCallsCount + AppState.personalStatistics.answeredIncomingCallsCount)
                                                                  / statisticsWindow.allCalls() * 100).toFixed(0))
                                                          : "0 (0%)"
                }
            }

            RowLayout {
                id:callsIncomin

                Layout.fillWidth: true
                Layout.topMargin: 8 * SettingsState.scale

                Text {
                    id: callLabelIncoming

                    Layout.fillWidth: true

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary
                    text: qsTrId("call_history_selection_incoming") + Translator.translate
                }

                Text {
                    id: callNumAllIncomingLabel

                    Layout.rightMargin: 0

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: "%1".arg(AppState.personalStatistics.incomingCallsCount)
                }

                Text {
                    id: callNumAcceptedIncomingLabel

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.additionalText
                    text: AppState.personalStatistics.incomingCallsCount > 0 ? "/ %1 (%2%)".arg(AppState.personalStatistics.answeredIncomingCallsCount)
                                                                               .arg((AppState.personalStatistics.answeredIncomingCallsCount / AppState.personalStatistics.incomingCallsCount * 100).toFixed(0))
                                                                             : "/ 0 (0%)"
                }
            }

            ProgressBar {
                id: progressBarIncoming

                value: AppState.teamEnabled ? 1 - AppState.personalStatistics.answeredIncomingCallsCount / AppState.personalStatistics.incomingCallsCount : 0.01
                padding: 0.5

                Layout.fillWidth: true
                Layout.topMargin: 0

                background: Rectangle {
                    implicitWidth: 302 * SettingsState.scale
                    implicitHeight: 13 * SettingsState.scale

                    radius: 4

                    color: ColorStorage.windowBorder
                }

                contentItem: Item {
                    Rectangle {
                        width: progressBarIncoming.visualPosition * parent.width
                        height: parent.height

                        radius: 4

                        color: ColorStorage.additionalText
                    }
                }
            }

            RowLayout {
                id:callsOutgoing

                Layout.fillWidth: true
                Layout.topMargin:  2 * SettingsState.scale

                Text {
                    id: callLabelOutgoing

                    Layout.fillWidth: true

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary
                    text: qsTrId("call_history_selection_outgoing") + Translator.translate
                }

                Text {
                    id: callNumAllOutgoingLabel

                    Layout.rightMargin: 0

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: "%1".arg(AppState.personalStatistics.outgoingCallsCount)
                }

                Text {
                    id: callNumAcceptedOutgoingLabel

                    font.pixelSize: 14 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.additionalText
                    text: AppState.personalStatistics.outgoingCallsCount > 0 ? "/ %1 (%2%)".arg(AppState.personalStatistics.answeredOutgoingCallsCount)
                                                                               .arg((AppState.personalStatistics.answeredOutgoingCallsCount / AppState.personalStatistics.outgoingCallsCount * 100).toFixed(0))
                                                                             : "/ 0 (0%)"
                }
            }

            ProgressBar {
                id: progressBarOutgoing

                value: AppState.teamEnabled ? 1 - AppState.personalStatistics.answeredOutgoingCallsCount/AppState.personalStatistics.outgoingCallsCount : 0.01
                padding: 0.5

                Layout.fillWidth: true
                Layout.topMargin: 0

                background: Rectangle {
                    implicitWidth: 302 * SettingsState.scale
                    implicitHeight: 13 * SettingsState.scale
                    radius: 4

                    color: ColorStorage.windowBorder
                }

                contentItem: Item {

                    Rectangle {
                        width: progressBarOutgoing.visualPosition * parent.width
                        height: parent.height

                        radius: 4

                        color: ColorStorage.additionalText
                    }
                }
            }
        }

        Rectangle{
            id: delimiter2

            height: 1 * SettingsState.scale

            anchors.top: columnCalls.bottom
            anchors.topMargin: 15 * SettingsState.scale
            anchors.left : parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            color: ColorStorage.textAndDisabledIconsGrey
        }

        ColumnLayout{
            id: columnWorkTime

            spacing: 5 * SettingsState.scale

            anchors.top: delimiter2.bottom
            anchors.topMargin: 15 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            RowLayout {
                id: workTime

                Layout.fillWidth: true
                Layout.topMargin: 2 * SettingsState.scale

                Text {
                    id: workTimeLabel

                    Layout.fillWidth: true

                    font.pixelSize: 15 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: qsTrId("statistics_work_time") + Translator.translate
                }

                Text {
                    id: workLabel

                    Layout.rightMargin: SettingsState.scale

                    font.pixelSize: 13  * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary
                    text: qsTrId("statistics_hours_worked") + Translator.translate
                }

                Text {
                    id: workedTimeLabel

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                    text: statisticsWindow.allWorkTime() >= 60
                          ? qsTrId("statistics_hours_minutes").arg((statisticsWindow.allWorkTime() / 60 - 0.5).toFixed())
                            .arg(statisticsWindow.allWorkTime() % 60) + Translator.translate :
                            qsTrId("statistics_minutes").arg(statisticsWindow.allWorkTime()) + Translator.translate
                }
            }

            ProgressBar {
                id: progressBarWorked
                value: AppState.teamEnabled ? (AppState.personalStatistics.planningEnabled ? statisticsWindow.allWorkTime() / AppState.personalStatistics.workTime : 0) : 0.01
                padding: 0.5

                Layout.fillWidth: true
                Layout.topMargin: 4 * SettingsState.scale

                ToolTip {
                    visible: ma.containsMouse && AppState.teamEnabled && !AppState.personalStatistics.planningEnabled

                    delay: 1000
                    timeout: 3000
                    contentItem: Text {
                        text: qsTrId("statistics_scheduling_disabled") + Translator.translate
                        color: ColorStorage.mainWindowBackground
                        wrapMode: Text.WordWrap
                    }

                    background: Rectangle {
                        color: ColorStorage.iconsAndTextPrimary
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                }

                background: Rectangle {
                    implicitWidth: 302 * SettingsState.scale
                    implicitHeight: 13 * SettingsState.scale

                    radius: 4 * SettingsState.scale

                    color: ColorStorage.windowBorder
                }

                contentItem: Item {
                    Rectangle {
                        width: progressBarWorked.visualPosition * parent.width
                        height: parent.height

                        radius: 4

                        color: ColorStorage.additionalText
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    id: chartRect

                    width: 110 * SettingsState.scale
                    height: 110 * SettingsState.scale

                    color: "transparent"

                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignBottom
                    Layout.topMargin: 21 * SettingsState.scale

                    Rectangle {
                        anchors.centerIn: parent
                        antialiasing: true

                        width: 110 * SettingsState.scale
                        height: 110 * SettingsState.scale

                        radius: width/2

                        color: "transparent"

                        visible: !AppState.teamEnabled
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        antialiasing: true

                        width: 100 * SettingsState.scale
                        height: 100 * SettingsState.scale

                        radius: width/2

                        color: ColorStorage.personalStatisticsPieSeriesBackgroundColor
                    }

                    Canvas {
                        id: pieSeries

                        anchors.fill: parent

                        //property for update pieSeries
                        property string allTime: statisticsWindow.allWorkTime()
                        onAllTimeChanged: {
                            pieSeries.requestPaint()
                        }

                        antialiasing: true

                        onPaint: {
                            if (AppState.teamEnabled) {
                                var ctx = getContext("2d");
                                ctx.reset();

                                var centreX = width / 2;
                                var centreY = height / 2;

                                ctx.beginPath();
                                ctx.fillStyle = ColorStorage.personalStatisticsOnCallPieColor;
                                ctx.moveTo(centreX, centreY);
                                ctx.arc(centreX, centreY, width / 2, statisticsWindow.onCallPieBegin(), statisticsWindow.onCallPieEnd(), false);
                                ctx.lineTo(centreX, centreY);
                                ctx.fill();

                                ctx.beginPath();
                                ctx.fillStyle = ColorStorage.personalStatisticsNaPieColor;
                                ctx.moveTo(centreX, centreY);
                                ctx.arc(centreX, centreY, width / 2, statisticsWindow.onCallPieEnd(), statisticsWindow.naPieEnd(), false);
                                ctx.lineTo(centreX, centreY);
                                ctx.fill();

                                ctx.beginPath();
                                ctx.fillStyle = ColorStorage.personalStatisticsDowntimePieColor;
                                ctx.moveTo(centreX, centreY);
                                ctx.arc(centreX, centreY, width / 2, statisticsWindow.naPieEnd(), statisticsWindow.downtimePieEnd(), false);
                                ctx.lineTo(centreX, centreY);
                                ctx.fill();

                                ctx.beginPath();
                                ctx.fillStyle = ColorStorage.personalStatisticsAwayPieColor;
                                ctx.moveTo(centreX, centreY);
                                ctx.arc(centreX, centreY, width / 2, statisticsWindow.downtimePieEnd(), statisticsWindow.awayPieEnd(), false);
                                ctx.lineTo(centreX, centreY);
                                ctx.fill();
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: columnStatuses

                    spacing: 14 * SettingsState.scale

                    Layout.alignment: Qt.AlignBottom
                    Layout.fillHeight: true
                    Layout.leftMargin: 15 * SettingsState.scale
                    Layout.topMargin: 21 * SettingsState.scale

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            id: oncallColor

                            height: 22 * SettingsState.scale
                            width: 4 * SettingsState.scale

                            radius: 2

                            color: ColorStorage.personalStatisticsOnCallStatusesColor
                        }

                        Text {
                            id: oncallLabel

                            Layout.margins: SettingsState.scale
                            Layout.fillWidth: true

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.iconsAndTextPrimary
                            text: qsTrId("statistics_talk") + Translator.translate
                        }

                        Text {
                            id: oncallTimeLabel

                            Layout.rightMargin: 5 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"
                            font.bold: true

                            color: ColorStorage.iconsAndTextPrimary
                            // "- 0.5"  - rounding down
                            text: AppState.personalStatistics.oncallDuration >= 60 ?
                                      qsTrId("statistics_hours_minutes").arg((AppState.personalStatistics.oncallDuration / 60 - 0.5).toFixed())
                                      .arg(AppState.personalStatistics.oncallDuration % 60) + Translator.translate :
                                      qsTrId("statistics_minutes").arg(AppState.personalStatistics.oncallDuration) + Translator.translate
                        }

                        Text {
                            id: onCallPercentTimeLabel

                            Layout.rightMargin: 8 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.additionalText
                            text: statisticsWindow.allWorkTime() > 0 ? "%1%".arg((AppState.personalStatistics.oncallDuration /
                                                                                  statisticsWindow.allWorkTime() * 100).toFixed()) : "0%"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            id: naColor

                            height: 22 * SettingsState.scale
                            width: 4 * SettingsState.scale

                            radius: 2

                            color: ColorStorage.personalStatisticsNaStatusesColor
                        }

                        Text {
                            id: naLabel

                            Layout.margins: SettingsState.scale
                            Layout.fillWidth: true

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.iconsAndTextPrimary
                            text: qsTrId("phone_status_na") + Translator.translate
                        }

                        Text {
                            id: naTimeLabel

                            Layout.rightMargin: 5 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"
                            font.bold: true

                            color: ColorStorage.iconsAndTextPrimary
                            // "- 0.5"  - rounding down
                            text: AppState.personalStatistics.naDuration >= 60 ?
                                      qsTrId("statistics_hours_minutes").arg((AppState.personalStatistics.naDuration / 60 - 0.5).toFixed())
                                      .arg(AppState.personalStatistics.naDuration % 60) + Translator.translate :
                                      qsTrId("statistics_minutes").arg(AppState.personalStatistics.naDuration) + Translator.translate
                        }

                        Text {
                            id: naPercentTimeLabel

                            Layout.rightMargin: 8 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.additionalText
                            text: statisticsWindow.allWorkTime() > 0 ? "%1%".arg((AppState.personalStatistics.naDuration /
                                                                                 statisticsWindow.allWorkTime() * 100).toFixed()) : "0%"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            id: awayColor

                            height: 22 * SettingsState.scale
                            width: 4 * SettingsState.scale
                            radius: 2
                            color: ColorStorage.personalStatisticsAwayStatusesColor
                        }

                        Text {
                            id: awayLabel

                            Layout.margins: SettingsState.scale
                            Layout.fillWidth: true

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.iconsAndTextPrimary
                            text: qsTrId("contact_status_away") + Translator.translate
                        }

                        Text {
                            id: awayTimeLabel

                            Layout.rightMargin: 5 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"
                            font.bold: true

                            color: ColorStorage.iconsAndTextPrimary
                            // "- 0.5"  - rounding down
                            text: AppState.personalStatistics.awayDuration >= 60 ?
                                      qsTrId("statistics_hours_minutes").arg((AppState.personalStatistics.awayDuration / 60 - 0.5).toFixed())
                                      .arg(AppState.personalStatistics.awayDuration % 60) + Translator.translate :
                                      qsTrId("statistics_minutes").arg(AppState.personalStatistics.awayDuration) + Translator.translate
                        }

                        Text {
                            id: awayPercentTimeLabel

                            Layout.rightMargin: 8 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.additionalText
                            text: statisticsWindow.allWorkTime() > 0 ? "%1%".arg((AppState.personalStatistics.awayDuration /
                                                                                  statisticsWindow.allWorkTime() * 100).toFixed()) : "0%"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            id: downtimeColor
                            height: 22 * SettingsState.scale
                            width: 4 * SettingsState.scale
                            radius: 2
                            color: ColorStorage.personalStatisticsDowntimeStatusesColor
                        }

                        Text {
                            id: downtimeLabel

                            Layout.margins: SettingsState.scale
                            Layout.fillWidth: true

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.iconsAndTextPrimary
                            text: qsTrId("statistics_idle") + Translator.translate
                        }

                        Text {
                            id: downtimeTimeLabel

                            Layout.rightMargin: 5 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"
                            font.bold: true

                            color: ColorStorage.iconsAndTextPrimary
                            // "- 0.5"  - rounding down
                            text: AppState.personalStatistics.downtime >= 60 ?
                                      qsTrId("statistics_hours_minutes").arg((AppState.personalStatistics.downtime / 60 - 0.5).toFixed())
                                      .arg(AppState.personalStatistics.downtime % 60) + Translator.translate :
                                      qsTrId("statistics_minutes").arg(AppState.personalStatistics.downtime) + Translator.translate
                        }

                        Text {
                            id: downtimePercentTimeLabel

                            Layout.rightMargin: 8 * SettingsState.scale

                            font.pixelSize: 12  * SettingsState.scale
                            font.family: "Segoe UI"

                            color: ColorStorage.additionalText
                            text: statisticsWindow.allWorkTime() > 0 ? "%1%".arg((AppState.personalStatistics.downtime /
                                                                                  statisticsWindow.allWorkTime() * 100).toFixed()) : "0%"
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: AppState.teamEnabled
            height: 30 * SettingsState.scale

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            color: ColorStorage.surfaceSecondary

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                font.pixelSize: 14 * SettingsState.scale
                font.family: "Segoe UI"

                visible: AppState.personalStatistics.refreshTime != ""
                color: ColorStorage.iconsAndTextPrimary
                text: qsTrId("statistics_updates").arg(AppState.personalStatistics.refreshTime)  + Translator.translate
            }

        }
    }
}
