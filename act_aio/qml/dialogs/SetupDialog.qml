import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

// Setup Dialog (Loading)
Rectangle {
    id: setupDialog
    anchors.fill: parent
    color: "#80000000"
    visible: false
    z: 2500

    property string pluginName: ""
    property var applicationWindow

    function show(name) {
        pluginName = name
        visible = true
    }

    function close() {
        visible = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {}
        onPressed: {}
        onReleased: {}
        onPositionChanged: {}
        onWheel: { wheel.accepted = true }
    }

    Rectangle {
        width: 400
        height: 200
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.surface1
        border.width: 2
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 20

            MultiLangText {
                rawText: "Setting up " + setupDialog.pluginName
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.text
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maxLines: 1
            }

            Text {
                text: "Installing requirements...\nThis may take a few minutes."
                font.family: "Roboto"
                font.pointSize: 12
                color: applicationWindow.subtext0
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                id: progressBarContainer
                Layout.fillWidth: true
                height: 4
                color: applicationWindow.surface1
                radius: 2

                Rectangle {
                    id: progressBar
                    width: 0
                    height: parent.height
                    color: applicationWindow.blue
                    radius: 2

                    SequentialAnimation on width {
                        loops: Animation.Infinite
                        running: setupDialog.visible

                        NumberAnimation {
                            from: 0
                            to: progressBarContainer.width
                            duration: 1500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: progressBarContainer.width
                            to: 0
                            duration: 1500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
