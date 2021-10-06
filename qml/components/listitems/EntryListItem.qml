import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{
    id: root

    signal moveDown()
    signal moveUp()

    property bool isChecked: marked
    onIsCheckedChanged: checkBox.checked = marked

    leadingActions: ListItemActions{
        actions: [
            Action{
                iconName: "delete"
                onTriggered: db_entries.remove(uid)
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
            onTriggered: db_entries.toggleMarked(uid)
        }

        title.text: ""

        Item {
            id: textItem
            anchors{
                left: checkBox.right
                right: iconDrapDrop.left
                verticalCenter: parent.verticalCenter
            }
            Label{
                id: lbQuantity
                anchors{
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 0.25*parent.width
                horizontalAlignment: Label.AlignRight
                font.bold: true
                text: quantity + " " + dimension
            }
            TextArea{
                id: lbName
                anchors{
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 0.75*parent.width - units.gu(2)
                text: name
                readOnly: true
                height: ( (lineCount<3) ? lineCount : 3 ) * units.gu(2) + units.gu(2)
            }
        }

        Icon{
            id: iconDrapDrop
            height: units.gu(4)
            SlotsLayout.position: SlotsLayout.Last
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

    Label{
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        textSize: Label.Small
        text: category
    }

    DropArea{
        anchors.fill: parent
        onEntered: {
            if (drag.source.dragItemIndex > index){
                db_entries.swap(db_entries.entryModel.get(drag.source.dragItemIndex).uid,uid)
            } else if (drag.source.dragItemIndex < index){
                db_entries.swap(uid,db_entries.entryModel.get(drag.source.dragItemIndex).uid)
            }
        }
    }

}
