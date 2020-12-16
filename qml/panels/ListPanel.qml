import QtQuick 2.7
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3

import "../components"

Item {
    id: root
    property string headerSuffix: ""

    // the connector to interact with the entries and categories database
    property var dbcon

    // the connector to interact with the history database
    property var db_histo

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
            for (var i=rows.length-1; i>-1; i--) {
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
        onFocusChanged: dbcon.removeDeleted()

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

    UbuntuListView{
        id: listView
        anchors{
            top:    inputRow.bottom
            bottom: btClear.top
            left:   root.left
            right:  root.right
            bottomMargin: units.gu(4)
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
            MouseArea{
                id: mouseDown
                visible: index<listView.model.count-1
                anchors{
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
                width: 1.5*height
                Icon{
                    name: "down"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked:{
                    dbcon.swapItems(listView.model.get(index).uid,listView.model.get(index+1).uid)
                    root.refreshListView()
                }
            }
            MouseArea{
                id: mouseUp
                visible: index>0
                anchors{
                    top:    parent.top
                    right:  parent.right
                    bottom: parent.bottom
                }
                width: 1.5*height
                Icon{
                    name: "up"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked: {
                    dbcon.swapItems(listView.model.get(index).uid,listView.model.get(index-1).uid)
                    root.refreshListView()
                }
            }
            Rectangle{
                id: downGradient
                width: 0.5*parent.width
                height: width
                x: 0
                y: 0.5*(parent.height-height)
                rotation: 90
                gradient: Gradient {
                        GradientStop { position: 1.0; color: "#88aa8888"}
                        GradientStop { position: 0.0; color: "#00aa8888"}
                    }
                visible: mouseDown.pressed
            }
            Rectangle{
                id: upGradient
                width: 0.5*parent.width
                height: width
                x: 0.5*parent.width
                y: 0.5*(parent.height-height)
                rotation: 90
                gradient: Gradient {
                        GradientStop { position: 0.0; color: "#8888aa88"}
                        GradientStop { position: 1.0; color: "#0088aa88"}
                    }
                visible: mouseUp.pressed
            }
        }
    }


    InputRow{
        id: inputRow
        width: parent.width
        anchors.top: sections.bottom
        placeholderText: i18n.tr("new entry ...")
        enabled: sections.selectedIndex>0
        db_histo: root.db_histo
        Component.onCompleted: {
            updateModel(db_histo)
        }
        onAccepted: {
            // remove deleted entries from DB
            dbcon.removeDeleted()
            if (text !== ""){
                // insert new entry to database
                dbcon.insertItem(text,root.categories[sections.selectedIndex])
                // insert new entry to history
                db_histo.addKey(text)
                // refresh
                refresh()
                reset()
                updateModel(db_histo)
            }
        }
    }
    // button to restore entries which where previously deleted
    Button{
        id: btRestore
        width: 0.4*root.width
        x:     0.3*root.width

        iconName: "undo"
        color: theme.palette.normal.base

        state: (dbcon.hasDeletedEntries) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btRestore; y: root.parent.height}
            },
            State{
                name: "on"
                PropertyChanges {target: btRestore; y: root.parent.height - height - units.gu(2)}
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
            dbcon.restoreDeleted()
            sections.refresh()
            refreshListView()
        }
    }

    // button to delete all currently displayed entries
    Button{
        id: btClear
        width: root.width/2
        x:     root.width/4

        text: i18n.tr("clear list")
        color: UbuntuColors.orange
        state: (listView.model.count>0) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btClear; y:root.parent.height}
            },
            State{
                name: "on"
                PropertyChanges {target: btClear; y:root.parent.height - height - units.gu(2)}
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

    // Navigation buttons to switch between categories
    Button{
        id: btPrevious
        anchors{
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(2)
        }
        height: units.gu(6)
        width:  height
        iconName: "previous"
        visible: sections.selectedIndex>0
        onClicked: {
            dbcon.removeDeleted()
            sections.selectedIndex -= 1
        }
        strokeColor: theme.palette.normal.base
    }
    Button{
        id: btNext
        anchors{
            bottom: parent.bottom
            right: parent.right
            margins: units.gu(2)
        }
        height: units.gu(6)
        width:  height
        iconName: "next"
        visible: sections.selectedIndex <sections.model.length-1
        onClicked: {
            dbcon.removeDeleted()
            sections.selectedIndex += 1
        }
        strokeColor: theme.palette.normal.base
    }
}
