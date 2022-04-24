import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: root
    width: parent.width
    height: units.gu(2.5)
    property string title: ""

    Label{
        id: lbTitle
        width: root.width
        text: root.title
        font.bold: true
    }

    Rectangle{
        anchors{
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(0.25)
        color: theme.palette.normal.base
    }


}
