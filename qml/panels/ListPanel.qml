import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components"

Item {
    id: root

    // the connector to interact with the database
    property var dbcon

    // the list of categories
    property var categories: []

    // the list of recently deleted entries
    property var deletedEntries: []

    function refresh(){
        // read categories
        var rawcat = []
        var rows = dbcon.selectCategories()
        for (var i=0; i<rows.length; i++){
            rawcat.push(rows[i].name)
        }
        // count entries
        var counts = dbcon.countEntriesPerCategory(rawcat)
        var counts_all = 0
        for (var i=0;i<counts.length;i++) counts_all += counts[i]
        categories = []
        categories.push("alle")
        var j
        for (j=0;j<rawcat.length;j++){
            categories.push(rawcat[j])
        }
        categories.push("sonstige")
        sections.refresh()
        refreshListView()
    }

    function refreshListView(){
        listView.model.clear()
        var category = root.categories[sections.selectedIndex]
        // check if all entries should be displayed
        if (sections.selectedIndex==0){
            var rows = dbcon.selectItems("")
            for (var i=0; i<rows.length; i++) {
                listView.model.append(rows[i])
            }
        } else {
            if (category==="sonstige") category = ""
            var rows = dbcon.selectItems(category)
            if (rows){
                for (var i= rows.length-1;i>-1;i--){
                    // if category=sonstige, then check whether category exists
                    if (category===""){
                        var found = false
                        for (var j=1; j<categories.length-1; j++){
                            if (categories[j]===rows[i].category) found = true
                        }
                        if (found) continue
                    }
                    listView.model.append(rows[i])
                }
            }
        }
    }

    Component.onCompleted: refresh()

    Sections{
        id: sections
        anchors{
            top:   parent.top
            left:  parent.left
            right: parent.right
        }
        height: units.gu(6)
        model: [i18n.tr("all"),i18n.tr("other")]

        onSelectedIndexChanged: refreshListView()

        function refresh(){
            var index = selectedIndex
            // get raw categories
            var rawcat = []
            for (var i=1;i<categories.length-1;i++) rawcat.push(categories[i])
            // count entries
            var counts = dbcon.countEntriesPerCategory(rawcat)
            var counts_all = 0
            for (var i=0;i<counts.length;i++) counts_all += counts[i]
            // generate titles for sections
            var newmodel = []
            if (counts_all>0){
                newmodel.push("<b>"+i18n.tr("all")+" ("+counts_all+")</b>")
            } else {
                newmodel.push(i18n.tr("all")+" ("+counts_all+")")
            }
            var j
            for (j=0;j<rawcat.length;j++){
                if (counts[j]>0){
                    newmodel.push("<b>"+rawcat[j]+" ("+counts[j]+")</b>")
                } else {
                    newmodel.push(rawcat[j]+" ("+counts[j]+")")
                }
            }
            if (counts[j]>0){
                newmodel.push("<b>"+i18n.tr("other")+" ("+counts[j]+")</b>")
            } else {
                newmodel.push(i18n.tr("other")+" ("+counts[j]+")")
            }
            model = newmodel
            selectedIndex = index
        }
    }
    Row{
        id: inputRow
        anchors.top: sections.bottom
        padding: units.gu(2)
        spacing: units.gu(2)
        TextField{
            id: inputItem
            width: root.width-btNewItem.width - 2*inputRow.padding - inputRow.spacing
            placeholderText: i18n.tr("new entry ...")
            enabled: sections.selectedIndex>0
            onAccepted: btNewItem.clicked()
        }
        Button{
            id: btNewItem
            color: theme.palette.normal.positive
            width: 1.6*height
            iconName: "add"
            enabled: sections.selectedIndex>0
            onClicked: {
                // remove deleted entries from DB
                dbcon.removeDeleted()
                // insert new entry
                if (inputItem.text !== ""){
                    dbcon.insertItem(inputItem.text,root.categories[sections.selectedIndex])
                    inputItem.text = ""
                    refresh()
                }
            }
        }
    }

    UbuntuListView{
        id: listView
        anchors{
            top:    inputRow.bottom
            bottom: btClear.top
            left:   root.left
            right:  root.right
        }
        currentIndex: -1
        model: ListModel{}
        delegate: ListItem{
            leadingActions: ListItemActions{
                actions: [
                    Action{
                        iconName: "delete"
                        onTriggered: {
                            dbcon.deleteItem(listView.model.get(index).uid)
                            sections.refresh()
                            root.refreshListView()
                        }
                    }
                ]
            }

            Label{
                anchors.centerIn: parent
                text: name
            }
            Label{
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                textSize: Label.Small
                text: category
            }
        }
    }
    Button{
        id: btClear
        width: root.width/2
        x:     root.width/4
        y:     root.height

        text: i18n.tr("clear list")
        color: UbuntuColors.orange
        state: (listView.model.count>0) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btClear; y:root.height}
            },
            State{
                name: "on"
                PropertyChanges {target: btClear; y:root.height - height - units.gu(2)}
            }
        ]
        transitions: Transition {
            reversible: true
            from: "off"
            to: "on"
            PropertyAnimation{
                property: "y"
                duration: 400
            }
        }
        onClicked: {
            // remove all entries that were deleted last time
            dbcon.removeDeleted()
            // mark all entries which are currently in listView as deleted
            for (var i=listView.model.count-1;i>-1;i--){
                dbcon.markAsDeleted(listView.model.get(i).uid)
            }
            // refresh
            sections.refresh()
            refreshListView()
        }
    }
    Button{
        id: btRestore
        width:  units.gu(6)
        height: units.gu(6)
        x: root.width
        y: root.height - height - units.gu(2)

        iconName: "undo"
        color: theme.palette.normal.base

        state: (dbcon.hasDeletedEntries) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btRestore; x:root.width}
            },
            State{
                name: "on"
                PropertyChanges {target: btRestore; x:root.width - width - units.gu(2)}
            }
        ]
        transitions: Transition {
            reversible: true
            from: "off"
            to: "on"
            PropertyAnimation{
                property: "x"
                duration: 400
            }
        }
        onClicked: {
            dbcon.restoreDeleted()
            sections.refresh()
            refreshListView()
        }
    }
}
