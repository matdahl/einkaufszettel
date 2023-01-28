import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3

/*
 * An item for the settings list which pushs a new subpage to the stack if clicked on
 */
ListItem{
    id: root

    // the text to display on the item
    property string text

    // states whether the switcher was checked
    property bool checked: false

    ListItemLayout {
        id: layout
        anchors.fill: parent

        title.text: root.text

        Switch {
            SlotsLayout.position: SlotsLayout.Last
            checked: root.checked
            onCheckedChanged: root.checked = checked
        }
    }
}
