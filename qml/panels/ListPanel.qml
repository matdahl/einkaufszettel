import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3

import "../components"
import "../components/listitems"

Item {
    id: root

    property string headerSuffix: ""
    readonly property bool hasCheckedEntries: db_entries.hasChecked


    function deselectAll(){
        for (var i=0;i<db_entries.entryModel.count;i++){
            var item = db_entries.entryModel.get(i)
            if (item.marked===1)
                db_entries.toggleMarked(item.uid)
        }
    }


    /* ------------------------------------
     *               Components
     * ------------------------------------ */

    Sections{
        id: sections
        anchors{
            top:   parent.top
            left:  parent.left
            right: parent.right
        }
        height: units.gu(6)
        model: db_categories.list
        onSelectedIndexChanged: {
            if (selectedIndex === 0)
                db_entries.updateSelectedCategory("",false)
            else if (selectedIndex === model.length-1)
                db_entries.updateSelectedCategory("",true)
            else
                db_entries.updateSelectedCategory(db_categories.rawModel.get(selectedIndex-1).name,false)
        }
    }

    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    UbuntuListView{
        id: listView
        anchors{
            top:    inputRow.bottom
            bottom: root.bottom
            left:   root.left
            right:  root.right
            bottomMargin: units.gu(6)
        }
        clip: true
        currentIndex: -1
        model: db_entries.entryModel
        delegate: EntryListItem{
            onMoveDown: {
                dbcon.swapItems(uid,listView.model.get(index+1).uid)
                // swap items in view
                var tempUID = uid
                uid = listView.model.get(index+1).uid
                listView.model.setProperty(index+1,"uid",tempUID)
                listView.model.move(index+1,index,1)
            }
            onMoveUp: {
                dbcon.swapItems(uid,listView.model.get(index-1).uid)
                // swap items in view
                var tempUID = uid
                uid = listView.model.get(index-1).uid
                listView.model.setProperty(index-1,"uid",tempUID)
                listView.model.move(index-1,index,1)
            }
        }
    }

    InputRow{
        id: inputRow
        width: parent.width
        anchors.top: sections.bottom
        placeholderText: i18n.tr("new entry ...")
        enabled: sections.selectedIndex>0
        onAccepted: {
            if (text.trim() !== ""){
                db_entries.insert(text.trim(),inputRow.quantity,inputRow.dimension)
                db_history.addKey(text.trim())
                reset()
            }
        }
    }

    ClearListButtons{
        id: clearList
        hasItems:        listView.model.count>0
        hasDeletedItems: dbcon.hasDeletedEntries
        hasCheckedItems: db_entries.hasChecked
        onRemoveDeleted:  dbcon.removeDeleted()
        onRestoreDeleted: dbcon.restoreDeleted()
        onRemoveAll:{
            for (var i=listView.model.count-1;i>-1;i--){
                dbcon.markAsDeleted(listView.model.get(i).uid)
            }
        }
        onRemoveSelected: {
            for (var i=listView.model.count-1;i>-1;i--){
                if (listView.model.get(i).marked===1){
                    dbcon.markAsDeleted(listView.model.get(i).uid)
                }
            }
        }
    }

    // Navigation buttons to switch between categories
    Button{
        id: btPrevious
        anchors{
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(2)
        }
        height: units.gu(4)
        width:  units.gu(6)
        visible: sections.selectedIndex>0
        onClicked: sections.selectedIndex -= 1
        Icon{
            anchors.centerIn: parent
            height: 0.7*parent.height
            name: "previous"
            color: theme.palette.normal.baseText
        }
    }
    Button{
        id: btNext
        anchors{
            bottom: parent.bottom
            right: parent.right
            margins: units.gu(2)
        }
        height: units.gu(4)
        width:  units.gu(6)
        visible: sections.selectedIndex <sections.model.length-1
        onClicked: sections.selectedIndex += 1
        Icon{
            anchors.centerIn: parent
            height: 0.7*parent.height
            name: "next"
            color: theme.palette.normal.baseText
        }
    }
}
