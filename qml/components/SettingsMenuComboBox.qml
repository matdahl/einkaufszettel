import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import QtQuick.Controls 2.2

/*
 * An item for the settings list which pushs a new subpage to the stack if clicked on
 */
ListItem{
    id: root

    property var model: [""]

    property string currentText: cb.currentText

    // the text to display on the item
    property string text

    // states whether the switcher was checked
    property bool checked: false

    ListItemLayout {
        id: layout
        anchors.fill: parent

        title.text: root.text

        ComboBox {id: cb
            SlotsLayout.position: SlotsLayout.Last
            width: 0.4*parent.width
            model: root.model
        }
    }
}
