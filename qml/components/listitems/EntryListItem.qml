import QtQuick 2.7
import Ubuntu.Components 1.3

ListItem{
    id: root

    signal remove(int uid)
    signal toggleMarked(int uid)
    signal moveDown()
    signal moveUp()

    leadingActions: ListItemActions{
        actions: [
            Action{
                iconName: "delete"
                onTriggered: remove(uid)
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
        CheckBox{
            id: checkBox
            SlotsLayout.position: SlotsLayout.First
            checked: marked
            onTriggered: {
                toggleMarked(uid)
                marked = 1-marked
            }
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
        }
    }

    Label{
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        textSize: Label.Small
        text: category
    }

}
