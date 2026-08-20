import QtQuick 2.15
import Flux 1.0

FocusScope {
    id: root

    implicitWidth: border.width
    implicitHeight: border.height

    Rectangle {
        id: border

        width: 6
        height: 40

        anchors.fill: parent
        color: "transparent"

        Column {
            spacing: 5

            Rectangle {
                id: circle1

                opacity: 1.0

                width: 4
                height: width
                radius: height / 2

                color: ColorStorage.loadingIndicatorCircles
            }

            Rectangle {
                id: circle2

                width: 4
                height: width
                radius: height / 2

                color: ColorStorage.loadingIndicatorCircles
            }

            Rectangle {
                id: circle3

                width: 4
                height: width
                radius: height / 2

                color: ColorStorage.loadingIndicatorCircles
            }

            Rectangle {
                id: circle4

                width: 4
                height: width
                radius: height / 2

                color: ColorStorage.loadingIndicatorCircles
            }
        }
    }

    SequentialAnimation {
        id: animation
        running: root.enabled && root.visible
        loops: Animation.Infinite

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 1.0
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.75
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.5
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.25
                to: 0.05

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.75
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.5
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.25
                to: 0.05

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.05
                to: 0.25

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.5
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.25
                to: 0.05

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.05
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.25
                to: 0.5

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.25
                to: 0.05

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.05
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.25
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.5
                to: 0.75

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.05
                to: 0.25

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.25
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.5
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.75
                to: 1.0

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.25
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.5
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.75
                to: 1.0

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 1.0
                to: 0.75

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.5
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 0.75
                to: 1.0

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 1.0
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.75
                to: 0.5

                duration: 250
            }
        }

        ParallelAnimation {

            OpacityAnimator {
                target: circle1

                from: 0.75
                to: 1.0

                duration: 250
            }

            OpacityAnimator {
                target: circle2

                from: 1.0
                to: 0.75

                duration: 250
            }

            OpacityAnimator {
                target: circle3

                from: 0.75
                to: 0.5

                duration: 250
            }

            OpacityAnimator {
                target: circle4

                from: 0.5
                to: 0.25

                duration: 250
            }
        }
    }
}
