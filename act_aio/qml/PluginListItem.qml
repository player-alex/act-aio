import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: root

    property string pluginName: ""
    property string pluginDescription: ""
    property string pluginVersion: ""
    property bool isExecutable: false
    property bool isSelected: false
    property var manuals: []
    property var tags: []
    property var commands: []

    signal clicked()
    signal manualButtonClicked()
    signal openDirectoryButtonClicked()
    signal commandButtonClicked()

    Component.onCompleted: {
        if (pluginName === "sample-plugin") {
            console.log("PluginListItem loaded for sample-plugin")
            console.log("  commands:", JSON.stringify(commands))
            console.log("  commands.length:", commands ? commands.length : "undefined")
            console.log("  manuals:", JSON.stringify(manuals))
            console.log("  manuals.length:", manuals ? manuals.length : "undefined")
        }
    }

    // Catppuccin colors (inherited from parent)
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color text: "#cdd6f4"
    property color subtext1: "#bac2de"
    property color subtext0: "#a6adc8"
    property color overlay0: "#6c7086"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color red: "#f38ba8"
    property color blue: "#89b4fa"

    height: 110
    radius: 8
    color: isSelected ? surface2 : (mouseArea.containsMouse ? surface1 : "transparent")
    border.color: isSelected ? blue : (mouseArea.containsMouse ? overlay0 : "transparent")
    border.width: isSelected ? 2 : 1

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.rightMargin: 12
        spacing: 12

        // Plugin info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            MultiLangText {
                rawText: root.pluginName || "Unknown Plugin"
                font.pointSize: 14
                font.weight: Font.Bold
                color: root.text
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maxLines: 1
            }

            MultiLangText {
                rawText: root.pluginDescription || "No description available"
                font.pointSize: 11
                color: root.subtext0
                Layout.fillWidth: true
                Layout.topMargin: 2
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            MultiLangText {
                rawText: root.tags && root.tags.length > 0 ? root.tags.join(", ") : ""
                font.pointSize: 9
                color: root.blue
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                visible: root.tags && root.tags.length > 0
            }
        }

        ColumnLayout {
            spacing: 12
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignRight

                Text {
                    text: root.pluginVersion || "0.0.0"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: root.subtext1
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: root.isExecutable ? root.green : root.red
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 4

                    ToolTip.visible: statusMouseArea.containsMouse
                    ToolTip.text: root.isExecutable ? "Ready to launch" : "Missing main.py file"

                    MouseArea {
                        id: statusMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignRight

                Rectangle {
                    id: directoryButton
                    width: 20
                    height: 20
                    radius: 4
                    color: directoryMouseArea.containsMouse ? root.blue : root.surface1
                    border.color: root.overlay0
                    border.width: 1

                    Canvas {
                        id: folderIcon
                        width: 14
                        height: 14
                        anchors.centerIn: parent

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.fillStyle = root.text
                            ctx.strokeStyle = root.text
                            ctx.lineWidth = 1

                            // Draw folder icon
                            ctx.beginPath()
                            // Folder tab
                            ctx.moveTo(2, 4)
                            ctx.lineTo(5, 4)
                            ctx.lineTo(6, 2)
                            ctx.lineTo(12, 2)
                            ctx.lineTo(12, 4)
                            // Folder body
                            ctx.lineTo(12, 12)
                            ctx.lineTo(2, 12)
                            ctx.lineTo(2, 4)
                            ctx.closePath()
                            ctx.stroke()
                        }
                    }

                    ToolTip.visible: directoryMouseArea.containsMouse
                    ToolTip.text: "Open plugin directory"

                    MouseArea {
                        id: directoryMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            mouse.accepted = true
                            root.openDirectoryButtonClicked()
                        }
                    }
                }

                Rectangle {
                    id: commandButton
                    width: 20
                    height: 20
                    radius: 4
                    color: commandMouseArea.containsMouse ? root.blue : root.surface1
                    border.color: root.overlay0
                    border.width: 1
                    visible: root.commands && root.commands.length > 0

                    Canvas {
                        id: commandIcon
                        width: 14
                        height: 14
                        anchors.centerIn: parent

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.fillStyle = root.text
                            ctx.strokeStyle = root.text
                            ctx.lineWidth = 1.5

                            // Draw command/terminal icon (like ">_")
                            ctx.beginPath()
                            // ">" symbol
                            ctx.moveTo(2, 4)
                            ctx.lineTo(6, 7)
                            ctx.lineTo(2, 10)
                            ctx.stroke()

                            // "_" symbol
                            ctx.beginPath()
                            ctx.moveTo(7, 10)
                            ctx.lineTo(12, 10)
                            ctx.stroke()
                        }
                    }

                    ToolTip.visible: commandMouseArea.containsMouse
                    ToolTip.text: "Run commands"

                    MouseArea {
                        id: commandMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            mouse.accepted = true
                            root.commandButtonClicked()
                        }
                    }
                }

                Rectangle {
                    id: manualButton
                    width: 20
                    height: 20
                    radius: 4
                    color: manualMouseArea.containsMouse ? root.blue : root.surface1
                    border.color: root.overlay0
                    border.width: 1
                    visible: root.manuals && root.manuals.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        font.family: "Roboto"
                        font.pointSize: 11
                        font.weight: Font.Bold
                        color: root.text
                    }

                    ToolTip.visible: manualMouseArea.containsMouse
                    ToolTip.text: "View manual"

                    MouseArea {
                        id: manualMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            mouse.accepted = true
                            root.manualButtonClicked()
                        }
                    }
                }
            }
        }
    }
}
