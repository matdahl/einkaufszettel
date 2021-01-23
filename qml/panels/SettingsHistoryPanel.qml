import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components/"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("History")

    // the database connector
    property var db_histo

    // the flag if check boxes are shown
    property bool checkMode: true

    property bool hasCheckedEntries: db_histo.hasMarkedKeys
    function deselectAll(){
        db_histo.deselectAll()
    }

    onVisibleChanged: {
        if (!visible && db_histo) db_histo.deselectAll()
    }



    /* ------------------------------------
     *               Components
     * ------------------------------------ */

    SortFilterModel{
        id: sortedModel
        model: db_histo.keyModel
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
            onRemove: db_histo.deleteKey(key)
            onToggleMarked: db_histo.toggleMarked(key)
        }
    }

    ClearListButtons{
        hasItems: listView.model.count>0
        hasCheckedItems: db_histo.hasMarkedKeys
        hasDeletedItems: db_histo.hasDeletedKeys
        onRemoveAll:      db_histo.markAllForDelete()
        onRemoveSelected: db_histo.markSelectedForDelete()
        onRemoveDeleted:  db_histo.removeDeleted()
        onRestoreDeleted: db_histo.restore()
    }
}
