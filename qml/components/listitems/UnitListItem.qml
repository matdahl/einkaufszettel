import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{
    id: root

    signal remove()
    signal moveUp()
    signal moveDown()
    signal toggleMarked()

    leadingActions: ListItemActions{ actions: [
        Action{
            iconName: "delete"
            onTriggered: remove()
            // the unit "piece" is not deletable
            visible: symbol !=="x"
        }
    ]}

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.positive
        opacity: 0.2
        visible: marked && symbol !=="x"
    }

    CheckBox{
        id: checkBox
        anchors{
            right: mouseUp.left
            verticalCenter: parent.verticalCenter
            margins: units.gu(2)
        }
        visible: checkMode && symbol !=="x"
        checked: marked
        onTriggered: {
            toggleMarked()
            marked = 1-marked
        }
    }

    Label{
        id: lbName
        anchors.verticalCenter: parent.verticalCenter
        x: 0.4*parent.width
        text: name
    }
    Label{
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: lbName.left
        anchors.margins: units.gu(2)
        text: "<b>"+symbol+"</b>"
        horizontalAlignment: Label.AlignRight
    }
    MouseArea{
        id: mouseDown
        // the unit "piece" is not movable
        visible: index<listView.model.count-1 && symbol !== "x"
        anchors{
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }
        width: 1.2*height
        Icon{
            name: "down"
            height: units.gu(3)
            anchors.centerIn: parent
        }
        onClicked: moveDown()
    }
    MouseArea{
        id: mouseUp
        visible: index>1
        anchors{
            top:    parent.top
            right:  parent.right
            bottom: parent.bottom
        }
        width: 1.2*height
        Icon{
            name: "up"
            height: units.gu(3)
            anchors.centerIn: parent
        }
        onClicked: moveUp()
    }
    Rectangle{
        id: downGradient
        width: 0.5*parent.width
        height: width
        x: 0
        y: 0.5*(parent.height-height)
        rotation: 90
        gradient: Gradient {
                GradientStop { position: 1.0; color: "#88aa8888"}
                GradientStop { position: 0.0; color: "#00aa8888"}
            }
        visible: mouseDown.pressed
    }
    Rectangle{
        id: upGradient
        width: 0.5*parent.width
        height: width
        x: 0.5*parent.width
        y: 0.5*(parent.height-height)
        rotation: 90
        gradient: Gradient {
                GradientStop { position: 0.0; color: "#8888aa88"}
                GradientStop { position: 1.0; color: "#0088aa88"}
            }
        visible: mouseUp.pressed
    }
}
