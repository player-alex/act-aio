import QtQuick 2.15
import QtQuick.Controls 2.15

ScrollBar {
    policy: ScrollBar.AsNeeded
    padding: 0
    hoverEnabled: true
    active: true

    background: Rectangle {
        implicitWidth: orientation === Qt.Vertical ? 5 : 0
        implicitHeight: orientation === Qt.Horizontal ? 5 : 0
        color: window.surface0
        radius: 2
    }

    contentItem: Rectangle {
        implicitWidth: orientation === Qt.Vertical ? 5 : 0
        implicitHeight: orientation === Qt.Horizontal ? 5 : 0
        color: window.overlay0
        radius: 2
        visible: parent.size < 1.0
    }
}