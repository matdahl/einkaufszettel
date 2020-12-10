import QtQuick 2.7
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

import "../components"

Item {
    id: root
    property var dbcon
    property var stack

    // settings
    property bool useDarkMode: false

    function refresh(){
        categoriesPanel.refresh()
    }

    signal categoriesChanged()

    Column{
        id: col
        width: root.width
        SettingsMenuItem{
            id: itCategories
            text: i18n.tr("Categories")
            subpage: categoriesPanel
            stack: root.stack
        }
        SettingsMenuSwitch{
            id: itDarkMode
            text: i18n.tr("Dark Mode")
            checked: root.useDarkMode
            onCheckedChanged: useDarkMode = checked
        }
    }

    SettingsCategoriesPanel{
        id: categoriesPanel
        visible: false
        dbcon: root.dbcon
        onCategoriesChanged: root.categoriesChanged()
    }
}
