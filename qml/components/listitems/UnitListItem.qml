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

    ListItemLayout{
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
        }
    }
}
