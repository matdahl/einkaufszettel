import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{

    signal remove  ()
    signal moveUp  (int index)
    signal moveDown(int index)
    signal toggleMarked(string name)

    leadingActions: ListItemActions{ actions: [
        Action{
            iconName: "delete"
            onTriggered: {
                remove()
            }
        }
    ]}

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.positive
        opacity: 0.2
        visible: marked
    }
    CheckBox{
        id: checkBox
        anchors{
            right: mouseUp.left
            verticalCenter: parent.verticalCenter
            margins: units.gu(2)
        }
        visible: root.checkMode
        checked: marked
        onTriggered: toggleMarked(name)
    }

    MouseArea{
        id: mouseDown
        visible: index<listView.model.count-1
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
        onClicked: moveDown(index)
    }
    MouseArea{
        id: mouseUp
        visible: index>0
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
        onClicked: moveUp(index)
    }

    Label{
        anchors.centerIn: parent
        text: name
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
