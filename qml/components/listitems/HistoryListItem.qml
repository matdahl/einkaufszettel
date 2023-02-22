import QtQuick 2.7
import Lomiri.Components 1.3

ListItem{

    property bool isChecked: marked
    onIsCheckedChanged: checkBox.checked = marked

    leadingActions: ListItemActions{
        actions: [
            Action{
                iconName: "delete"
                onTriggered: db_history.deleteKey(key)
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
            onTriggered: db_history.toggleMarked(key)
        }

        title.text: key

        Label {
            id: lbCount
            SlotsLayout.position: SlotsLayout.Last
            horizontalAlignment: Label.AlignHCenter
            text: "("+count+")"
        }
    }
}
