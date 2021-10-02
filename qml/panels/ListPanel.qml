import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3

import "../components"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: ""
    property bool hasCheckedEntries: checkedEntries>0

    // the number of checked entries in the current list
    property int checkedEntries: 0

    // deselect all entries in current list
    function deselectAll(){
        for (var i=0;i<listView.model.count;i++){
            if (listView.model.get(i).marked===1){
                dbcon.toggleItemMarked(listView.model.get(i).uid)
                listView.model.get(i).marked = 0
            }
        }
        checkedEntries = 0
        listView.refresh()
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
        model: db_categories.categoriesList

        // connect signals from DB connector with slots
        Component.onCompleted: {
            dbcon.itemsChanged.connect(recount)
            dbcon.categoryListChanged.connect(refresh)
            //model = Qt.binding(function() { return db_categories.categoriesList })
            refresh()
        }
        onSelectedIndexChanged: listView.refresh()

        /* refreshs the sections in case the categories changed */
        function refresh(){
            return; // deactivate refresh function
            // empty old model
            model.length = 0
            for (var i=0;i<dbcon.categoriesModel.count;i++){
                model.push(dbcon.categoriesModel.get(i).name)
            }
            // count entries per category
            recount()
        }

        /* update the counts of entries per category */
        function recount(){
            var counts = dbcon.countEntriesPerCategory()
            model[0] = (counts[0]>0) ? "<b>"+i18n.tr("all")+" ("+counts[0]+")</b>"
                                              :       i18n.tr("all")+" (0)"
            var j
            for (j=1;j<model.length-1;j++){
                model[j] = (counts[j]>0) ? "<b>"+dbcon.categoriesModel.get(j).name+" ("+counts[j]+")</b>"
                                                  :       dbcon.categoriesModel.get(j).name+" (0)"
            }
            model[j] = (counts[j]>0) ? "<b>"+i18n.tr("other")+" ("+counts[j]+")</b>"
                                              :       i18n.tr("other")+" (0)"
            // trigger event to repaint view
            var temp = selectedIndex
            modelChanged()
            selectedIndex = temp
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


        function recountChecked(){
            var count = 0
            for (var i=0;i<model.count;i++){
                if (model.get(i).marked===1) count += 1
            }
            checkedEntries = count
        }

        function refresh(){
            return; // deactivate refresh function
            model.clear()
            // check if all entries should be displayed
            if (sections.selectedIndex==0){
                var rows = dbcon.selectItems("")
                for (var i=rows.length-1; i>-1; i--) {
                    listView.model.append(rows[i])
                }
            } else {
                var category = dbcon.categoriesModel.get(sections.selectedIndex).name
                var rows = dbcon.selectItems((category===i18n.tr("other")) ? "" : category)
                if (rows){
                    for (var i= rows.length-1;i>-1;i--){
                        // if category=other, then check whether category exists
                        if (category===i18n.tr("other")){
                            var found = false
                            for (var j=1; j<dbcon.categoriesList.length-1; j++){
                                if (dbcon.categoriesList[j]===rows[i].category) {
                                    found = true
                                    break
                                }
                            }
                            if (found) continue
                        }
                        listView.model.append(rows[i])
                    }
                }
            }
            recountChecked()
        }

        delegate: EntryListItem{
            onRemove: dbcon.deleteItem(uid)
            onToggleMarked: {
                dbcon.toggleItemMarked(uid)
                if (marked===1) {
                    checkedEntries -= 1
                } else{
                    checkedEntries += 1
                }
            }
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
            if (text !== ""){
                // insert new entry to database
                dbcon.insertItem(text.trim(),dbcon.categoriesList[sections.selectedIndex],inputRow.quantity,inputRow.dimension)
                // insert new entry to history
                db_history.addKey(text.trim())
                reset()
            }
        }
    }

    ClearListButtons{
        id: clearList
        hasItems:        listView.model.count>0
        hasDeletedItems: dbcon.hasDeletedEntries
        hasCheckedItems: checkedEntries>0
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
