import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3

/*
 * An item for the settings list which pushs a new subpage to the stack if clicked on
 */
ListItem{
    id: root

    // the text to display on the item
    property string text

    // the subpage which should be pushed on stack
    property string subpage: ""

    // if set, the corresponding icon is shown on the left
    property string iconName

    ListItemLayout {
        id: layout
        anchors.fill: parent

        title.text: root.text

        Icon{
            SlotsLayout.position: SlotsLayout.First
            height: units.gu(3)
            name: iconName
        }

        Icon {
            SlotsLayout.position: SlotsLayout.Last
            height: units.gu(2)
            visible: subpage !== ""
            name: "next"
        }
    }

    onClicked:{
        if (subpage !== "")
            pages.push(Qt.resolvedUrl("../"+subpage))
    }
}
