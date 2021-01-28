import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{
    signal remove()
    signal toggleMarked()

    function uncheck(){
        if (checkBox) checkBox.checked = false
    }

    leadingActions: ListItemActions{ actions: [
        Action{
            iconName: "delete"
            onTriggered: remove()
        }
    ]}

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.positive
        opacity: 0.2
        visible: marked
    }

    Label {
        id: lbCount
        anchors{
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: units.gu(6)
        horizontalAlignment: Label.AlignHCenter
        text: "("+count+")"
    }

    Label{
        id: lbKey
        anchors{
            left:  parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: units.gu(6)
        }
        horizontalAlignment: Label.AlignHCenter
        text: key
        elide: Qt.ElideRight
    }

    CheckBox{
        id: checkBox
        anchors{
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: units.gu(2)
        }
        checked: marked
        onTriggered: toggleMarked()
    }
}
