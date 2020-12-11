/*
 * Copyright (C) 2020  Matthias Dahlmanns
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * einkaufszettel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import "panels"
import "db"

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'einkaufszettel.matdahl'
    automaticOrientation: true

    /*
        define theme and colors

        main color params (using gpick):
        hue: 340
        saturation: 96%
        lightness:
            headerBackground:  -20% / +10%
            background: -44% / +44%
     */
    theme.name: settings.useDarkMode ? "Ubuntu.Components.Themes.SuruDark" : "Ubuntu.Components.Themes.Ambiance"
    property color headerBackgroundColor: settings.useDarkMode ? "#960334" : "#FB3778"
    property color backgroundColor: settings.useDarkMode ? "#1E010A" : "#FEE1EB"

    width: units.gu(45)
    height: units.gu(75)

    property var dbcon: DBconnector{}

    Settings{
        id: settings
        property bool useDarkMode: true
        onUseDarkModeChanged: {
            root.theme.name = settings.useDarkMode ? "Ubuntu.Components.Themes.SuruDark" : "Ubuntu.Components.Themes.Ambiance"
        }
    }

    Page {
        anchors.fill: parent
        header: PageHeader {
            id: header
            title: i18n.tr("Shopping List")
            StyleHints{
                backgroundColor: root.headerBackgroundColor
            }

            leadingActionBar.actions: [
                Action{
                    iconName: "back"
                    visible: stack.depth>1
                    onTriggered: stack.pop()
                }
            ]
            trailingActionBar.actions: [
                Action{
                    iconName: "settings"
                    onTriggered: {
                        while (stack.depth>1 && stack.currentItem!==settingsPanel) stack.pop()
                        if (stack.currentItem!==settingsPanel) {
                            settingsPanel.refresh()
                            stack.push(settingsPanel)
                        }
                    }
                }
            ]
        }

        Rectangle{
            id: background
            color: root.backgroundColor
            anchors.fill: parent
        }

        StackView{
            id: stack
            anchors.fill: parent
        }
        ListPanel{
            id: listPanel
            Component.onCompleted: stack.push(listPanel)
            dbcon: root.dbcon
        }

        SettingsPanel{
            id: settingsPanel
            visible: false
            dbcon: root.dbcon
            stack: stack
            Component.onCompleted: {
                useDarkMode = settings.useDarkMode
            }

            onUseDarkModeChanged: settings.useDarkMode = useDarkMode
            onCategoriesChanged: listPanel.refresh()
        }
    }
}
