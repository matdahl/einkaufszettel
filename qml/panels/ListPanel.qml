import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components"

Item {
    id: root

    property var dbcon

    property var categories: []

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
        theme.name: "Ubuntu.Components.Themes.SuruDark"
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
        y:     root.height - height - units.gu(2)
        text: i18n.tr("clear list")
        color: UbuntuColors.orange
        visible: listView.model.count>0
        onClicked: {
            for (var i=listView.model.count-1;i>-1;i--){
                dbcon.deleteItem(listView.model.get(i).uid)
                sections.refresh()
                refreshListView()
            }
        }
    }
}
