import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import ActAio 1.0
import "components"
import "dialogs"

ApplicationWindow {
    id: window
    width: Math.max(600, Screen.width * 0.4)
    height: Math.max(700, Screen.height * 0.75)
    visible: true
    title: appTitle

    Component.onCompleted: {
        // Center the window on screen
        x = (Screen.width - width) / 2
        y = (Screen.height - height) / 2
    }

    // Catppuccin Mocha color scheme
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color subtext1: "#bac2de"
    property color subtext0: "#a6adc8"
    property color overlay2: "#9399b2"
    property color overlay1: "#7f849c"
    property color overlay0: "#6c7086"
    property color lavender: "#b4befe"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color sky: "#89dceb"
    property color teal: "#94e2d5"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color peach: "#fab387"
    property color maroon: "#eba0ac"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color flamingo: "#f2cdcd"
    property color rosewater: "#f5e0dc"

    color: base

    // Plugin Manager
    PluginManager {
        id: pluginManager

        onErrorOccurred: function(title, message) {
            errorDialog.show(title, message)
        }

        onSetupStarted: function(pluginName) {
            setupDialog.show(pluginName)
        }

        onSetupFinished: {
            setupDialog.close()
        }

        onConfirmationRequested: function(title, message, callbackId) {
            confirmationDialog.show(title, message, callbackId)
        }

        onInfoMessageRequested: function(title, message) {
            infoDialog.show(title, message)
        }
    }

    // Plugin List Model
    PluginListModel {
        id: pluginListModel
        pluginManager: pluginManager
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Top Bar with Menu and Settings
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            // Menu Button (left)
            Rectangle {
                id: menuButton
                width: 40
                height: 40
                color: menuMouseArea.containsMouse ? window.surface1 : window.surface0
                radius: 8
                border.color: window.overlay0
                border.width: 1

                // Menu icon (three horizontal lines)
                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 18
                            height: 2
                            color: window.text
                            radius: 1
                        }
                    }
                }

                MouseArea {
                    id: menuMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: menuDropdown.visible = !menuDropdown.visible
                }
            }

            // Title (center)
            MultiLangText {
                Layout.fillWidth: true
                rawText: appTitle
                font.pointSize: 18
                font.weight: Font.Bold
                color: window.text
                horizontalAlignment: Text.AlignHCenter
            }

            // Settings Button (right)
            Rectangle {
                id: settingsButton
                width: 40
                height: 40
                color: settingsMouseArea.containsMouse ? window.surface1 : window.surface0
                radius: 8
                border.color: window.overlay0
                border.width: 1

                // Settings icon (gear)
                Canvas {
                    id: settingsIcon
                    width: 20
                    height: 20
                    anchors.centerIn: parent

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.fillStyle = window.text
                        ctx.strokeStyle = window.text
                        ctx.lineWidth = 1.5

                        // Draw gear icon
                        ctx.beginPath()
                        ctx.arc(10, 10, 6, 0, 2 * Math.PI)
                        ctx.stroke()

                        // Draw gear teeth
                        for (var i = 0; i < 8; i++) {
                            var angle = (i * Math.PI) / 4
                            var x1 = 10 + Math.cos(angle) * 8
                            var y1 = 10 + Math.sin(angle) * 8
                            var x2 = 10 + Math.cos(angle) * 10
                            var y2 = 10 + Math.sin(angle) * 10
                            ctx.moveTo(x1, y1)
                            ctx.lineTo(x2, y2)
                        }
                        ctx.stroke()

                        // Center hole
                        ctx.beginPath()
                        ctx.arc(10, 10, 3, 0, 2 * Math.PI)
                        ctx.stroke()
                    }
                }

                MouseArea {
                    id: settingsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: settingsDialog.open()
                }
            }
        }

        // Search Box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            color: window.surface0
            radius: 8
            border.color: searchField.activeFocus ? window.blue : window.surface1
            border.width: searchField.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Search Icon
                Canvas {
                    id: searchIcon
                    width: 20
                    height: 20
                    Layout.alignment: Qt.AlignVCenter

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = window.subtext0
                        ctx.lineWidth = 2

                        // Draw magnifying glass circle
                        ctx.beginPath()
                        ctx.arc(8, 8, 6, 0, 2 * Math.PI)
                        ctx.stroke()

                        // Draw handle
                        ctx.beginPath()
                        ctx.moveTo(13, 13)
                        ctx.lineTo(18, 18)
                        ctx.stroke()
                    }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Search plugins..."
                    font.family: "Roboto"
                    font.pointSize: 11
                    color: window.text
                    placeholderTextColor: window.subtext0
                    verticalAlignment: TextInput.AlignVCenter
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    background: Rectangle {
                        color: "transparent"
                    }
                    onTextChanged: {
                        pluginListModel.searchText = text
                    }
                }

                // Clear button (visible when text is entered)
                Rectangle {
                    width: 20
                    height: 20
                    color: clearMouseArea.containsMouse ? window.surface2 : "transparent"
                    radius: 10
                    visible: searchField.text.length > 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: "Roboto"
                        font.pointSize: 14
                        font.weight: Font.Bold
                        color: window.subtext0
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        // Plugin List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: window.surface0
            radius: 12
            border.color: window.surface1
            border.width: 1
                            
		ListView {                                
		id: pluginListView                
		anchors.fill: parent
                anchors.margins: 0
                anchors.rightMargin: 0
                model: pluginListModel
                spacing: 8
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    policy: ScrollBar.AsNeeded
                    padding: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    hoverEnabled: true
                    active: true
                    orientation: Qt.Vertical

                    background: Rectangle {
                        implicitWidth: 10
                        color: window.surface0
                        radius: 5
                    }

                    contentItem: Rectangle {
                        implicitWidth: 10
                        color: window.overlay0
                        radius: 5
                        visible: vbar.size < 1.0
                    }
                }

                delegate: PluginListItem {
                    width: pluginListView.width - vbar.width
                    pluginName: model.displayName
                    pluginDescription: model.description
                    pluginVersion: model.version
                    isExecutable: model.executable
                    isSelected: index === pluginListModel.selectedIndex
                    manuals: model.manuals
                    tags: model.tags
                    commands: model.commands

                    onClicked: {
                        pluginListModel.selectedIndex = index
                    }

                    onOpenDirectoryButtonClicked: {
                        pluginManager.openPluginDirectory(model.name)
                    }

                    onCommandButtonClicked: {
                        console.log("Command button clicked for:", model.name)
                        console.log("model.commands:", JSON.stringify(model.commands))
                        commandDialog.displayName = model.displayName
                        commandDialog.pluginName = model.name
                        commandDialog.commands = model.commands || []
                        console.log("commandDialog.commands after assignment:", JSON.stringify(commandDialog.commands))
                        commandDialog.open()
                    }

                    onManualButtonClicked: {
                        manualDialog.displayName = model.displayName
                        manualDialog.pluginName = model.name
                        manualDialog.manuals = model.manuals
                        manualDialog.open()
                    }
                }

                // Show message when no plugins are found
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: noPluginsText.height + 40
                    color: "transparent"
                    visible: pluginListView.count === 0

                    Text {
                        id: noPluginsText
                        anchors.centerIn: parent
                        text: "No plugins found in ./plugins directory"
                        font.family: "Roboto"
                        font.pointSize: 14
                        color: window.subtext0
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }

        // Bottom Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 120
                height: 40
                color: window.surface1
                radius: 4
                border.color: window.overlay0
                border.width: 1
                scale: mouseArea.containsMouse ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: window.text
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        pluginListModel.refresh()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: launchButton
                width: 120
                height: 40
                color: pluginListModel.canLaunch ? window.blue : window.overlay0
                radius: 4
                border.color: pluginListModel.canLaunch ? window.blue : window.overlay1
                border.width: 1
                scale: (launchMouseArea.containsMouse && pluginListModel.canLaunch) ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Launch"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: pluginListModel.canLaunch ? window.base : window.subtext0
                }

                MouseArea {
                    id: launchMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: pluginListModel.canLaunch
                    onClicked: {
                        if (pluginListModel.launchSelected()) {
                            console.log("Plugin launched successfully")
                        } else {
                            console.log("Failed to launch plugin")
                        }
                    }
                }
            }
        }
    }

    // Dropdown Menu (outside the layout hierarchy for proper z-ordering)
    Rectangle {
        id: menuDropdown
        width: 120
        height: importExportColumn.height + 20
        color: window.surface1
        radius: 8
        border.color: window.overlay0
        border.width: 1
        visible: false
        x: 20  // Same as left margin
        y: 80  // Below the top bar
        z: 1000  // Very high z-index

        // Track which submenu is currently open (for future extensibility)
        property string activeSubmenu: ""

        onVisibleChanged: {
            if (!visible) {
                activeSubmenu = ""
                importSubmenu.visible = false
            }
        }

        // Helper function to close all submenus
        function closeAllSubmenus() {
            importSubmenu.visible = false
            // Add more submenus here in the future
        }

        // Consume clicks inside the menu to prevent closing
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Do nothing, just consume the click
            hoverEnabled: false
        }

        Column {
            id: importExportColumn
            anchors.centerIn: parent
            spacing: 8

            // Import Button
            SubMenuRootItem {
                id: importButton
                text: "Import"
                textColor: window.text
                hoverTextColor: window.base
                hoverBackgroundColor: window.blue
                isHovered: importMouseArea.containsMouse
                isActive: importSubmenu.visible

                MouseArea {
                    id: importMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        if (menuDropdown.activeSubmenu !== "import") {
                            menuDropdown.closeAllSubmenus()
                            menuDropdown.activeSubmenu = "import"
                        }
                        importSubmenu.visible = true
                    }
                }
            }

            // Export Button
            Rectangle {
                width: 100
                height: 30
                color: exportMouseArea.containsMouse && pluginListModel.canLaunch ? window.green : "transparent"
                radius: 4
                opacity: pluginListModel.canLaunch ? 1.0 : 0.5

                Text {
                    anchors.centerIn: parent
                    text: "Export"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: exportMouseArea.containsMouse && pluginListModel.canLaunch ? window.base : window.text
                }

                MouseArea {
                    id: exportMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        // Close all submenus when hovering over non-submenu items
                        menuDropdown.closeAllSubmenus()
                        menuDropdown.activeSubmenu = ""
                    }
                    onClicked: {
                        if (pluginListModel.canLaunch) {
                            menuDropdown.visible = false
                            pluginManager.exportPlugin(pluginListModel.selectedPluginDisplayName, pluginListModel.selectedPluginPath)
                        }
                    }
                }
            }

            Rectangle {
                width: 100
                height: 30
                color: aboutMouseArea.containsMouse ? window.blue : "transparent"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "About"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: aboutMouseArea.containsMouse ? window.base : window.text
                }

                MouseArea {
                    id: aboutMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        // Close all submenus when hovering over non-submenu items
                        menuDropdown.closeAllSubmenus()
                        menuDropdown.activeSubmenu = ""
                    }
                    onClicked: {
                        menuDropdown.visible = false
                        aboutDialog.open()
                    }
                }
            }
        }

        // Import Submenu (outside Column to prevent layout interference)
        Rectangle {
            id: importSubmenu
            width: 120
            height: importSubmenuColumn.height + 16
            color: window.surface1
            radius: 8
            border.color: window.overlay0
            border.width: 1
            visible: false
            x: importExportColumn.x + importButton.width + 5
            y: importExportColumn.y + importButton.y
            z: 2000

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    if (!importFromDiskMouseArea.containsMouse && !importFromUrlMouseArea.containsMouse) {
                        importSubmenu.visible = false
                    }
                }
            }

            Column {
                id: importSubmenuColumn
                anchors.centerIn: parent
                spacing: 8

                // Import from Disk
                Rectangle {
                    width: 110
                    height: 30
                    color: importFromDiskMouseArea.containsMouse ? window.blue : "transparent"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "from Disk"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: importFromDiskMouseArea.containsMouse ? window.base : window.text
                    }

                    MouseArea {
                        id: importFromDiskMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            importSubmenu.visible = false
                            menuDropdown.visible = false
                            pluginManager.importPlugin()
                        }
                    }
                }

                // Import from URL
                Rectangle {
                    width: 110
                    height: 30
                    color: importFromUrlMouseArea.containsMouse ? window.blue : "transparent"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "from URL"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: importFromUrlMouseArea.containsMouse ? window.base : window.text
                    }

                    MouseArea {
                        id: importFromUrlMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            importSubmenu.visible = false
                            menuDropdown.visible = false
                            urlInputDialog.show()
                        }
                    }
                }
            }
        }
    }

    AboutDialog {
        id: aboutDialog
        applicationWindow: window
        pluginManager: pluginManager
    }

    SettingsDialog {
        id: settingsDialog
        applicationWindow: window
        pluginManager: pluginManager
    }

    SetupDialog {
        id: setupDialog
        applicationWindow: window
    }

    ManualDialog {
        id: manualDialog
        applicationWindow: window
        pluginManager: pluginManager
    }

    // Close dropdown when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: menuDropdown.visible
        onClicked: menuDropdown.visible = false
        z: 50
    }

    ErrorDialog {
        id: errorDialog
        applicationWindow: window
    }

    UrlInputDialog {
        id: urlInputDialog
        applicationWindow: window
        pluginManager: pluginManager
    }

    ConfirmationDialog {
        id: confirmationDialog
        applicationWindow: window
        pluginManager: pluginManager
    }

    InfoDialog {
        id: infoDialog
        applicationWindow: window
    }

    CommandDialog {
        id: commandDialog
        applicationWindow: window
        pluginManager: pluginManager
    }
}
