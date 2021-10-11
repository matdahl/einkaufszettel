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
        Component.onCompleted: db_categories.categoriesChanged.connect(update)
        onSelectedIndexChanged: {
            if (selectedIndex <= 0)
                db_entries.updateSelectedCategory("",false)
            else if (selectedIndex > db_categories.model.count)
                db_entries.updateSelectedCategory("",true)
            else
                db_entries.updateSelectedCategory(db_categories.model.get(selectedIndex-1).name,false)
        }
        function update(){
            // check if sections need to be reduced
            var index = -2
            if (db_categories.model.count+2 < actions.length){
                index = selectedIndex
                for (var j=actions.length-1; j>0; j--)
                    actions[j].destroy()
                actions = []
            }

            // check if sections need to be added
            if (db_categories.model.count+2 > actions.length){
                index = selectedIndex
                for (var i=actions.length; i<db_categories.model.count+2; i++){
                    actions.push(Qt.createQmlObject("import Ubuntu.Components 1.3; Action{text:'test "+i+"'}",sections))
                }
            }
            if (index !== -2 && index < actions.length)
                selectedIndex = index

            // update texts
            actions[0].text = db_categories.countAll>0 ? "<b>" + i18n.tr("all") + " ("+db_categories.countAll+")</b>"
                                                       : i18n.tr("all") + " (0)"
            actions[db_categories.model.count+1].text = db_categories.countOther>0 ? "<b>" + i18n.tr("other") + " ("+db_categories.countOther+")</b>"
                                                                                   : i18n.tr("other") + " (0)"
            for (var k=0; k<db_categories.model.count; k++){
                var count = db_categories.model.get(k).count
                var txt = count>0 ? "<b>" : ""
                txt += db_categories.model.get(k).name + " ("+count+")"
                txt += count>0? "</b>" : ""
                actions[k+1].text = txt
            }
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
        hasDeletedItems: db_entries.hasDeleted
        hasCheckedItems: db_entries.hasChecked
        onRemoveDeleted:  db_entries.removeDeleted()
        onRemoveAll:      db_entries.removeAll()
        onRemoveSelected: db_entries.removeSelected()
        onRestoreDeleted: db_entries.restoreDeleted()
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
