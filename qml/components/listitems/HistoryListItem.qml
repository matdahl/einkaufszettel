import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{
    signal remove()
    signal toggleMarked()

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

    Label{
        anchors{
            left: parent.left
            right: lbCount.left
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: Label.AlignHCenter
        text: key
        elide: Qt.ElideRight
    }

    Label {
        id: lbCount
        anchors{
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: units.gu(8)
        horizontalAlignment: Label.AlignHCenter
        font.bold: true
        text: count
    }

    Rectangle{
        anchors{
            left: lbCount.left
            verticalCenter: parent.verticalCenter
        }
        width: 1
        height: parent.height - units.gu(2)
        color: theme.palette.normal.base
    }

    CheckBox{
        id: checkBox
        anchors{
            right: lbCount.left
            verticalCenter: parent.verticalCenter
            margins: units.gu(2)
        }
        visible: root.checkMode
        checked: marked
        onTriggered: toggleMarked()
    }
}
