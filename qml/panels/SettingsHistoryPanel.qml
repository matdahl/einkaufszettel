import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components/"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("History")

    property bool hasCheckedEntries: db_history.hasMarkedKeys
    signal deselectAll()
    onDeselectAll: db_history.deselectAll()

    onVisibleChanged: {
        if (!visible && db_history) db_history.deselectAll()
    }



    /* ------------------------------------
     *               Components
     * ------------------------------------ */

    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    UbuntuListView{
        id: listView
        anchors{
            fill: parent
            bottomMargin: units.gu(4)
        }
        currentIndex: -1
        model: db_history.presortedKeyModel
        delegate: HistoryListItem{
            Component.onCompleted: root.deselectAll.connect(uncheck)
            onRemove: db_history.deleteKey(key)
            onToggleMarked: {
                db_history.toggleMarked(key)
            }
        }
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
