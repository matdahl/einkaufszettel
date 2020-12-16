import QtQuick 2.7
import Ubuntu.Components 1.3

Item{
    id: root

    height: units.gu(3)
    width: parent.width
    property string title: ""

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.base
        opacity: 0.25
    }

    Label{
        anchors.centerIn: parent
        text: root.title
    }
    Rectangle{
        anchors{
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
        }
        height: 1
        color: theme.palette.normal.base
    }
}
