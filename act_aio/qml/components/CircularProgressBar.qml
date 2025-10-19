// import QtQuick 2.15
// import QtQuick.Shapes 1.15

// Item {
//     id: root

//     property int value: 0
//     property int maximum: 100
//     property color backgroundColor: "#E0E0E0"
//     property color progressColor: "#0078D4"
//     property int lineWidth: 3
//     property bool showPercentage: false
//     property bool indeterminate: false

//     property int indeterminateSweepAngle: 120
//     property int indeterminateDuration: 800

//     // --- 수정된 부분: Behavior를 sweepAngle이 아닌 value 프로퍼티에 적용 ---
//     Behavior on value {
//         NumberAnimation {
//             duration: 200
//             easing.type: Easing.InOutQuad
//         }
//     }

//     width: 32
//     height: 32

//     readonly property real percentage: maximum > 0 ? Math.min(value / maximum, 1.0) : 0

//     // Background circle
//     Shape {
//         anchors.fill: parent
//         antialiasing: true
//         smooth: true
//         layer.enabled: true
//         layer.smooth: true
//         layer.samples: 16

//         ShapePath {
//             strokeWidth: root.lineWidth
//             strokeColor: root.backgroundColor
//             fillColor: "transparent"
//             capStyle: ShapePath.RoundCap

//             PathAngleArc {
//                 centerX: root.width / 2
//                 centerY: root.height / 2
//                 radiusX: (root.width - root.lineWidth) / 2
//                 radiusY: (root.height - root.lineWidth) / 2
//                 startAngle: 0
//                 sweepAngle: 360
//             }
//         }
//     }

//     // Determinate Progress arc
//     Shape {
//         id: determinateProgress
//         anchors.fill: parent
//         visible: !root.indeterminate && root.percentage > 0
//         antialiasing: true
//         smooth: true
//         layer.enabled: true
//         layer.smooth: true
//         layer.samples: 16

//         ShapePath {
//             strokeWidth: root.lineWidth
//             strokeColor: root.progressColor
//             fillColor: "transparent"
//             capStyle: ShapePath.RoundCap

//             PathAngleArc {
//                 centerX: root.width / 2
//                 centerY: root.height / 2
//                 radiusX: (root.width - root.lineWidth) / 2
//                 radiusY: (root.height - root.lineWidth) / 2
//                 startAngle: -90
//                 sweepAngle: root.percentage * 360
//                 // --- 여기서 Behavior를 제거했습니다 ---
//             }
//         }
//     }

//     // Indeterminate (중간 상태) 애니메이션
//     Shape {
//         id: indeterminateProgress
//         anchors.fill: parent
//         visible: root.indeterminate
//         antialiasing: true
//         smooth: true
//         layer.enabled: true
//         layer.smooth: true
//         layer.samples: 16

//         ShapePath {
//             strokeWidth: root.lineWidth
//             strokeColor: root.progressColor
//             fillColor: "transparent"
//             capStyle: ShapePath.RoundCap

//             PathAngleArc {
//                 centerX: root.width / 2
//                 centerY: root.height / 2
//                 radiusX: (root.width - root.lineWidth) / 2
//                 radiusY: (root.height - root.lineWidth) / 2
//                 startAngle: 0
//                 sweepAngle: root.indeterminateSweepAngle
//             }
//         }

//         RotationAnimation on rotation {
//             from: 0
//             to: 360
//             duration: root.indeterminateDuration
//             loops: Animation.Infinite
//         }
//     }

//     // Center percentage text (optional)
//     Text {
//         anchors.centerIn: parent
//         text: Math.round(root.percentage * 100) + "%"
//         font.family: "Roboto"
//         font.pointSize: 6
//         font.weight: Font.Bold
//         color: root.progressColor
//         visible: !root.indeterminate && root.showPercentage && root.percentage > 0
//     }
// }

