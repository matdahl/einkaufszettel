import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: root
    width: label.width + units.gu(2)
    height: units.gu(5)

    property string text: ""
    property bool   bold: true

    property bool enabled: true

    property int   borderWidth: 1
    property color borderColor: UbuntuColors.graphite
    property color fillColor:   UbuntuColors.lightGrey

    signal clicked()

    Rectangle{
        id: rect
        anchors.fill: parent
        color: root.fillColor
        border.width: root.borderWidth
        border.color: root.borderColor
    }
    Label{
        id: label
        anchors.centerIn: parent
        text: root.text
        font.bold: root.bold
    }
    MouseArea{
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }

}
