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
    property var subpage

    // the panel stack
    property var stack

    ListItemLayout {
        id: layout
        anchors.fill: parent

        title.text: root.text

        Icon {
            SlotsLayout.position: SlotsLayout.Last
            width: units.gu(2); height: width
            name: "next"
        }
    }

    onClicked:{
        if (subpage){
            if (stack){
                stack.push(subpage)
            } else {
                console.error("SettingsMenuItem '"+text+"': No stack found")
            }
        } else {
            console.log("SettingsMenuItem '"+text+"': No subpage set")
        }
    }
}
