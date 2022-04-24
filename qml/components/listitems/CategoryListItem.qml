import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{

    property bool isChecked: marked
    onIsCheckedChanged: checkBox.checked = marked

    leadingActions: ListItemActions{
        actions: [
            Action{
                iconName: "delete"
                onTriggered: db_categories.remove(index)
            }
        ]
    }

    Rectangle{
        anchors.fill: parent
        color: theme.palette.normal.positive
        opacity: 0.2
        visible: marked
    }

    ListItemLayout{
        id: layout
        CheckBox{
            id: checkBox
            SlotsLayout.position: SlotsLayout.First
            checked: marked
            onTriggered: db_categories.toggleMarked(index)
        }

        title.text: name

        Icon{
            id: iconDragDrop
            SlotsLayout.position: SlotsLayout.Last
            height: units.gu(3)
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
            if (drag.source.dragItemIndex > index){
                db_categories.swap(drag.source.dragItemIndex,index)
            } else if (drag.source.dragItemIndex < index){
                db_categories.swap(index,drag.source.dragItemIndex)
            }
        }
    }
}
