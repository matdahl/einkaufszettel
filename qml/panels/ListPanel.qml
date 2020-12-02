import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components"

Item {
    id: root

    property var dbcon

    property var categories: []

    function refresh(){
        // read categories
        categories = []
        var rows = dbcon.selectCategories()
        for (var i=0; i<rows.length; i++){
            categories.push(rows[i].name)
        }
        categories.push("sonstige")
        sections.model = categories
        refreshListView()
    }

    function refreshListView(){
        listView.model.clear()
        var category = sections.model[sections.selectedIndex]
        if (category==="sonstige") category = ""
        var rows = dbcon.selectItems(category)
        if (rows){
            for (var i= rows.length-1;i>-1;i--){
                // if category=sonstige, then check whether category exists
                if (category===""){
                    var found = false
                    for (var j=0; j<categories.length; j++){
                        if (categories[j]===rows[i].category) found = true
                    }
                    if (found) continue
                }
                listView.model.append(rows[i])
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

        model: root.categories
        onSelectedIndexChanged: refreshListView()
    }
    Row{
        id: inputRow
        anchors.top: sections.bottom
        padding: units.gu(2)
        spacing: units.gu(2)
        TextField{
            id: inputItem
            width: root.width-btNewItem.width - 2*inputRow.padding - inputRow.spacing
            placeholderText: "neue Eingabe ..."
        }
        Button{
            id: btNewItem
            color: UbuntuColors.green
            width: 1.6*height
            iconName: "add"
            onClicked: {
                if (inputItem.text !== ""){
                    dbcon.insertItem(inputItem.text,sections.model[sections.selectedIndex])
                    inputItem.text = ""
                    refreshListView()
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
        model: ListModel{}
        delegate: ListItem{
            leadingActions: ListItemActions{
                actions: [
                    Action{
                        iconName: "delete"
                        onTriggered: {
                            dbcon.deleteItem(listView.model.get(index).uid)
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
        text: "Liste leeren"
        color: UbuntuColors.orange
        visible: listView.model.count>0
        onClicked: {
            for (var i=listView.model.count-1;i>-1;i--){
                dbcon.deleteItem(listView.model.get(i).uid)
                refreshListView()
            }
        }
    }
}
