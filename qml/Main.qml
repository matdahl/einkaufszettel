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

import "components"
import "db"

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'einkaufszettel.matdahl'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    Component.onCompleted: {
        pages.push(Qt.resolvedUrl("pages/MainPage.qml"))
        if (settings.showManualOnStart)
            manual.show()
    }

    // the database connector which manage all interactions for entries
    DBEntries{
        id: db_entries
    }

    // the database connector which manage all interactions for categories
    DBCategories{
        id: db_categories
    }

    // the database connector to store the history of entries if wanted
    DBHistory{
        id: db_history
    }

    // the colors object which stores all informations about current color theme settings
    Colors{
        id: colors
        defaultIndex: 1
    }
    theme.name: colors.currentThemeName


    // the units to measure quantities of entries
    Dimensions{
        id: dimensions
    }

    // settings
    Settings{
        id: settings
        property bool showManualOnStart: true
    }

    // user interface
    PageStack{
        id: pages
    }

    ManualPopover{
        id: manual
    }
}
