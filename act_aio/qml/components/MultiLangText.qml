// MultiLangText.qml
import QtQuick

Text {
    id: root
    
    property string rawText: ""
    property int maxLines: 0
    property int elide: Text.ElideNone
    property bool debugMode: false
    
    function elideToInt(elideMode) {
        switch(elideMode) {
            case Text.ElideRight: return 0
            case Text.ElideLeft: return 1
            case Text.ElideMiddle: return 2
            case Text.ElideNone:
            default: return 3
        }
    }
    
    function updateText() {
        if (!rawText) {
            text = ""
            return
        }
        
        if (width <= 0) {
            updateTimer.restart()
            return
        }
        
        let elideMode = elideToInt(elide)
        
        // Python에서 모든 로직 처리 (필요하면 elide, 아니면 그냥 포맷팅)
        if (maxLines > 0 && elideMode !== 3) {
            text = textFormatter.formatTextWithElide(
                rawText,
                width,
                font.pointSize,
                maxLines,
                elideMode
            )
        } else {
            text = textFormatter.formatText(rawText)
        }
    }
    
    Timer {
        id: updateTimer
        interval: 10
        repeat: false
        onTriggered: root.updateText()
    }
    
    textFormat: Text.RichText
    renderType: Text.QtRendering
    antialiasing: true
    // wrapMode는 외부에서 설정 가능하도록 하드코딩하지 않음
    maximumLineCount: maxLines > 0 ? maxLines : 99999
    clip: true  // RichText에서 overflow를 막기 위해 항상 true
    
    onRawTextChanged: updateText()
    onWidthChanged: updateText()
    onMaxLinesChanged: updateText()
    onElideChanged: updateText()
    
    Component.onCompleted: updateText()
}