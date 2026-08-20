import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0

FocusScope {
    id: root

    property bool alwaysOnTop: false

    property alias viewElementWidth: dropdown.viewElementWidth
    property alias viewElementHeight: dropdown.viewElementHeight

    property bool showAction: true

    property var doWorkOnListItemClick: function() {}
    property var doWorkOnActionItemClick: function() {}

    implicitWidth: dropdown.width
    implicitHeight: dropdown.height

    focus: true

    property var open: function() {
        if (Screen.desktopAvailableWidth < root.x + dropdown.width) {
            window.x = root.x - dropdown.width
        } else {
            window.x = root.x
        }

        if (Screen.desktopAvailableHeight < root.y + dropdown.height) {
            window.y = root.y - dropdown.height
        } else {
            window.y = root.y
        }

        dropdown.open();
        view.currentIndex = 0;
        view.forceActiveFocus();
    }

    property var closeDropdown: function() {
        dropdown.close();
    }

    Keys.onSpacePressed: {
        openDropdown();
    }
    ApplicationWindow {
        id: window

        flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

        width: scope.width
        height: scope.height

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

            focus: true


            Popup {
                id: dropdown
                property int viewElementWidth: 0 * SettingsState.scale
                property int viewElementHeight: 28 * SettingsState.scale
                property int viewElementMaxWidth: 190 * SettingsState.scale
                property int viewElementMaxHeight: 140 * SettingsState.scale


                // add border in 1 px
                width: viewElementWidth + 2 * SettingsState.scale
                height: AppState.externalEventButtonClickCount > 5 ? viewElementMaxHeight :
                                                                             AppState.externalEventButtonClickCount ? viewElementHeight * AppState.externalEventButtonClickCount : 0

                closePolicy: Popup.CloseOnPressOutside

                contentItem: ListView {
                    id: view

                    anchors.fill: parent
                    anchors.margins: 1 * SettingsState.scale

                    model: SettingsState.allExternalEventReceiverModel

                    keyNavigationEnabled: true

                    interactive: true
                    focus: true

                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        active: view.activeFocus && view.count > 8
                    }

                    Keys.onUpPressed: {
                        if (view.currentIndex == 0) {
                            view.footerItem.forceActiveFocus();
                            return;
                        }
                        view.decrementCurrentIndex();
                        while (view.currentItem.width == 0) {
                            if (view.currentIndex == 0) {
                                view.footerItem.forceActiveFocus();
                                return;
                            }
                            view.decrementCurrentIndex();
                        }
                    }

                    Keys.onDownPressed: {
                        if (view.currentIndex == view.count - 1) {
                            view.footerItem.forceActiveFocus();
                            return;
                        }
                        view.incrementCurrentIndex();
                        while (view.currentItem.width == 0) {
                            if (view.currentIndex == view.count - 1) {
                                view.footerItem.forceActiveFocus();
                                return;
                            }
                            view.incrementCurrentIndex();
                        }
                    }

                    Keys.onTabPressed: {
                        dropdown.close();
                        window.close();
                        root.forceActiveFocus();
                    }

                    Keys.onEscapePressed: {
                        dropdown.close();
                        window.close();
                        root.forceActiveFocus();
                    }

                    Keys.onReturnPressed: {
                        ActionProvider.sendExternalAppButtonClick(AppState.activeCall.id, view.currentIndex)
                        dropdown.close();
                        window.close();
                        root.forceActiveFocus();
                    }

                    Keys.onEnterPressed: {
                        ActionProvider.sendExternalAppButtonClick(AppState.activeCall.id, view.currentIndex)
                        dropdown.close();
                        window.close();
                        root.forceActiveFocus();
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus && !root.activeFocus && !dropdown.activeFocus) {
                            dropdown.close();
                            window.close();
                        }
                    }

                    delegate: Rectangle {
                        id: delegateBody

                        property bool isActiveSipAccount: sipAccount == "" || sipAccount == AppState.activeCall.accountId
                        implicitWidth: title != "" && isActiveSipAccount ? dropdown.viewElementWidth : 0
                        implicitHeight: title != "" && isActiveSipAccount ? name.height + 10 * SettingsState.scale: 0

                        readonly property string colorDefault: ColorStorage.surfaceSecondary
                        readonly property string colorOnHover: ColorStorage.mainWindowBackground

                        color: colorDefault

                        visible: title != "" && isActiveSipAccount ? true : false
                        enabled: title != "" && isActiveSipAccount ? true : false

                        onActiveFocusChanged: {
                            color = activeFocus ? colorOnHover : colorDefault;
                        }

                        Shortcut {
                            enabled: true
                            sequence: index + 1

                            onActivated: {
                                ActionProvider.sendExternalAppButtonClick(AppState.activeCall.id, index)
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }
                        }

                        MouseArea {
                            anchors.fill: delegateBody
                            hoverEnabled: true

                            onEntered: {
                                view.currentIndex = index;
                                delegateBody.forceActiveFocus();
                            }

                            onExited: {
                                if (!parent.activeFocus) {
                                    parent.color = parent.colorDefault;
                                }
                            }

                            onReleased: {
                                if (!containsMouse) {
                                    return;
                                }

                                ActionProvider.sendExternalAppButtonClick(AppState.activeCall.id, view.currentIndex)
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }
                        }

                        Text {
                            id: name

                            font.family: "Segoe UI"
                            font.pixelSize: 13 * SettingsState.scale

                            property bool buttonVisible : root.visible
                            anchors.verticalCenter: delegateBody.verticalCenter
                            anchors.left: delegateBody.left
                            anchors.leftMargin: 10
                            elide: Text.ElideRight

                            text: title
                            visible: dropdown.visible

                            onVisibleChanged: {
                                // to recalculate listview element's width
                                if(visible) {
                                    updateWidth();
                                }
                            }

                            function updateWidth() {
                                var margin = 20 * SettingsState.scale;
                                var itemWidth = name.implicitWidth + margin;

                                if (itemWidth > dropdown.viewElementMaxWidth) {
                                    dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                    name.width = dropdown.viewElementMaxWidth - margin;
                                    return;
                                }

                                if (dropdown.viewElementWidth < itemWidth) {
                                    dropdown.viewElementWidth = itemWidth;
                                    return;
                                }
                            }

                            onTextChanged: {
                                updateWidth();
                            }

                            Component.onCompleted: {
                                updateWidth();
                            }
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
