import QtQuick 2.7
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

import "../components"

Item {
    id: root
    property var dbcon
    property var stack
    property var colors

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
            onCheckedChanged: colors.darkMode = checked
            Component.onCompleted: checked = colors.darkMode
        }
        SettingsMenuDoubleColorSelect{
            id: stColor
            text: i18n.tr("Color")
            model: colors.headerColors
            Component.onCompleted: currentSelectedColor =  colors.currentIndex
            onCurrentSelectedColorChanged: colors.currentIndex = currentSelectedColor
        }
    }

    SettingsCategoriesPanel{
        id: categoriesPanel
        visible: false
        dbcon: root.dbcon
        onCategoriesChanged: root.categoriesChanged()
    }
}
