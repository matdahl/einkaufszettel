import QtQuick 2.7
import Ubuntu.Components 1.3

Button{
    id: bt
    width:  units.gu(8)
    height: units.gu(3)
    y: (parent.height - height)/2

    property int padding: units.gu(0.5)
    property int spacing: units.gu(0)

    property color color1: "green"
    property color color2: "blue"

    property int index: -1

    signal selected(int index)

    onClicked: selected(bt.index)
    Rectangle{
        width:  0.5*(parent.width-2*parent.padding-parent.spacing)
        height: (parent.height-2*parent.padding)
        x: parent.padding
        y: parent.padding
        radius: parent.padding
        color: bt.color1
        Rectangle{
            color: parent.color
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width: parent.radius
        }
    }
    Rectangle{
        width:  0.5*(parent.width-2*parent.padding-parent.spacing)
        height: (parent.height-2*parent.padding)
        x: 0.5*(parent.width + parent.spacing)
        y: parent.padding
        radius: parent.padding
        color: bt.color2
        Rectangle{
            color: parent.color
            anchors.left:   parent.left
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width: parent.radius
        }
    }
}
