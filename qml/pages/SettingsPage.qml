import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components"

Page {
    id: root

    header: PageHeader {
        StyleHints{backgroundColor: colors.currentHeader}
        title: i18n.tr("Shopping List") + " - " + i18n.tr("Settings")
    }

    ScrollView{
        anchors{
            fill: parent
            topMargin: header.height
        }

        Column{
            id: col
            width: root.width

            SettingsMenuItem{
                id: stManual
                text: i18n.tr("Show manual")
                iconName: "info"
                onClicked: manual.show()
            }

            SettingsMenuItem{
                id: stCategories
                text: i18n.tr("Edit categories")
                iconName: "edit"
                subpage: "pages/SettingsCategoriesPage.qml"
            }
            SettingsMenuItem{
                id: stUnits
                text: i18n.tr("Edit units")
                iconName: "edit"
                subpage: "pages/SettingsUnitsPage.qml"
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
                iconName: "edit"
                subpage: "pages/SettingsHistoryPage.qml"
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
    }
}
