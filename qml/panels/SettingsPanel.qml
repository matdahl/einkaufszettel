import QtQuick 2.7
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

import "../components"

Item {
    id: root
    property var dbcon
    property var db_histo
    property var stack
    property var colors
    property var dimensions

    property string headerSuffix: i18n.tr("Settings")
    property bool hasCheckedEntries: false

    Column{
        id: col
        width: root.width

        //SettingsCaption{title: i18n.tr("General")}
        SettingsMenuItem{
            id: stCategories
            text: i18n.tr("Edit categories")
            subpage: categoriesPanel
            stack: root.stack
        }
        SettingsMenuItem{
            id: stUnits
            text: i18n.tr("Edit units")
            subpage: unitsPanel
            stack: root.stack
        }

        SettingsCaption{title: i18n.tr("Suggestions")}
        SettingsMenuSwitch{
            id: stHistoryEnabled
            text: i18n.tr("Show suggestions")
            Component.onCompleted: checked = db_histo.active
            onCheckedChanged: db_histo.active = checked
        }
        SettingsMenuItem{
            id: stHistory
            text: i18n.tr("Edit history")
            subpage: historyPanel
            stack: root.stack
        }

        SettingsCaption{title: i18n.tr("Appearance")}
        SettingsMenuSwitch{
            id: stDarkMode
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
    }

    SettingsHistoryPanel{
        id: historyPanel
        visible: false
        db_histo: root.db_histo
    }

    SettingsUnitsPanel{
        id: unitsPanel
        visible: false
        dimensions: root.dimensions
    }
}
