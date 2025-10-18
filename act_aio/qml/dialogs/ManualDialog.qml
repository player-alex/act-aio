import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

// Manual Dialog
Rectangle {
    id: manualDialog
    anchors.fill: parent
    color: "#80000000"
    visible: false
    z: 2000

    property string displayName: ""
    property string pluginName: ""
    property var manuals: []
    property int selectedIndex: -1
    property var applicationWindow
    property var pluginManager

    function open() {
        selectedIndex = -1
        visible = true
    }

    function close() {
        visible = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onReleased: mouse.accepted = true
        onPositionChanged: (mouse) => {
            mouse.accepted = true
        }
        onWheel: (wheel) => {
            wheel.accepted = true
        }
    }

    Rectangle {
        id: manualDialogContent
        width: 500
        height: 400
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.surface1
        border.width: 2
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            spacing: 15

            RowLayout {
                Layout.fillWidth: true

                MultiLangText {
                    rawText: "Manuals - " + manualDialog.displayName
                    wrapMode: Text.NoWrap
                    maxLines: 1
                    elide: Text.ElideRight
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: applicationWindow.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30
                    height: 30
                    color: manualCloseMouseArea.containsMouse ? applicationWindow.red : "transparent"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: "Roboto"
                        font.pointSize: 16
                        font.weight: Font.Bold
                        color: applicationWindow.text
                    }

                    MouseArea {
                        id: manualCloseMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: manualDialog.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: applicationWindow.surface2
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: applicationWindow.surface0
                radius: 8
                border.color: applicationWindow.surface1
                border.width: 1

                ListView {
                    id: manualListView
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.rightMargin: 2
                    model: manualDialog.manuals
                    spacing: 4
                    clip: true

                    ScrollBar.vertical: CustomScrollBar {
                        orientation: Qt.Vertical
                        bottomPadding: 8
                    }

                    delegate: Rectangle {
                        width: manualListView.width - 10
                        height: 40
                        color: manualDialog.selectedIndex === index ? applicationWindow.surface2 : (manualItemMouseArea.containsMouse ? applicationWindow.surface1 : "transparent")
                        radius: 4
                        border.color: manualDialog.selectedIndex === index ? applicationWindow.blue : "transparent"
                        border.width: manualDialog.selectedIndex === index ? 2 : 0

                        property string manualPath: modelData

                        MultiLangText {
                            anchors.centerIn: parent
                            rawText: {
                                var parts = manualPath.split(/[\\\/]/)
                                return parts[parts.length - 1]
                            }
                            font.pointSize: 11
                            color: manualDialog.selectedIndex === index ? applicationWindow.blue : applicationWindow.text
                            font.weight: manualDialog.selectedIndex === index ? Font.Bold : Font.Normal
                            elide: Text.ElideMiddle
                            width: parent.width - 20
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: manualItemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                manualDialog.selectedIndex = index
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: applicationWindow.surface2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 80
                    height: 35
                    color: manualCancelMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
                    radius: 4
                    border.color: applicationWindow.overlay0
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: applicationWindow.text
                    }

                    MouseArea {
                        id: manualCancelMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: manualDialog.close()
                    }
                }

                Rectangle {
                    width: 80
                    height: 35
                    color: manualDialog.selectedIndex >= 0 ? (manualOpenMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1) : applicationWindow.overlay0
                    radius: 4
                    border.color: manualDialog.selectedIndex >= 0 ? applicationWindow.blue : applicationWindow.overlay1
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Open"
                        font.family: "Roboto"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: manualOpenMouseArea.containsMouse ? applicationWindow.base : (manualDialog.selectedIndex >= 0 ? applicationWindow.text : applicationWindow.subtext0)
                    }

                    MouseArea {
                        id: manualOpenMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: manualDialog.selectedIndex >= 0
                        onClicked: {
                            if (manualDialog.selectedIndex >= 0) {
                                var selectedManual = manualDialog.manuals[manualDialog.selectedIndex]
                                pluginManager.openManual(selectedManual)
                            }
                        }
                    }
                }
            }
        }
    }
}
