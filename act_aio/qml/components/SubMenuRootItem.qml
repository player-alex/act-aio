import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property alias text: labelText.text
    property color textColor: window.text
    property color hoverTextColor: window.base
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: window.blue
    property bool isHovered: false
    property bool isActive: false

    width: 100
    height: 30
    color: (isHovered || isActive) ? hoverBackgroundColor : backgroundColor
    radius: 4

    Text {
        id: labelText
        anchors.centerIn: parent
        font.family: "Roboto"
        font.pointSize: 10
        color: (isHovered || isActive) ? hoverTextColor : textColor
    }

    Text {
        text: "›"
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        font.family: "Roboto"
        font.pointSize: 10
        color: (isHovered || isActive) ? hoverTextColor : textColor
    }
}
