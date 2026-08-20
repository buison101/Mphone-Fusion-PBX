import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.4 as OldControls
import QtQuick.Controls.Styles 1.4
import Flux 1.0
import "../utils"

FocusScope {
    id: root

    property alias hoverWide: body.width
    property alias hoverHeigth: body.height

    property alias title: title.text
    property alias titleSize: title.font.pixelSize

    property int popupX: 0
    property int popupY: 0

    property bool alignRight: false

    property bool focusFromTagDropdown: false
    property var selectedDate: new Date()

    property var hours: hours.text
    property var minutes: minutes.text

    implicitWidth: hoverWide
    implicitHeight: hoverHeigth

    property alias selectionSize: selection.font.pixelSize

    focus: true

    property var openDropdown: function() {
        dropdownLoader.item.dropdown.open();
        dropdownLoader.item.dropdown.forceActiveFocus();
    }

    property var closeDropdown: function() {
        dropdownLoader.item.dropdown.close();
    }

    property var backtabRefocus: function() {}
    property var tabRefocus: function() {}

    onActiveFocusChanged: {
        if (!activeFocus) {
            return;
        }
        if (focusFromTagDropdown) {
            calendarFocusScope.forceActiveFocus();
        } else {
            minutes.forceActiveFocus();
        }
    }


    Keys.onSpacePressed: {
        openDropdown();
    }

    onVisibleChanged: {
        if (!root.visible) {
            closeDropdown();
        }

        hours.text = Qt.formatTime(new Date(), "hh");
        minutes.text = Qt.formatTime(new Date(), "mm");
        selectedDate = new Date();
    }

    Rectangle {
        id: body

        implicitWidth: {
            if (title.width  > 102 * SettingsState.scale ) {
                return (title.width + 15);
            }
            else {
                return 110 * SettingsState.scale;
            }
        }

        implicitHeight: selection.height + 18 * SettingsState.scale

        readonly property string colorDefault: ColorStorage.mainWindowBackground
        readonly property string colorOnHover: ColorStorage.mSizeButtonOnHover
        readonly property string colorOnPress: ColorStorage.mainWindowBackground

        color: ColorStorage.secondaryWindowBackground

        focus: true

        Rectangle {
            id: bodyBacklight

            implicitWidth: calendarFocusScope.width
            implicitHeight: selection.height + 18 * SettingsState.scale

            radius: 8 * SettingsState.scale

            focus: true

            color: body.colorDefault
        }

        Column {
            anchors.fill: parent
            anchors.margins: 6 * SettingsState.scale

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter

                visible: !selection.text

                font.family: "Segoe UI"
                font.pixelSize: 14 * SettingsState.scale

                color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.disabledButtonsGrey
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter

                width: body.width - timeRow.implicitWidth - 32 * SettingsState.scale
                height: selection.height

                Text {
                    id: selection

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: chevronImage.left
                    anchors.rightMargin: 5 * SettingsState.scale

                    elide: Text.ElideRight

                    font.family: "Segoe UI"
                    font.pixelSize: 16 * SettingsState.scale

                    color: calendarFocusScope.activeFocus || mouseArea.containsMouse ? ColorStorage.iconsAndTextPrimary : (!root.enabled ? ColorStorage.textAndDisabledIconsGrey :
                                                                                                                                                    ColorStorage.iconsAndTextSecondary)

                    text: root.selectedDate != "" ? root.selectedDate.toLocaleDateString(Qt.locale, Locale.ShortFormat) : "";
                }

                Image {
                    id: chevronImage

                    property string chevronImageColorDefault: ColorStorage.additionalText

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: false

                    width: 18 * SettingsState.scale
                    height: 18 * SettingsState.scale

                    source: "qrc:/images/chevron_down.svg"
                }

                IconShader {
                    anchors.centerIn: chevronImage
                    imageSrcComponent: chevronImage
                    imgColor: chevronImage.chevronImageColorDefault
                    imageWidth: chevronImage.width
                    imageHeight: chevronImage.height
                }
            }
        }

        Row {
            id: reminderRow

            anchors.top: body.top
            anchors.right: root.alignRight ? body.right : undefined
            anchors.left: root.alignRight ? undefined : body.left

            spacing: 12 * SettingsState.scale

            FocusScope {
                id: calendarFocusScope

                implicitWidth: hoverWide - timeRow.implicitWidth - 12 * SettingsState.scale
                implicitHeight: hoverHeigth

                focus: true

                KeyNavigation.tab: hours
                Keys.onBacktabPressed: root.backtabRefocus();

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true

                    onEntered: {
                        bodyBacklight.color = body.colorOnHover;
                    }

                    onExited: {
                        bodyBacklight.color = body.colorDefault;
                    }

                    onPressed: {
                        bodyBacklight.color = body.colorOnPress;
                        dropdownLoader.item.dropdown.open();
                        dropdownLoader.item.dropdown.forceActiveFocus();
                    }

                    onReleased: {
                        bodyBacklight.color = body.colorDefault;
                    }
                }

                Component {
                    id: dropdownComponent

                    ApplicationWindow {
                        id: window

                        property alias dropdown: dropdown

                        flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint |
                               Qt.WindowStaysOnTopHint

                        x: root.popupX + (root.width - width) / 2
                        y: root.popupY

                        width: scope.width
                        height: scope.height

                        visible: dropdown.visible

                        FocusScope {
                            id: scope

                            implicitWidth: dropdown.implicitWidth - 24 * SettingsState.scale
                            implicitHeight: dropdown.implicitHeight - 24 * SettingsState.scale

                            focus: true

                            Popup {
                                id: dropdown

                                closePolicy: Popup.CloseOnPressOutside

                                property bool alreadyClosed: false

                                onActiveFocusChanged: {
                                    if (alreadyClosed) {
                                        alreadyClosed = false;
                                        return;
                                    }

                                    if (!activeFocus) {
                                        closeDropdown();
                                    }
                                }

                                contentItem: Rectangle {
                                    anchors.fill: parent

                                    color: "transparent"

                                    OldControls.Calendar {
                                        id: calendar

                                        selectedDate: new Date()

                                        minimumDate: new Date()
                                        maximumDate: new Date(2075, 0, 1)

                                        frameVisible: true

                                        style: CalendarStyle {
                                            gridVisible: true
                                            gridColor: ColorStorage.windowBorder

                                            dayDelegate: Rectangle {
                                                color: styleData.selected ? ColorStorage.mainWindowBackground : ColorStorage.surfaceSecondary

                                                Label {
                                                    anchors.centerIn: parent

                                                    text: styleData.date.getDate()

                                                    color: styleData.valid ? ColorStorage.iconsAndTextPrimary : ColorStorage.textAndDisabledIconsGrey
                                                }
                                            }

                                            navigationBar: Rectangle {
                                                height: calendar.height / 7

                                                color: ColorStorage.surfaceSecondary

                                                Rectangle {
                                                    id: prevMonthBody

                                                    anchors.left: parent.left
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    height: parent.height
                                                    width: height

                                                    color: ColorStorage.surfaceSecondary

                                                    Label {
                                                        anchors.centerIn: parent

                                                        text: "<"
                                                        font.pixelSize: 18 * SettingsState.scale

                                                        color: ColorStorage.iconsAndTextPrimary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent

                                                        onPressed: {
                                                            parent.color = ColorStorage.mainWindowBackground;
                                                            calendar.showPreviousMonth()
                                                        }

                                                        onReleased: {
                                                            parent.color = ColorStorage.surfaceSecondary;
                                                        }
                                                    }
                                                }

                                                Label {
                                                    id: date

                                                    anchors.left: prevMonthBody.right
                                                    anchors.right: nextMonthBody.left

                                                    height: parent.height

                                                    text: styleData.title
                                                    font.pixelSize: 14 * SettingsState.scale

                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter

                                                    color: ColorStorage.iconsAndTextPrimary
                                                }

                                                Rectangle {
                                                    id: nextMonthBody

                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    height: parent.height
                                                    width: height

                                                    color: ColorStorage.surfaceSecondary

                                                    Label {
                                                        anchors.centerIn: parent

                                                        text: ">"
                                                        font.pixelSize: 20 * SettingsState.scale

                                                        color: ColorStorage.iconsAndTextPrimary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent

                                                        onPressed: {
                                                            parent.color = ColorStorage.mainWindowBackground;
                                                            calendar.showNextMonth()
                                                        }

                                                        onReleased: {
                                                            parent.color = ColorStorage.surfaceSecondary;
                                                        }
                                                    }
                                                }
                                            }

                                            dayOfWeekDelegate: Rectangle {
                                                height: calendar.height / 7

                                                color: ColorStorage.surfaceSecondary

                                                Label {
                                                    anchors.centerIn: parent

                                                    text: calendar.locale.dayName(styleData.dayOfWeek, calendar.dayOfWeekFormat)
                                                    font.pixelSize: 14 * SettingsState.scale

                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                            }

                                            background: Rectangle {
                                                implicitHeight: 250 * SettingsState.scale
                                                implicitWidth: 260 * SettingsState.scale

                                                color: ColorStorage.surfaceSecondary
                                            }
                                        }

                                        onClicked: {
                                            dropdown.alreadyClosed = true;
                                            dropdown.close();
                                            root.forceActiveFocus();
                                        }

                                        onSelectedDateChanged: {
                                            root.selectedDate = calendar.selectedDate;
                                        }

                                        onVisibleChanged: {
                                            calendar.selectedDate = root.selectedDate;
                                        }
                                    }
                                }

                                background: Rectangle {
                                    border.color: ColorStorage.sSizeButtonBorderDefault
                                    border.width: 1 * SettingsState.scale
                                    color: ColorStorage.surfaceSecondary
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: dropdownLoader

                    sourceComponent: dropdownComponent
                }
            }

            Row {
                id: timeRow

                anchors.verticalCenter: calendarFocusScope.verticalCenter

                spacing: 2 * SettingsState.scale

                Rectangle {
                    id: hoursBody

                    width: height - 4 * SettingsState.scale
                    height: bodyBacklight.height

                    radius: 8 * SettingsState.scale

                    color: ColorStorage.mainWindowBackground

                    border.color: hours.activeFocus ? ColorStorage.grayNeutralOnPress : "transparent"
                    border.width: 1 * SettingsState.scale

                    TextInput {
                        id: hours

                        anchors.fill: parent

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: Qt.formatTime(new Date(),"hh")
                        font.pixelSize: 13 * SettingsState.scale

                        color: ColorStorage.iconsAndTextPrimary

                        validator: IntValidator {
                            bottom: 0
                            top: 23
                        }

                        KeyNavigation.tab: minutes
                        KeyNavigation.backtab: calendarFocusScope

                        onTextChanged: {
                            if (text.length == 1 && text * 1 + 0 > 2) {
                                text = timeRow.leadZero(text);
                            }
                            if (text.length == 2) {
                                minutes.forceActiveFocus();
                            }
                        }

                        onFocusChanged: {
                            if (!focus) {
                                text = timeRow.leadZero(text);
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: false

                        cursorShape: Qt.IBeamCursor
                    }
                }

                Label {
                    anchors.verticalCenter: hoursBody.verticalCenter

                    text: ":"
                    font.pixelSize: 15 * SettingsState.scale
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary
                }

                Rectangle {
                    id: minutesBody

                    width: height - 4 * SettingsState.scale
                    height: bodyBacklight.height

                    radius: 8 * SettingsState.scale

                    color: ColorStorage.mainWindowBackground

                    border.color: minutes.activeFocus ? ColorStorage.grayNeutralOnPress : "transparent"
                    border.width: 1 * SettingsState.scale

                    TextInput {
                        id: minutes

                        anchors.fill: parent

                        color: ColorStorage.iconsAndTextPrimary

                        text: Qt.formatTime(new Date(),"mm")
                        font.pixelSize: 13 * SettingsState.scale

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        width: 25 * SettingsState.scale
                        height: width

                        validator: IntValidator {
                            bottom: 0
                            top: 59
                        }

                        Keys.onTabPressed: root.tabRefocus();
                        KeyNavigation.backtab: hours

                        onTextChanged: {
                            if ((text.length == 1 && text * 1 + 0 > 5) || text.length > 2) {
                                text = timeRow.leadZero(text);
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: false

                        cursorShape: Qt.IBeamCursor
                    }
                }

                function leadZero(num) {
                    var s = "00" + num;
                    return s.substr(s.length - 2);
                }
            }
        }
    }
}
