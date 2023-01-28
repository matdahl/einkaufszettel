import QtQuick 2.7
import Lomiri.Components 1.3

import "../components/"
import "../components/listitems"

Page {
    id: root

    header: PageHeader {
        StyleHints{backgroundColor: colors.currentHeader}
        title: i18n.tr("Shopping List") + " - " + i18n.tr("History")
        trailingActionBar.actions: [
            Action{
                iconName: "select-none"
                visible: db_history.hasMarkedKeys
                onTriggered: db_history.deselectAll()
            }
        ]
    }

    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    LomiriListView{
        id: listView
        anchors{
            fill: parent
            topMargin: root.header.height
            bottomMargin: units.gu(4)
        }
        currentIndex: -1
        model: db_history.presortedKeyModel
        delegate: HistoryListItem{}
    }

    ClearListButtons{
        hasItems:        listView.model.count>0
        hasCheckedItems: db_history.hasMarkedKeys
        hasDeletedItems: db_history.hasDeletedKeys
        onRemoveAll:      db_history.markAllForDelete()
        onRemoveSelected: db_history.markSelectedForDelete()
        onRemoveDeleted:  db_history.removeDeleted()
        onRestoreDeleted: db_history.restore()
    }


}
