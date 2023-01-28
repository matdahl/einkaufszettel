import QtQuick 2.7
import Lomiri.Components 1.3

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
            visible: symbol !=="x"
        }
    ]}

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.positive
        opacity: 0.2
        visible: marked && symbol !=="x"
    }

    ListItemLayout{
        id: layout

        CheckBox{
            id: checkBox
            SlotsLayout.position: SlotsLayout.First
            checked: marked
            opacity: symbol !=="x" ? 1 : 0
            enabled: symbol !=="x"
            onTriggered: toggleMarked(name)
        }

        title.text: ""

        Item{
            anchors{
                left: checkBox.right
                right: iconDragDrop.left
                verticalCenter: parent.verticalCenter
            }
            Label{
                anchors{
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 0.25*parent.width
                text: symbol
                horizontalAlignment: Label.AlignRight
                font.bold: true
            }
            Label{
                anchors{
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 0.75*parent.width - units.gu(2)
                text: name
            }
        }

        Icon{
            id: iconDragDrop
            SlotsLayout.position: SlotsLayout.Last
            height: units.gu(3)
            opacity: symbol !=="x" ? 1 : 0
            enabled: symbol !=="x"
            name: "sort-listitem"
            MouseArea{
                id: dragMouse
                anchors{
                    fill: parent
                    margins: units.gu(-1)
                }
                drag.target: layout
            }
        }

        property int dragItemIndex: index

        states: [
            State {
                when: layout.Drag.active
                ParentChange {
                    target: layout
                    parent: listView
                }
            },
            State {
                when: !layout.Drag.active
                AnchorChanges {
                    target: layout
                    anchors.horizontalCenter: layout.parent.horizontalCenter
                    anchors.verticalCenter: layout.parent.verticalCenter
                }
            }
        ]
        Drag.active: dragMouse.drag.active
        Drag.hotSpot.x: layout.width / 2
        Drag.hotSpot.y: layout.height / 2
    }

    DropArea{
        anchors.fill: parent
        onEntered: {
            if (symbol !== "x"){
                if (drag.source.dragItemIndex > index){
                    dimensions.swap(dimensions.unitsModel.get(drag.source.dragItemIndex).uid,uid)
                } else if (drag.source.dragItemIndex < index){
                    dimensions.swap(uid,dimensions.unitsModel.get(drag.source.dragItemIndex).uid)
                }
            }
        }
    }
}
