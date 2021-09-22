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

    ListItemLayout{
        CheckBox{
            id: checkBox
            SlotsLayout.position: SlotsLayout.First
            checked: marked
            onTriggered: toggleMarked(name)
        }

        title.text: name

        Icon{
            id: iconDragDrop
            SlotsLayout.position: SlotsLayout.Last
            height: units.gu(4)
        }
    }
}
