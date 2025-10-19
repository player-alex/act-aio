import QtQuick 2.15
import QtQuick.Controls 2.15

// Qt Quick Controls Menu 예제 (참고용)
ApplicationWindow {
    visible: true

    menuBar: MenuBar {
        Menu {
            title: "File"

            // 서브메뉴가 있는 MenuItem
            Menu {
                title: "Import"  // 자동으로 화살표 표시됨

                MenuItem {
                    text: "from Disk"
                    onTriggered: console.log("Import from Disk")
                }

                MenuItem {
                    text: "from URL"
                    onTriggered: console.log("Import from URL")
                }
            }

            MenuItem {
                text: "Export"
                onTriggered: console.log("Export")
            }

            MenuSeparator {}

            MenuItem {
                text: "About"
                onTriggered: console.log("About")
            }
        }
    }
}
