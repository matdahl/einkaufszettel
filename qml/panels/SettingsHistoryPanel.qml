import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components/"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("History")

    // the flag if check boxes are shown
    property bool checkMode: true

    property bool hasCheckedEntries: db_history.hasMarkedKeys
    function deselectAll(){
        db_history.deselectAll()
    }

    onVisibleChanged: {
        if (!visible && db_history) db_history.deselectAll()
    }



    /* ------------------------------------
     *               Components
     * ------------------------------------ */

    SortFilterModel{
        id: sortedModel
        model: db_history.sortedKeyModel
        sort.property: "key"
        sort.order: Qt.AscendingOrder
        sortCaseSensitivity: Qt.CaseInsensitive
    }

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
        model: sortedModel
        delegate: HistoryListItem{
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
