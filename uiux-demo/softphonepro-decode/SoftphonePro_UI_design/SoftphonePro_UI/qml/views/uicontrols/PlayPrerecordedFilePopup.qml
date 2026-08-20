import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../dialogs"

FocusScope {
    id: root

    focus: true
    implicitWidth: mesagesDropdownLoader.width
    implicitHeight: mesagesDropdownLoader.height
    property bool fromIncomingWindow: false

    property bool alwaysOnTop: false

    onImplicitWidthChanged: {
        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
            phonesDropdownLoader.item.x = root.x;
        }
    }

    onImplicitHeightChanged: {
        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
            phonesDropdownLoader.item.y = root.y;
        }
    }

    function open() {

        mesagesDropdownLoader.item.dropdown.open();
        mesagesDropdownLoader.item.requestActivate();

        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
        }

        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
        }

        mesagesDropdownLoader.item.x = root.x;
        mesagesDropdownLoader.item.y = root.y;

        root.implicitWidth = Qt.binding(function() { return mesagesDropdownLoader.item.width; });
        root.implicitHeight = Qt.binding(function() { return mesagesDropdownLoader.item.height; });
    }

    Component {
        id: messagesDropdownComponent

        ApplicationWindow {
            id: window

            property alias dropdown: dropdown

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

            width: scope.width + 10 * SettingsState.scale
            height: scope.height + 10 * SettingsState.scale
            color: "transparent"
            visible: dropdown.visible

            property bool alwaysOnTop: root.alwaysOnTop

            onAlwaysOnTopChanged: {
                var flags = window.flags;
                flags = root.alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                         : (flags & ~Qt.WindowStaysOnTopHint);
                window.flags = flags;
            }

            FocusScope {
                id: scope

                implicitWidth: dropdown.width
                implicitHeight: dropdown.height
                anchors.centerIn: parent
                focus: true

                property var doWorkOnListItemClick: function(path) {
                    if (AppState.activeCall) {
                        if (fromIncomingWindow) {
                            ActionProvider.answerCall(AppState.activeCall.id);
                            AppLogger.debug("Incoming window: User clicked Answer button");
                        }
                        ActionProvider.playPrerecordedFile(path);
                    }
                }

                Popup {
                    id: dropdown

                    property int viewElementMaxWidth: 300 * SettingsState.scale
                    property int viewElementWidth: 0 * SettingsState.scale
                    property int viewElementHeight: 40 * SettingsState.scale
                    property int viewMaxElementCount: 10 * SettingsState.scale

                    // add border in 1 px
                    width: view.count ? viewElementWidth + 2 * SettingsState.scale : message.width
                    height: {
                        if (view.count == 0) {
                            return message.height;
                        }

                        var rowCount = viewMaxElementCount > view.count ?
                                    view.count : viewMaxElementCount;

                        return viewElementHeight * rowCount + 2 * SettingsState.scale;
                    }

                    closePolicy: Popup.CloseOnPressOutside
                    focus: true

                    contentItem: Rectangle {
                        anchors.fill: parent
                        color: "transparent"

                        Rectangle {
                            id: body
                            anchors.fill: parent
                            color: "transparent"

                            ListView {
                                id: view

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 1 * SettingsState.scale

                                model: AppState.prerecordedFileModel

                                highlightFollowsCurrentItem: false

                                interactive: true
                                focus: true

                                clip: true

                                visible: count > 0

                                enabled: visible

                                ScrollBar.vertical: ScrollBar {
                                    id: scrollBar
                                    active: view.activeFocus && view.count > dropdown.viewMaxElementCount
                                }

                                Keys.onUpPressed: {
                                    scrollBar.decrease();
                                    view.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    scrollBar.increase();
                                    view.incrementCurrentIndex();
                                }

                                Keys.onEscapePressed: {
                                    dropdown.visible = false;
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                delegate: Rectangle {
                                    id: delegateBody

                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewElementHeight
                                    radius: (index == 0 || index == view.count - 1) ? 8 * SettingsState.scale : 0
                                    readonly property string colorDefault: ColorStorage.mainWindowBackground
                                    readonly property string colorOnHover: ColorStorage.surfaceSecondary

                                    color: colorDefault

                                    Shortcut {
                                        enabled: true
                                        sequence: index + 1

                                        onActivated: {
                                            scope.doWorkOnListItemClick(path);
                                            dropdown.visible = false;
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: delegateBody
                                        hoverEnabled: true

                                        onEntered: {
                                            view.currentIndex = index;
                                            delegateBody.color = delegateBody.colorOnHover;
                                        }

                                        onExited: {
                                            delegateBody.color = delegateBody.colorDefault;
                                        }

                                        onReleased: {
                                            if (containsMouse) {
                                                scope.doWorkOnListItemClick(path);
                                                dropdown.visible = false;
                                            }
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        scope.doWorkOnListItemClick(path);
                                        dropdown.visible = false;
                                    }

                                    Keys.onEnterPressed: {
                                        scope.doWorkOnListItemClick(path);
                                        dropdown.visible = false;
                                    }

                                    Rectangle {
                                        id: bottomCorners

                                        anchors.bottom: parent.bottom

                                        height: parent.height / 3
                                        width: parent.width
                                        color: parent.color
                                        enabled: false
                                        visible: view.count > 1 && index == 0
                                    }

                                    Rectangle {
                                        id: topCorners

                                        anchors.top: parent.top

                                        height: parent.height / 3
                                        width: parent.width
                                        color: parent.color
                                        enabled: false
                                        visible: view.count > 1 && index == view.count - 1
                                    }

                                    Component {
                                        id: prerecordedMessageComponent

                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"

                                            onVisibleChanged: {
                                                description.text = name;
                                            }

                                            Text {
                                                id: description

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 15 * SettingsState.scale
                                                anchors.right: parent.right
                                                anchors.rightMargin: 15 * SettingsState.scale

                                                font.family: "Segoe UI"
                                                font.pixelSize: 13 * SettingsState.scale
                                                color: ColorStorage.iconsAndTextPrimary
                                                text: name
                                                elide: Text.ElideRight

                                                Component.onCompleted: {
                                                    var margin = 30 * SettingsState.scale;

                                                    if (description.implicitWidth + margin > dropdown.viewElementMaxWidth) {
                                                        dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                        description.width = dropdown.viewElementMaxWidth - margin;
                                                        return;
                                                    }

                                                    var itemWidth = description.implicitWidth + margin;
                                                    if (dropdown.viewElementWidth < itemWidth) {
                                                        dropdown.viewElementWidth = itemWidth;
                                                        return;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Loader {
                                        id: prerecordedMessageLoader
                                        anchors.fill: parent
                                        sourceComponent: prerecordedMessageComponent
                                    }
                                }
                            }

                            Rectangle {
                                id: message

                                width: 240 * SettingsState.scale
                                height: text.implicitHeight + 10 * SettingsState.scale

                                color: ColorStorage.iconsAndTextPrimary

                                visible: !view.count
                                enabled: visible
                                Text {
                                    id: text

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8 * SettingsState.scale
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8 * SettingsState.scale

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    color: ColorStorage.mainWindowBackground

                                    wrapMode: Text.WordWrap
                                    text: qsTrId("prerecorded_file_dropdown_empty_message") + Translator.translate
                                }

                                onVisibleChanged: {
                                    if (visible) {
                                        forceActiveFocus();
                                    }
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: message.enabled

                                hoverEnabled: enabled

                                onEntered: {
                                    message.forceActiveFocus();
                                }

                                onReleased: {
                                    dropdown.visible = false;
                                }
                            }
                        }

                        DropShadow {
                            anchors.fill: body
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: 14
                            samples: 28
                            transparentBorder: true
                            color: ColorStorage.menuShadowColor
                            smooth: true
                            source: body
                        }
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }

    InfoDialog {
        id: infoDialog

        width: 363
        height: 115

        visible: SettingsState.showInvalidPrerecordedFileDialog
        message: qsTrId("dialog_failed_play_prerecorded_audio_file") + Translator.translate

        onOKAction: function() {
            ActionProvider.confirmInvalidPrerecordedFile(false);
        }
    }

    Loader {
        id: mesagesDropdownLoader
        sourceComponent: messagesDropdownComponent
    }
}
