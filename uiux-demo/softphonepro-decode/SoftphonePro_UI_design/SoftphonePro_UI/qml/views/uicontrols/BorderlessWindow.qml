import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0


ApplicationWindow {
    id: root

   flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint |
           Qt.Window

    title: StringStorage.appTitle
    color: "transparent"

    readonly property alias activeFocus: focusScope.activeFocus
    property alias content: loader.sourceComponent

    property string titleButtonImageColor: ColorStorage.iconsAndTextPrimary
    property string titleButtonColorOnHover: ColorStorage.grayNeutralOnHover
    property string titleButtonColorOnPress: ColorStorage.grayNeutralOnPress
    property int titleButtonSize: 24 * SettingsState.scale

    property bool alwaysOnTop: false
    property bool enableMove: true
    property int radius: 0

    // do not show parent window on focus received
    property bool beSubWindow: false
    property bool showDialogButtons: true
    property bool disableCloseButton: false
    property bool hideCloseButton: false
    property bool disableMinimizeButton: false
    property bool disableMaximizeButton: true

    property bool destroyWindowManually: false
    property var doWorkOnWindowClose: function() {}
    property var doWorkOnWindowMinimized: function() {}
    property var doWorkOnWindowMaximized: function() {}
    property var doWorkOnOpenControlGuiMenu: function() {}

    property bool instanceWillDestroy: AppState.instanceWillDestroy

    property int mouseAreaLeftMargin: 0
    property int mouseAreaRightMargin: 0
    property int mouseAreaHeight: 40 * SettingsState.scale

    property int windowBorderWidth: 1
    property int windowOffset: 2 * windowBorderWidth
    property double borderOpacity: ColorStorage.mainWindowBorderOpacity
    property string borderColor: ColorStorage.mainWindowBorder

    onInstanceWillDestroyChanged: {
        if (destroyWindowManually && instanceWillDestroy) {
            root.destroy();
        }
    }

    onAlwaysOnTopChanged: {
        var flags = root.flags;
        flags = root.alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                 : (flags & ~Qt.WindowStaysOnTopHint);
        root.flags = flags;
    }

    onBeSubWindowChanged: {
        if (AppFeatures.osType == OSType.MacOS) {
            return;
        }
        var flags = root.flags;
        flags = root.beSubWindow ? (flags | Qt.SubWindow) : (flags & ~Qt.SubWindow);

        root.flags = flags;
    }

    onShowDialogButtonsChanged:  {
        root.disableCloseButton = root.showDialogButtons;
        root.disableMinimizeButton = root.showDialogButtons;
        root.disableMaximizeButton = root.showDialogButtons;
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true

        Rectangle {
            anchors.fill: parent

            Rectangle {
                id: topBorder

                color: borderColor
                opacity: borderOpacity
                anchors.top: parent.top
                width: parent.width
                height: 1 * SettingsState.scale
                z: 1
            }

            Rectangle {
                id: bottomBorder

                color: borderColor
                opacity: borderOpacity
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1 * SettingsState.scale
                z: 1
            }

            Rectangle {
                id: rightBorder

                color: borderColor
                opacity: borderOpacity
                anchors.right: parent.right
                anchors.top: topBorder.bottom
                anchors.bottom: bottomBorder.top
                width: 1 * SettingsState.scale
                z:1
            }

            Rectangle {
                id: leftBorder

                color: borderColor
                opacity: borderOpacity
                anchors.left: parent.left
                anchors.top: topBorder.bottom
                anchors.bottom: bottomBorder.top
                width: 1 * SettingsState.scale
                z: 1
            }

            FocusScope {
                anchors.fill: parent
                focus: true
                Loader {
                    id: loader

                    anchors.centerIn: parent

                    focus: true

                    onLoaded: {
                        root.width = Qt.binding(function() { return loader.item.width + windowOffset; });
                        root.height = Qt.binding(function() { return loader.item.height + windowOffset; });
                    }
                }

            }

            MouseArea {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: root.mouseAreaLeftMargin
                anchors.right: parent.right
                anchors.rightMargin: root.mouseAreaRightMargin
                property real lastMouseX: 0
                property real lastMouseY: 0

                height: mouseAreaHeight
                enabled: root.enableMove

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

            Row {
                id: dialogButtons

                anchors.top: parent.top
                anchors.topMargin: 1 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: 1 * SettingsState.scale

                TitleButton {
                    id: openControlGuiMenu

                    scale: SettingsState.scale

                    enabled: !root.disableMinimizeButton
                    visible: enabled

                    bodyWidth: 39 * SettingsState.scale
                    bodyHeight: bodyWidth

                    colorDefault: "transparent"
                    colorOnHover: titleButtonColorOnHover //white: "#C4C4C4" //black: #545454
                    colorOnPress: titleButtonColorOnPress //white: "#ACACAC" //black: #707070

                    imageSource: "qrc:/images/chevron_down_white.svg"
                    imageColorDefault: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnHover: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnPress: titleButtonImageColor //white: "#FFFFFF" //black: #FFFFFF

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    doWorkOnButtonClick: function() {
                        root.doWorkOnOpenControlGuiMenu();
                    }
                }

                TitleButton {
                    id: windowMinimize

                    scale: SettingsState.scale
                    enabled: !root.disableMinimizeButton
                    visible: enabled

                    bodyWidth: 39 * SettingsState.scale
                    bodyHeight: bodyWidth

                    colorDefault: "transparent"
                    colorOnHover: titleButtonColorOnHover //white: "#C4C4C4" //black: #545454
                    colorOnPress: titleButtonColorOnPress //white: "#ACACAC" //black: #707070

                    imageSource: "qrc:/images/window_minimize_default.svg"
                    imageColorDefault: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnHover: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnPress: titleButtonImageColor //white: "#FFFFFF" //black: #FFFFFF

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    doWorkOnButtonClick: function() {
                        if (AppFeatures.osType != OSType.MacOS && AppFeatures.osType != OSType.Unix) {
                            root.showMinimized();
                        }
                        root.doWorkOnWindowMinimized();
                    }
                }

                TitleButton {
                    id: windowMaximize

                    scale: SettingsState.scale
                    enabled: !root.disableMaximizeButton
                    visible: enabled

                    colorDefault: "transparent"
                    colorOnHover: titleButtonColorOnHover //white: "#C4C4C4" //black: #545454
                    colorOnPress: titleButtonColorOnPress //white: "#ACACAC" //black: #707070

                    imageSource: "qrc:/images/window_maximize_default.svg"
                    imageColorDefault: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnHover: titleButtonImageColor //white: "#000000" //black: #FFFFFF
                    imageColorOnPress: titleButtonImageColor //white: "#FFFFFF" //black: #FFFFFF

                    doWorkOnButtonClick: function() {
                        root.showMaximized();
                        root.doWorkOnWindowMaximized();
                    }
                }

                TitleButton {
                    id: windowClose

                    scale: SettingsState.scale
                    enabled: !root.disableCloseButton
                    visible: !hideCloseButton

                    bodyHeight: titleButtonSize
                    bodyWidth: titleButtonSize

                    colorDefault: "transparent"
                    colorOnHover: ColorStorage.redOnHover
                    colorOnPress: ColorStorage.redOnPress

                    imageSource:  "qrc:/images/close_default.svg"
                    imageColorDefault: titleButtonImageColor
                    imageColorOnHover: titleButtonImageColor
                    imageColorOnPress: titleButtonImageColor
                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    doWorkOnButtonClick: function() {
                        root.doWorkOnWindowClose();
                        if (!root.destroyWindowManually) {
                            root.close();
                        }
                    }
                }
            }
        }
    }

    // window "sticky"-like functionality
    property var stickyBuddies: null
    property alias stickyProps: stickyProps

    Item {
        id: stickyProps

        property var buddyLeft: null
        property var buddyRight: null
        property bool leftAsSlave: false
        property bool rightAsSlave: false
    }

    function tryToStick() {
        if (stickyBuddies == null) {
            return;
        }

        var xOuterOffset = 10 * SettingsState.scale
        var xInnerOffset = -10 * SettingsState.scale
        var yOffset = 20 * SettingsState.scale

        var index;
        for (index = 0; index < stickyBuddies.length; ++index) {
            var buddy = stickyBuddies[index];

            // check for sticking or unsticking from the RIGHT border of the buddy window
            if (buddy.stickyProps.buddyRight && buddy.stickyProps.buddyRight == root
                    && !buddy.stickyProps.rightAsSlave
                    && (x - buddy.x - buddy.width >= xOuterOffset || x - buddy.x - buddy.width < xInnerOffset
                        || Math.abs(y - buddy.y) >= yOffset)) {

                buddy.stickyProps.buddyRight = null;
                root.stickyProps.buddyLeft = null;
                root.stickyProps.leftAsSlave = false;
                return;
            }
            //Sticking condition
            else if ((!buddy.stickyProps.buddyRight ||
                      (buddy.stickyProps.buddyRight == root && !buddy.stickyProps.rightAsSlave))
                      && x - buddy.x - buddy.width < xOuterOffset
                     && x - buddy.x - buddy.width >= xInnerOffset
                     && Math.abs(y - buddy.y) < yOffset) {
                root.x = Qt.binding(function() { return buddy.x + buddy.width - 1; });
                root.y = Qt.binding(function() { return buddy.y; });

                buddy.stickyProps.buddyRight = root;
                root.stickyProps.buddyLeft = buddy;
                root.stickyProps.leftAsSlave = true;
                return;
            }

            // check for sticking or unsticking from the LEFT border of the buddy window
            if (buddy.stickyProps.buddyLeft && buddy.stickyProps.buddyLeft == root
                    && !buddy.stickyProps.leftAsSlave
                    && (buddy.x - x - width >= xOuterOffset || buddy.x - x - width < xInnerOffset
                        || Math.abs(y - buddy.y) >= yOffset)) {

                buddy.stickyProps.buddyLeft = null;
                root.stickyProps.buddyRight = null;
                root.stickyProps.rightAsSlave = false;
                return;
            }
            //Sticking condition
            else if ((!buddy.stickyProps.buddyLeft ||
                      (buddy.stickyProps.buddyLeft == root && !buddy.stickyProps.leftAsSlave))
                     && buddy.x - x - width < xOuterOffset
                     && buddy.x - x - width >= xInnerOffset
                     && Math.abs(y - buddy.y) < yOffset) {
                root.x = Qt.binding(function() { return buddy.x - width + 1; });
                root.y = Qt.binding(function() { return buddy.y; });

                buddy.stickyProps.buddyLeft = root;
                root.stickyProps.buddyRight = buddy;
                root.stickyProps.rightAsSlave = true;
                return;
            }
        }
    }

    function unstick() {
        if (stickyBuddies == null) {
            return;
        }

        var index;
        for (index = 0; index < stickyBuddies.length; ++index) {
            var buddy = stickyBuddies[index];

            if (buddy.stickyProps.buddyRight && buddy.stickyProps.buddyRight == root
                    && !buddy.stickyProps.rightAsSlave) {

                buddy.stickyProps.buddyRight = null;
                root.stickyProps.buddyLeft = null;
                root.stickyProps.leftAsSlave = false;
                // remove bindings
                root.x = x;
                root.y = y;
                continue;
            }

            if (buddy.stickyProps.buddyLeft && buddy.stickyProps.buddyLeft == root
                    && !buddy.stickyProps.leftAsSlave) {
                buddy.stickyProps.buddyLeft = null;
                root.stickyProps.buddyRight = null;
                root.stickyProps.rightAsSlave = false;
                // remove bindings
                root.x = x;
                root.y = y;
            }
        }
    }
}
