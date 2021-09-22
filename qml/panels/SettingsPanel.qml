import QtQuick 2.7
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

import "../components"

Item {
    id: root

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
        }
        SettingsMenuItem{
            id: stUnits
            text: i18n.tr("Edit units")
            subpage: unitsPanel
        }

        SettingsCaption{title: i18n.tr("Suggestions")}
        SettingsMenuSwitch{
            id: stHistoryEnabled
            text: i18n.tr("Show suggestions")
            Component.onCompleted: checked = db_history.active
            onCheckedChanged: db_history.active = checked
        }
        SettingsMenuSwitch{
            id: stAcceptOnClicked
            text: i18n.tr("Insert suggestion on click")
            Component.onCompleted: checked = db_history.acceptOnClick
            onCheckedChanged: db_history.acceptOnClick = checked
        }
        SettingsMenuItem{
            id: stHistory
            text: i18n.tr("Edit history")
            subpage: historyPanel
        }

        SettingsCaption{title: i18n.tr("Appearance")}
        SettingsMenuSwitch{
            text: i18n.tr("Use default theme")
            Component.onCompleted: checked = colors.useDefaultTheme
            onCheckedChanged: colors.useDefaultTheme = checked

        }
        SettingsMenuSwitch{
            enabled: !colors.useDefaultTheme
            text: i18n.tr("Dark Mode")
            onCheckedChanged: colors.darkMode = checked
            Component.onCompleted: checked = colors.darkMode
        }
        SettingsMenuDoubleColorSelect{
            enabled: !colors.useDefaultTheme
            text: i18n.tr("Color")
            model: colors.headerColors
            Component.onCompleted: currentSelectedColor =  colors.currentIndex
            onCurrentSelectedColorChanged: colors.currentIndex = currentSelectedColor
        }
    }

    SettingsCategoriesPanel{
        id: categoriesPanel
        visible: false
    }

    SettingsHistoryPanel{
        id: historyPanel
        visible: false
    }

    SettingsUnitsPanel{
        id: unitsPanel
        visible: false
    }
}