import QtQuick 2.15
import QtQuick.Shapes 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property int value: 0
    property int maximum: 100
    property color backgroundColor: "#E0E0E0"
    property color progressColor: "#0078D4"
    property int lineWidth: 3
    property bool showPercentage: false
    property bool indeterminate: false
    property int indeterminateSweepAngle: 120
    property int indeterminateDuration: 800

    Behavior on value {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    width: 32
    height: 32

    readonly property real percentage: maximum > 0 ? Math.min(value / maximum, 1.0) : 0

    // Background circle
    Shape {
        anchors.fill: parent
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.samples: 16
        ShapePath {
            strokeWidth: root.lineWidth
            strokeColor: root.backgroundColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Determinate Progress arc
    Shape {
        id: determinateProgress
        anchors.fill: parent
        visible: !root.indeterminate && root.percentage > 0
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.samples: 16
        ShapePath {
            strokeWidth: root.lineWidth
            strokeColor: root.progressColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: -90
                sweepAngle: root.percentage * 360
            }
        }
    }

    // --- 임시 테스트용 Indeterminate 애니메이션 빨간 사각형이 빙글거림 ---
    // Rectangle {
    //     id: indeterminateContainer
    //     anchors.fill: parent
    //     visible: root.indeterminate
    //     color: "red" // 눈에 잘 띄는 색상으로 변경
    //     opacity: 0.7 // 반투명하게 설정

    //     // 회전 애니메이션은 그대로 유지
    //     RotationAnimation on rotation {
    //         from: 0
    //         to: 360
    //         duration: root.indeterminateDuration
    //         loops: Animation.Infinite
    //     }
    // }

    // Indeterminate Animation
    // Item {
    //     id: indeterminateContainer
    //     anchors.fill: parent
    //     visible: root.indeterminate

    //     Rectangle {
    //         id: gradientRectangle
    //         anchors.fill: parent
    //         color: "transparent"

    //         gradient: ConicalGradient {
    //             angle: -90
    //             GradientStop { position: 0.0; color: root.progressColor }
    //             GradientStop { position: root.indeterminateSweepAngle / 360.0; color: root.progressColor }
    //             GradientStop { position: (root.indeterminateSweepAngle / 360.0) + 0.001; color: "transparent" }
    //             GradientStop { position: 1.0; color: "transparent" }
    //         }

    //         layer.enabled: true
    //         layer.smooth: true
    //         layer.effect: OpacityMask {
    //             maskSource: Item {
    //                 width: gradientRectangle.width
    //                 height: gradientRectangle.height
    //                 Rectangle {
    //                     anchors.fill: parent
    //                     radius: width / 2
    //                     antialiasing: true
    //                 }
    //                 Rectangle {
    //                     anchors.centerIn: parent
    //                     width: parent.width - (root.lineWidth * 2)
    //                     height: parent.height - (root.lineWidth * 2)
    //                     radius: width / 2
    //                     color: "transparent"
    //                     antialiasing: true
    //                 }
    //             }
    //         }
    //     }

    //     RotationAnimation on rotation {
    //         from: 0
    //         to: 360
    //         duration: root.indeterminateDuration
    //         loops: Animation.Infinite
    //     }
    // }

// Indeterminate (중간 상태) 애니메이션
    Shape {
        id: indeterminateProgress
        anchors.fill: parent
        visible: root.indeterminate
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 16 // 다른 Shape과 일관성을 위해 4로 설정

        ShapePath {
            strokeWidth: root.lineWidth
            strokeColor: root.progressColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: 0
                sweepAngle: root.indeterminateSweepAngle
            }
        }

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: root.indeterminateDuration
            loops: Animation.Infinite
        }
    }


    // Center percentage text
    Text {
        anchors.centerIn: parent
        text: Math.round(root.percentage * 100) + "%"
        font.family: "Roboto"
        font.pointSize: 6
        font.weight: Font.Bold
        color: root.progressColor
        visible: !root.indeterminate && root.showPercentage && root.percentage > 0
    }
}
