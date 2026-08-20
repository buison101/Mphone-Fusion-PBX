import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import AuthEngineModule 1.0
import Flux 1.0

import "login"

ApplicationWindow {
    id: root

    flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint |
           Qt.Window

    width: 364 * AuthEngine.scale

    height: 646 * AuthEngine.scale

    visible: AuthEngine.status != AuthStatus.Unknown

    FocusScope {
        id: focusScope

        width: parent.width
        height: parent.height
        focus: true

            Rectangle {
                anchors.fill: parent
                border.width: 1 * AuthEngine.scale
                border.color: ColorStorage.windowBorder

                FocusScope {
                    anchors.fill: parent
                    focus: true

                    Loader {
                        id: loader

                        anchors.centerIn: parent
                        sourceComponent: LoginWindow {
                            anchors.top: parent.top

                            mainLoginWidth: root.width
                            mainLoginHeight: root.height

                            function closeWindow() {
                                AuthEngine.tryQuitApplication();
                            }

                            doWorkOnWindowClose: closeWindow
                        }

                        focus: true
                    }
                }
            }

        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 26 * AuthEngine.scale

            property real lastMouseX: 0
            property real lastMouseY: 0

            height: 30 * AuthEngine.scale

            enabled: true

            onPressed: {
                lastMouseX = mouseX;
                lastMouseY = mouseY;

                if (focusScope.activeFocus == false) {
                    focusScope.forceActiveFocus();
                }
            }

            onMouseXChanged: root.x += (mouseX - lastMouseX)
            onMouseYChanged: root.y += (mouseY - lastMouseY)
        }
    }
}
